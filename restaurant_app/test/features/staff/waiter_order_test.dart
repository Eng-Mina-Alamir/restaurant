import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/menu/data/menu_seed_data.dart';
import 'package:restaurant_app/features/table_management/presentation/pages/waiter_order_page.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, String tableId) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: WaiterOrderPage(tableId: tableId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders menu items for waiter intake', (tester) async {
    await pumpPage(tester, 't1');

    final firstItem = MenuSeedData.items.first;
    expect(find.text(firstItem.name), findsWidgets);
    expect(find.textContaining('إرسال إلى المطبخ'), findsOneWidget);
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
}
