import 'dart:async';

import 'package:flutter/services.dart';

/// Semantic haptic intensities routed by [AppHaptics].
enum AppHapticsType { selectionTap, actionSuccess, milestoneSuccess }

/// Centralized haptic feedback for key confirmation moments.
///
/// MASTER.md rule: avoid haptic overuse — only wire these into the three
/// verified confirmations (add-to-cart, successful checkout, coupon applied).
///
/// Mirrors the alert-service pattern (`unawaited(...catchError((_) {}))`
/// inside try/catch) so calls are safe on web/desktop and in unit tests
/// where the platform channel is unavailable (MissingPluginException or a
/// synchronous "binding not initialized" error are both swallowed).
class AppHaptics {
  AppHaptics._();

  /// Test hook: when non-null every call routes through it instead of the
  /// platform channel. Tests stub this to observe/record calls; reset to
  /// null in teardown.
  static Future<void> Function(AppHapticsType type)? override;

  /// Light tick for small confirmations (item added to cart).
  static void selectionTap() => _fire(AppHapticsType.selectionTap);

  /// Medium impact for meaningful success (coupon applied).
  static void actionSuccess() => _fire(AppHapticsType.actionSuccess);

  /// Heavy impact for milestone success (order placed / checkout done).
  static void milestoneSuccess() => _fire(AppHapticsType.milestoneSuccess);

  static void _fire(AppHapticsType type) {
    final hook = override;
    if (hook != null) {
      unawaited(hook(type).catchError((_) {}));
      return;
    }
    try {
      unawaited(_platformCall(type).catchError((_) {}));
    } catch (_) {
      // Haptics unsupported on web/desktop – ignore.
    }
  }

  static Future<void> _platformCall(AppHapticsType type) {
    switch (type) {
      case AppHapticsType.selectionTap:
        return HapticFeedback.selectionClick();
      case AppHapticsType.actionSuccess:
        return HapticFeedback.mediumImpact();
      case AppHapticsType.milestoneSuccess:
        return HapticFeedback.heavyImpact();
    }
  }
}
