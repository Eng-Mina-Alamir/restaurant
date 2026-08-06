import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/menu.dart';

/// Domain contract for menu data access.
///
/// Offline-first: the production implementation may read from a local seed or
/// cache before falling back to the network. Consumers never touch transport
/// details.
abstract class MenuRepository {
  /// Loads the full restaurant [Menu].
  Future<Either<Failure, Menu>> getMenu();
}
