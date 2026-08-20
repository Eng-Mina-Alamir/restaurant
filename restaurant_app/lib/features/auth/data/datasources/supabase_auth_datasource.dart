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
      AppLogger.error('Supabase login unexpected error', error: e, stackTrace: st);
      throw const ServerException('حدث خطأ في الاتصال بالخادم، يرجى المحاولة لاحقاً');
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.customer,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name.trim(),
          'phone': phone.trim(),
        },
      );

      final user = response.user;
      if (user == null) {
        throw const ServerException('فشل إنشاء الحساب، يرجى التحقق من البيانات والمحاولة مرة أخرى');
      }

      // Upsert profile in `profiles` table (server trigger forces role to customer for safety)
      try {
        await _supabase.from(SupabaseConfig.profilesTable).upsert({
          'id': user.id,
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'role': UserRole.customer.name,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (profileError) {
        AppLogger.warning('Direct profile upsert skipped/handled by trigger: $profileError');
      }

      return UserModel(
        id: user.id,
        name: name,
        email: email,
        phone: phone,
        role: UserRole.customer,
        token: response.session?.accessToken,
        createdAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      AppLogger.warning('Supabase register AuthException: ${e.message}');
      throw ServerException(e.message);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Supabase register unexpected error', error: e, stackTrace: st);
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
    try {
      final response = await _supabase.auth.refreshSession();
      final token = response.session?.accessToken;
      if (token == null || token.isEmpty) {
        throw const ServerException('جلسة العمل منتهية، يرجى إعادة تسجيل الدخول');
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
  Future<UserModel> _fetchOrConstructProfile(User user, String? token) async {
    try {
      final data = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        return UserModel(
          id: user.id,
          name: data['name'] as String? ?? user.userMetadata?['name'] as String? ?? 'مستخدم',
          email: data['email'] as String? ?? user.email ?? '',
          phone: data['phone'] as String? ?? user.phone ?? user.userMetadata?['phone'] as String? ?? '',
          role: UserRole.fromName(data['role'] as String? ?? user.userMetadata?['role'] as String?),
          token: token,
          createdAt: data['created_at'] != null
              ? DateTime.tryParse(data['created_at'] as String) ?? DateTime.now()
              : DateTime.now(),
        );
      }
    } catch (e) {
      AppLogger.warning('Could not load profile from table, falling back to metadata: $e');
    }

    final meta = user.userMetadata ?? {};
    return UserModel(
      id: user.id,
      name: (meta['name'] as String?) ?? 'مستخدم',
      email: user.email ?? (meta['email'] as String?) ?? '',
      phone: user.phone ?? (meta['phone'] as String?) ?? '',
      role: UserRole.fromName(meta['role'] as String?),
      token: token,
      createdAt: DateTime.now(),
    );
  }
}
