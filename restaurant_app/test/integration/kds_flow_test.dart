import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/kds/presentation/pages/kds_page.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

void main() {
  const pizza = MenuItem(
    id: 'p1',
    categoryId: 'البيتزا',
    name: 'بيتزا مارجريتا',
    description: 'جبنة وطماطم',
    price: 45.0,
  );

  group('KDS Flow Integration', () {
    testWidgets('Full lifecycle: Order arrives -> Preparing -> Ready -> Completed', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cart = container.read(cartControllerProvider.notifier);
      cart.addItem(const CartItem(menuItem: pizza));

      final orders = container.read(ordersControllerProvider.notifier);
      final created = await orders.placeOrder();
      expect(created, isNotNull);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: KdsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial pending state
      expect(find.textContaining('بيتزا مارجريتا'), findsOneWidget);
      expect(find.textContaining('بانتظار التحضير'), findsOneWidget);

      // 2. Advance to preparing
      await tester.tap(find.text('قيد التحضير').last);
      await tester.pumpAndSettle();

      expect(find.text('جاهز للتسليم'), findsOneWidget);

      // 3. Advance to ready
      await tester.tap(find.text('جاهز للتسليم').last);
      await tester.pumpAndSettle();

      expect(find.text('استكمال'), findsOneWidget);

      // 4. Advance to served/completed
      await tester.tap(find.text('استكمال').last);
      await tester.pumpAndSettle();

      // Order should now be completed and removed from active KDS columns
      expect(find.textContaining('بيتزا مارجريتا'), findsNothing);
    });
  });
}
