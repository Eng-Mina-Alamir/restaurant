import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Encapsulates the token refresh use case.
class RefreshTokenUseCase {
  final AuthRepository repository;

  RefreshTokenUseCase(this.repository);

  Future<Either<Failure, String>> call() => repository.refreshToken();
}
