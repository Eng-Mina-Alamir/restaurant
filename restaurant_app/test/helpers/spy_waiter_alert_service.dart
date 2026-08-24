import 'package:restaurant_app/core/notifications/waiter_alert_service.dart';

/// Records pickup notifications without touching platform channels
/// (mirrors SpyKdsAlertService in test/helpers).
class SpyWaiterAlertService implements WaiterAlertService {
  int notifyCalls = 0;
  bool disposed = false;

  @override
  Future<void> notifyReadyForPickup() async => notifyCalls++;

  @override
  void dispose() => disposed = true;
}
