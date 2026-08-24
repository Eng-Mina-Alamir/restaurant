import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';

/// Network connectivity state.
enum ConnectivityStatus { online, offline }

/// Service managing and broadcasting the app's online/offline network connectivity.
class ConnectivityService {
  ConnectivityService([ConnectivityStatus initial = ConnectivityStatus.online])
    : _status = initial {
    AppLogger.info('ConnectivityService initialized: ${_status.name}');
  }

  ConnectivityStatus _status;
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus get currentStatus => _status;
  bool get isOnline => _status == ConnectivityStatus.online;
  bool get isOffline => _status == ConnectivityStatus.offline;

  Stream<ConnectivityStatus> get onStatusChanged => _controller.stream;

  /// Updates the current connectivity status and notifies listeners.
  void setStatus(ConnectivityStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    _controller.add(newStatus);
    AppLogger.info('Connectivity changed: ${newStatus.name}');
  }

  /// Sets status to online.
  void goOnline() => setStatus(ConnectivityStatus.online);

  /// Sets status to offline.
  void goOffline() => setStatus(ConnectivityStatus.offline);

  void dispose() {
    _controller.close();
  }
}

/// Provider for [ConnectivityService].
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

/// Convenience provider watching whether the device is currently online.
final isOnlineProvider = Provider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.isOnline;
});
