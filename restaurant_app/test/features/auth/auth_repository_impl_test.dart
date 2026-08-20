import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/storage/in_memory_secure_storage_service.dart';
import 'package:restaurant_app/features/auth/data/datasources/demo_auth_datasource.dart';
import 'package:restaurant_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:restaurant_app/features/auth/domain/entities/user_entity.dart';

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
  });
}
