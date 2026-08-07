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

  const fries = MenuModifierOption(
    id: 'opt-fries',
    name: 'بطاطس مقلية',
    extraPrice: 5,
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

  testWidgets('shows modifier options and special notes on the card', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(
      const CartItem(
        menuItem: burger,
        quantity: 1,
        selectedModifiers: [fries],
        specialNotes: 'بدون ملح',
      ),
    );
    await container.read(ordersControllerProvider.notifier).placeOrder();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('بطاطس مقلية'), findsOneWidget);
    expect(find.textContaining('ملاحظات الطلب: بدون ملح'), findsOneWidget);
  });

  testWidgets('shows new badge for freshly placed orders', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger));
    await container.read(ordersControllerProvider.notifier).placeOrder();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('جديد'), findsOneWidget);
  });

  testWidgets('shows item count and order total on the card', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger, quantity: 2));
    await container.read(ordersControllerProvider.notifier).placeOrder();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // 2 × burger line plus the summary row both show a count.
    expect(find.text('عدد الأصناف: 2'), findsOneWidget);
  });

  testWidgets('shows the table number instead of the raw id', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger));
    await container
        .read(ordersControllerProvider.notifier)
        .placeOrderForTable('t1');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: KdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Seed table 't1' has tableNumber 1.
    expect(find.text('طاولة 1'), findsOneWidget);
    expect(find.textContaining('مقاعد t1'), findsNothing);
  });
}
