import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/menu.dart';
import '../../domain/repositories/menu_repository.dart';
import '../menu_seed_data.dart';

/// Offline [MenuRepository] backed by the in-app [MenuSeedData].
///
/// Returns the seeded menu synchronously wrapped in an [Either]. When a live
/// backend is introduced, this implementation can be replaced by a remote
/// counterpart without touching the domain layer.
class MenuRepositoryImpl implements MenuRepository {
  const MenuRepositoryImpl();

  @override
  Future<Either<Failure, Menu>> getMenu() async {
    return Right<Failure, Menu>(MenuSeedData.buildMenu());
  }
}
