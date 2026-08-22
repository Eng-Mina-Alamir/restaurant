import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/notifications/waiter_alert_service.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/pages/waiter_dashboard_page.dart';
import '../../helpers/test_container.dart';

/// Records pickup notifications without touching platform channels.
class SpyWaiterAlertService implements WaiterAlertService {
  int notifyCalls = 0;

  @override
  Future<void> notifyReadyForPickup() async => notifyCalls++;

  @override
  void dispose() {}
}

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: WaiterDashboardPage())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the seeded tables grid', (tester) async {
    await pumpPage(tester);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    // Table 8 is below the fold; scroll until visible.
    await tester.scrollUntilVisible(find.text('8'), 200);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('shows a take-order button on each table', (tester) async {
    await pumpPage(tester);
    expect(find.text('أخذ الطلب'), findsWidgets);
  });

  testWidgets('shows the table location label', (tester) async {
    await pumpPage(tester);
    // Table 1 sits in the "تراس" zone (seed data).
    expect(find.text('تراس'), findsWidgets);
    expect(find.byIcon(Icons.place_outlined), findsWidgets);
  });

  test('TableStatus labelAr maps every status to an Arabic label', () {
    expect(TableStatus.available.labelAr, 'متاحة');
    expect(TableStatus.occupied.labelAr, 'مشغولة');
    expect(TableStatus.reserved.labelAr, 'محجوزة');
    expect(TableStatus.needsCleaning.labelAr, 'تحتاج تنظيف');
  });

  test('tableStatusColor returns a distinct color per status', () {
    final colors = <Color>{
      tableStatusColor(TableStatus.available),
      tableStatusColor(TableStatus.occupied),
      tableStatusColor(TableStatus.reserved),
      tableStatusColor(TableStatus.needsCleaning),
    };
    expect(colors, hasLength(4));
  });

  testWidgets('shows an active orders summary when orders exist', (
    tester,
  ) async {
    final container = createTestContainer(seedCheckoutFixtures: true);
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    // Place a pending order so the summary row appears.
    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger));
    await container.read(ordersControllerProvider.notifier).placeOrder();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: WaiterDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الطلبات النشطة'), findsOneWidget);
    expect(find.textContaining('قيد الانتظار: 1'), findsOneWidget);
  });

  testWidgets('hides the summary when there are no active orders', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text('الطلبات النشطة'), findsNothing);
  });

  testWidgets(
    'shows pickup badge and fires the alert when a dine-in order turns ready',
    (tester) async {
      final spy = SpyWaiterAlertService();
      final container = createTestContainer(
        seedCheckoutFixtures: true,
        additionalOverrides: [
          waiterAlertServiceProvider.overrideWithValue(spy),
        ],
      );
      addTearDown(container.dispose);
      await primeMenuForCheckout(container);

      // Place a dine-in order for table 1 (still pending).
      container
          .read(cartControllerProvider.notifier)
          .addItem(const CartItem(menuItem: burger));
      await container
          .read(ordersControllerProvider.notifier)
          .placeOrderForTable('1');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: WaiterDashboardPage()),
        ),
      );
      await tester.pumpAndSettle();

      // No badge and no alert while nothing is ready yet.
      expect(find.byType(Badge), findsNothing);
      expect(spy.notifyCalls, 0);

      // Kitchen marks it ready → count goes 0 → 1.
      final orderId = container.read(ordersControllerProvider).first.id;
      await container
          .read(ordersControllerProvider.notifier)
          .updateStatus(orderId, OrderStatus.ready);
      await tester.pumpAndSettle();

      expect(spy.notifyCalls, 1);
      expect(find.byType(Badge), findsOneWidget);
    },
  );

  testWidgets('badge shows one entry per ready dine-in order', (tester) async {
    final spy = SpyWaiterAlertService();
    final container = createTestContainer(
      seedCheckoutFixtures: true,
      additionalOverrides: [
        waiterAlertServiceProvider.overrideWithValue(spy),
      ],
    );
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    final notifier = container.read(ordersControllerProvider.notifier);
    final cart = container.read(cartControllerProvider.notifier);
    for (final table in const ['1', '2']) {
      cart.addItem(const CartItem(menuItem: burger));
      await notifier.placeOrderForTable(table);
    }
    for (final order in container.read(ordersControllerProvider)) {
      await notifier.updateStatus(order.id, OrderStatus.ready);
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: WaiterDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsOneWidget);
    // Scope to the Badge: table cards also render bare digits.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('2')),
      findsOneWidget,
    );
    // Mounting with 2 ready orders counts as an increase over the initial
    // baseline (same as the KDS new-order alert), so exactly one chime.
    expect(spy.notifyCalls, 1);
  });

  testWidgets(
    'ready takeaway orders do not raise the pickup badge or alert',
    (tester) async {
      final spy = SpyWaiterAlertService();
      final container = createTestContainer(
        seedCheckoutFixtures: true,
        additionalOverrides: [
          waiterAlertServiceProvider.overrideWithValue(spy),
        ],
      );
      addTearDown(container.dispose);
      await primeMenuForCheckout(container);

      // Takeaway order placed through the customer flow.
      container.read(cartControllerProvider.notifier).addItem(
            const CartItem(menuItem: burger),
          );
      await container
          .read(ordersControllerProvider.notifier)
          .placeOrder(orderType: OrderType.takeaway);
      final orderId = container.read(ordersControllerProvider).first.id;
      await container
          .read(ordersControllerProvider.notifier)
          .updateStatus(orderId, OrderStatus.ready);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: WaiterDashboardPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Badge), findsNothing);
      expect(spy.notifyCalls, 0);
    },
  );
}
