import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../core/data/app_cache.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/network/realtime_event.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/supabase/supabase_realtime_service.dart';
import '../../data/repositories/hive_table_repository.dart';
import '../../data/repositories/in_memory_table_repository.dart';
import '../../data/repositories/supabase_table_repository.dart';
import '../../data/table_seed_data.dart';
import '../../domain/entities/restaurant_table.dart';
import '../../domain/repositories/table_repository.dart';

/// Shared [TableRepository].
///
/// Uses Supabase table repository when enabled, or falls back to Hive/In-memory.
final tableRepositoryProvider = Provider<TableRepository>((ref) {
  if (AppConfig.useSupabase) {
    return SupabaseTableRepository(ref.watch(supabaseClientProvider));
  }
  final cache = ref.watch(localCacheServiceProvider);
  if (cache != null) return HiveTableRepository(cache);
  return InMemoryTableRepository();
});

/// Manages the restaurant's tables and their status transitions.
///
/// Loads tables on first access and exposes mutators to update status / mark a
/// table occupied with an active order. Changes flow back through the
/// repository and are synchronized via Supabase Realtime Postgres Changes.
class TableController extends StateNotifier<List<RestaurantTable>> {
  TableController(this._repository, {SupabaseRealtimeService? realtimeService})
    : _realtimeService = realtimeService,
      super(TableSeedData.buildTables()) {
    _load();
    _initRealtime();
  }

  final TableRepository _repository;
  final SupabaseRealtimeService? _realtimeService;
  StreamSubscription<RealtimeEvent>? _realtimeSub;

  void _initRealtime() {
    final service = _realtimeService;
    if (service == null) return;
    _realtimeSub = service.events.listen((event) {
      if (event.type == RealtimeEventType.tableStatusChanged) {
        try {
          final tableId = (event.payload['id'] ?? event.payload['tableId'])
              ?.toString();
          if (tableId == null) return;

          final index = state.indexWhere((t) => t.id == tableId);
          if (index == -1) return;

          final statusStr = event.payload['status']?.toString();
          final orderId = (event.payload['current_order_id'] ??
                  event.payload['currentOrderId'])
              ?.toString();
          final tableNum = ((event.payload['table_number'] ??
                  event.payload['tableNumber']) as num?)
              ?.toInt();
          final capacity = (event.payload['capacity'] as num?)?.toInt();
          final location = event.payload['location']?.toString();
          final assignedWaiter = (event.payload['assigned_waiter_id'] ??
                  event.payload['assignedWaiterId'])
              ?.toString();

          final updated = state[index].copyWith(
            tableNumber: tableNum ?? state[index].tableNumber,
            capacity: capacity ?? state[index].capacity,
            location: location ?? state[index].location,
            status: statusStr != null
                ? TableStatus.fromName(statusStr)
                : state[index].status,
            currentOrderId: orderId ?? state[index].currentOrderId,
            assignedWaiterId: assignedWaiter ?? state[index].assignedWaiterId,
            lastUpdated: DateTime.now(),
          );
          state = [...state]..[index] = updated;
        } catch (_) {}
      }
    });
  }

  Future<void> _load() async {
    final result = await _repository.getTables();
    if (!mounted) return;
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

  /// Adds a new table to the restaurant floor.
  Future<void> addTable({
    required int tableNumber,
    required int capacity,
    String? assignedWaiterId,
  }) async {
    final newTable = RestaurantTable(
      id: '0',
      tableNumber: tableNumber,
      capacity: capacity,
      status: TableStatus.available,
      assignedWaiterId: assignedWaiterId,
      lastUpdated: DateTime.now(),
    );
    final result = await _repository.addTable(newTable);
    result.when(
      onLeft: (_) => null,
      onRight: (saved) {
        state = [...state, saved]
          ..sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
      },
    );
  }

  /// Edits an existing table's capacity or assigned waiter.
  Future<void> editTable(
    String tableId, {
    int? tableNumber,
    int? capacity,
    String? assignedWaiterId,
    TableStatus? status,
  }) async {
    final current = tableById(tableId);
    if (current == null) return;
    final updated = current.copyWith(
      tableNumber: tableNumber ?? current.tableNumber,
      capacity: capacity ?? current.capacity,
      assignedWaiterId: assignedWaiterId ?? current.assignedWaiterId,
      status: status ?? current.status,
      lastUpdated: DateTime.now(),
    );
    final result = await _repository.updateTable(updated);
    result.when(
      onLeft: (_) => null,
      onRight: (saved) {
        state = state.map((t) => t.id == tableId ? saved : t).toList()
          ..sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
      },
    );
  }

  /// Deletes a table by [tableId].
  Future<void> deleteTable(String tableId) async {
    final result = await _repository.deleteTable(tableId);
    result.when(
      onLeft: (_) => null,
      onRight: (_) {
        state = state.where((t) => t.id != tableId).toList();
      },
    );
  }

  /// Transfers an active order from [fromTableId] to [toTableId].
  /// [fromTableId] is flagged as needsCleaning so staff can prepare it,
  /// while [toTableId] becomes occupied with the transferred order.
  Future<bool> transferTable(
    String fromTableId,
    String toTableId, {
    String? reason,
  }) async {
    final fromTable = tableById(fromTableId);
    final toTable = tableById(toTableId);

    if (fromTable == null || toTable == null) return false;
    if (fromTable.currentOrderId == null) return false;
    if (toTable.status == TableStatus.occupied) return false;

    final activeOrderId = fromTable.currentOrderId;

    // 1. Release source table to needsCleaning
    final updatedFrom = fromTable.copyWith(
      status: TableStatus.needsCleaning,
      currentOrderId: null,
      lastUpdated: DateTime.now(),
    );

    // 2. Occupy destination table with activeOrderId
    final updatedTo = toTable.copyWith(
      status: TableStatus.occupied,
      currentOrderId: activeOrderId,
      lastUpdated: DateTime.now(),
    );

    state = state.map((t) {
      if (t.id == fromTableId) return updatedFrom;
      if (t.id == toTableId) return updatedTo;
      return t;
    }).toList();

    await _repository.updateTable(updatedFrom);
    await _repository.updateTable(updatedTo);
    return true;
  }

  /// Merges [secondaryTableIds] into [primaryTableId] under one unified order.
  Future<bool> mergeTables(
    String primaryTableId,
    List<String> secondaryTableIds,
  ) async {
    final primary = tableById(primaryTableId);
    if (primary == null) return false;

    final orderId = primary.currentOrderId ?? 'ORD-MERGE-${DateTime.now().millisecondsSinceEpoch}';

    final updatedPrimary = primary.copyWith(
      status: TableStatus.occupied,
      currentOrderId: orderId,
      lastUpdated: DateTime.now(),
    );

    final List<RestaurantTable> updatedSecondaries = [];
    for (final secId in secondaryTableIds) {
      final secTable = tableById(secId);
      if (secTable != null) {
        final up = secTable.copyWith(
          status: TableStatus.occupied,
          currentOrderId: orderId,
          lastUpdated: DateTime.now(),
        );
        updatedSecondaries.add(up);
      }
    }

    state = state.map((t) {
      if (t.id == primaryTableId) return updatedPrimary;
      final match = updatedSecondaries.where((s) => s.id == t.id);
      if (match.isNotEmpty) return match.first;
      return t;
    }).toList();

    await _repository.updateTable(updatedPrimary);
    for (final s in updatedSecondaries) {
      await _repository.updateTable(s);
    }
    return true;
  }

  /// Sends a "Fire Course" timing signal to the kitchen brigade for [courseCode].
  void fireCourse({
    required String tableId,
    required String orderId,
    required String courseCode,
  }) {
    _realtimeService?.emit(
      RealtimeEvent(
        type: RealtimeEventType.kitchenCourseFired,
        payload: {
          'tableId': tableId,
          'orderId': orderId,
          'courseCode': courseCode,
          'firedAt': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}

/// Provider for [TableController].
final tableControllerProvider =
    StateNotifierProvider<TableController, List<RestaurantTable>>((ref) {
      return TableController(
        ref.watch(tableRepositoryProvider),
        realtimeService: ref.watch(supabaseRealtimeServiceProvider),
      );
    });
