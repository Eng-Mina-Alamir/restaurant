import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/restaurant_table.dart';

/// Domain contract for restaurant table management.
///
/// Offline-first: the seed-backed implementation returns the current session
/// table list; a future remote implementation syncs with the floor plan.
abstract class TableRepository {
  /// Loads all tables for the restaurant floor.
  Future<Either<Failure, List<RestaurantTable>>> getTables();

  /// Updates a table's status (and optionally links the active order).
  Future<Either<Failure, RestaurantTable>> updateTable(RestaurantTable table);

  /// Adds a new table to the floor plan.
  Future<Either<Failure, RestaurantTable>> addTable(RestaurantTable table);

  /// Deletes a table by its ID.
  Future<Either<Failure, void>> deleteTable(String id);
}
