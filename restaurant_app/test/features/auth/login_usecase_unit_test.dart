import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/auth/domain/entities/user_entity.dart';
import 'package:restaurant_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:restaurant_app/features/auth/domain/usecases/login_usecase.dart';

class _FakeLoginRepository implements AuthRepository {
  String? loggedIdentifier;
  String? loggedPassword;
  bool returnFailure = false;

  @override
  Future<Either<Failure, UserEntity>> login(
    String identifier,
    String password,
  ) async {
    loggedIdentifier = identifier;
    loggedPassword = password;

    if (returnFailure) {
      return const Left(ValidationFailure('بيانات الدخول غير صحيحة'));
    }

    return Right(
      UserEntity(
        id: 'usr-login',
        name: 'Logged User',
        email: identifier,
        phone: '0500000000',
        role: UserRole.manager,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Either<Failure, void>> logout() => throw UnimplementedError();

  @override
  Future<Either<Failure, String>> refreshToken() => throw UnimplementedError();

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.customer,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, UserEntity>> restoreSession() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String otp,
    required String phone,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('LoginUseCase Unit Tests', () {
    late _FakeLoginRepository repo;
    late LoginUseCase useCase;

    setUp(() {
      repo = _FakeLoginRepository();
      useCase = LoginUseCase(repo);
    });

    test('calls repository.login with exact parameters and returns user', () async {
      final res = await useCase('manager@restaurant.com', '123456');

      expect(res.isRight, isTrue);
      expect(repo.loggedIdentifier, 'manager@restaurant.com');
      expect(repo.loggedPassword, '123456');
      final user = (res as Right).value as UserEntity;
      expect(user.role, UserRole.manager);
    });

    test('returns failure when repository fails', () async {
      repo.returnFailure = true;
      final res = await useCase('wrong@email.com', 'badpass');

      expect(res.isLeft, isTrue);
      expect(((res as Left).value as Failure).message, contains('غير صحيحة'));
    });
  });
}
