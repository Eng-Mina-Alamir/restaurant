import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/pages/table_detail_page.dart';
import '../../helpers/test_container.dart';

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );

  testWidgets('shows table info and no active order when empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: TableDetailPage(tableId: 't1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('تفاصيل الطاولة'), findsOneWidget);
    expect(find.text('لا يوجد طلب نشط'), findsWidgets);
    // Seed table 1 is in the "تراس" zone.
    expect(find.text('تراس'), findsOneWidget);
    expect(find.byIcon(Icons.place_outlined), findsOneWidget);
  });

  testWidgets('shows active order items after placing one', (tester) async {
    final container = createTestContainer();
    addTearDown(container.dispose);

    // Pump first so TableController's async load completes.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TableDetailPage(tableId: 't1')),
      ),
    );
    await tester.pumpAndSettle();

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger, quantity: 2));
    await container
        .read(ordersControllerProvider.notifier)
        .placeOrderForTable('t1');
    await container
        .read(tableControllerProvider.notifier)
        .occupy('t1', orderId: 'ORD-0001');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TableDetailPage(tableId: 't1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('برجر كلاسيك'), findsOneWidget);
    // Occupied table: take-order button is hidden.
    expect(find.text('أخذ الطلب'), findsNothing);
  });
}
