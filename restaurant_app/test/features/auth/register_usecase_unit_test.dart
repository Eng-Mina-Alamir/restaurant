import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/auth/domain/entities/user_entity.dart';
import 'package:restaurant_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:restaurant_app/features/auth/domain/usecases/register_usecase.dart';

class _FakeAuthRepository implements AuthRepository {
  String? registeredName;
  String? registeredEmail;
  String? registeredPhone;
  String? registeredPassword;
  UserRole? registeredRole;

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String restaurantId,
    UserRole role = UserRole.customer,
  }) async {
    registeredName = name;
    registeredEmail = email;
    registeredPhone = phone;
    registeredPassword = password;
    registeredRole = role;

    return Right(
      UserEntity(
        id: 'usr-1',
        name: name,
        email: email,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Either<Failure, UserEntity>> login(
    String identifier,
    String password,
  ) => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> logout() => throw UnimplementedError();

  @override
  Future<Either<Failure, String>> refreshToken() => throw UnimplementedError();

  @override
  Future<Either<Failure, UserEntity>> restoreSession() =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String otp,
    required String phone,
  }) => throw UnimplementedError();
}

void main() {
  group('RegisterUseCase Validation & Execution Tests', () {
    late _FakeAuthRepository repository;
    late RegisterUseCase useCase;

    setUp(() {
      repository = _FakeAuthRepository();
      useCase = RegisterUseCase(repository);
    });

    test('fails when name is empty', () async {
      final res = await useCase(
        name: '   ',
        email: 'test@example.com',
        phone: '0501234567',
        password: 'password123',
        restaurantId: 'test-restaurant-id',
      );

      expect(res.isLeft, isTrue);
      expect((res as Left).value, isA<ValidationFailure>());
      expect(((res as Left).value as Failure).message, contains('الاسم'));
    });

    test('fails when email is invalid', () async {
      final res = await useCase(
        name: 'Ahmed Ali',
        email: 'notanemail',
        phone: '0501234567',
        password: 'password123',
        restaurantId: 'test-restaurant-id',
      );

      expect(res.isLeft, isTrue);
      expect(((res as Left).value as Failure).message, contains('بريد'));
    });

    test('fails when phone is too short', () async {
      final res = await useCase(
        name: 'Ahmed Ali',
        email: 'ahmed@example.com',
        phone: '12345',
        password: 'password123',
        restaurantId: 'test-restaurant-id',
      );

      expect(res.isLeft, isTrue);
      expect(((res as Left).value as Failure).message, contains('هاتف'));
    });

    test('fails when password is less than 8 chars', () async {
      final res = await useCase(
        name: 'Ahmed Ali',
        email: 'ahmed@example.com',
        phone: '0501234567',
        password: '123',
        restaurantId: 'test-restaurant-id',
      );

      expect(res.isLeft, isTrue);
      expect(((res as Left).value as Failure).message, contains('8'));
    });

    test('trims inputs and delegates to repository on valid input', () async {
      final res = await useCase(
        name: '  Ahmed Ali  ',
        email: '  ahmed@example.com  ',
        phone: '  0501234567  ',
        password: 'password123',
        restaurantId: 'test-restaurant-id',
        role: UserRole.waiter,
      );

      expect(res.isRight, isTrue);
      expect(repository.registeredName, 'Ahmed Ali');
      expect(repository.registeredEmail, 'ahmed@example.com');
      expect(repository.registeredPhone, '0501234567');
      expect(repository.registeredRole, UserRole.waiter);
    });
  });
}
