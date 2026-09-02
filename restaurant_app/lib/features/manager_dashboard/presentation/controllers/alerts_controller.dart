import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../data/repositories/supabase_manager_operations_repository.dart';
import '../../domain/entities/alert_entity.dart';

/// Controller managing operational alerts for the manager.
class AlertsController extends StateNotifier<List<AlertEntity>> {
  AlertsController([this._repository]) : super(const []) {
    loadAlerts();
  }

  final SupabaseManagerOperationsRepository? _repository;

  Future<void> loadAlerts() async {
    if (_repository == null) return;
    final result = await _repository.getAlerts();
    result.when(
      onLeft: (_) {},
      onRight: (alerts) {
        if (mounted) state = alerts;
      },
    );
  }

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
    _repository?.addAlert(alert);
  }

  /// Marks an alert as read.
  void markAsRead(String id) {
    state = state
        .map((a) => a.id == id ? a.copyWith(isRead: true) : a)
        .toList();
    _repository?.markAlertAsRead(id);
  }

  /// Marks all alerts as read.
  void markAllAsRead() {
    state = state.map((a) => a.copyWith(isRead: true)).toList();
    for (final a in state) {
      _repository?.markAlertAsRead(a.id);
    }
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
      final repo = ref.watch(supabaseManagerOperationsRepositoryProvider);
      return AlertsController(repo);
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
