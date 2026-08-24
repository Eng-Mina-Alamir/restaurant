import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/notifications/push_notification_service.dart';
import 'package:restaurant_app/features/notifications/presentation/pages/notifications_page.dart';

void main() {
  group('NotificationsPage Widget Tests', () {
    testWidgets('renders empty state when no notifications', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: NotificationsPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('مركز الإشعارات والتنبيهات'), findsOneWidget);
      expect(find.text('لا توجد إشعارات حالياً'), findsOneWidget);
    });

    testWidgets('renders notifications list when push notification arrives', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(pushNotificationServiceProvider);
      service.showNotification(
        title: 'طلب جديد',
        body: 'تم استلام طلب جديد #ORD-101',
        category: NotificationCategory.newOrder,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: NotificationsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('طلب جديد'), findsOneWidget);
      expect(find.text('تم استلام طلب جديد #ORD-101'), findsOneWidget);
    });
  });
}
