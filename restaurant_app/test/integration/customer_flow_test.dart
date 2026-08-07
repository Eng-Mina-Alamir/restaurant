import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:restaurant_app/features/cart/presentation/pages/cart_page.dart';
import 'package:restaurant_app/features/customer/presentation/pages/customer_home_page.dart';
import 'package:restaurant_app/features/menu/data/menu_seed_data.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/orders/presentation/pages/order_confirmation_page.dart';

/// End-to-end style flow test: browse menu → add item → open cart →
/// checkout → land on confirmation with the placed order.
void main() {
  testWidgets('customer can complete an order from menu to confirmation', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const CustomerHomePage(),
        ),
        GoRoute(
          path: '/customer/cart',
          builder: (context, state) => const CartPage(),
        ),
        GoRoute(
          path: '/customer/order-confirmation',
          builder: (context, state) =>
              OrderConfirmationPage(order: state.extra! as dynamic),
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

    // Pick a simple item (no modifiers) and quick-add it to the cart.
    final simpleItem = MenuSeedData.items.firstWhere(
      (item) => item.modifierGroups.isEmpty,
    );
    final tile = find.ancestor(
      of: find.text(simpleItem.name).first,
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(of: tile, matching: find.byIcon(Icons.add)),
    );
    await tester.pump();

    // Cart badge reflects the new unit.
    expect(find.text('1'), findsWidgets);

    // Open the cart.
    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await tester.pumpAndSettle();
    expect(find.text('سلة الطلب'), findsOneWidget);

    // Checkout.
    await tester.tap(find.text('إتمام الطلب'));
    await tester.pumpAndSettle();

    // Land on the confirmation page with the order summary.
    expect(find.byType(OrderConfirmationPage), findsOneWidget);
    expect(find.textContaining('تم استلام طلبك بنجاح'), findsOneWidget);
    expect(find.textContaining(simpleItem.name), findsWidgets);

    // The order is persisted in the controller.
    final orders = container.read(ordersControllerProvider);
    expect(orders, hasLength(1));
    expect(orders.first.items.single.menuItem.name, simpleItem.name);
  });
}
