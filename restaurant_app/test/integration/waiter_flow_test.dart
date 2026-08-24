import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/pages/waiter_dashboard_page.dart';
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
  });
}
