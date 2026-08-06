import '../../../../core/data/local_cache_service.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/restaurant_table.dart';
import '../../domain/repositories/table_repository.dart';
import '../table_seed_data.dart';

/// Hive-persisted [TableRepository].
///
/// Seeds the floor plan from [TableSeedData] on first use, then persists any
/// status/order updates across restarts.
class HiveTableRepository implements TableRepository {
  HiveTableRepository(this._cache);

  static const String cacheKey = 'tables_v1';

  final LocalCacheService _cache;

  @override
  Future<Either<Failure, List<RestaurantTable>>> getTables() async {
    try {
      final list = await _load();
      return Right<Failure, List<RestaurantTable>>(list);
    } catch (e) {
      return Left<Failure, List<RestaurantTable>>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RestaurantTable>> updateTable(
    RestaurantTable table,
  ) async {
    try {
      final all = await _load();
      final index = all.indexWhere((t) => t.id == table.id);
      if (index == -1) {
        all.add(table);
      } else {
        all[index] = table;
      }
      await _cache.writeList(cacheKey, all.map((t) => t.toJson()).toList());
      return Right<Failure, RestaurantTable>(table);
    } catch (e) {
      return Left<Failure, RestaurantTable>(CacheFailure(e.toString()));
    }
  }

  Future<List<RestaurantTable>> _load() async {
    var list = _cache.readList(cacheKey).map(RestaurantTable.fromJson).toList();
    if (list.isEmpty) {
      list = List<RestaurantTable>.of(TableSeedData.tables);
      await _cache.writeList(cacheKey, list.map((t) => t.toJson()).toList());
    }
    return list..sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
  }
}
