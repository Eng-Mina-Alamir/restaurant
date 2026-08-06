import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Encapsulates the logout use case.
class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() => repository.logout();
}
