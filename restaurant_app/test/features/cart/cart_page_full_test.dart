import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/cart/presentation/pages/cart_page.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'مشويات',
    name: 'شيش طاووق متبل',
    description: 'قطع صدور دجاج مشوية بتتبيلة الزعفران والليمون',
    price: 190,
  );

  testWidgets('renders full CartPage with realistic item without error', (tester) async {
    final container = ProviderContainer(
      overrides: [
        cartControllerProvider.overrideWith((ref) {
          final controller = CartController();
          controller.addItem(const CartItem(menuItem: burger, quantity: 1));
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
    await tester.pumpAndSettle();

    expect(find.text('شيش طاووق متبل'), findsOneWidget);
    expect(find.text('سلة الطلب'), findsOneWidget);
    expect(find.text('نوع الطلب'), findsOneWidget);
    expect(find.text('تناول محلي'), findsOneWidget);
    expect(find.text('توصيل'), findsOneWidget);
  });
}
