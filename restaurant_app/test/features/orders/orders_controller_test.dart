import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/order_mapper.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

void main() {
  const cheese = MenuModifierOption(id: 'c1', name: 'جبنة', extraPrice: 4);
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

  test('buildForCustomer maps cart items to an order entity', () {
    final order = OrderMapper.buildForCustomer(
      orderId: 'ORD-0001',
      restaurantId: 'demo-restaurant-1',
      cartItems: const [
        CartItem(menuItem: burger, quantity: 2, selectedModifiers: [cheese]),
        CartItem(menuItem: burger, quantity: 1),
      ],
      createdAt: DateTime(2026, 8, 6, 12, 0),
    );

    expect(order.items, hasLength(2));
    // (28+4)*2 = 64 + (28)*1 = 28 -> 92 subtotal
    expect(order.subtotal, closeTo(92, 0.001));
    expect(order.taxAmount, closeTo(13.8, 0.001));
    expect(order.totalAmount, closeTo(105.8, 0.001));
    expect(order.status.name, 'pending');
    expect(order.items.first.itemTotal, closeTo(64, 0.001));
  });

  test('placeOrder appends an order and clears the cart', () async {
    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger, quantity: 1));

    final orders = container.read(ordersControllerProvider.notifier);
    final order = await orders.placeOrder();

    expect(order, isNotNull);
    expect(order!.id, 'ORD-0001');
    expect(container.read(ordersControllerProvider), hasLength(1));
    expect(cart.state, isEmpty);
  });

  test('placeOrder returns null when cart is empty', () async {
    final orders = container.read(ordersControllerProvider.notifier);
    final order = await orders.placeOrder();
    expect(order, isNull);
  });

  test('placeOrder increments the order number sequentially', () async {
    final cart = container.read(cartControllerProvider.notifier);

    final orders = container.read(ordersControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger));
    final first = await orders.placeOrder();
    cart.addItem(const CartItem(menuItem: burger));
    final second = await orders.placeOrder();

    expect(first!.id, 'ORD-0001');
    expect(second!.id, 'ORD-0002');
  });

  test('updateStatus advances the order and keeps it in state', () async {
    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger));

    final orders = container.read(ordersControllerProvider.notifier);
    final placed = await orders.placeOrder();

    final updated = await orders.updateStatus(
      placed!.id,
      OrderStatus.preparing,
    );
    expect(updated, isNotNull);
    expect(updated!.status, OrderStatus.preparing);
    expect(
      container.read(ordersControllerProvider).first.status,
      OrderStatus.preparing,
    );
  });

  test('updateStatus returns null for an unknown order id', () async {
    final orders = container.read(ordersControllerProvider.notifier);
    final updated = await orders.updateStatus('ORD-9999', OrderStatus.ready);
    expect(updated, isNull);
  });

  test('activeOrders excludes terminal orders', () async {
    final cart = container.read(cartControllerProvider.notifier);
    final orders = container.read(ordersControllerProvider.notifier);

    cart.addItem(const CartItem(menuItem: burger));
    final first = await orders.placeOrder();
    cart.addItem(const CartItem(menuItem: burger));
    final second = await orders.placeOrder();

    await orders.updateStatus(first!.id, OrderStatus.completed);

    final active = orders.activeOrders;
    expect(active, hasLength(1));
    expect(active.first.id, second!.id);
  });

  test('InMemoryOrderRepository returns created orders oldest-first', () async {
    final repo = InMemoryOrderRepository();
    final order = OrderMapper.buildForCustomer(
      orderId: 'ORD-0001',
      restaurantId: 'r1',
      cartItems: const [CartItem(menuItem: burger)],
      createdAt: DateTime(2026, 8, 6, 12, 0),
    );

    final created = await repo.createOrder(order);
    expect(created, isA<Right<Failure, OrderEntity>>());

    final orders = await repo.getOrders();
    expect(orders, isA<Right<Failure, List<OrderEntity>>>());
    final value = orders.when(
      onLeft: (_) => <OrderEntity>[],
      onRight: (o) => o,
    );
    expect(value, hasLength(1));
    expect(value.first.id, 'ORD-0001');
  });
}
