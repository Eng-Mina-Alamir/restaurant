import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/cart/presentation/pages/cart_page.dart';
import 'package:restaurant_app/features/customer/presentation/pages/order_history_page.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
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
    final container = createTestContainer(seedCheckoutFixtures: true);
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger, quantity: 2));
    cart.addItem(const CartItem(menuItem: fries));
    await container
        .read(ordersControllerProvider.notifier)
        .placeOrder(paymentMethod: PaymentMethod.card);

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
    // Payment method shown on the history card.
    expect(find.textContaining('الدفع: بطاقة'), findsOneWidget);
  });

  testWidgets('reorder adds items back to the cart', (tester) async {
    final container = createTestContainer(seedCheckoutFixtures: true);
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger, quantity: 2));
    cart.addItem(const CartItem(menuItem: fries));
    await container.read(ordersControllerProvider.notifier).placeOrder();

    expect(cart.state, isEmpty); // cart cleared after ordering

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const OrderHistoryPage(),
        ),
        GoRoute(
          path: '/customer/cart',
          builder: (context, state) => const CartPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('أعد الطلب'));
    await tester.pumpAndSettle();

    expect(cart.unitCount, 3); // 2 burgers + 1 fries
    expect(cart.state, hasLength(2));
    // Reorder navigates straight to the cart for review/checkout.
    expect(find.byType(CartPage), findsOneWidget);
  });

  testWidgets('reorder skips unavailable items', (tester) async {
    final container = createTestContainer(seedCheckoutFixtures: true);
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    // fries becomes unavailable after the original order was placed.
    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: fries));
    await container.read(ordersControllerProvider.notifier).placeOrder();
    final unavailableFries = fries.copyWith(isAvailable: false);

    final orders = container.read(ordersControllerProvider.notifier);
    final placed = orders.state.single;
    orders.state = [
      placed.copyWith(
        items: [placed.items.single.copyWith(menuItem: unavailableFries)],
      ),
    ];

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const OrderHistoryPage(),
        ),
        GoRoute(
          path: '/customer/cart',
          builder: (context, state) => const CartPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('أعد الطلب'));
    await tester.pumpAndSettle();

    // No items were added because the only item is now unavailable.
    expect(cart.state, isEmpty);
    expect(find.text('لا يوجد أصناف لإعادة طلبها'), findsOneWidget);
  });

  testWidgets('reorder reports skipped items when some are unavailable', (
    tester,
  ) async {
    final container = createTestContainer(seedCheckoutFixtures: true);
    addTearDown(container.dispose);
    await primeMenuForCheckout(container);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: burger));
    cart.addItem(const CartItem(menuItem: fries));
    await container.read(ordersControllerProvider.notifier).placeOrder();

    // Fries becomes unavailable; burger stays available.
    final orders = container.read(ordersControllerProvider.notifier);
    final placed = orders.state.single;
    final burgerItem = placed.items.firstWhere(
      (i) => i.menuItem.id == burger.id,
    );
    final friesItem = placed.items
        .firstWhere((i) => i.menuItem.id == fries.id)
        .copyWith(menuItem: fries.copyWith(isAvailable: false));
    orders.state = [
      placed.copyWith(items: [burgerItem, friesItem]),
    ];

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const OrderHistoryPage(),
        ),
        GoRoute(
          path: '/customer/cart',
          builder: (context, state) => const CartPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('أعد الطلب'));
    await tester.pumpAndSettle();

    // Only the available burger is added; fries is reported as skipped.
    expect(cart.state, hasLength(1));
    expect(cart.state.first.menuItem.id, burger.id);
    expect(find.textContaining('تم تخطي'), findsOneWidget);
  });
}
