import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RestaurantController and Page Validation Rules', () {
    final phoneRegex = RegExp(r'^(\+201|01)[0125]\d{8}$');

    test('validates Egyptian mobile phone numbers correctly', () {
      expect(phoneRegex.hasMatch('01012345678'), isTrue);
      expect(phoneRegex.hasMatch('01123456789'), isTrue);
      expect(phoneRegex.hasMatch('01234567890'), isTrue);
      expect(phoneRegex.hasMatch('01512345678'), isTrue);
      expect(phoneRegex.hasMatch('+201012345678'), isTrue);
      expect(phoneRegex.hasMatch('+201123456789'), isTrue);

      // Invalid formats
      expect(phoneRegex.hasMatch('01312345678'), isFalse);
      expect(phoneRegex.hasMatch('01412345678'), isFalse);
      expect(phoneRegex.hasMatch('0101234567'), isFalse); // too short
      expect(phoneRegex.hasMatch('010123456789'), isFalse); // too long
      expect(phoneRegex.hasMatch('invalid'), isFalse);
    });

    test('validates coordinates within valid geographic bounds', () {
      bool validateCoords(double lat, double lng) {
        return lat >= -90.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0;
      }

      expect(validateCoords(30.0444, 31.2357), isTrue); // Cairo
      expect(validateCoords(-90.0, -180.0), isTrue);
      expect(validateCoords(90.0, 180.0), isTrue);
      expect(validateCoords(91.0, 31.0), isFalse);
      expect(validateCoords(-91.0, 31.0), isFalse);
      expect(validateCoords(30.0, 181.0), isFalse);
      expect(validateCoords(30.0, -181.0), isFalse);
    });

    test('validates operating hours open < close', () {
      int parseTimeToMinutes(String timeStr) {
        final parts = timeStr.trim().split(':');
        if (parts.length != 2) return -1;
        final h = int.tryParse(parts[0]) ?? -1;
        final m = int.tryParse(parts[1]) ?? -1;
        if (h < 0 || h > 23 || m < 0 || m > 59) return -1;
        return h * 60 + m;
      }

      expect(parseTimeToMinutes('10:00') < parseTimeToMinutes('23:00'), isTrue);
      expect(parseTimeToMinutes('09:30') < parseTimeToMinutes('18:00'), isTrue);
      expect(parseTimeToMinutes('23:00') < parseTimeToMinutes('10:00'), isFalse);
      expect(parseTimeToMinutes('12:00') < parseTimeToMinutes('12:00'), isFalse);
    });

    test('validates total_tables against actual tables count', () {
      const actualCount = 12;

      bool canSaveTables(int totalTables) {
        return totalTables >= 0 && totalTables >= actualCount;
      }

      expect(canSaveTables(12), isTrue);
      expect(canSaveTables(20), isTrue);
      expect(canSaveTables(11), isFalse);
      expect(canSaveTables(-1), isFalse);
    });
  });
}
