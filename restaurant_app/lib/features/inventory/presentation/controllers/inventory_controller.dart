import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../data/repositories/in_memory_inventory_repository.dart';
import '../../data/repositories/supabase_inventory_repository.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  if (AppConfig.useSupabase) {
    return SupabaseInventoryRepository(
      supabase: ref.watch(supabaseClientProvider),
    );
  }
  return InMemoryInventoryRepository();
});

/// State for the inventory list and operations.
class InventoryController
    extends StateNotifier<AsyncValue<List<InventoryItemEntity>>> {
  InventoryController(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final InventoryRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    final result = await _repository.getInventoryItems();
    state = result.when(
      onLeft: (f) => AsyncValue.error(f.message, StackTrace.current),
      onRight: (items) => AsyncValue.data(items),
    );
  }

  Future<bool> addItem({
    required String name,
    required String category,
    required double currentStock,
    required String unit,
    required double minThreshold,
    required double costPerUnit,
  }) async {
    final newItem = InventoryItemEntity(
      id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: category,
      currentStock: currentStock,
      unit: unit,
      minThreshold: minThreshold,
      costPerUnit: costPerUnit,
    );

    final result = await _repository.addItem(newItem);
    return result.when(
      onLeft: (_) => false,
      onRight: (saved) {
        final current = state.valueOrNull ?? <InventoryItemEntity>[];
        state = AsyncValue.data(<InventoryItemEntity>[...current, saved]);
        return true;
      },
    );
  }

  Future<bool> restock(String id, double amount) async {
    final result = await _repository.restock(id, amount);
    return result.when(
      onLeft: (_) => false,
      onRight: (updated) {
        final current = state.valueOrNull ?? <InventoryItemEntity>[];
        state = AsyncValue.data(
          current
              .map<InventoryItemEntity>((i) => i.id == id ? updated : i)
              .toList(),
        );
        return true;
      },
    );
  }

  Future<bool> updateItem(InventoryItemEntity item) async {
    final result = await _repository.updateItem(item);
    return result.when(
      onLeft: (_) => false,
      onRight: (updated) {
        final current = state.valueOrNull ?? <InventoryItemEntity>[];
        state = AsyncValue.data(
          current
              .map<InventoryItemEntity>((i) => i.id == item.id ? updated : i)
              .toList(),
        );
        return true;
      },
    );
  }

  Future<bool> deleteItem(String id) async {
    final result = await _repository.deleteItem(id);
    return result.when(
      onLeft: (_) => false,
      onRight: (_) {
        final current = state.valueOrNull ?? <InventoryItemEntity>[];
        state = AsyncValue.data(current.where((i) => i.id != id).toList());
        return true;
      },
    );
  }
}

final inventoryControllerProvider =
    StateNotifierProvider<
      InventoryController,
      AsyncValue<List<InventoryItemEntity>>
    >((ref) => InventoryController(ref.watch(inventoryRepositoryProvider)));
