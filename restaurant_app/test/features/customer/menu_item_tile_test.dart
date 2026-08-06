import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/utils/formatters.dart';
import 'package:restaurant_app/features/customer/presentation/widgets/menu_item_tile.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  const base = MenuItem(
    id: 'm1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );

  Widget wrap(MenuItem item) => MaterialApp(
    home: Scaffold(body: MenuItemTile(item: item)),
  );

  testWidgets('shows name, description and price', (tester) async {
    await tester.pumpWidget(wrap(base));
    expect(find.text('برجر كلاسيك'), findsOneWidget);
    expect(find.text('وصف'), findsOneWidget);
    expect(find.text(Formatters.formatCurrency(28)), findsOneWidget);
  });

  testWidgets('shows veg and spicy badges when set', (tester) async {
    await tester.pumpWidget(
      wrap(base.copyWith(isVegetarian: true, isSpicy: true)),
    );
    expect(find.text('نباتي'), findsOneWidget);
    expect(find.text('حار'), findsOneWidget);
    expect(find.text('غير متوفر'), findsNothing);
  });

  testWidgets('shows unavailable badge and disables add when out of stock', (
    tester,
  ) async {
    var added = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MenuItemTile(
            item: base.copyWith(isAvailable: false),
            onAdd: () => added = true,
          ),
        ),
      ),
    );
    expect(find.text('غير متوفر'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add), warnIfMissed: false);
    expect(added, isFalse);
  });

  testWidgets('add button triggers onAdd when available', (tester) async {
    var added = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MenuItemTile(item: base, onAdd: () => added = true),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.add));
    expect(added, isTrue);
  });
}
