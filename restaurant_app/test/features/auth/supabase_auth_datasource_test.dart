import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/exceptions.dart';
import 'package:restaurant_app/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseAuthRemoteDataSourceImpl Unit Tests', () {
    late SupabaseClient client;
    late SupabaseAuthRemoteDataSourceImpl datasource;

    setUp(() {
      client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
      datasource = SupabaseAuthRemoteDataSourceImpl(client);
    });

    test('initializes with SupabaseClient successfully', () {
      expect(datasource, isNotNull);
    });

    test(
      'login with invalid credentials throws ServerException or InvalidCredentialsException',
      () async {
        expect(
          () => datasource.login('invalid@example.com', 'wrongpassword'),
          throwsA(isA<AppException>()),
        );
      },
    );

    test(
      'login with phone number routes properly and catches auth exceptions',
      () async {
        expect(
          () => datasource.login('01012345678', 'wrongpass'),
          throwsA(isA<AppException>()),
        );
      },
    );

    test(
      'register with invalid email/parameters throws AppException',
      () async {
        expect(
          () => datasource.register(
            name: 'تست',
            email: 'invalid-email',
            phone: '01000000000',
            password: '123',
            restaurantId: 'test-restaurant-id',
            role: UserRole.customer,
          ),
          throwsA(isA<AppException>()),
        );
      },
    );

    test('verifyOtp with invalid OTP throws AppException', () async {
      expect(
        () => datasource.verifyOtp(otp: '000000', phone: '01000000000'),
        throwsA(isA<AppException>()),
      );
    });

    test('logout completes cleanly without throwing exceptions', () async {
      await expectLater(datasource.logout('fake-token'), completes);
    });
  });
}
