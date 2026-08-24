import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import '../helpers/test_container.dart';

void main() {
  group('Concurrency & Resilience Integration Tests', () {
    const burger = MenuItem(
      id: 'item-conc-1',
      categoryId: 'cat-burger',
      name: 'برجر دبل',
      description: 'برجر لحم مشوي طازج',
      price: 50.0,
    );

    test(
      'Rapid simultaneous cart additions maintain exact state count and total',
      () async {
        final container = createTestContainer();
        addTearDown(container.dispose);

        final cartNotifier = container.read(cartControllerProvider.notifier);

        // Perform 50 concurrent addition operations
        await Future.wait(
          List.generate(
            50,
            (i) => Future(() {
              cartNotifier.addItem(
                const CartItem(menuItem: burger, quantity: 1),
              );
            }),
          ),
        );

        final cartItems = container.read(cartControllerProvider);
        expect(cartItems.length, 1);
        expect(cartItems.first.quantity, 50);
        expect(cartNotifier.totals.subtotal, 2500.0);
      },
    );

    test(
      'Concurrent order status modifications maintain atomic consistency',
      () async {
        final container = createTestContainer(
          seedCheckoutFixtures: true,
          extraCheckoutItems: [burger],
        );
        addTearDown(container.dispose);
        await primeMenuForCheckout(container);

        final cartNotifier = container.read(cartControllerProvider.notifier);
        final ordersNotifier = container.read(
          ordersControllerProvider.notifier,
        );

        cartNotifier.addItem(const CartItem(menuItem: burger, quantity: 2));
        final order = await ordersNotifier.placeOrder();
        expect(order, isNotNull);

        // Concurrent status updates
        await Future.wait([
          ordersNotifier.updateStatus(order!.id, OrderStatus.preparing),
          ordersNotifier.updateStatus(order.id, OrderStatus.ready),
        ]);

        final allOrders = container.read(ordersControllerProvider);
        final updatedOrder = allOrders.firstWhere((o) => o.id == order.id);

        expect(
          updatedOrder.status == OrderStatus.preparing ||
              updatedOrder.status == OrderStatus.ready,
          isTrue,
        );
      },
    );
  });
}
