import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/notifications/new_order_notifier.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import '../helpers/test_container.dart';

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );

  test('NewOrderNotifier counts and resets alerts', () {
    final notifier = NewOrderNotifier();
    addTearDown(notifier.dispose);

    expect(notifier.alertCount, 0);
    notifier.notifyNewOrder();
    notifier.notifyNewOrder();
    expect(notifier.alertCount, 2);

    notifier.reset();
    expect(notifier.alertCount, 0);
  });

  test('stream emits on each notification', () async {
    final notifier = NewOrderNotifier();
    addTearDown(notifier.dispose);

    final emissions = <int>[];
    notifier.stream.listen((_) => emissions.add(1));

    notifier.notifyNewOrder();
    notifier.notifyNewOrder();
    await Future<void>.delayed(Duration.zero);

    expect(emissions, hasLength(2));
  });

  test('placing an order notifies the shared notifier', () async {
    // Checkout-time menu revalidation requires a primed menu snapshot,
    // otherwise placeOrder is rejected before notifying (see
    // primeMenuForCheckout docs).
    final container = createTestContainer(seedCheckoutFixtures: true);
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    final notifier = container.read(newOrderNotifierProvider);
    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger));

    expect(notifier.alertCount, 0);
    await container.read(ordersControllerProvider.notifier).placeOrder();
    expect(notifier.alertCount, 1);
  });
}
