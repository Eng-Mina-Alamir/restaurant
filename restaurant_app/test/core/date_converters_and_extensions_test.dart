import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/date_converters.dart';
import 'package:restaurant_app/core/utils/extensions.dart';

void main() {
  group('Date Converters & Extensions Unit Tests', () {
    test('dateTimeFromJson parses ISO-8601 string correctly', () {
      const isoString = '2026-08-19T14:30:00.000Z';
      final dt = dateTimeFromJson(isoString);
      expect(dt.year, 2026);
      expect(dt.month, 8);
      expect(dt.day, 19);
    });

    test('dateTimeFromJson converts epoch millis properly', () {
      final now = DateTime.now();
      final dt = dateTimeFromJson(now.millisecondsSinceEpoch);
      expect(dt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('dateTimeFromJson falls back safely for invalid input', () {
      final dt = dateTimeFromJson('invalid-date-format');
      expect(dt, isNotNull);
    });

    test('nullableDateTimeFromJson handles null', () {
      expect(nullableDateTimeFromJson(null), isNull);
      expect(nullableDateTimeFromJson('2026-08-19T12:00:00Z'), isNotNull);
    });

    test('dateTimeToJson and nullableDateTimeToJson produce ISO-8601 strings', () {
      final now = DateTime.utc(2026, 8, 19, 12, 0, 0);
      expect(dateTimeToJson(now), '2026-08-19T12:00:00.000Z');
      expect(nullableDateTimeToJson(null), isNull);
    });

    test('StringNullableExtensions orEmpty works properly', () {
      const String? nullString = null;
      String? nullableString = 'hello';
      expect(nullString.orEmpty(), '');
      expect(nullableString.orEmpty(), 'hello');
    });

    test('SeparatedListExtension inserts separator between elements', () {
      final list = [1, 2, 3];
      final separated = list.separatedBy(0);
      expect(separated, [1, 0, 2, 0, 3]);

      final singleList = [1];
      expect(singleList.separatedBy(0), [1]);

      final emptyList = <int>[];
      expect(emptyList.separatedBy(0), <int>[]);
    });
  });
}
