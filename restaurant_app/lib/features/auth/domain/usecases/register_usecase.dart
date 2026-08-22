import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/validators.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case that encapsulates the user registration flow.
///
/// Validation is delegated to [Validators] — the app's single source of truth
/// for input rules — so form validators and domain checks can never drift.
class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String restaurantId,
    UserRole role = UserRole.customer,
  }) {
    final nameError = Validators.validateName(name);
    if (nameError != null) {
      return Future.value(Left(ValidationFailure(nameError)));
    }
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      return Future.value(Left(ValidationFailure(emailError)));
    }
    final phoneError = Validators.validatePhone(phone);
    if (phoneError != null) {
      return Future.value(Left(ValidationFailure(phoneError)));
    }
    final passwordError = Validators.validatePassword(password);
    if (passwordError != null) {
      return Future.value(Left(ValidationFailure(passwordError)));
    }

    return _repository.register(
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      password: password,
      restaurantId: restaurantId,
      role: role,
    );
  }
}

