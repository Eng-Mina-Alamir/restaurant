import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';

/// Recorded user behavior or system analytics event.
class AnalyticsEvent {
  const AnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
  });

  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
}

/// Recorded error or crash report for diagnostics.
class AnalyticsErrorRecord {
  const AnalyticsErrorRecord({
    required this.exception,
    this.stackTrace,
    this.reason,
    required this.timestamp,
  });

  final Object exception;
  final StackTrace? stackTrace;
  final String? reason;
  final DateTime timestamp;
}

/// Enterprise analytics and telemetry service.
class AnalyticsService {
  AnalyticsService();

  final List<AnalyticsEvent> _events = [];
  final List<AnalyticsErrorRecord> _errors = [];
  final Map<String, String> _userProperties = {};

  List<AnalyticsEvent> get loggedEvents => List.unmodifiable(_events);
  List<AnalyticsErrorRecord> get recordedErrors => List.unmodifiable(_errors);
  Map<String, String> get userProperties => Map.unmodifiable(_userProperties);

  /// Logs a custom event with arbitrary parameters.
  void logEvent(String name, [Map<String, dynamic> parameters = const {}]) {
    final event = AnalyticsEvent(
      name: name,
      parameters: parameters,
      timestamp: DateTime.now(),
    );
    _events.add(event);
    AppLogger.info('Analytics Event: $name | $parameters');
  }

  /// Tracks screen view transitions.
  void logScreenView(String screenName, [String? screenClass]) {
    logEvent('screen_view', {
      'screen_name': screenName,
      'screen_class': ?screenClass,
    });
  }

  /// Tracks item added to cart.
  void logAddToCart({
    required String itemId,
    required String itemName,
    required double price,
    int quantity = 1,
  }) {
    logEvent('add_to_cart', {
      'item_id': itemId,
      'item_name': itemName,
      'price': price,
      'quantity': quantity,
      'total': price * quantity,
    });
  }

  /// Tracks successful order placement.
  void logOrderPlaced({
    required String orderId,
    required double totalAmount,
    required String orderType,
    required int itemCount,
  }) {
    logEvent('order_placed', {
      'order_id': orderId,
      'value': totalAmount,
      'currency': 'EGP',
      'order_type': orderType,
      'item_count': itemCount,
    });
  }

  /// Tracks completed payment transaction.
  void logPaymentCompleted({
    required String orderId,
    required double amount,
    required String method,
  }) {
    logEvent('payment_completed', {
      'order_id': orderId,
      'amount': amount,
      'method': method,
      'currency': 'EGP',
    });
  }

  /// Records an uncaught exception or handled error with stack trace.
  void recordError(Object exception, {StackTrace? stackTrace, String? reason}) {
    final record = AnalyticsErrorRecord(
      exception: exception,
      stackTrace: stackTrace,
      reason: reason,
      timestamp: DateTime.now(),
    );
    _errors.add(record);
    AppLogger.error(
      'Crash/Error recorded: $exception ${reason != null ? "($reason)" : ""}',
      error: exception,
      stackTrace: stackTrace,
    );
  }

  /// Sets a user property (e.g. role, storeId, loyaltyTier).
  void setUserProperty(String name, String value) {
    _userProperties[name] = value;
    AppLogger.info('Set user property $name = $value');
  }

  /// Clears in-memory audit trail.
  void clear() {
    _events.clear();
    _errors.clear();
    _userProperties.clear();
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
