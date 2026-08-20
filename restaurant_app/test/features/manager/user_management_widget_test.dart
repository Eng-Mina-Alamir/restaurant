import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/user_management_page.dart';

void main() {
  group('UserManagementPage Widget Tests', () {
    testWidgets('renders user list, role filters and search bar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: UserManagementPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إدارة الموظفين والمستخدمين'), findsOneWidget);
      expect(find.text('إضافة موظف'), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('tapping add employee opens bottom sheet', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: UserManagementPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_add_alt_1_outlined));
      await tester.pumpAndSettle();

      expect(find.text('إضافة موظف جديد'), findsOneWidget);
      expect(find.text('الاسم بالكامل *'), findsOneWidget);
      expect(find.text('البريد الإلكتروني *'), findsOneWidget);
      expect(find.text('رقم الهاتف *'), findsOneWidget);
      expect(find.text('إضافة الموظف'), findsOneWidget);
    });
  });
}
