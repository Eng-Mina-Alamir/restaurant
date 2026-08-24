import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/notifications/push_notification_service.dart';

void main() {
  group('PushNotificationService', () {
    test('showNotification adds to history and emits stream event', () async {
      final service = PushNotificationService();
      addTearDown(service.dispose);

      AppNotification? emitted;
      final sub = service.onNotification.listen((n) => emitted = n);
      addTearDown(sub.cancel);

      service.showNotification(
        title: 'تنبيه جديد',
        body: 'تم استلام طلبك بنجاح',
        category: NotificationCategory.orderStatus,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted, isNotNull);
      expect(emitted?.title, 'تنبيه جديد');
      expect(service.history.length, 1);
      expect(service.history.first.title, 'تنبيه جديد');
      expect(service.history.first.isRead, isFalse);
    });

    test('notifyOrderStatus creates formatted order notification', () async {
      final service = PushNotificationService();
      addTearDown(service.dispose);

      service.notifyOrderStatus(orderId: 'ORD-1234', statusAr: 'جاهز للتسليم');

      expect(service.history.length, 1);
      expect(service.history.first.title, contains('ORD-1234'));
      expect(service.history.first.body, contains('جاهز للتسليم'));
      expect(service.history.first.category, NotificationCategory.orderStatus);
    });

    test('notifyDeliveryJob creates delivery notification', () async {
      final service = PushNotificationService();
      addTearDown(service.dispose);

      service.notifyDeliveryJob(
        deliveryId: 'DEL-55',
        destination: 'حي العليا - الرياض',
      );

      expect(service.history.length, 1);
      expect(service.history.first.title, contains('طلب توصيل جديد'));
      expect(service.history.first.body, contains('حي العليا - الرياض'));
    });

    test('markAsRead and clearAll work correctly', () async {
      final service = PushNotificationService();
      addTearDown(service.dispose);

      service.showNotification(title: 'T1', body: 'B1');
      service.showNotification(title: 'T2', body: 'B2');
      expect(service.history.length, 2);

      final id = service.history.first.id;
      service.markAsRead(id);
      expect(service.history.first.isRead, isTrue);
      expect(service.history.last.isRead, isFalse);

      service.clearAll();
      expect(service.history.isEmpty, isTrue);
    });
  });
}
