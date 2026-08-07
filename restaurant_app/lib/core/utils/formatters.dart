import 'package:intl/intl.dart';

import '../../config/app_config.dart';

/// Formatting helpers for currency, dates and order numbers.
///
/// Pure Dart + `intl` only, so every function is unit-testable without the
/// Flutter framework. Note: formatting dates with the `ar` locale requires
/// `initializeDateFormatting('ar')` in pure Dart tests (Flutter initializes
/// locale data automatically).
abstract final class Formatters {
  Formatters._();

  static final NumberFormat _currencyNumber = NumberFormat('#,##0.00', 'en_US');

  static const String _datePattern = 'd MMM yyyy';
  static const String _timePattern = 'HH:mm';
  static const String _dateTimePattern = 'd MMM yyyy، HH:mm';

  /// Formats [amount] as Western digits followed by the Arabic currency symbol.
  ///
  /// Example: `50.00 ر.س`
  static String formatCurrency(double amount) {
    return '${_currencyNumber.format(amount)} ${AppConfig.defaultCurrency}';
  }

  /// Formats [date] with an Arabic locale (e.g. `6 أغسطس 2026`).
  static String formatDate(DateTime date) {
    return DateFormat(_datePattern, AppConfig.locale).format(date);
  }

  /// Formats [time] in 24-hour form (e.g. `19:30`).
  static String formatTime(DateTime time) {
    return DateFormat(_timePattern, AppConfig.locale).format(time);
  }

  /// Formats [dateTime] combining date and time (e.g. `6 أغسطس 2026، 19:30`).
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(_dateTimePattern, AppConfig.locale).format(dateTime);
  }

  /// Formats an order id as a human-friendly order number (e.g. `#1024`).
  static String formatOrderNumber(int orderNumber) => '#$orderNumber';

  /// Extracts the numeric part of an order id and formats it as a friendly
  /// order number (e.g. `ORD-1024-A` → `#1024`). Falls back to the raw id
  /// when it contains no digits.
  static String formatOrderId(String orderId) {
    final digits = orderId.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? orderId : formatOrderNumber(int.parse(digits));
  }

  /// Whole minutes elapsed since [createdAt], clamped at zero when [createdAt]
  /// is in the future. Pure and injectable so it is unit-testable.
  static int elapsedMinutes(DateTime createdAt, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(createdAt);
    final minutes = diff.inMinutes;
    return minutes < 0 ? 0 : minutes;
  }

  /// Estimates delivery time (minutes) from a route distance, assuming a
  /// typical urban delivery speed of 30 km/h (~8.33 m/s), with a 10 minute
  /// pickup/prep offset. Pure function so it is unit-testable.
  static int estimateDeliveryMinutes(double distanceMeters) {
    const averageSpeedMps = 8.33; // ~30 km/h
    const prepOffsetMinutes = 10;
    final travelMinutes = (distanceMeters / averageSpeedMps / 60).ceil();
    return prepOffsetMinutes + travelMinutes;
  }
}
