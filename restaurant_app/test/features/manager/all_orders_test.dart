import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/pages/all_orders_page.dart';
import '../../helpers/test_container.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );

  Future<ProviderContainer> seedOrder() async {
    final container = createTestContainer(seedCheckoutFixtures: true);
    await primeMenuForCheckout(container);
    container
        .read(cartControllerProvider.notifier)
        .addItem(const CartItem(menuItem: burger, quantity: 1));
    await container
        .read(ordersControllerProvider.notifier)
        .placeOrderForTable('t1');
    return container;
  }

  testWidgets('shows empty state when no orders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AllOrdersPage())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('جميع الطلبات'), findsOneWidget);
    expect(find.textContaining('لا توجد طلبات'), findsOneWidget);
  });

  testWidgets('lists orders and advances status via button', (tester) async {
    final container = await seedOrder();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AllOrdersPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('#1'), findsOneWidget);
    expect(find.textContaining('نقل إلى'), findsWidgets);

    // Advance the order (pending -> preparing).
    await tester.tap(find.textContaining('نقل إلى').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('قيد التحضير'), findsWidgets);
  });

  testWidgets('filters orders by status chip', (tester) async {
    final container = await seedOrder();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AllOrdersPage()),
      ),
    );
    await tester.pumpAndSettle();

    // The seeded order is pending; only it should be listed.
    expect(find.textContaining('#1'), findsOneWidget);

    // Filter to "confirmed" -> no pending orders match, empty state shows.
    await tester.tap(find.text('مؤكد'));
    await tester.pumpAndSettle();
    expect(find.textContaining('لا توجد طلبات'), findsOneWidget);

    // Back to "الكل" -> the pending order reappears.
    await tester.tap(find.text('الكل'));
    await tester.pumpAndSettle();
    expect(find.textContaining('#1'), findsOneWidget);
  });
}
