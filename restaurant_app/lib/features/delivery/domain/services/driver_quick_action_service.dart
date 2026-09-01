import 'package:flutter/services.dart';

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

/// Service providing 1-Tap actions for drivers: WhatsApp, Phone Calls, Maps, and Change calculations.
class DriverQuickActionService {
  const DriverQuickActionService._();

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
