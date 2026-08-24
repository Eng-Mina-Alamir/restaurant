import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/manager_dashboard/domain/entities/alert_entity.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/controllers/alerts_controller.dart';

void main() {
  group('AlertsController and AlertEntity State Tests', () {
    late AlertsController controller;

    setUp(() {
      controller = AlertsController();
    });

    test('initial state has seed alerts', () {
      expect(controller.state, isNotEmpty);
      expect(
        controller.state.any((a) => a.severity == AlertSeverity.critical),
        isTrue,
      );
    });

    test('addSmartAlert inserts alert at top of list', () {
      final initialCount = controller.state.length;

      controller.addSmartAlert(
        title: 'تنبيه ذكي',
        message: 'تقييم سلبي تم تسجيله',
        severity: AlertSeverity.warning,
        category: AlertCategory.system,
      );

      expect(controller.state, hasLength(initialCount + 1));
      expect(controller.state.first.title, 'تنبيه ذكي');
      expect(controller.state.first.isRead, isFalse);
    });

    test('markAsRead and markAllAsRead updates read flags', () {
      final firstId = controller.state.first.id;
      controller.markAsRead(firstId);

      expect(
        controller.state.firstWhere((a) => a.id == firstId).isRead,
        isTrue,
      );

      controller.markAllAsRead();
      expect(controller.state.every((a) => a.isRead), isTrue);
    });

    test('dismissAlert removes specified alert', () {
      final firstId = controller.state.first.id;
      controller.dismissAlert(firstId);

      expect(controller.state.any((a) => a.id == firstId), isFalse);
    });

    test('clearAll empties the alerts list', () {
      controller.clearAll();
      expect(controller.state, isEmpty);
    });
  });
}
