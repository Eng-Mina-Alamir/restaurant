import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/staff_performance_page.dart';

void main() {
  group('StaffPerformancePage', () {
    testWidgets('renders staff KPI metrics cards and staff leaderboard list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StaffPerformancePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('أداء الموظفين'), findsOneWidget);
      expect(find.text('أفضل موظف اليوم'), findsOneWidget);
      expect(find.text('تفاصيل الأداء'), findsOneWidget);
      expect(find.text('أحمد محمد'), findsOneWidget);
      expect(find.text('سارة خالد'), findsOneWidget);
    });
  });
}
