import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/app_cache.dart';
import '../../../../core/domain/enums.dart';
import '../../data/repositories/hive_table_repository.dart';
import '../../data/repositories/in_memory_table_repository.dart';
import '../../domain/entities/restaurant_table.dart';
import '../../domain/repositories/table_repository.dart';

/// Shared [TableRepository].
///
/// Hive-persisted when the local cache is available, in-memory otherwise
/// (tests / unsupported platforms).
final tableRepositoryProvider = Provider<TableRepository>((ref) {
  final cache = ref.watch(localCacheServiceProvider);
  if (cache != null) return HiveTableRepository(cache);
  return InMemoryTableRepository();
});

/// Manages the restaurant's tables and their status transitions.
///
/// Loads tables on first access and exposes mutators to update status / mark a
/// table occupied with an active order. Changes flow back through the
/// repository so a future remote impl stays consistent.
class TableController extends StateNotifier<List<RestaurantTable>> {
  TableController(this._repository) : super(const []) {
    _load();
  }

  final TableRepository _repository;

  Future<void> _load() async {
    final result = await _repository.getTables();
    state = result.when(onLeft: (_) => const [], onRight: (tables) => tables);
  }

  RestaurantTable? tableById(String id) {
    for (final t in state) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Applies [update] then persists through the repository.
  Future<void> _apply(
    String tableId,
    RestaurantTable Function(RestaurantTable) update,
  ) async {
    final current = tableById(tableId);
    if (current == null) return;
    final updated = update(current);
    state = state.map((t) => t.id == tableId ? updated : t).toList();
    await _repository.updateTable(updated);
  }

  /// Occupies [tableId] and links the active [orderId].
  Future<void> occupy(String tableId, {required String orderId}) {
    return _apply(
      tableId,
      (t) => t.copyWith(
        status: TableStatus.occupied,
        currentOrderId: orderId,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  /// Releases [tableId], clearing the active order and marking it available
  /// (or needs-cleaning per policy).
  Future<void> release(String tableId, {bool needsCleaning = false}) {
    return _apply(
      tableId,
      (t) => t.copyWith(
        status: needsCleaning
            ? TableStatus.needsCleaning
            : TableStatus.available,
        currentOrderId: null,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  /// Marks a table as / not reserved.
  Future<void> setReserved(String tableId, {required bool reserved}) {
    return _apply(
      tableId,
      (t) => t.copyWith(
        status: reserved ? TableStatus.reserved : TableStatus.available,
        lastUpdated: DateTime.now(),
      ),
    );
  }
}

/// Provider for [TableController].
final tableControllerProvider =
    StateNotifierProvider<TableController, List<RestaurantTable>>((ref) {
      return TableController(ref.watch(tableRepositoryProvider));
    });
