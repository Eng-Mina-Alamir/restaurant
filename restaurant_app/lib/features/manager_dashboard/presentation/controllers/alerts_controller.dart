import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/alert_entity.dart';

/// Controller managing operational alerts for the manager.
class AlertsController extends StateNotifier<List<AlertEntity>> {
  AlertsController() : super(const []);

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
