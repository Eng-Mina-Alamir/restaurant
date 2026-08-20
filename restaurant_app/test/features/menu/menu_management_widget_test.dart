import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/menu/presentation/pages/menu_management_page.dart';

void main() {
  group('MenuManagementPage Widget Tests', () {
    testWidgets('renders menu list, categories chips and action buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MenuManagementPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إدارة القائمة والأصناف'), findsOneWidget);
      expect(find.text('إضافة صنف'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsWidgets);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('tapping add category opens dialog', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MenuManagementPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.create_new_folder_outlined));
      await tester.pumpAndSettle();

      expect(find.text('إضافة قسم جديد'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('إضافة'), findsOneWidget);
    });

    testWidgets('tapping add item opens bottom sheet', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MenuManagementPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('إضافة صنف جديد'), findsOneWidget);
      expect(find.text('اسم الوجبة / الصنف *'), findsOneWidget);
      expect(find.text('حفظ وإضافة الصنف'), findsOneWidget);
    });
  });
}
