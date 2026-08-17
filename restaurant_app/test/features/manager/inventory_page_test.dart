import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/inventory_page.dart';

void main() {
  group('InventoryPage', () {
    testWidgets('renders inventory overview metrics and items list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: InventoryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إدارة المخزون'), findsOneWidget);
      expect(find.textContaining('منتهية'), findsWidgets);
      expect(find.textContaining('منخفضة'), findsWidgets);
      expect(find.text('لحم بقري مفروم'), findsOneWidget);
      expect(find.text('صنف جديد'), findsOneWidget);

      // Tap FAB
      await tester.tap(find.text('صنف جديد'));
      await tester.pumpAndSettle();

      expect(find.text('سيتم إضافة هذه الميزة في الإصدار القادم'), findsOneWidget);
    });
  });
}
