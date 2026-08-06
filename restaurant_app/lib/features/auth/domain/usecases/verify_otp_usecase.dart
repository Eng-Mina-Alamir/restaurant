import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Encapsulates the OTP verification use case.
class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String otp,
    required String phone,
  }) {
    return repository.verifyOtp(otp: otp, phone: phone);
  }
}
