import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/config/app_config.dart';
import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/customer/presentation/pages/customer_home_page.dart';
import 'package:restaurant_app/features/customer/presentation/widgets/category_chips.dart';
import 'package:restaurant_app/features/customer/presentation/widgets/menu_item_tile.dart';
import 'package:restaurant_app/features/menu/data/menu_seed_data.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CustomerHomePage())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders seeded menu item names and prices', (tester) async {
    await pumpPage(tester);

    final firstItem = MenuSeedData.items.first;
    expect(find.text(firstItem.name), findsWidgets);
    expect(find.textContaining(AppConfig.defaultCurrency), findsWidgets);
  });

  testWidgets('add button increments the cart unit count', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
      matching: find.byType(MenuItemTile),
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
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    expect(find.text(burgerItems.first.name), findsWidgets);
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

  testWidgets('category chips narrow the menu to one category', (tester) async {
    await pumpPage(tester);

    // Tap the desserts category chip.
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'حلويات'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'حلويات'));
    await tester.pumpAndSettle();

    final desserts = MenuSeedData.items
        .where((i) => i.categoryId == 'حلويات')
        .toList();
    expect(desserts, isNotEmpty);
    expect(find.text(desserts.first.name), findsWidgets);
    // A burger item should no longer be visible.
    final burger = MenuSeedData.items.firstWhere((i) => i.categoryId == 'برجر');
    expect(find.text(burger.name), findsNothing);

    // Back to "الكل" restores the full menu (category row's all-chip).
    await tester.drag(find.byType(CategoryChips), const Offset(600, 0));
    await tester.pumpAndSettle();
    final allChip = find.descendant(
      of: find.byType(CategoryChips),
      matching: find.widgetWithText(ChoiceChip, AppConstants.dietAll),
    );
    await tester.tap(allChip);
    await tester.pumpAndSettle();
    expect(find.text(burger.name), findsWidgets);
  });
}
