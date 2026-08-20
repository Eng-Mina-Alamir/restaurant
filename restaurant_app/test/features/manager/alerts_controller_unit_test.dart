import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/entities/alert_entity.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/controllers/alerts_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('AlertsController Unit Tests', () {
    test('initializes with seed alerts and unread count', () {
      final alerts = container.read(alertsControllerProvider);
      expect(alerts.isNotEmpty, isTrue);

      final unreadCount = container.read(unreadAlertsCountProvider);
      expect(unreadCount, greaterThan(0));
    });

    test('addSmartAlert inserts new alert at top', () {
      final controller = container.read(alertsControllerProvider.notifier);
      final initialCount = container.read(alertsControllerProvider).length;

      controller.addSmartAlert(
        title: 'تنبيه جديد',
        message: 'محتوى التنبيه',
        severity: AlertSeverity.critical,
        category: AlertCategory.kitchenDelay,
      );

      final alerts = container.read(alertsControllerProvider);
      expect(alerts.length, initialCount + 1);
      expect(alerts.first.title, 'تنبيه جديد');
      expect(alerts.first.isRead, isFalse);
    });

    test('markAsRead and markAllAsRead update alert states', () {
      final controller = container.read(alertsControllerProvider.notifier);
      final first = container.read(alertsControllerProvider).firstWhere((a) => !a.isRead);

      controller.markAsRead(first.id);
      expect(container.read(alertsControllerProvider).firstWhere((a) => a.id == first.id).isRead, isTrue);

      controller.markAllAsRead();
      expect(container.read(unreadAlertsCountProvider), 0);
    });

    test('dismissAlert and clearAll remove alerts', () {
      final controller = container.read(alertsControllerProvider.notifier);
      final first = container.read(alertsControllerProvider).first;

      controller.dismissAlert(first.id);
      expect(container.read(alertsControllerProvider).any((a) => a.id == first.id), isFalse);

      controller.clearAll();
      expect(container.read(alertsControllerProvider), isEmpty);
      expect(container.read(unreadAlertsCountProvider), 0);
    });
  });
}
