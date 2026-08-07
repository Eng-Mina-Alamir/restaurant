import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/customer/presentation/pages/menu_item_detail_sheet.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';

void main() {
  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 28,
  );

  const spicyVeggie = MenuItem(
    id: 'b2',
    categoryId: 'برجر',
    name: 'برجر حار نباتي',
    description: 'وصف',
    price: 30,
    isVegetarian: true,
    isSpicy: true,
  );

  const unavailable = MenuItem(
    id: 'b3',
    categoryId: 'برجر',
    name: 'برجر غير متوفر',
    description: 'وصف',
    price: 26,
    isAvailable: false,
  );

  const withRequiredGroup = MenuItem(
    id: 'b4',
    categoryId: 'برجر',
    name: 'برجر بالتخصيص',
    description: 'وصف',
    price: 20,
    modifierGroups: [
      MenuModifierGroup(
        id: 'g1',
        title: 'الحجم',
        isRequired: true,
        options: [
          MenuModifierOption(id: 'o1', name: 'وسط', extraPrice: 0),
          MenuModifierOption(id: 'o2', name: 'كبير', extraPrice: 8),
        ],
      ),
    ],
  );

  testWidgets('shows dietary and availability badges', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: _Host(menuItem: spicyVeggie)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.dietVegetarian), findsOneWidget);
    expect(find.text(AppConstants.dietSpicy), findsOneWidget);
    expect(find.text(AppConstants.itemUnavailable), findsNothing);
  });

  testWidgets('shows unavailable badge for out-of-stock items', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: _Host(menuItem: unavailable)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.itemUnavailable), findsOneWidget);
    expect(find.text(AppConstants.dietVegetarian), findsNothing);
    expect(find.text(AppConstants.dietSpicy), findsNothing);

    // Add button is disabled for out-of-stock items.
    final addButton = find.widgetWithText(FilledButton, 'أضف إلى السلة');
    expect(tester.widget<FilledButton>(addButton).enabled, isFalse);
  });

  testWidgets('adds item with special notes to the cart', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: _Host(menuItem: burger)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('برجر كلاسيك'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'بدون بصل');
    await tester.tap(find.text('أضف إلى السلة'));
    await tester.pumpAndSettle();

    final cart = container.read(cartControllerProvider);
    expect(cart, hasLength(1));
    expect(cart.first.specialNotes, 'بدون بصل');
    expect(cart.first.quantity, 1);
  });

  testWidgets('empty notes are stored as null', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: _Host(menuItem: burger)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أضف إلى السلة'));
    await tester.pumpAndSettle();

    final cart = container.read(cartControllerProvider);
    expect(cart, hasLength(1));
    expect(cart.first.specialNotes, isNull);
  });

  testWidgets('requires a selection for a required modifier group', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: _Host(menuItem: withRequiredGroup)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Add button is disabled until a required option is chosen.
    final addButton = find.widgetWithText(FilledButton, 'أضف إلى السلة');
    expect(tester.widget<FilledButton>(addButton).enabled, isFalse);

    await tester.tap(find.textContaining('كبير'));
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(addButton).enabled, isTrue);

    await tester.tap(addButton);
    await tester.pumpAndSettle();

    final cart = container.read(cartControllerProvider);
    expect(cart, hasLength(1));
    expect(cart.first.selectedModifiers.single.name, 'كبير');
  });

  testWidgets('decrement is disabled when quantity is already one', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: _Host(menuItem: burger)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final decrement = find.widgetWithIcon(IconButton, Icons.remove);
    expect(tester.widget<IconButton>(decrement).onPressed, isNull);
  });
}

class _Host extends StatelessWidget {
  const _Host({required this.menuItem});

  final MenuItem menuItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: FilledButton(
            onPressed: () => MenuItemDetailSheet.show(context, menuItem),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}
