import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/pages/waiter_dashboard_page.dart';

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

  test('tableStatusLabel maps every status to an Arabic label', () {
    expect(tableStatusLabel(TableStatus.available), 'متاحة');
    expect(tableStatusLabel(TableStatus.occupied), 'مشغولة');
    expect(tableStatusLabel(TableStatus.reserved), 'محجوزة');
    expect(tableStatusLabel(TableStatus.needsCleaning), 'تحتاج تنظيف');
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
    final container = ProviderContainer();
    addTearDown(container.dispose);

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
}
