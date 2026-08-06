import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Domain contract for authentication operations.
///
/// Every method returns an [Either] so failures are represented as typed
/// [Failure] values rather than thrown exceptions, keeping the presentation
/// layer free of try/catch noise. The repository remains the single boundary
/// between the domain and the (network + storage) data sources.
abstract class AuthRepository {
  /// Authenticates a user using an email/phone [identifier] and [password].
  ///
  /// On success a [UserEntity] is returned and the access/refresh tokens are
  /// persisted to secure storage.
  Future<Either<Failure, UserEntity>> login(String identifier, String password);

  /// Verifies the one-time password sent during OTP-based login.
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String otp,
    required String phone,
  });

  /// Exchanges the stored refresh token for a fresh access token.
  ///
  /// Returns the new access token on success.
  Future<Either<Failure, String>> refreshToken();

  /// Logs the current user out and clears all locally persisted auth data.
  Future<Either<Failure, void>> logout();
}
