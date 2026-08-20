import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:restaurant_app/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:restaurant_app/features/inventory/presentation/controllers/inventory_controller.dart';

void main() {
  late InMemoryInventoryRepository repo;
  late InventoryController controller;

  setUp(() {
    repo = InMemoryInventoryRepository();
    controller = InventoryController(repo);
  });

  group('InventoryController Unit Tests', () {
    test('initializes and loads inventory items', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.state, isA<AsyncData<List<InventoryItemEntity>>>());
      final items = controller.state.value!;
      expect(items.isNotEmpty, isTrue);
    });

    test('addItem creates a new inventory record', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final initialCount = controller.state.value!.length;

      final success = await controller.addItem(
        name: 'طماطم طازجة',
        category: 'خضروات',
        currentStock: 25.0,
        unit: 'كجم',
        minThreshold: 5.0,
        costPerUnit: 3.5,
      );

      expect(success, isTrue);
      expect(controller.state.value!.length, initialCount + 1);
      final newItem = controller.state.value!.firstWhere((i) => i.name == 'طماطم طازجة');
      expect(newItem.currentStock, 25.0);
    });

    test('restock increases stock for item', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final item = controller.state.value!.first;
      final oldStock = item.currentStock;

      final success = await controller.restock(item.id, 10.0);
      expect(success, isTrue);

      final updated = controller.state.value!.firstWhere((i) => i.id == item.id);
      expect(updated.currentStock, oldStock + 10.0);
    });

    test('updateItem and deleteItem succeed', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final item = controller.state.value!.first;
      final modified = item.copyWith(name: 'اسم معدل', minThreshold: 99.0);

      final updated = await controller.updateItem(modified);
      expect(updated, isTrue);
      expect(controller.state.value!.firstWhere((i) => i.id == item.id).name, 'اسم معدل');

      final countBeforeDelete = controller.state.value!.length;
      final deleted = await controller.deleteItem(item.id);
      expect(deleted, isTrue);
      expect(controller.state.value!.length, countBeforeDelete - 1);
    });
  });
}
