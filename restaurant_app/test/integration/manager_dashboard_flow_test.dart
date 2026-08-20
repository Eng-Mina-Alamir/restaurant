import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurant_app/config/constants.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/alerts_page.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/discounts_page.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/financial_reports_page.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/inventory_page.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/manager_dashboard_page.dart';
import '../helpers/test_container.dart';

void main() {
  testWidgets('Manager dashboard full navigation flow', (tester) async {
    final container = createTestContainer();
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/manager',
      routes: [
        GoRoute(
          path: '/manager',
          builder: (context, state) => const ManagerDashboardPage(),
        ),
        GoRoute(
          path: '/manager/alerts',
          builder: (context, state) => const AlertsPage(),
        ),
        GoRoute(
          path: '/manager/discounts',
          builder: (context, state) => const DiscountsPage(),
        ),
        GoRoute(
          path: '/manager/inventory',
          builder: (context, state) => const InventoryPage(),
        ),
        GoRoute(
          path: '/manager/financial-reports',
          builder: (context, state) => const FinancialReportsPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Verify on Dashboard
    expect(find.text(AppConstants.managerTitle), findsOneWidget);
    expect(find.text('الإجراءات السريعة'), findsOneWidget);

    // Navigate to Alerts Page
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('مركز التنبيهات'), findsOneWidget);

    // Go back
    router.go('/manager');
    await tester.pumpAndSettle();
    expect(find.text(AppConstants.managerTitle), findsOneWidget);

    // Navigate to Discounts
    await tester.tap(find.text('الخصومات'));
    await tester.pumpAndSettle();
    expect(find.text('الخصومات والعروض'), findsOneWidget);

    // Go back
    router.go('/manager');
    await tester.pumpAndSettle();

    // Navigate to Inventory
    await tester.tap(find.text('المخزون'));
    await tester.pumpAndSettle();
    expect(find.text('إدارة المخزون والتوريد'), findsOneWidget);
  });
}
