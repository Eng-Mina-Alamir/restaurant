import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:restaurant_app/features/inventory/domain/entities/inventory_item_entity.dart';

void main() {
  group('Inventory Repository & Entity Unit Tests', () {
    late InMemoryInventoryRepository repository;

    setUp(() {
      repository = InMemoryInventoryRepository();
    });

    test('getInventoryItems returns seeded ingredients', () async {
      final result = await repository.getInventoryItems();
      expect(result.isRight, isTrue);
      final items = (result as Right<Failure, List<InventoryItemEntity>>).value;
      expect(items.length, 8);
      expect(items.any((i) => i.status == StockStatus.low), isTrue);
    });

    test('addItem creates and stores new inventory item', () async {
      const newItem = InventoryItemEntity(
        id: 'inv-99',
        name: 'زعفران أصلي',
        category: 'بهارات',
        currentStock: 2.0,
        unit: 'كغ',
        minThreshold: 1.0,
        costPerUnit: 1200.0,
      );

      final result = await repository.addItem(newItem);
      expect(result.isRight, isTrue);

      final all = await repository.getInventoryItems();
      expect(
        (all as Right<Failure, List<InventoryItemEntity>>).value.any(
          (i) => i.id == 'inv-99',
        ),
        isTrue,
      );
    });

    test('updateItem updates item properties or returns failure', () async {
      final all = await repository.getInventoryItems();
      final target =
          (all as Right<Failure, List<InventoryItemEntity>>).value.first;
      final updated = target.copyWith(currentStock: 50.0);

      final updateResult = await repository.updateItem(updated);
      expect(updateResult.isRight, isTrue);
      expect(
        (updateResult as Right<Failure, InventoryItemEntity>)
            .value
            .currentStock,
        50.0,
      );

      const nonExistent = InventoryItemEntity(
        id: 'inv-fake',
        name: 'Fake',
        category: 'Fake',
        currentStock: 0,
        unit: 'x',
        minThreshold: 0,
        costPerUnit: 0,
      );
      final notFoundResult = await repository.updateItem(nonExistent);
      expect(notFoundResult.isLeft, isTrue);
    });

    test('deleteItem removes item', () async {
      final deleteResult = await repository.deleteItem('inv-1');
      expect(deleteResult.isRight, isTrue);

      final all = await repository.getInventoryItems();
      expect(
        (all as Right<Failure, List<InventoryItemEntity>>).value.any(
          (i) => i.id == 'inv-1',
        ),
        isFalse,
      );
    });

    test('restock increases stock count accurately', () async {
      final restockResult = await repository.restock('inv-2', 50.0);
      expect(restockResult.isRight, isTrue);
      expect(
        (restockResult as Right<Failure, InventoryItemEntity>)
            .value
            .currentStock,
        170.0,
      );
    });
  });
}
