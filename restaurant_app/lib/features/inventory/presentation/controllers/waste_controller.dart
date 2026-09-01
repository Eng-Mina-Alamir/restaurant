import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/waste_log_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'inventory_controller.dart';

/// State notifier for logging and tracking kitchen & inventory waste.
class WasteController extends StateNotifier<AsyncValue<List<WasteLogEntity>>> {
  WasteController(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
    load();
  }

  final InventoryRepository _repository;
  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    final result = await _repository.getWasteLogs();
    state = result.when(
      onLeft: (f) => AsyncValue.error(f.message, StackTrace.current),
      onRight: (logs) => AsyncValue.data(logs),
    );
  }

  Future<bool> logWaste({
    required String inventoryItemId,
    required String inventoryItemName,
    required double quantity,
    required String unit,
    required double unitCost,
    required WasteReason reason,
    required String loggedByName,
    String? notes,
  }) async {
    final newLog = WasteLogEntity(
      id: 'waste-${DateTime.now().millisecondsSinceEpoch}',
      inventoryItemId: inventoryItemId,
      inventoryItemName: inventoryItemName,
      quantity: quantity,
      unit: unit,
      unitCost: unitCost,
      totalCost: quantity * unitCost,
      reason: reason,
      loggedByName: loggedByName,
      notes: notes,
      createdAt: DateTime.now(),
    );

    final result = await _repository.logWaste(newLog);
    return result.when(
      onLeft: (_) => false,
      onRight: (saved) {
        final current = state.valueOrNull ?? <WasteLogEntity>[];
        state = AsyncValue.data(<WasteLogEntity>[saved, ...current]);
        // Also refresh inventory items in inventoryController
        _ref.read(inventoryControllerProvider.notifier).load();
        return true;
      },
    );
  }

  /// Total cost of wasted items
  double get totalWasteCost {
    final list = state.valueOrNull ?? [];
    return list.fold<double>(0.0, (acc, item) => acc + item.totalCost);
  }
}

final wasteControllerProvider =
    StateNotifierProvider<WasteController, AsyncValue<List<WasteLogEntity>>>(
      (ref) => WasteController(ref.watch(inventoryRepositoryProvider), ref),
    );
