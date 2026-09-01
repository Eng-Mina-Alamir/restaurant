import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:restaurant_app/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:restaurant_app/features/inventory/domain/entities/waste_log_entity.dart';

void main() {
  group('Waste & Spoilage Logs Tests', () {
    test('Logs waste accurately and deducts wasted stock from inventory', () async {
      final initialInventory = [
        const InventoryItemEntity(
          id: 'inv-milk',
          name: 'حليب طبيعي مبستر',
          category: 'ألبان',
          currentStock: 20.0, // 20 liters
          unit: 'لتر',
          minThreshold: 5.0,
          costPerUnit: 30.0,
        ),
      ];

      final repo = InMemoryInventoryRepository(initialInventory, [], []);

      final wasteLog = WasteLogEntity(
        id: 'waste-test-1',
        inventoryItemId: 'inv-milk',
        inventoryItemName: 'حليب طبيعي مبستر',
        quantity: 4.0, // 4 liters spoiled
        unit: 'لتر',
        unitCost: 30.0,
        totalCost: 120.0,
        reason: WasteReason.expired,
        loggedByName: 'شيف حسام',
        notes: 'انتهاء تاريخ الصلاحية',
        createdAt: DateTime.now(),
      );

      final logResult = await repo.logWaste(wasteLog);
      expect(logResult.isRight, isTrue);

      // Verify log was saved
      final logsResult = await repo.getWasteLogs();
      final logs = logsResult.when(
        onLeft: (_) => <WasteLogEntity>[],
        onRight: (v) => v,
      );
      expect(logs.length, equals(1));
      expect(logs.first.totalCost, equals(120.0));
      expect(logs.first.reason, equals(WasteReason.expired));

      // Verify stock was reduced from 20 to 16 liters
      final itemsResult = await repo.getInventoryItems();
      final items = itemsResult.when(
        onLeft: (_) => <InventoryItemEntity>[],
        onRight: (v) => v,
      );
      final milk = items.firstWhere((i) => i.id == 'inv-milk');
      expect(milk.currentStock, equals(16.0));
    });
  });
}
