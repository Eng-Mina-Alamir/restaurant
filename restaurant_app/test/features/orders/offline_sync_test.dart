import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/network/connectivity_service.dart';
import 'package:restaurant_app/core/notifications/new_order_notifier.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 30.0,
  );

  group('Offline order queue and sync', () {
    test('queues orders placed while offline and auto-syncs when online', () async {
      final connectivity = ConnectivityService();
      final cart = CartController();
      final repository = InMemoryOrderRepository();
      final notifier = NewOrderNotifier();

      final controller = OrdersController(
        repository,
        cart,
        notifier,
        connectivityService: connectivity,
      );
      addTearDown(controller.dispose);
      addTearDown(connectivity.dispose);
      addTearDown(notifier.dispose);

      // 1. Go offline
      connectivity.goOffline();
      expect(connectivity.isOffline, isTrue);

      // 2. Add item to cart and place order
      cart.addItem(const CartItem(menuItem: burger));
      final order1 = await controller.placeOrder();
      expect(order1, isNotNull);
      expect(controller.pendingSyncCount, 1);
      expect(controller.offlineQueue.first.id, order1?.id);

      // 3. Place another order
      cart.addItem(const CartItem(menuItem: burger, quantity: 2));
      final order2 = await controller.placeOrder();
      expect(order2, isNotNull);
      expect(controller.pendingSyncCount, 2);

      // 4. Go online -> auto syncs and clears queue
      connectivity.goOnline();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.pendingSyncCount, 0);
      expect(controller.offlineQueue, isEmpty);
      expect(controller.state.length, 2);
    });
  });
}
