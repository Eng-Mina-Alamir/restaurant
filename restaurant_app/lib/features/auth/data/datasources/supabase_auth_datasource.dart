import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/exceptions.dart';
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
        throw const ServerException('فشل تسجيل الدخول: لم يتم العثور على بيانات المستخدم');
      }

      return await _fetchOrConstructProfile(user, response.session?.accessToken);
    } on AuthException catch (e) {
      throw InvalidCredentialsException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('خطأ في الاتصال بالخادم: $e');
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
          'role': role.name,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const ServerException('فشل إنشاء الحساب');
      }

      // Upsert profile in `profiles` table
      try {
        await _supabase.from(SupabaseConfig.profilesTable).upsert({
          'id': user.id,
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'role': role.name,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        // If RLS prevents direct upsert or trigger handles it, continue
      }

      return UserModel(
        id: user.id,
        name: name,
        email: email,
        phone: phone,
        role: role,
        token: response.session?.accessToken,
        createdAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('خطأ في التسجيل: $e');
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

      return await _fetchOrConstructProfile(user, response.session?.accessToken);
    } on AuthException catch (e) {
      throw InvalidCredentialsException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('خطأ أثناء التحقق: $e');
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await _supabase.auth.refreshSession();
      final token = response.session?.accessToken;
      if (token == null || token.isEmpty) {
        throw const ServerException('جلسة العمل منتهية');
      }
      return token;
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('فشل تجديد الجلسة: $e');
    }
  }

  @override
  Future<void> logout(String? token) async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Clean exit
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
    } catch (_) {
      // Fallback to user metadata
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
