import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/di/service_locator.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/auth/domain/entities/user_entity.dart';
import 'package:restaurant_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:restaurant_app/features/auth/presentation/controllers/auth_controller.dart';

class _FakeAuthRepository implements AuthRepository {
  UserEntity? loggedUser;
  Failure? failureToReturn;

  @override
  Future<Either<Failure, UserEntity>> login(String identifier, String password) async {
    if (failureToReturn != null) return Left(failureToReturn!);
    loggedUser = UserEntity(
      id: 'usr-1',
      name: 'Test User',
      email: identifier,
      phone: '0501234567',
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
    return Right(loggedUser!);
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.customer,
  }) async {
    if (failureToReturn != null) return Left(failureToReturn!);
    loggedUser = UserEntity(
      id: 'usr-reg',
      name: name,
      email: email,
      phone: phone,
      role: role,
      createdAt: DateTime.now(),
    );
    return Right(loggedUser!);
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String otp,
    required String phone,
  }) async {
    if (failureToReturn != null) return Left(failureToReturn!);
    loggedUser = UserEntity(
      id: 'usr-otp',
      name: 'OTP User',
      email: 'otp@example.com',
      phone: phone,
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
    return Right(loggedUser!);
  }

  @override
  Future<Either<Failure, void>> logout() async {
    loggedUser = null;
    return const Right(null);
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    return const Right('new-token');
  }

  @override
  Future<Either<Failure, UserEntity>> restoreSession() async {
    if (loggedUser != null) return Right(loggedUser!);
    return const Left(UnauthorizedFailure());
  }
}

void main() {
  group('AuthState Unit Tests', () {
    test('initial state has unknown status and isLoading is true', () {
      const state = AuthState();
      expect(state.status, AuthStatus.unknown);
      expect(state.isLoading, isTrue);
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
    });

    test('copyWith updates state correctly', () {
      const state = AuthState();
      final updated = state.copyWith(
        status: AuthStatus.authenticated,
        user: UserEntity(
          id: '1',
          name: 'N',
          email: 'e',
          phone: 'p',
          role: UserRole.waiter,
          createdAt: DateTime.now(),
        ),
      );

      expect(updated.status, AuthStatus.authenticated);
      expect(updated.isAuthenticated, isTrue);
      expect(updated.user?.name, 'N');
    });
  });

  group('AuthController Lifecycle & Action Tests', () {
    late _FakeAuthRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('login success sets authenticated state', () async {
      final controller = container.read(authControllerProvider.notifier);

      await controller.login('customer@test.com', '123456');

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.email, 'customer@test.com');
      expect(state.authFailure, isNull);
    });

    test('login failure sets unauthenticated state and failure message', () async {
      repo.failureToReturn = const ValidationFailure('Invalid credentials');
      final controller = container.read(authControllerProvider.notifier);

      await controller.login('bad@test.com', 'badpass');

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.isAuthenticated, isFalse);
      expect(state.authFailure, isNotNull);
      expect(state.authFailure?.message, 'Invalid credentials');
    });

    test('register success sets authenticated state', () async {
      final controller = container.read(authControllerProvider.notifier);

      await controller.register(
        name: 'New Waiter',
        email: 'waiter@test.com',
        phone: '0501112233',
        password: 'password',
        role: UserRole.waiter,
      );

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.role, UserRole.waiter);
    });

    test('verifyOtp success sets authenticated state', () async {
      final controller = container.read(authControllerProvider.notifier);

      await controller.verifyOtp('1234', '0501112233');

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.id, 'usr-otp');
    });

    test('logout clears user and sets unauthenticated', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.login('test@test.com', '123456');
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);

      await controller.logout();
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.isAuthenticated, isFalse);
    });

    test('bootstrap with no session sets unauthenticated', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.bootstrap();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
    });
  });
}
