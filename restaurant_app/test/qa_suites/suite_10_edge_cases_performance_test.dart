import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/network/connectivity_service.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/kds/presentation/pages/kds_page.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'helpers/qa_test_helpers.dart';

void main() {
  setUpAll(() {
    initQaTestEnvironment();
  });

  group('Suite 10: Non-Functional & Edge Cases (حالات الشبكة والأداء والأمان)', () {
    const testItem = MenuItem(
      id: 'edge-item-1',
      categoryId: 'الوجبات',
      name: 'وجبة تجريبية للحواف',
      description: 'وجبة لاختبار حالات الحافة والشبكة',
      price: 80.0,
    );

    // -------------------------------------------------------------
    // TC-EDGE-01: Offline Mode & Queueing
    // -------------------------------------------------------------
    test('TC-EDGE-01: Placing an order in offline mode enqueues order safely without crashing', () async {
      final connectivity = ConnectivityService();
      // Set to offline
      connectivity.goOffline();

      final container = createQaContainer(
        connectivityService: connectivity,
        extraCheckoutItems: [testItem],
      );
      addTearDown(container.dispose);
      // Prime the menu snapshot BEFORE entering the offline branch — checkout
      // revalidation runs synchronously against the live menu.
      await primeMenuForCheckout(container);

      final cartNotifier = container.read(cartControllerProvider.notifier);
      cartNotifier.addItem(const CartItem(menuItem: testItem));

      final ordersNotifier = container.read(ordersControllerProvider.notifier);
      final created = await ordersNotifier.placeOrder();

      expect(created, isNotNull);
      // Order queued for offline sync
      expect(ordersNotifier.offlineQueue, isNotEmpty);
      expect(ordersNotifier.pendingSyncCount, 1);

      // Reconnect
      connectivity.goOnline();
      await ordersNotifier.syncOfflineOrders();
      expect(ordersNotifier.pendingSyncCount, 0);
    });

    // -------------------------------------------------------------
    // TC-EDGE-02: Idempotency & Unique Identifiers
    // -------------------------------------------------------------
    test('TC-EDGE-02: Each generated order possesses a distinct unique identifier to avoid duplicate charges', () async {
      final container = createQaContainer(extraCheckoutItems: [testItem]);
      addTearDown(container.dispose);
      await primeMenuForCheckout(container);

      final cartNotifier = container.read(cartControllerProvider.notifier);
      final ordersNotifier = container.read(ordersControllerProvider.notifier);

      cartNotifier.addItem(const CartItem(menuItem: testItem));
      final order1 = await ordersNotifier.placeOrder();

      cartNotifier.addItem(const CartItem(menuItem: testItem));
      final order2 = await ordersNotifier.placeOrder();

      expect(order1?.id, isNotNull);
      expect(order2?.id, isNotNull);
      expect(order1?.id, isNot(equals(order2?.id)));
    });

    // -------------------------------------------------------------
    // TC-EDGE-03: Double-Tap Prevention
    // -------------------------------------------------------------
    test('TC-EDGE-03: Rapid concurrent placeOrder requests result in single order execution', () async {
      final container = createQaContainer(extraCheckoutItems: [testItem]);
      addTearDown(container.dispose);
      await primeMenuForCheckout(container);

      final cartNotifier = container.read(cartControllerProvider.notifier);
      cartNotifier.addItem(const CartItem(menuItem: testItem));

      final ordersNotifier = container.read(ordersControllerProvider.notifier);

      // Trigger two concurrent invocations
      final future1 = ordersNotifier.placeOrder();
      final future2 = ordersNotifier.placeOrder();

      final results = await Future.wait([future1, future2]);

      // Exactly one should succeed, second blocked by _placing lock
      final successfulOrders = results.where((r) => r != null).toList();
      expect(successfulOrders, hasLength(1));
    });

    // -------------------------------------------------------------
    // TC-EDGE-04: Session & Cart Retention
    // -------------------------------------------------------------
    test('TC-EDGE-04: Cart retains items across component rebuilds and state lookups', () {
      final container = createQaContainer();
      addTearDown(container.dispose);

      final cartNotifier = container.read(cartControllerProvider.notifier);
      cartNotifier.addItem(const CartItem(menuItem: testItem, quantity: 3));

      expect(container.read(cartControllerProvider), hasLength(1));
      expect(container.read(cartControllerProvider).first.quantity, 3);
      expect(cartNotifier.unitCount, 3);
    });

    // -------------------------------------------------------------
    // TC-EDGE-05: Responsiveness across Tablet & Phone dimensions
    // -------------------------------------------------------------
    testWidgets('TC-EDGE-05: KDS renders cleanly on Tablet Landscape (1280x800) and Phone (390x844)', (
      tester,
    ) async {
      final container = createQaContainer();
      addTearDown(container.dispose);

      // 1. Tablet Landscape (1280x800)
      await pumpQaWidget(
        tester,
        container: container,
        screenSize: const Size(1280, 800),
        child: const KdsPage(),
      );
      expect(find.byType(KdsPage), findsOneWidget);
      expect(tester.takeException(), isNull); // No overflow

      // 2. Phone Portrait (390x844)
      await pumpQaWidget(
        tester,
        container: container,
        screenSize: const Size(390, 844),
        child: const KdsPage(),
      );
      expect(find.byType(KdsPage), findsOneWidget);
      expect(tester.takeException(), isNull); // No overflow
    });
  });
}
