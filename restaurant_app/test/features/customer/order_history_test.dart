import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/customer/presentation/pages/order_history_page.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

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
  const fries = MenuItem(
    id: 'f1',
    categoryId: 'مقبلات',
    name: 'بطاطس مقلية',
    description: 'وصف',
    price: 12,
  );

  testWidgets('shows empty state when no orders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OrderHistoryPage())),
    );
    await tester.pump();
    expect(find.text('لا توجد طلبات حالياً'), findsOneWidget);
  });

  testWidgets('lists placed orders with reorder action', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger, quantity: 2));
    cart.addItem(const CartItem(menuItem: fries));
    await container.read(ordersControllerProvider.notifier).placeOrder();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OrderHistoryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('برجر كلاسيك'), findsOneWidget);
    expect(find.textContaining('بطاطس مقلية'), findsOneWidget);
    expect(find.text('أعد الطلب'), findsOneWidget);
  });

  testWidgets('reorder adds items back to the cart', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger, quantity: 2));
    cart.addItem(const CartItem(menuItem: fries));
    await container.read(ordersControllerProvider.notifier).placeOrder();

    expect(cart.state, isEmpty); // cart cleared after ordering

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OrderHistoryPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('أعد الطلب'));
    await tester.pumpAndSettle();

    expect(cart.unitCount, 3); // 2 burgers + 1 fries
    expect(cart.state, hasLength(2));
  });
}
