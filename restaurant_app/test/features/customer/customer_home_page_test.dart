import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/customer/presentation/pages/customer_home_page.dart';
import 'package:restaurant_app/features/menu/data/menu_seed_data.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CustomerHomePage())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders seeded menu item names and prices', (tester) async {
    await pumpPage(tester);

    final firstItem = MenuSeedData.items.first;
    expect(find.text(firstItem.name), findsWidgets);
    expect(find.textContaining('ر.س'), findsWidgets);
  });

  testWidgets('add button increments the cart unit count', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CustomerHomePage()),
      ),
    );
    await tester.pumpAndSettle();

    final cart = container.read(cartControllerProvider.notifier);
    expect(cart.unitCount, 0);

    final simpleItem = MenuSeedData.items.firstWhere(
      (item) => item.modifierGroups.isEmpty,
    );
    // Tapping the tile's add (IconButton) on a no-modifier item quick-adds.
    final simpleTile = find.ancestor(
      of: find.text(simpleItem.name).first,
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(of: simpleTile, matching: find.byIcon(Icons.add)),
    );
    await tester.pump();

    expect(cart.unitCount, greaterThan(0));
  });

  testWidgets('app bar cart icon shows a badge with the unit count', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Pre-seed the cart with two units of the first simple item.
    final simpleItem = MenuSeedData.items.firstWhere(
      (item) => item.modifierGroups.isEmpty,
    );
    container
        .read(cartControllerProvider.notifier)
        .addItem(CartItem(menuItem: simpleItem, quantity: 2));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CustomerHomePage()),
      ),
    );
    await tester.pumpAndSettle();

    // Badge label shows the total unit count (2).
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('search field narrows the visible items', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), 'برجر');
    await tester.pumpAndSettle();

    // Only burger items remain visible.
    final burgerItems = MenuSeedData.items
        .where((i) => i.name.contains('برجر'))
        .toList();
    expect(burgerItems, isNotEmpty);
    for (final item in burgerItems) {
      expect(find.text(item.name), findsWidgets);
    }
    // An unrelated item (e.g. a dessert) should be filtered out.
    final nonBurger = MenuSeedData.items.firstWhere(
      (i) => !i.name.contains('برجر') && !i.description.contains('برجر'),
    );
    expect(find.text(nonBurger.name), findsNothing);
  });

  testWidgets('search with no matches shows the empty state', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), 'zzz-not-found');
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.noItemsFound), findsOneWidget);
  });

  testWidgets('diet chips filter to vegetarian items only', (tester) async {
    await pumpPage(tester);

    // Tap the vegetarian chip (a ChoiceChip in the diet filter row).
    await tester.tap(
      find.widgetWithText(ChoiceChip, AppConstants.dietVegetarian),
    );
    await tester.pumpAndSettle();

    // All visible items should be vegetarian.
    final vegetarianCount = MenuSeedData.items
        .where((i) => i.isVegetarian)
        .length;
    expect(vegetarianCount, greaterThan(0));
    final nonVeg = MenuSeedData.items.firstWhere((i) => !i.isVegetarian);
    expect(find.text(nonVeg.name), findsNothing);
  });
}
