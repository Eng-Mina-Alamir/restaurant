import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  group('TableController', () {
    test('loads seeded tables sorted by number', () async {
      container.read(tableControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final tables = container.read(tableControllerProvider);

      expect(tables, isNotEmpty);
      expect(tables.first.tableNumber, 1);
      // sort ascending
      for (var i = 0; i < tables.length - 1; i++) {
        expect(tables[i].tableNumber <= tables[i + 1].tableNumber, isTrue);
      }
    });

    test('occupy links an order and sets status', () async {
      final controller = container.read(tableControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await controller.occupy('t1', orderId: 'ORD-0099');
      final updated = controller.tableById('t1')!;
      expect(updated.status, TableStatus.occupied);
      expect(updated.currentOrderId, 'ORD-0099');
    });

    test('release clears the active order', () async {
      final controller = container.read(tableControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await controller.occupy('t1', orderId: 'ORD-0001');
      await controller.release('t1');
      final released = controller.tableById('t1')!;
      expect(released.status, TableStatus.available);
      expect(released.currentOrderId, isNull);
    });

    test('setReserved marks a table reserved then available', () async {
      final controller = container.read(tableControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await controller.setReserved('t1', reserved: true);
      expect(controller.tableById('t1')!.status, TableStatus.reserved);

      await controller.setReserved('t1', reserved: false);
      expect(controller.tableById('t1')!.status, TableStatus.available);
    });

    test('release with needsCleaning marks the table needs-cleaning', () async {
      final controller = container.read(tableControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      await controller.occupy('t1', orderId: 'ORD-0001');
      await controller.release('t1', needsCleaning: true);
      final released = controller.tableById('t1')!;
      expect(released.status, TableStatus.needsCleaning);
      expect(released.currentOrderId, isNull);
    });
  });

  group('OrdersController status transitions', () {
    test('placeOrderForTable creates a dine-in order for the table', () async {
      final cart = container.read(cartControllerProvider.notifier);
      cart.addItem(const CartItem(menuItem: burger, quantity: 2));

      final orders = container.read(ordersControllerProvider.notifier);
      final order = await orders.placeOrderForTable('t1');

      expect(order, isNotNull);
      expect(order!.tableId, 't1');
      expect(order.orderType, OrderType.dineIn);
      expect(order.status, OrderStatus.pending);
    });

    test('updateStatus advances the order status', () async {
      final cart = container.read(cartControllerProvider.notifier);
      cart.addItem(const CartItem(menuItem: burger));

      final orders = container.read(ordersControllerProvider.notifier);
      final created = await orders.placeOrderForTable('t1');

      final updated = await orders.updateStatus(
        created!.id,
        OrderStatus.preparing,
      );
      expect(updated!.status, OrderStatus.preparing);

      final updated2 = await orders.updateStatus(created.id, OrderStatus.ready);
      expect(updated2!.status, OrderStatus.ready);
    });

    test('activeOrders excludes terminal statuses', () async {
      final cart = container.read(cartControllerProvider.notifier);

      final orders = container.read(ordersControllerProvider.notifier);
      cart.addItem(const CartItem(menuItem: burger));
      final first = await orders.placeOrderForTable('t1');
      cart.addItem(const CartItem(menuItem: burger));
      final second = await orders.placeOrderForTable('t2');

      await orders.updateStatus(first!.id, OrderStatus.completed);

      final active = orders.activeOrders;
      expect(active.map((o) => o.id), contains(second!.id));
      expect(active.map((o) => o.id), isNot(contains(first.id)));
    });
  });
}
