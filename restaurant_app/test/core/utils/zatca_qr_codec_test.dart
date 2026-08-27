import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/utils/zatca_qr_codec.dart';

void main() {
  group('ZatcaQrCodec', () {
    test('encodes and decodes ZATCA TLV Base64 QR code correctly', () {
      final timestamp = DateTime.utc(2026, 8, 27, 23, 0, 0);
      const sellerName = 'مطعم الأصالة والنكهة';
      const vatNumber = '300123456700003';
      const total = 115.00;
      const vat = 15.00;

      final base64Qr = ZatcaQrCodec.generateBase64Qr(
        sellerName: sellerName,
        vatNumber: vatNumber,
        invoiceTimestamp: timestamp,
        totalWithVat: total,
        vatAmount: vat,
      );

      expect(base64Qr.isNotEmpty, isTrue);

      final decodedTags = ZatcaQrCodec.decodeBase64Qr(base64Qr);

      expect(decodedTags[1], equals(sellerName));
      expect(decodedTags[2], equals(vatNumber));
      expect(decodedTags[3], equals(timestamp.toIso8601String()));
      expect(decodedTags[4], equals('115.00'));
      expect(decodedTags[5], equals('15.00'));
    });

    test('handles malformed base64 safely without throwing', () {
      final tags = ZatcaQrCodec.decodeBase64Qr('invalid-base-64!!!');
      expect(tags, isEmpty);
    });
  });
}
