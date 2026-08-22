import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import '../../helpers/test_container.dart';

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );

  test('payment method defaults to cash', () {
    final container = createTestContainer();
    addTearDown(container.dispose);
    expect(container.read(selectedPaymentMethodProvider), PaymentMethod.cash);
  });

  test('selected payment method flows into the placed order', () async {
    final container = createTestContainer(seedCheckoutFixtures: true);
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    container
        .read(cartControllerProvider.notifier)
        .addItem(const CartItem(menuItem: burger));
    container.read(selectedPaymentMethodProvider.notifier).state =
        PaymentMethod.card;

    final order = await container
        .read(ordersControllerProvider.notifier)
        .placeOrder(paymentMethod: PaymentMethod.card);

    expect(order, isNotNull);
    expect(order!.paymentMethod, PaymentMethod.card);
  });

  test('cash order carries cash payment method', () async {
    final container = createTestContainer(seedCheckoutFixtures: true);
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    container
        .read(cartControllerProvider.notifier)
        .addItem(const CartItem(menuItem: burger));

    final order = await container
        .read(ordersControllerProvider.notifier)
        .placeOrder(paymentMethod: PaymentMethod.cash);

    expect(order, isNotNull);
    expect(order!.paymentMethod, PaymentMethod.cash);
  });
}
