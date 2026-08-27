import 'dart:convert';
import 'dart:typed_data';

/// Encodes tax invoice data into compliant ZATCA (الهيئة العامة للزكاة والضريبة والجمارك)
/// TLV (Tag-Length-Value) Base64 QR code format according to Saudi e-invoicing standards (Fatoorah Phase 1 & 2).
class ZatcaQrCodec {
  const ZatcaQrCodec._();

  /// Encodes individual TLV tag:
  /// - Tag number (1 byte)
  /// - Length of value (1 byte)
  /// - Value (N UTF-8 bytes)
  static Uint8List _encodeTag(int tagNumber, String value) {
    final valueBytes = utf8.encode(value);
    final length = valueBytes.length;

    final bytes = BytesBuilder(copy: false)
      ..addByte(tagNumber)
      ..addByte(length)
      ..add(valueBytes);

    return bytes.toBytes();
  }

  /// Generates the standard Base64-encoded ZATCA TLV string from invoice fields.
  ///
  /// [sellerName]: Registered merchant/restaurant name (Tag 1)
  /// [vatNumber]: 15-digit VAT registration number (Tag 2)
  /// [invoiceTimestamp]: Timestamp formatted in ISO 8601 (Tag 3)
  /// [totalWithVat]: Total invoice amount including VAT (Tag 4)
  /// [vatAmount]: Total VAT amount (Tag 5)
  static String generateBase64Qr({
    required String sellerName,
    required String vatNumber,
    required DateTime invoiceTimestamp,
    required double totalWithVat,
    required double vatAmount,
  }) {
    final builder = BytesBuilder(copy: false);

    // Tag 1: Seller's name
    builder.add(_encodeTag(1, sellerName.trim()));

    // Tag 2: VAT registration number
    builder.add(_encodeTag(2, vatNumber.trim()));

    // Tag 3: Timestamp (ISO 8601 string)
    builder.add(_encodeTag(3, invoiceTimestamp.toUtc().toIso8601String()));

    // Tag 4: Invoice total with VAT formatted with 2 decimals
    builder.add(_encodeTag(4, totalWithVat.toStringAsFixed(2)));

    // Tag 5: VAT total amount formatted with 2 decimals
    builder.add(_encodeTag(5, vatAmount.toStringAsFixed(2)));

    return base64Encode(builder.toBytes());
  }

  /// Decodes a ZATCA TLV Base64 string back to its structured Tag Map.
  ///
  /// Returns a map where keys are tag numbers (1..5) and values are the decoded UTF-8 strings.
  static Map<int, String> decodeBase64Qr(String base64String) {
    final result = <int, String>{};
    try {
      final bytes = base64Decode(base64String);
      var offset = 0;

      while (offset < bytes.length) {
        if (offset + 2 > bytes.length) break;
        final tag = bytes[offset];
        final length = bytes[offset + 1];
        offset += 2;

        if (offset + length > bytes.length) break;
        final valueBytes = bytes.sublist(offset, offset + length);
        result[tag] = utf8.decode(valueBytes);
        offset += length;
      }
    } catch (_) {}
    return result;
  }
}
