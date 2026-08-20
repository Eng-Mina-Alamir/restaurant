import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/table_management/data/repositories/in_memory_table_repository.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';

void main() {
  group('Concurrency & High-Load Stress Integration Tests', () {
    const sampleItem1 = MenuItem(
      id: 'stress-item-1',
      categoryId: 'cat-main',
      name: 'وجبة البرجر العملاق',
      description: 'برجر عائلي مشوي',
      price: 60.0,
    );

    const sampleItem2 = MenuItem(
      id: 'stress-item-2',
      categoryId: 'cat-drinks',
      name: 'عصير برتقال فريش',
      description: 'طبيعي 100%',
      price: 20.0,
    );

    test('Concurrent cart item modifications maintain calculation integrity', () async {
      final cartController = CartController();

      // Dispatch 50 concurrent addition & modification tasks
      final futures = <Future<void>>[];
      for (int i = 0; i < 25; i++) {
        futures.add(Future(() {
          cartController.addItem(const CartItem(menuItem: sampleItem1, quantity: 1));
        }));
        futures.add(Future(() {
          cartController.addItem(const CartItem(menuItem: sampleItem2, quantity: 2));
        }));
      }

      await Future.wait(futures);

      // Verify cart state
      final state = cartController.state;
      expect(state.length, equals(2));

      final item1InCart = state.firstWhere((i) => i.menuItem.id == sampleItem1.id);
      final item2InCart = state.firstWhere((i) => i.menuItem.id == sampleItem2.id);

      expect(item1InCart.quantity, equals(25));
      expect(item2InCart.quantity, equals(50));
      expect(cartController.totals.subtotal, equals((25 * 60.0) + (50 * 20.0)));
    });

    test('Multi-table concurrent status transitions in TableController', () async {
      final tableRepo = InMemoryTableRepository();
      final tableController = TableController(tableRepo);

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final tables = tableController.state;
      if (tables.isNotEmpty) {
        final futures = <Future<void>>[];
        for (final tbl in tables) {
          futures.add(tableController.occupy(tbl.id, orderId: 'ORD-${tbl.id}'));
        }
        await Future.wait(futures);

        // Verify occupied
        for (final tbl in tableController.state) {
          expect(tbl.status, equals(TableStatus.occupied));
        }

        // Release all
        final releaseFutures = <Future<void>>[];
        for (final tbl in tableController.state) {
          releaseFutures.add(tableController.release(tbl.id));
        }
        await Future.wait(releaseFutures);

        for (final tbl in tableController.state) {
          expect(tbl.status, equals(TableStatus.available));
        }
      }
    });

    test('Rapid order placement and status transitions through ProviderContainer', () async {
      final container = ProviderContainer();

      final cart = container.read(cartControllerProvider.notifier);
      final orders = container.read(ordersControllerProvider.notifier);

      for (int i = 0; i < 5; i++) {
        cart.addItem(CartItem(menuItem: sampleItem1, quantity: i + 1));
        final order = await orders.placeOrder();
        expect(order, isNotNull);
        expect(order!.items.first.quantity, equals(i + 1));
      }

      expect(orders.state.length, equals(5));

      container.dispose();
    });
  });
}
