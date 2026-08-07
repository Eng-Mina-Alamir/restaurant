import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Encapsulates restoring a persisted session (offline / demo mode).
class RestoreSessionUseCase {
  final AuthRepository repository;

  RestoreSessionUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call() => repository.restoreSession();
}
