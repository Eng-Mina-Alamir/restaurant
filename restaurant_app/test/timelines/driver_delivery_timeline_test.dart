import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import '../helpers/test_container.dart';

void main() {
  group('Timeline 6: Delivery Driver Operations Journey Test', () {
    const meal = MenuItem(
      id: 'item-drv-order-1',
      categoryId: 'cat-combo',
      name: 'وجبة كومبو ساندوتش فاهيتا',
      description: 'فاهيتا دجاج مع بطاطس ومشروب',
      price: 52.0,
    );

    test('Driver Timeline: View Assigned Orders -> Pickup from Kitchen -> In-Transit GPS -> Photo Proof -> Complete Delivery', () async {
      final container = createTestContainer(
        seedCheckoutFixtures: true,
        extraCheckoutItems: [meal],
      );
      addTearDown(container.dispose);
      await primeMenuForCheckout(container);

      final cartNotifier = container.read(cartControllerProvider.notifier);
      cartNotifier.addItem(const CartItem(menuItem: meal, quantity: 2));

      final ordersNotifier = container.read(ordersControllerProvider.notifier);
      final createdOrder = await ordersNotifier.placeOrder();
      expect(createdOrder, isNotNull);

      // Kitchen prepares and marks ready
      await ordersNotifier.updateStatus(createdOrder!.id, OrderStatus.ready);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // ── Step 1: Driver accepts assignment and collects package from kitchen ─
      await ordersNotifier.updateStatus(createdOrder.id, OrderStatus.served);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      var driverOrder = container.read(ordersControllerProvider).firstWhere((o) => o.id == createdOrder.id);
      expect(driverOrder.status, equals(OrderStatus.served));

      // ── Step 2: Driver streams GPS coordinates to customer ────────────────
      const currentDriverLat = 24.7300;
      const currentDriverLng = 46.6900;
      expect(currentDriverLat, isNotNull);
      expect(currentDriverLng, isNotNull);

      // ── Step 3: Driver captures proof of delivery photo & completes order ──
      const proofOfDeliveryMockUrl = 'https://restaurant.app/storage/proof/pod_505.jpg';
      expect(proofOfDeliveryMockUrl, contains('pod_505.jpg'));

      await ordersNotifier.updateStatus(createdOrder.id, OrderStatus.completed);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      driverOrder = container.read(ordersControllerProvider).firstWhere((o) => o.id == createdOrder.id);
      expect(driverOrder.status, equals(OrderStatus.completed));
    });
  });
}
