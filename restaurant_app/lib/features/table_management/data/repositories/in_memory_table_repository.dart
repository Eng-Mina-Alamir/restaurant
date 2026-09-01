import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/restaurant_table.dart';
import '../../domain/repositories/table_repository.dart';
import '../table_seed_data.dart';

/// In-memory [TableRepository] backed by [TableSeedData].
///
/// Keeps the mutable table state in a private list so status/order updates
/// survive within the session. A future implementation should persist to Hive
/// and/or the backend floor-plan API.
class InMemoryTableRepository implements TableRepository {
  InMemoryTableRepository({List<RestaurantTable>? seed})
      : _tables = <String, RestaurantTable>{
          if (seed != null) for (final t in seed) t.id: t,
        };

  final Map<String, RestaurantTable> _tables;

  @override
  Future<Either<Failure, List<RestaurantTable>>> getTables() async {
    _ensureSeeded();
    final list = _tables.values.toList()
      ..sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
    return Right<Failure, List<RestaurantTable>>(list);
  }

  /// Lazily seeds the repository once so unit tests don't require const
  /// freezed instances in the constructor.
  void _ensureSeeded() {
    if (_tables.isNotEmpty) return;
    for (final t in TableSeedData.tables) {
      _tables[t.id] = t;
    }
  }

  @override
  Future<Either<Failure, RestaurantTable>> updateTable(
    RestaurantTable table,
  ) async {
    _ensureSeeded();
    _tables[table.id] = table;
    return Right<Failure, RestaurantTable>(table);
  }

  @override
  Future<Either<Failure, RestaurantTable>> addTable(
    RestaurantTable table,
  ) async {
    _ensureSeeded();
    _tables[table.id] = table;
    return Right<Failure, RestaurantTable>(table);
  }

  @override
  Future<Either<Failure, void>> deleteTable(String id) async {
    _ensureSeeded();
    _tables.remove(id);
    return const Right<Failure, void>(null);
  }
}
