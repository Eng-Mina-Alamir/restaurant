import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/discounts_page.dart';

void main() {
  group('DiscountsPage', () {
    testWidgets('renders discounts list and allows adding new discount', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DiscountsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الخصومات والعروض'), findsOneWidget);
      expect(find.text('خصم الأحد'), findsOneWidget);
      expect(find.text('خصم جديد'), findsOneWidget);

      // Open add discount dialog
      await tester.tap(find.text('خصم جديد'));
      await tester.pumpAndSettle();

      expect(find.text('إضافة خصم جديد'), findsOneWidget);
      expect(find.text('اسم الخصم'), findsOneWidget);
    });
  });
}
