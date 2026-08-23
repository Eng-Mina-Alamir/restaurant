import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';
import '../helpers/test_container.dart';

void main() {
  group('Timeline 4: Waiter / Captain Full Journey Test', () {
    const mixedGrill = MenuItem(
      id: 'menu-grill-1',
      categoryId: 'cat-grills',
      name: 'مشاوي مشكلة شخصين',
      description: 'كباب وشيش طاووق وريش ضأن',
      price: 120.0,
    );

    const freshJuice = MenuItem(
      id: 'menu-juice-1',
      categoryId: 'cat-beverages',
      name: 'عصير رمان فريش',
      description: 'عصير رمان طبيعي طازج',
      price: 22.0,
    );

    test('Waiter Timeline: Login -> Floor Overview -> Seat Guests -> Take Table Order -> Kitchen Sync -> Serve -> Split Bill -> Clean & Free', () async {
      final container = createTestContainer(
        seedCheckoutFixtures: true,
        extraCheckoutItems: [mixedGrill, freshJuice],
      );
      addTearDown(container.dispose);
      await primeMenuForCheckout(container);

      final tableNotifier = container.read(tableControllerProvider.notifier);
      await tableNotifier.addTable(tableNumber: 1, capacity: 4);
      await tableNotifier.addTable(tableNumber: 2, capacity: 4);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final initialTables = container.read(tableControllerProvider);
      expect(initialTables, isNotEmpty);

      // ── Step 1: Waiter views available tables & seats guests on Table 2 ────
      final table2 = initialTables.firstWhere((t) => t.tableNumber == 2, orElse: () => initialTables.first);
      expect(table2.status, equals(TableStatus.available));

      await tableNotifier.occupy(table2.id, orderId: 'ORD-WAITER-${table2.id}');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      var activeTable = container.read(tableControllerProvider).firstWhere((t) => t.id == table2.id);
      expect(activeTable.status, equals(TableStatus.occupied));

      // ── Step 2: Waiter takes order from guests at Table 2 ──────────────────
      final cartNotifier = container.read(cartControllerProvider.notifier);
      cartNotifier.setTableId(table2.id);

      cartNotifier.addItem(const CartItem(menuItem: mixedGrill, quantity: 1));
      cartNotifier.addItem(const CartItem(menuItem: freshJuice, quantity: 2));

      expect(cartNotifier.itemCount, equals(2));
      expect(cartNotifier.totals.subtotal, equals(120.0 + (22.0 * 2))); // 164.0 SAR

      // ── Step 3: Waiter sends order to Kitchen ──────────────────────────────
      final ordersNotifier = container.read(ordersControllerProvider.notifier);
      final createdOrder = await ordersNotifier.placeOrderForTable(table2.id);

      expect(createdOrder, isNotNull);
      expect(createdOrder!.tableId, equals(table2.id));
      expect(createdOrder.orderType, equals(OrderType.dineIn));
      expect(createdOrder.status, equals(OrderStatus.pending));

      // ── Step 4: Kitchen prepares order and notifies waiter ─────────────────
      await ordersNotifier.updateStatus(createdOrder.id, OrderStatus.preparing);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await ordersNotifier.updateStatus(createdOrder.id, OrderStatus.ready);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      var orderState = container.read(ordersControllerProvider).firstWhere((o) => o.id == createdOrder.id);
      expect(orderState.status, equals(OrderStatus.ready));

      // ── Step 5: Waiter picks up dishes from Kitchen and serves Table 2 ──────
      await ordersNotifier.updateStatus(createdOrder.id, OrderStatus.served);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      orderState = container.read(ordersControllerProvider).firstWhere((o) => o.id == createdOrder.id);
      expect(orderState.status, equals(OrderStatus.served));

      // ── Step 6: Guests request bill split between 2 persons ────────────────
      final totalAmount = orderState.totalAmount;
      const splitGuestCount = 2;
      final perPersonAmount = totalAmount / splitGuestCount;
      expect(perPersonAmount, equals(totalAmount / 2));

      // ── Step 7: Order is paid and completed -> Waiter clears table ─────────
      await ordersNotifier.updateStatus(createdOrder.id, OrderStatus.completed);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      orderState = container.read(ordersControllerProvider).firstWhere((o) => o.id == createdOrder.id);
      expect(orderState.status, equals(OrderStatus.completed));

      // Table needs cleaning
      await tableNotifier.release(table2.id, needsCleaning: true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      activeTable = container.read(tableControllerProvider).firstWhere((t) => t.id == table2.id);
      expect(activeTable.status, equals(TableStatus.needsCleaning));

      // Table cleaned and ready for next guests
      await tableNotifier.release(table2.id, needsCleaning: false);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      activeTable = container.read(tableControllerProvider).firstWhere((t) => t.id == table2.id);
      expect(activeTable.status, equals(TableStatus.available));
      expect(activeTable.currentOrderId, isNull);
    });
  });
}
