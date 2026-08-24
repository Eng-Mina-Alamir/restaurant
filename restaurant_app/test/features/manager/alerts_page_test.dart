import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/controllers/alerts_controller.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/alerts_page.dart';

void main() {
  group('AlertsController and AlertsPage', () {
    test('AlertsController marks as read, dismisses, and clears alerts', () {
      final controller = AlertsController();
      expect(controller.state.isNotEmpty, isTrue);

      final initialLength = controller.state.length;
      final firstId = controller.state.first.id;

      // 1. Mark as read
      controller.markAsRead(firstId);
      expect(controller.state.first.isRead, isTrue);

      // 2. Mark all as read
      controller.markAllAsRead();
      expect(controller.state.every((a) => a.isRead), isTrue);

      // 3. Dismiss single alert
      controller.dismissAlert(firstId);
      expect(controller.state.length, initialLength - 1);
      expect(controller.state.any((a) => a.id == firstId), isFalse);

      // 4. Clear all
      controller.clearAll();
      expect(controller.state, isEmpty);
    });

    testWidgets('AlertsPage renders alerts list and filters by category', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AlertsPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('مركز التنبيهات'), findsOneWidget);
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('المخزون'), findsOneWidget);

      // Filter by inventory
      await tester.tap(find.text('المخزون'));
      await tester.pumpAndSettle();

      expect(find.textContaining('انخفاض مخزون'), findsOneWidget);
    });
  });
}
