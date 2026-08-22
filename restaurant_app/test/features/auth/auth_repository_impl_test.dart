import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/storage/in_memory_secure_storage_service.dart';
import 'package:restaurant_app/features/auth/data/datasources/demo_auth_datasource.dart';
import 'package:restaurant_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:restaurant_app/features/auth/domain/entities/user_entity.dart';

/// Builds a syntactically valid JWT with the given [payload] claims.
String buildJwt(Map<String, dynamic> payload) {
  String enc(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${enc({'alg': 'HS256'})}.${enc(payload)}.signature';
}

void main() {
  group('AuthRepositoryImpl Unit Tests', () {
    late AuthRepositoryImpl repository;
    late DemoAuthRemoteDataSource remoteDataSource;
    late InMemorySecureStorageService storage;

    setUp(() {
      remoteDataSource = DemoAuthRemoteDataSource();
      storage = InMemorySecureStorageService();
      repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        secureStorage: storage,
      );
    });

    test('login with valid demo credentials succeeds and stores session', () async {
      final result = await repository.login('manager@demo.com', '123456');

      expect(result.isRight, isTrue);
      final user = (result as Right<Failure, UserEntity>).value;
      expect(user.role, UserRole.manager);

      final token = await storage.readToken();
      expect(token, isNotNull);

      final session = await repository.restoreSession();
      expect(session.isRight, isTrue);
      final restoredUser = (session as Right<Failure, UserEntity>).value;
      expect(restoredUser.role, UserRole.manager);
    });

    test('login with invalid credentials fails with Failure', () async {
      final result = await repository.login('manager@demo.com', 'wrong_pass');

      expect(result.isLeft, isTrue);
    });

    test('register succeeds, returns UserEntity, and stores session', () async {
      final result = await repository.register(
        name: 'Sara Driver',
        email: 'sara@demo.com',
        phone: '0509998877',
        password: '123',
        restaurantId: 'test-restaurant-id',
        role: UserRole.driver,
      );

      expect(result.isRight, isTrue);
      final user = (result as Right<Failure, UserEntity>).value;
      expect(user.name, 'Sara Driver');
      expect(user.role, UserRole.driver);
    });

    test('logout purges token and session from storage', () async {
      await repository.login('customer@demo.com', '123456');
      expect(await storage.readToken(), isNotNull);

      final logoutResult = await repository.logout();
      expect(logoutResult.isRight, isTrue);
      expect(await storage.readToken(), isNull);

      final restoreResult = await repository.restoreSession();
      expect(restoreResult.isLeft, isTrue);
    });

    group('restoreSession hardening', () {
      test('tampered/corrupt session JSON is rejected and purged', () async {
        await storage.write(key: 'demo_user_session', value: '{not-json!!');

        final result = await repository.restoreSession();

        expect(result.isLeft, isTrue);
        // The poisoned payload must not linger in storage.
        expect(await storage.read('demo_user_session'), isNull);
      });

      test('session JSON of the wrong shape is rejected', () async {
        await storage.write(
          key: 'demo_user_session',
          value: jsonEncode(['not', 'a', 'map']),
        );

        expect((await repository.restoreSession()).isLeft, isTrue);
      });

      test('expired JWT session is rejected and purged', () async {
        final expired = DateTime.now()
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch ~/
            1000;
        final token = buildJwt({'sub': 'usr-9', 'exp': expired});
        await storage.writeToken(token);
        await storage.write(
          key: 'demo_user_session',
          value: jsonEncode({
            'id': 'usr-9',
            'name': 'Ghost',
            'email': 'ghost@demo.com',
            'phone': '0500000000',
            'role': 'manager',
            'token': token,
            'createdAt': DateTime.now().toIso8601String(),
          }),
        );

        final result = await repository.restoreSession();

        expect(result.isLeft, isTrue);
        expect(await storage.read('demo_user_session'), isNull);
        expect(await storage.readToken(), isNull);
      });

      test('live (non-expired) JWT session still restores', () async {
        final future = DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch ~/
            1000;
        final token = buildJwt({'sub': 'usr-10', 'exp': future});
        await storage.write(
          key: 'demo_user_session',
          value: jsonEncode({
            'id': 'usr-10',
            'name': 'Live',
            'email': 'live@demo.com',
            'phone': '0500000000',
            'role': 'waiter',
            'token': token,
            'createdAt': DateTime.now().toIso8601String(),
          }),
        );

        final result = await repository.restoreSession();

        expect(result.isRight, isTrue);
        final user = (result as Right<Failure, UserEntity>).value;
        expect(user.role, UserRole.waiter);
      });
    });

    test('logout wipes ALL storage keys, not only auth keys', () async {
      await repository.login('customer@demo.com', '123456');
      // Simulate any other sensitive key a previous session left behind.
      await storage.write(key: 'some_legacy_key', value: 'legacy-secret');
      expect(await storage.read('some_legacy_key'), isNotNull);

      final result = await repository.logout();

      expect(result.isRight, isTrue);
      expect(await storage.readToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
      expect(await storage.read('demo_user_session'), isNull);
      expect(await storage.read('some_legacy_key'), isNull);
    });
  });
}
