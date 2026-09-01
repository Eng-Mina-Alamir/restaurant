import 'package:intl/intl.dart';

import '../../config/app_config.dart';

/// Formatting helpers for currency, dates and order numbers.
///
/// Pure Dart + `intl` only, so every function is unit-testable without the
/// Flutter framework.
abstract final class Formatters {
  Formatters._();

  static final NumberFormat _currencyNumber = NumberFormat('#,##0.00', 'en_US');

  static const String _datePattern = 'd MMM yyyy';
  static const String _timePattern = 'HH:mm';
  static const String _dateTimePatternAr = 'd MMM yyyy، HH:mm';
  static const String _dateTimePatternEn = 'd MMM yyyy, HH:mm';

  /// Active currency symbol ('ج.م' for Arabic, 'EGP' for English).
  static String activeCurrencySymbol = AppConfig.defaultCurrency;
  static String activeLocale = AppConfig.locale;

  /// Sets the active locale & currency symbol dynamically across the whole app.
  static void setLocale(String localeCode) {
    activeLocale = localeCode;
    activeCurrencySymbol = localeCode == 'ar' ? 'ج.م' : 'EGP';
  }

  /// Formats [amount] as Western digits followed by the active currency symbol.
  ///
  /// Examples: `50.00 ج.م` (Arabic), `50.00 EGP` (English).
  static String formatCurrency(double amount, [String? currency]) {
    return '${_currencyNumber.format(amount)} ${currency ?? activeCurrencySymbol}';
  }

  /// Formats [date] with the active locale (e.g. `6 أغسطس 2026` or `6 Aug 2026`).
  static String formatDate(DateTime date, [String? locale]) {
    try {
      return DateFormat(_datePattern, locale ?? activeLocale).format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Formats [time] in 24-hour form (e.g. `19:30`).
  static String formatTime(DateTime time, [String? locale]) {
    try {
      return DateFormat(_timePattern, locale ?? activeLocale).format(time);
    } catch (_) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Formats [dateTime] combining date and time (e.g. `6 أغسطس 2026، 19:30` or `6 Aug 2026, 19:30`).
  static String formatDateTime(DateTime dateTime, [String? locale]) {
    try {
      final loc = locale ?? activeLocale;
      final pattern = loc == 'ar' ? _dateTimePatternAr : _dateTimePatternEn;
      return DateFormat(pattern, loc).format(dateTime);
    } catch (_) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Formats an order id as a human-friendly order number (e.g. `#1024`).
  static String formatOrderNumber(int orderNumber) => '#$orderNumber';

  /// Extracts the numeric part of an order id (e.g. `ORD-1024-A` → `1024`),
  /// or `null` when the id contains no digits.
  static int? orderNumberFromId(String orderId) {
    final digits = orderId.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  /// Extracts the numeric part of an order id and formats it as a friendly
  /// order number (e.g. `ORD-1024-A` → `#1024`). Falls back to the raw id
  /// when it contains no digits.
  static String formatOrderId(String orderId) {
    final number = orderNumberFromId(orderId);
    return number == null ? orderId : formatOrderNumber(number);
  }

  /// Whole minutes elapsed since [createdAt], clamped at zero when [createdAt]
  /// is in the future. Pure and injectable so it is unit-testable.
  static int elapsedMinutes(DateTime createdAt, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(createdAt);
    final minutes = diff.inMinutes;
    return minutes < 0 ? 0 : minutes;
  }

  /// Estimates delivery time (minutes) from a route distance.
  static int estimateDeliveryMinutes(double distanceMeters) {
    const averageSpeedMps = 8.33; // ~30 km/h
    const prepOffsetMinutes = 10;
    final travelMinutes = (distanceMeters / averageSpeedMps / 60).ceil();
    return prepOffsetMinutes + travelMinutes;
  }
}
