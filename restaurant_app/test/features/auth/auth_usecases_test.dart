import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/auth/domain/entities/user_entity.dart';
import 'package:restaurant_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:restaurant_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:restaurant_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:restaurant_app/features/auth/domain/usecases/refresh_token_usecase.dart';
import 'package:restaurant_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:restaurant_app/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:restaurant_app/features/auth/domain/usecases/verify_otp_usecase.dart';

class FakeAuthRepository implements AuthRepository {
  UserEntity? currentUser;
  bool shouldFail = false;

  @override
  Future<Either<Failure, UserEntity>> login(String identifier, String password) async {
    if (shouldFail) {
      return const Left(UnauthorizedFailure('Invalid credentials'));
    }
    final user = UserEntity(
      id: 'usr-1',
      name: 'Manager User',
      email: '$identifier@restaurant.com',
      phone: identifier,
      role: UserRole.manager,
      createdAt: DateTime.now(),
    );
    currentUser = user;
    return Right(user);
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.customer,
  }) async {
    if (shouldFail) {
      return const Left(ValidationFailure('Registration failed'));
    }
    final user = UserEntity(
      id: 'usr-2',
      name: name,
      phone: phone,
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );
    currentUser = user;
    return Right(user);
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String otp,
    required String phone,
  }) async {
    if (shouldFail || otp != '123456') {
      return const Left(UnauthorizedFailure('Invalid OTP'));
    }
    final user = UserEntity(
      id: 'usr-3',
      name: 'OTP User',
      phone: phone,
      email: '$phone@restaurant.com',
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
    currentUser = user;
    return Right(user);
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    if (shouldFail) {
      return const Left(UnauthorizedFailure('Token refresh failed'));
    }
    return const Right('new-refreshed-jwt-token');
  }

  @override
  Future<Either<Failure, UserEntity>> restoreSession() async {
    if (shouldFail || currentUser == null) {
      return const Left(UnauthorizedFailure('Session expired'));
    }
    return Right(currentUser!);
  }

  @override
  Future<Either<Failure, void>> logout() async {
    currentUser = null;
    return const Right(null);
  }
}

void main() {
  group('Auth Use Cases Unit Tests', () {
    late FakeAuthRepository repository;

    setUp(() {
      repository = FakeAuthRepository();
    });

    test('LoginUseCase succeeds and returns UserEntity', () async {
      final useCase = LoginUseCase(repository);
      final result = await useCase('0501234567', 'password123');

      expect(result.isRight, isTrue);
      expect((result as Right<Failure, UserEntity>).value.role, UserRole.manager);
    });

    test('LoginUseCase fails and returns UnauthorizedFailure', () async {
      repository.shouldFail = true;
      final useCase = LoginUseCase(repository);
      final result = await useCase('0501234567', 'wrong-pass');

      expect(result.isLeft, isTrue);
      expect((result as Left<Failure, UserEntity>).value.message, 'Invalid credentials');
    });

    test('RegisterUseCase registers new user with valid inputs', () async {
      final useCase = RegisterUseCase(repository);
      final result = await useCase(
        name: 'New Waiter',
        email: 'waiter@restaurant.com',
        phone: '0555555555',
        password: 'password123',
        role: UserRole.waiter,
      );

      expect(result.isRight, isTrue);
      final user = (result as Right<Failure, UserEntity>).value;
      expect(user.name, 'New Waiter');
      expect(user.role, UserRole.waiter);
    });

    test('RegisterUseCase rejects invalid email or short password', () async {
      final useCase = RegisterUseCase(repository);
      final badEmailResult = await useCase(
        name: 'New User',
        email: 'bad-email',
        phone: '0555555555',
        password: 'password123',
      );
      expect(badEmailResult.isLeft, isTrue);

      final shortPassResult = await useCase(
        name: 'New User',
        email: 'good@email.com',
        phone: '0555555555',
        password: '123',
      );
      expect(shortPassResult.isLeft, isTrue);
    });

    test('VerifyOtpUseCase verifies correct OTP', () async {
      final useCase = VerifyOtpUseCase(repository);
      final result = await useCase(phone: '0501234567', otp: '123456');

      expect(result.isRight, isTrue);
      expect((result as Right<Failure, UserEntity>).value.role, UserRole.customer);
    });

    test('VerifyOtpUseCase rejects wrong OTP', () async {
      final useCase = VerifyOtpUseCase(repository);
      final result = await useCase(phone: '0501234567', otp: '000000');

      expect(result.isLeft, isTrue);
      expect((result as Left<Failure, UserEntity>).value.message, 'Invalid OTP');
    });

    test('RefreshTokenUseCase generates new token', () async {
      final useCase = RefreshTokenUseCase(repository);
      final result = await useCase();

      expect(result.isRight, isTrue);
      expect((result as Right<Failure, String>).value, 'new-refreshed-jwt-token');
    });

    test('RestoreSessionUseCase restores logged in user', () async {
      repository.currentUser = UserEntity(
        id: 'usr-active',
        name: 'Active User',
        email: 'active@demo.com',
        phone: '0501112233',
        role: UserRole.driver,
        createdAt: DateTime(2026, 1, 1),
      );
      final useCase = RestoreSessionUseCase(repository);
      final result = await useCase();

      expect(result.isRight, isTrue);
      expect((result as Right<Failure, UserEntity>).value.role, UserRole.driver);
    });

    test('LogoutUseCase clears user session', () async {
      final useCase = LogoutUseCase(repository);
      final result = await useCase();

      expect(result.isRight, isTrue);
      expect(repository.currentUser, isNull);
    });
  });
}
