import 'dart:math';

/// Generates and validates per-order random delivery verification codes.
///
/// Each delivery order gets its OWN random 6-digit code (stored server-side
/// in `delivery_verification_codes`), so codes differ from order to order
/// and cannot be guessed from the order id. The QR shown to the customer
/// encodes [qrPayloadFor] so the driver's scanner accepts both the raw code
/// (`123456`) and the full payload (`DELIVERY:<orderId>:<code>`).
abstract final class DeliveryPinService {
  DeliveryPinService._();

  static final RegExp _codePattern = RegExp(r'\b\d{4,8}\b');

  /// Generates a cryptographically-strong numeric code of [length] digits.
  ///
  /// Defaults to 6 digits (`100000..999999`) — no leading zeros, easy to
  /// dictate over the phone, and ~1M combinations per order.
  static String generatePin({int length = 6, Random? random}) {
    assert(length >= 4 && length <= 8, 'PIN length must be 4..8 digits');
    final rng = random ?? Random.secure();
    final min = pow(10, length - 1).toInt();
    final max = pow(10, length).toInt() - 1;
    return (min + rng.nextInt(max - min + 1)).toString();
  }

  /// QR payload shown on the customer device.
  static String qrPayloadFor({required String orderId, required String code}) =>
      'DELIVERY:$orderId:$code';

  /// Extracts the verification code from scanner input.
  ///
  /// Accepts the raw code (`482910`), the full payload
  /// (`DELIVERY:ORD-0042:482910`), or any string containing a 4-8 digit
  /// group (e.g. pasted SMS text). Returns '' when nothing looks like a code.
  static String extractCode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    // Full payload form: DELIVERY:<orderId>:<code>
    final payloadMatch = RegExp(
      r'DELIVERY:[^:]+:(\d{4,8})',
    ).firstMatch(trimmed.toUpperCase());
    // NOTE: upper-casing is safe here — we only capture the digit group.
    if (payloadMatch != null) return payloadMatch.group(1)!;
    final digitsMatch = _codePattern.firstMatch(trimmed);
    return digitsMatch?.group(0) ?? trimmed;
  }

  /// True when [code] has a plausible shape (4-8 digits).
  static bool isValidFormat(String code) =>
      RegExp(r'^\d{4,8}$').hasMatch(code.trim());
}
