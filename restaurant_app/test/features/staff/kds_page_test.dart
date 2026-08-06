import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/kds/presentation/pages/kds_page.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );

  testWidgets('shows empty state when no orders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: KdsPage())),
    );
    await tester.pump();
    expect(find.text('لا توجد طلبات حالياً'), findsOneWidget);
  });

  testWidgets('shows a sent order and advances its status', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger));
    final orders = container.read(ordersControllerProvider.notifier);
    await orders.placeOrder();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Order appears under pending column.
    expect(find.textContaining('برجر كلاسيك'), findsOneWidget);
    expect(find.textContaining('بانتظار التحضير'), findsOneWidget);

    // Advance to preparing.
    await tester.tap(find.text('قيد التحضير').last);
    await tester.pumpAndSettle();
    expect(find.text('جاهز للتسليم'), findsOneWidget);
  });
}
