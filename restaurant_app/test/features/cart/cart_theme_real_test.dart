import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/theme/app_theme.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/cart/presentation/pages/cart_page.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  const item = MenuItem(
    id: 'kebab_1',
    categoryId: 'مشويات',
    name: 'كباب وكفتة ضاني',
    description: 'مشويات على الفحم مع أرز بسمتي وسلطات وطحينة',
    price: 280,
  );

  testWidgets('renders CartPage under full Arabic AppTheme.light', (tester) async {
    final container = ProviderContainer(
      overrides: [
        cartControllerProvider.overrideWith((ref) {
          final controller = CartController();
          controller.addItem(const CartItem(menuItem: item, quantity: 4));
          return controller;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const CartPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('كباب وكفتة ضاني'), findsOneWidget);
    expect(find.text('سلة الطلب'), findsOneWidget);
    expect(find.text('نوع الطلب'), findsOneWidget);
    expect(find.text('تناول محلي'), findsOneWidget);
    expect(find.text('إتمام الطلب'), findsOneWidget);
    expect(find.textContaining('1,288'), findsWidgets);
  });
}
