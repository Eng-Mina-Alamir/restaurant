import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case that encapsulates the user registration flow.
class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.customer,
  }) {
    if (name.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('يرجى إدخال الاسم بالكامل')),
      );
    }
    if (email.trim().isEmpty || !email.contains('@')) {
      return Future.value(
        const Left(ValidationFailure('يرجى إدخال بريد إلكتروني صحيح')),
      );
    }
    if (phone.trim().isEmpty || phone.trim().length < 8) {
      return Future.value(
        const Left(ValidationFailure('يرجى إدخال رقم هاتف صحيح')),
      );
    }
    if (password.length < 6) {
      return Future.value(
        const Left(ValidationFailure('يجب أن لا تقل كلمة المرور عن 6 أحرف')),
      );
    }

    return _repository.register(
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      password: password,
      role: role,
    );
  }
}
