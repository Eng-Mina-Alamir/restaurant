import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
