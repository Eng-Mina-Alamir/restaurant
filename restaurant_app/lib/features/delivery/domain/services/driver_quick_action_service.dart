import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/logger.dart';

class ChangeCalculationResult {
  const ChangeCalculationResult({
    required this.orderTotal,
    required this.cashReceived,
    required this.changeDue,
    required this.isExact,
    required this.isInsufficient,
    required this.shortfall,
  });

  final double orderTotal;
  final double cashReceived;
  final double changeDue;
  final bool isExact;
  final bool isInsufficient;
  final double shortfall;
}

/// Service providing 1-Tap actions for drivers: WhatsApp, Phone Calls, Maps, OTP, and Change calculations.
class DriverQuickActionService {
  const DriverQuickActionService._();

  /// Legacy deterministic 4-digit PIN derived from the order id.
  ///
  /// Kept ONLY as an offline fallback when the per-order random verification
  /// code (see `DeliveryPinService` / `delivery_verification_codes` table)
  /// cannot be fetched. New orders must use a random code instead — this
  /// fallback is predictable and must never be the primary mechanism.
  @Deprecated('Use DeliveryPinRepository.ensurePin instead (random per order)')
  static String getOrderDeliveryPin(String orderId) {
    final numeric = orderId.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeric.length >= 4) {
      return numeric.substring(numeric.length - 4);
    }
    final code = (orderId.hashCode.abs() % 9000) + 1000;
    return code.toString();
  }

  static const List<String> defaultWhatsAppTemplates = [
    'أنا كابتن التوصيل ومعايا أوردر حضرتك وفي الطريق إليك 🛵',
    'أنا وصلت تحت العمارة حالياً، برجاء الاستلام 📍',
    'برجاء توضيح رقم الدور / الشقة أو إرسال اللوكيشن الدقيق 🏢',
  ];

  /// Formats international Egyptian/Gulf phone number for WhatsApp
  static String formatPhoneForWhatsApp(String rawPhone) {
    var cleaned = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('01')) {
      cleaned = '2$cleaned'; // Egyptian prefix: 201xxxxxxxxx
    } else if (cleaned.startsWith('05')) {
      cleaned = '966${cleaned.substring(1)}'; // Saudi prefix
    }
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  /// Generates a valid WhatsApp URL string
  static String getWhatsAppUriString({
    required String phone,
    required String message,
  }) {
    final formattedPhone = formatPhoneForWhatsApp(phone);
    final encodedMessage = Uri.encodeComponent(message);
    return 'https://wa.me/$formattedPhone?text=$encodedMessage';
  }

  /// Generates a phone call URI string
  static String getTelUriString(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return 'tel:$cleaned';
  }

  /// Parses [getTelUriString] into a launchable [Uri].
  static Uri toTelUri(String phone) => Uri.parse(getTelUriString(phone));

  /// Parses [getWhatsAppUriString] into a launchable [Uri].
  static Uri toWhatsAppUri({required String phone, required String message}) =>
      Uri.parse(getWhatsAppUriString(phone: phone, message: message));

  /// Parses [getGoogleMapsDirectionsUrl] into a launchable [Uri].
  static Uri toMapsUri({
    required double latitude,
    required double longitude,
    String? label,
  }) => Uri.parse(
    getGoogleMapsDirectionsUrl(
      latitude: latitude,
      longitude: longitude,
      label: label,
    ),
  );

  /// Best-effort launcher for driver 1-tap actions.
  ///
  /// Tries [launchUrl] with [LaunchMode.externalApplication] first so the
  /// native dialer / Google Maps / WhatsApp actually opens. Returns true on
  /// success, false when nothing could handle the URI (caller should then
  /// fall back to copying the raw string + snackbar).
  static Future<bool> launchExternal(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      AppLogger.warning('DriverQuickActionService.launchExternal failed: $e');
      return false;
    }
  }

  /// Generates external Google Maps directions URL
  static String getGoogleMapsDirectionsUrl({
    required double latitude,
    required double longitude,
    String? label,
  }) {
    if (latitude != 0 && longitude != 0) {
      return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    }
    final encodedQuery = Uri.encodeComponent(label ?? 'الموقع');
    return 'https://www.google.com/maps/search/?api=1&query=$encodedQuery';
  }

  /// Calculates change due when customer pays cash
  static ChangeCalculationResult calculateChange({
    required double orderTotal,
    required double cashReceived,
  }) {
    if (cashReceived < orderTotal) {
      return ChangeCalculationResult(
        orderTotal: orderTotal,
        cashReceived: cashReceived,
        changeDue: 0.0,
        isExact: false,
        isInsufficient: true,
        shortfall: orderTotal - cashReceived,
      );
    }

    final diff = cashReceived - orderTotal;
    return ChangeCalculationResult(
      orderTotal: orderTotal,
      cashReceived: cashReceived,
      changeDue: diff,
      isExact: diff == 0.0,
      isInsufficient: false,
      shortfall: 0.0,
    );
  }

  /// Helper to copy text to clipboard with fallback
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
