import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/notifications/waiter_alert_service.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/pages/waiter_dashboard_page.dart';
import '../helpers/spy_waiter_alert_service.dart';
import '../helpers/test_container.dart';

void main() {
  group('Waiter Flow Integration', () {
    testWidgets(
      'Waiter views tables, selects table and places order for table',
      (tester) async {
        final container = createTestContainer(seedCheckoutFixtures: true);
        addTearDown(container.dispose);
        await primeMenuForCheckout(container);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: WaiterDashboardPage()),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Dashboard displays tables and actions
        expect(find.text(AppConstants.tablesTitle), findsOneWidget);
        expect(find.byType(GridView), findsOneWidget);
        expect(find.text('أخذ الطلب'), findsWidgets);

        // 2. Add item to cart and place table order
        final cart = container.read(cartControllerProvider.notifier);
        cart.addItem(CartItem(menuItem: checkoutFixtureItems.first));

        final orders = container.read(ordersControllerProvider.notifier);
        final tableOrder = await orders.placeOrderForTable('t1');
        expect(tableOrder, isNotNull);
        expect(tableOrder?.tableId, 't1');
        expect(tableOrder?.orderType, OrderType.dineIn);

        // 3. Mark table occupied
        final tableCtrl = container.read(tableControllerProvider.notifier);
        await tableCtrl.occupy('t1', orderId: tableOrder!.id);

        final table = container
            .read(tableControllerProvider)
            .firstWhere((t) => t.id == 't1');
        expect(table.status, TableStatus.occupied);
      },
    );

    testWidgets(
      'kitchen marks the table order ready → dashboard badge and chime fire',
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

        // 1. Waiter takes the order for table t1.
        final cart = container.read(cartControllerProvider.notifier);
        cart.addItem(CartItem(menuItem: checkoutFixtureItems.first));
        final orders = container.read(ordersControllerProvider.notifier);
        final tableOrder = await orders.placeOrderForTable('t1');
        expect(tableOrder, isNotNull);

        // 2. Kitchen finishes the ticket → status flips to ready via the
        // legal path (pending -> preparing -> ready).
        await orders.updateStatus(tableOrder!.id, OrderStatus.preparing);
        await orders.updateStatus(tableOrder.id, OrderStatus.ready);
        expect(
          container.read(ordersControllerProvider).first.status,
          OrderStatus.ready,
        );

        // 3. Waiter opens the dashboard: one ready dine-in ticket means the
        //    AppBar badge shows '1' and exactly one pickup chime fires.
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
          find.descendant(of: find.byType(Badge), matching: find.text('1')),
          findsOneWidget,
        );
        expect(spy.notifyCalls, 1);
      },
    );
  });
}
