import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handles audio and haptic alerts for the Kitchen Display System.
///
/// Plays a chime sound when new orders arrive and provides colour-coded
/// urgency levels based on how long an order has been waiting.
class KdsAlertService {
  KdsAlertService() {
    _player = AudioPlayer();
  }

  late final AudioPlayer _player;
  bool _disposed = false;

  /// Plays a notification sound and triggers heavy haptic feedback to alert
  /// kitchen staff of a new incoming order.
  Future<void> alertNewOrder() async {
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

  /// Provides a light haptic tap when a kitchen user marks an order ready.
  void alertOrderReady() {
    if (_disposed) return;
    try {
      unawaited(HapticFeedback.mediumImpact().catchError((_) {}));
    } catch (_) {}
  }

  /// Returns the urgency level for a [waitingMinutes] duration:
  /// - `green` → 0–5 min
  /// - `amber` → 5–10 min
  /// - `red`   → > 10 min
  static KdsUrgency urgencyFor(int waitingMinutes) {
    if (waitingMinutes <= 5) return KdsUrgency.green;
    if (waitingMinutes <= 10) return KdsUrgency.amber;
    return KdsUrgency.red;
  }

  void dispose() {
    _disposed = true;
    _player.dispose();
  }
}

/// Urgency level used by the KDS to colour-code order cards.
enum KdsUrgency {
  green,
  amber,
  red;

  /// ARGB colour values for each urgency level.
  int get colorValue {
    switch (this) {
      case KdsUrgency.green:
        return 0xFF4CAF50;
      case KdsUrgency.amber:
        return 0xFFFFC107;
      case KdsUrgency.red:
        return 0xFFF44336;
    }
  }
}

/// Single shared KDS alert service so pages (and tests) can observe
/// kitchen notifications without touching platform channels directly.
final kdsAlertServiceProvider = Provider<KdsAlertService>((ref) {
  final service = KdsAlertService();
  ref.onDispose(service.dispose);
  return service;
});
