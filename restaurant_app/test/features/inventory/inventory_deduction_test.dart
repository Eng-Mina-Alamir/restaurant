import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_item.dart';

void main() {
  group('Inventory Deductions on Orders', () {
    test('deductStockForOrder decreases currentStock for matching ingredients', () async {
      final repo = InMemoryInventoryRepository();

      final initialItemsResult = await repo.getInventoryItems();
      final initialItems = initialItemsResult.when(
        onLeft: (_) => throw Exception('Failed to load items'),
        onRight: (items) => items,
      );
      final meatItem = initialItems.firstWhere((i) => i.name.contains('لحم'));
      final initialMeatStock = meatItem.currentStock;

      final orderItem = OrderItem(
        menuItem: const MenuItem(
          id: 'dish-1',
          categoryId: 'cat-tajin',
          name: 'طاجن لحمة بلدي بالبصل',
          description: 'طاجن لذيذ',
          price: 180.0,
        ),
        quantity: 2,
        addedAt: DateTime.now(),
      );

      final order = OrderEntity(
        id: 'ORD-TEST-001',
        restaurantId: 'rest-1',
        tableId: 'tbl-1',
        orderType: OrderType.dineIn,
        status: OrderStatus.completed,
        items: [orderItem],
        subtotal: 360.0,
        taxAmount: 54.0,
        totalAmount: 414.0,
        createdAt: DateTime.now(),
      );

      await repo.deductStockForOrder(order);

      final updatedItemsResult = await repo.getInventoryItems();
      final updatedItems = updatedItemsResult.when(
        onLeft: (_) => throw Exception('Failed to load items'),
        onRight: (items) => items,
      );
      final updatedMeatItem = updatedItems.firstWhere((i) => i.name.contains('لحم'));

      expect(updatedMeatItem.currentStock, lessThan(initialMeatStock));
      expect(updatedMeatItem.currentStock, equals(initialMeatStock - 0.5));
    });
  });
}
