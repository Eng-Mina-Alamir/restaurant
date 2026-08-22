import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handles audio and haptic alerts for the delivery driver app.
///
/// Plays a chime and fires a heavy haptic pulse when a new delivery
/// assignment is dispatched, mirroring [WaiterAlertService] behaviour.
class DriverAlertService {
  DriverAlertService() {
    _player = AudioPlayer();
  }

  late final AudioPlayer _player;
  bool _disposed = false;

  /// Plays a notification sound and triggers heavy haptic feedback to alert
  /// the driver that a new assignment was just dispatched to them.
  Future<void> notifyNewAssignment() async {
    if (_disposed) return;
    try {
      // Use a short, system-level notification sound.
      await _player.play(AssetSource('sounds/order_alert.mp3'));
    } catch (_) {
      // Sound file may not exist in dev; fall through to haptic only.
    }
    try {
      unawaited(HapticFeedback.heavyImpact().catchError((_) {}));
    } catch (_) {
      // Haptics unsupported on web/desktop – ignore.
    }
  }

  void dispose() {
    _disposed = true;
    _player.dispose();
  }
}

/// Single shared driver alert service so driver pages (and tests) can observe
/// assignment notifications without touching platform channels directly.
final driverAlertServiceProvider = Provider<DriverAlertService>((ref) {
  final service = DriverAlertService();
  ref.onDispose(service.dispose);
  return service;
});
