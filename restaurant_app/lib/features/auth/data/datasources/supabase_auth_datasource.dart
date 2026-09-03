import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

/// Supabase-backed implementation of [AuthRemoteDataSource].
class SupabaseAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  SupabaseAuthRemoteDataSourceImpl(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<UserModel> login(String identifier, String password) async {
    try {
      final AuthResponse response;
      if (identifier.contains('@')) {
        response = await _supabase.auth.signInWithPassword(
          email: identifier.trim(),
          password: password,
        );
      } else {
        response = await _supabase.auth.signInWithPassword(
          phone: identifier.trim(),
          password: password,
        );
      }

      final user = response.user;
      if (user == null) {
        throw const ServerException(
          'فشل تسجيل الدخول: لم يتم العثور على بيانات المستخدم',
        );
      }

      return await _fetchOrConstructProfile(
        user,
        response.session?.accessToken,
      );
    } on AuthException catch (e) {
      AppLogger.warning('Supabase login AuthException: ${e.message}');
      throw InvalidCredentialsException(e.message);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error(
        'Supabase login unexpected error',
        error: e,
        stackTrace: st,
      );
      throw const ServerException(
        'حدث خطأ في الاتصال بالخادم، يرجى المحاولة لاحقاً',
      );
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String restaurantId,
    UserRole role = UserRole.customer,
  }) async {
    try {
      final safeRestaurantId = _resolveRestaurantId(restaurantId);
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name.trim(),
          'phone': phone.trim(),
          'restaurant_id': safeRestaurantId,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const ServerException(
          'فشل إنشاء الحساب، يرجى التحقق من البيانات والمحاولة مرة أخرى',
        );
      }

      // When email confirmation is enabled, Supabase returns a user WITHOUT a
      // session. Persisting that as an authenticated session would leave the
      // app "logged in" with a null token while every RLS-gated call fails.
      // Surface it as an explicit message instead.
      if (response.session?.accessToken == null) {
        // Best-effort profile self-heal for the confirmation-pending user so
        // the row exists once they confirm and sign in.
        await _ensureProfileRow(
          user,
          name: name,
          phone: phone,
          restaurantId: safeRestaurantId,
        );
        throw const ServerException(
          'تم إنشاء الحساب بنجاح، يرجى تأكيد البريد الإلكتروني ثم تسجيل الدخول',
        );
      }

      // Profile is auto-created by the `on_auth_user_created` trigger on
      // auth.users (see migration 20260904000000_account_linking_hardening).
      // _fetchOrConstructProfile self-heals the row if the trigger lagged.
      final profile = await _fetchOrConstructProfile(
        user,
        response.session?.accessToken,
      );
      return profile.copyWith(restaurantId: safeRestaurantId);
    } on AuthException catch (e) {
      AppLogger.warning('Supabase register AuthException: ${e.message}');
      throw ServerException(e.message);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error(
        'Supabase register unexpected error',
        error: e,
        stackTrace: st,
      );
      throw const ServerException('حدث خطأ في التسجيل، يرجى المحاولة مرة أخرى');
    }
  }

  @override
  Future<UserModel> verifyOtp({
    required String otp,
    required String phone,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        token: otp.trim(),
        phone: phone.trim(),
      );

      final user = response.user;
      if (user == null) {
        throw const ServerException('رمز التحقق غير صحيح');
      }

      return await _fetchOrConstructProfile(
        user,
        response.session?.accessToken,
      );
    } on AuthException catch (e) {
      AppLogger.warning('Supabase verifyOtp AuthException: ${e.message}');
      throw InvalidCredentialsException(e.message);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Supabase verifyOtp error', error: e, stackTrace: st);
      throw const ServerException('خطأ أثناء التحقق، يرجى المحاولة مرة أخرى');
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    // NOTE: the [refreshToken] argument is legacy from the Dio backend. In
    // Supabase mode the SDK owns refresh-token persistence (and auto-refresh)
    // internally, so the session is refreshed from the SDK store directly.
    try {
      final response = await _supabase.auth.refreshSession();
      final token = response.session?.accessToken;
      if (token == null || token.isEmpty) {
        throw const ServerException(
          'جلسة العمل منتهية، يرجى إعادة تسجيل الدخول',
        );
      }
      return token;
    } on AuthException catch (e) {
      AppLogger.warning('Supabase refreshToken AuthException: ${e.message}');
      throw ServerException(e.message);
    } catch (e, st) {
      AppLogger.error('Supabase refreshToken error', error: e, stackTrace: st);
      throw const ServerException('فشل تجديد الجلسة');
    }
  }

  @override
  Future<void> logout(String? token) async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      AppLogger.warning('Supabase signOut notice: $e');
    }
  }

  /// Fetches the profile from the `profiles` table or falls back to `userMetadata`.
  ///
  /// When the row is missing (e.g. the `on_auth_user_created` trigger lagged
  /// or predates the hardening migration), one self-heal insert is attempted
  /// before degrading to the minimal identity below — so a missing row can
  /// never silently strand the account's cart/orders/loyalty linkage.
  Future<UserModel> _fetchOrConstructProfile(User user, String? token) async {
    try {
      var data = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      data ??= await _ensureProfileRow(user);

      if (data != null) {
        return UserModel(
          id: user.id,
          name:
              data['name'] as String? ??
              user.userMetadata?['name'] as String? ??
              'مستخدم',
          email: data['email'] as String? ?? user.email ?? '',
          phone:
              data['phone'] as String? ??
              user.phone ??
              user.userMetadata?['phone'] as String? ??
              '',
          // SECURITY: the role comes ONLY from the server-side profiles row.
          // Signup metadata (`user_metadata`) is client-controlled and must
          // never grant privileges. Missing role degrades to customer.
          role: UserRole.fromName(data['role'] as String?),
          restaurantId:
              data['restaurant_id'] as String? ??
              user.userMetadata?['restaurant_id'] as String?,
          token: token,
          createdAt: data['created_at'] != null
              ? DateTime.tryParse(data['created_at'] as String) ??
                    DateTime.now()
              : DateTime.now(),
        );
      }
    } catch (e) {
      AppLogger.warning(
        'Could not load profile from table, falling back to metadata: $e',
      );
    }

    // Profile unavailable: construct a MINIMAL unprivileged identity.
    // Name/email/phone may come from signup metadata (cosmetic fields), but the
    // role is forced to customer — never read from client-controlled metadata.
    final meta = user.userMetadata ?? {};
    AppLogger.warning(
      'Profile row missing for ${user.id}; defaulting role to customer',
    );
    return UserModel(
      id: user.id,
      name: (meta['name'] as String?) ?? 'مستخدم',
      email: user.email ?? (meta['email'] as String?) ?? '',
      phone: user.phone ?? (meta['phone'] as String?) ?? '',
      role: UserRole.customer,
      restaurantId:
          (meta['restaurant_id'] as String?) ?? SupabaseConfig.defaultRestaurantId,
      token: token,
      createdAt: DateTime.now(),
    );
  }

  /// Best-effort self-heal for a missing `profiles` row.
  ///
  /// Succeeds only for the caller's own row (`id = auth.uid()` per RLS) and is
  /// a no-op when the row already exists. Returns the row when one is (now)
  /// present, else null. Role is intentionally omitted: the server trigger
  /// `enforce_profile_insert_role` forces `customer` regardless.
  Future<Map<String, dynamic>?> _ensureProfileRow(
    User user, {
    String? name,
    String? phone,
    String? restaurantId,
  }) async {
    try {
      final meta = user.userMetadata ?? {};
      final resolvedName =
          name?.trim().isNotEmpty == true ? name!.trim() : null;
      final resolvedPhone =
          phone?.trim().isNotEmpty == true ? phone!.trim() : null;
      await _supabase.from(SupabaseConfig.profilesTable).upsert(
        {
          'id': user.id,
          'name':
              resolvedName ?? (meta['name'] as String?) ?? 'مستخدم جديد',
          'email': user.email ?? (meta['email'] as String?),
          'phone': resolvedPhone ?? user.phone ?? (meta['phone'] as String?),
          'restaurant_id':
              restaurantId ?? (meta['restaurant_id'] as String?),
        },
        onConflict: 'id',
        ignoreDuplicates: true,
      );
      return await _supabase
          .from(SupabaseConfig.profilesTable)
          .select()
          .eq('id', user.id)
          .maybeSingle()
          .then((row) => row == null ? null : Map<String, dynamic>.from(row as Map));
    } catch (e) {
      AppLogger.warning('Profile self-heal skipped for ${user.id}: $e');
      return null;
    }
  }

  /// Accepts [restaurantId] only when it is a well-formed UUID; anything else
  /// (empty, demo ids, garbage) falls back to the configured default so the
  /// server trigger never receives a value that would orphan the profile.
  String _resolveRestaurantId(String restaurantId) {
    if (_isValidUuid(restaurantId)) return restaurantId;
    return SupabaseConfig.defaultRestaurantId;
  }

  bool _isValidUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}
