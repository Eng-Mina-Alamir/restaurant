import 'package:restaurant_app/core/notifications/kds_alert_service.dart';

/// Records KDS notifications without touching platform channels
/// (mirrors SpyWaiterAlertService in test/features/staff).
class SpyKdsAlertService implements KdsAlertService {
  int newOrderAlerts = 0;
  int orderReadyAlerts = 0;
  bool disposed = false;

  @override
  Future<void> alertNewOrder() async => newOrderAlerts++;

  @override
  void alertOrderReady() => orderReadyAlerts++;

  @override
  void dispose() => disposed = true;
}
