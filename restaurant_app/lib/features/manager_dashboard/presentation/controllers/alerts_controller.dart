import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/alert_entity.dart';

/// Controller managing operational alerts for the manager.
class AlertsController extends StateNotifier<List<AlertEntity>> {
  AlertsController() : super(_initialSeedAlerts);

  static final List<AlertEntity> _initialSeedAlerts = [
    AlertEntity(
      id: 'ALT-1',
      title: 'انخفاض مخزون اللحم البقري',
      message: 'المخزون المتبقي أقل من 5 كجم. يرجى طلب شحنة جديدة فوراً.',
      severity: AlertSeverity.critical,
      category: AlertCategory.inventory,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    AlertEntity(
      id: 'ALT-2',
      title: 'تأخر في تحضير الطلب #ORD-104',
      message: 'تجاوز الطلب 25 دقيقة في المطبخ دون اكتمال.',
      severity: AlertSeverity.warning,
      category: AlertCategory.kitchenDelay,
      createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
    ),
    AlertEntity(
      id: 'ALT-3',
      title: 'تأخر سائق التوصيل',
      message: 'السائق أحمد تأخر 10 دقائق عن الموعد المتوقع للتوصيل.',
      severity: AlertSeverity.warning,
      category: AlertCategory.delivery,
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
    ),
    AlertEntity(
      id: 'ALT-4',
      title: 'نسخ احتياطي مكتمل',
      message: 'تم إتمام المزامنة السحابية الدورية بنجاح 100%.',
      severity: AlertSeverity.info,
      category: AlertCategory.system,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
    ),
  ];

  /// Emits a dynamic smart alert (e.g. from low stock, delayed order, or negative review).
  void addSmartAlert({
    required String title,
    required String message,
    required AlertSeverity severity,
    required AlertCategory category,
  }) {
    final alert = AlertEntity(
      id: 'ALT-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      severity: severity,
      category: category,
      createdAt: DateTime.now(),
    );
    state = [alert, ...state];
  }

  /// Marks an alert as read.
  void markAsRead(String id) {
    state = state
        .map((a) => a.id == id ? a.copyWith(isRead: true) : a)
        .toList();
  }

  /// Marks all alerts as read.
  void markAllAsRead() {
    state = state.map((a) => a.copyWith(isRead: true)).toList();
  }

  /// Removes an alert from the active list.
  void dismissAlert(String id) {
    state = state.where((a) => a.id != id).toList();
  }

  /// Clears all alerts.
  void clearAll() {
    state = const [];
  }
}

final alertsControllerProvider =
    StateNotifierProvider<AlertsController, List<AlertEntity>>((ref) {
      return AlertsController();
    });

/// Currently selected alert filter category.
final selectedAlertCategoryProvider = StateProvider<AlertCategory>(
  (ref) => AlertCategory.all,
);

/// Count of unread critical/warning alerts.
final unreadAlertsCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertsControllerProvider);
  return alerts.where((a) => !a.isRead).length;
});
