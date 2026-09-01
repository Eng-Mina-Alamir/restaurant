import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/features/menu/data/menu_seed_data.dart';
import 'package:restaurant_app/features/table_management/presentation/pages/waiter_order_page.dart';

import '../../helpers/test_container.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, String tableId) async {
    final container = createTestContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: WaiterOrderPage(tableId: tableId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders menu items for waiter intake', (tester) async {
    await pumpPage(tester, 't1');

    final firstItem = MenuSeedData.items.first;
    expect(find.text(firstItem.name), findsWidgets);
    // Empty cart: button shows the disabled hint instead of the send action.
    expect(find.text('أضف أصنافاً أولاً'), findsOneWidget);
  });

  testWidgets('tapping a simple item adds it to the cart', (tester) async {
    await pumpPage(tester, 't1');

    final simpleItem = MenuSeedData.items.firstWhere(
      (item) => item.modifierGroups.isEmpty,
    );
    final tile = find.ancestor(
      of: find.text(simpleItem.name).first,
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(of: tile, matching: find.byIcon(Icons.add)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('إرسال إلى المطبخ'), findsOneWidget);
    expect(find.textContaining('1'), findsWidgets);
  });

  testWidgets('search narrows the menu list', (tester) async {
    await pumpPage(tester, 't1');

    final firstItem = MenuSeedData.items.first;
    expect(find.text(firstItem.name), findsWidgets);

    await tester.enterText(find.byType(TextField), 'بيتزا');
    await tester.pumpAndSettle();

    final pizzaItem = MenuSeedData.items.firstWhere(
      (item) => item.name.contains('بيتزا'),
    );
    expect(find.text(pizzaItem.name), findsWidgets);
    expect(find.text(firstItem.name), findsNothing);
  });

  testWidgets('shows empty state when search matches nothing', (tester) async {
    await pumpPage(tester, 't1');

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.noItemsFound), findsOneWidget);
  });
}
