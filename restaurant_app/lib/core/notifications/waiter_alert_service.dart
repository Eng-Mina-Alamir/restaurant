import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handles audio and haptic alerts for the waiter dashboard.
///
/// Plays a chime and fires a medium haptic pulse when the kitchen marks a
/// dine-in order ready for pickup, mirroring [KdsAlertService] behaviour.
class WaiterAlertService {
  WaiterAlertService() {
    _player = AudioPlayer();
  }

  late final AudioPlayer _player;
  bool _disposed = false;

  /// Plays a notification sound and triggers medium haptic feedback to alert
  /// waiters that an order is ready for pickup.
  Future<void> notifyReadyForPickup() async {
    if (_disposed) return;
    try {
      // Use a short, system-level notification sound.
      await _player.play(AssetSource('sounds/order_alert.mp3'));
    } catch (_) {
      // Sound file may not exist in dev; fall through to haptic only.
    }
    try {
      unawaited(HapticFeedback.mediumImpact().catchError((_) {}));
    } catch (_) {
      // Haptics unsupported on web/desktop – ignore.
    }
  }

  void dispose() {
    _disposed = true;
    _player.dispose();
  }
}

/// Single shared waiter alert service so dashboards (and tests) can observe
/// pickup notifications without touching platform channels directly.
final waiterAlertServiceProvider = Provider<WaiterAlertService>((ref) {
  final service = WaiterAlertService();
  ref.onDispose(service.dispose);
  return service;
});
