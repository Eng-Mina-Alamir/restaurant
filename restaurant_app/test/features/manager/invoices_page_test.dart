import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/invoices_page.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import '../../helpers/test_container.dart';

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );

  group('InvoicesPage', () {
    testWidgets('shows empty state when no completed orders exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: InvoicesPage())),
      );
      await tester.pump();

      expect(find.textContaining('الفواتير'), findsOneWidget);
      expect(find.textContaining('لا توجد فواتير'), findsOneWidget);
    });

    testWidgets(
      'shows invoice card when completed orders exist and clicking export triggers snackbar',
      (tester) async {
        final container = createTestContainer(seedCheckoutFixtures: true);
        await primeMenuForCheckout(container);
        addTearDown(container.dispose);

        final cart = container.read(cartControllerProvider.notifier);
        cart.addItem(const CartItem(menuItem: burger));

        final orders = container.read(ordersControllerProvider.notifier);
        final placed = await orders.placeOrder();
        expect(placed, isNotNull);

        // Advance order to completed
        await orders.updateStatus(placed!.id, OrderStatus.completed);

        expect(
          container.read(ordersControllerProvider).first.status,
          OrderStatus.completed,
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: InvoicesPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(placed.id), findsOneWidget);
        expect(find.text('مكتمل'), findsOneWidget);

        // Tap Export button
        await tester.tap(find.byIcon(Icons.download_outlined));
        await tester.pump();

        expect(find.textContaining('تم تصدير الفواتير بنجاح'), findsOneWidget);
      },
    );
  });
}
