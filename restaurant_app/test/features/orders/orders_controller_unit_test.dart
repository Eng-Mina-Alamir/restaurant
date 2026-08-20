import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/notifications/new_order_notifier.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

void main() {
  const burger = MenuItem(
    id: 'm1',
    categoryId: 'burgers',
    name: 'برجر دجاج',
    description: 'لذيذ',
    price: 30.0,
  );

  late InMemoryOrderRepository repo;
  late CartController cart;
  late NewOrderNotifier notifier;
  late OrdersController controller;

  setUp(() {
    repo = InMemoryOrderRepository();
    cart = CartController();
    notifier = NewOrderNotifier();
    controller = OrdersController(repo, cart, notifier);
  });

  tearDown(() {
    controller.dispose();
    notifier.dispose();
  });

  group('OrdersController Unit Tests', () {
    test('starts with empty orders state and offline queue', () {
      expect(controller.state, isEmpty);
      expect(controller.offlineQueue, isEmpty);
      expect(controller.pendingSyncCount, 0);
      expect(controller.activeOrders, isEmpty);
    });

    test('placeOrder with empty cart returns null', () async {
      final order = await controller.placeOrder();
      expect(order, isNull);
      expect(controller.state, isEmpty);
    });

    test('placeOrder adds order to state and clears cart', () async {
      cart.addItem(const CartItem(menuItem: burger, quantity: 2));
      expect(cart.state.length, 1);

      final order = await controller.placeOrder(paymentMethod: PaymentMethod.card);
      expect(order, isNotNull);
      expect(order!.items.length, 1);
      expect(order.orderType, OrderType.takeaway);
      expect(order.paymentMethod, PaymentMethod.card);

      expect(controller.state.length, 1);
      expect(controller.state.first.id, order.id);
      expect(cart.state, isEmpty); // Cart cleared
    });

    test('placeOrderForTable sets dineIn order type and tableId', () async {
      cart.addItem(const CartItem(menuItem: burger, quantity: 1));

      final order = await controller.placeOrderForTable('table-42');
      expect(order, isNotNull);
      expect(order!.tableId, 'table-42');
      expect(order.orderType, OrderType.dineIn);
      expect(controller.state.length, 1);
    });

    test('updateStatus modifies order status and persists', () async {
      cart.addItem(const CartItem(menuItem: burger, quantity: 1));
      final order = await controller.placeOrder();
      expect(order!.status, OrderStatus.pending);

      final updated = await controller.updateStatus(order.id, OrderStatus.preparing);
      expect(updated, isNotNull);
      expect(updated!.status, OrderStatus.preparing);
      expect(controller.state.first.status, OrderStatus.preparing);

      // Advance to completed
      await controller.updateStatus(order.id, OrderStatus.completed);
      expect(controller.state.first.status, OrderStatus.completed);
    });

    test('updateStatus on non-existent order returns null', () async {
      final res = await controller.updateStatus('invalid-id', OrderStatus.ready);
      expect(res, isNull);
    });

    test('activeOrders excludes terminal orders', () async {
      cart.addItem(const CartItem(menuItem: burger, quantity: 1));
      final o1 = await controller.placeOrder();

      cart.addItem(const CartItem(menuItem: burger, quantity: 1));
      final o2 = await controller.placeOrder();

      expect(controller.activeOrders.length, 2);

      await controller.updateStatus(o1!.id, OrderStatus.completed);
      expect(controller.activeOrders.length, 1);
      expect(controller.activeOrders.first.id, o2!.id);

      await controller.updateStatus(o2.id, OrderStatus.cancelled);
      expect(controller.activeOrders, isEmpty);
    });
  });
}
