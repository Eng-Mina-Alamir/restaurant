import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/cart/presentation/pages/cart_page.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  const cheese = MenuModifierOption(id: 'c1', name: 'جبنة', extraPrice: 4);
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );

  Future<void> pumpWithCart(WidgetTester tester, List<CartItem> items) async {
    final container = ProviderContainer(
      overrides: [
        cartControllerProvider.overrideWith((ref) {
          final controller = CartController();
          for (final item in items) {
            controller.addItem(item);
          }
          return controller;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CartPage()),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows empty message when no items', (tester) async {
    await pumpWithCart(tester, const []);
    expect(find.text('العربة فارغة'), findsOneWidget);
    expect(find.text('تصفح القائمة'), findsOneWidget);
  });

  testWidgets('renders item, quantity, price and totals', (tester) async {
    await pumpWithCart(tester, const [
      CartItem(menuItem: burger, quantity: 2, selectedModifiers: [cheese]),
    ]);

    expect(find.text('برجر كلاسيك'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    // unit (32) * 2 = 64 line price
    expect(find.textContaining('64.00'), findsWidgets);
    // totals: subtotal 64 + 9.6 tax = 73.60
    expect(find.textContaining('73.60'), findsWidgets);
  });

  testWidgets('increment updates quantity via stepper', (tester) async {
    await pumpWithCart(tester, const [CartItem(menuItem: burger)]);
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('shows special notes on the cart line', (tester) async {
    await pumpWithCart(tester, const [
      CartItem(menuItem: burger, specialNotes: 'بدون بصل'),
    ]);

    expect(find.textContaining('ملاحظات الطلب: بدون بصل'), findsOneWidget);
  });
}
