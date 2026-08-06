import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/table_management/presentation/pages/waiter_dashboard_page.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: WaiterDashboardPage())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the seeded tables grid', (tester) async {
    await pumpPage(tester);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    // Table 8 is below the fold; scroll until visible.
    await tester.scrollUntilVisible(find.text('8'), 200);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('shows a take-order button on each table', (tester) async {
    await pumpPage(tester);
    expect(find.text('أخذ الطلب'), findsWidgets);
  });

  test('tableStatusLabel maps every status to an Arabic label', () {
    expect(tableStatusLabel(TableStatus.available), 'متاحة');
    expect(tableStatusLabel(TableStatus.occupied), 'مشغولة');
    expect(tableStatusLabel(TableStatus.reserved), 'محجوزة');
    expect(tableStatusLabel(TableStatus.needsCleaning), 'تحتاج تنظيف');
  });

  test('tableStatusColor returns a distinct color per status', () {
    final colors = <Color>{
      tableStatusColor(TableStatus.available),
      tableStatusColor(TableStatus.occupied),
      tableStatusColor(TableStatus.reserved),
      tableStatusColor(TableStatus.needsCleaning),
    };
    expect(colors, hasLength(4));
  });
}
