import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/utils/formatters.dart';

void main() {
  group('Formatters.estimateDeliveryMinutes', () {
    test('includes a fixed prep offset for zero distance', () {
      // 10 min prep offset, no travel time.
      expect(Formatters.estimateDeliveryMinutes(0), 10);
    });

    test('grows with distance using ~30 km/h speed', () {
      // 2.5 km → ~5 min travel + 10 prep = ~15 min.
      final short = Formatters.estimateDeliveryMinutes(2500);
      expect(short, inInclusiveRange(15, 18));

      final long = Formatters.estimateDeliveryMinutes(10000);
      expect(long, greaterThan(short));
    });
  });

  group('Formatters.formatCurrency', () {
    test('formats whole and decimal values', () {
      assert(Formatters.formatCurrency(0).isNotEmpty);
      expect(Formatters.formatCurrency(56.0).contains('56'), isTrue);
    });
  });

  group('Formatters.formatOrderId', () {
    test('extracts digits and prefixes with #', () {
      expect(Formatters.formatOrderId('ORD-1024-A'), '#1024');
      expect(Formatters.formatOrderId('order_7'), '#7');
      expect(Formatters.formatOrderId('1024'), '#1024');
    });

    test('falls back to raw id when no digits present', () {
      expect(Formatters.formatOrderId('ABC'), 'ABC');
    });
  });

  group('Formatters.orderNumberFromId', () {
    test('extracts the numeric part of an order id', () {
      expect(Formatters.orderNumberFromId('ORD-0101'), 101);
      expect(Formatters.orderNumberFromId('order_7'), 7);
      expect(Formatters.orderNumberFromId('1024'), 1024);
    });

    test('returns null when no digits are present', () {
      expect(Formatters.orderNumberFromId('ABC'), isNull);
    });
  });

  group('Formatters.elapsedMinutes', () {
    final now = DateTime(2026, 8, 7, 12, 0);

    test('returns whole minutes elapsed since the timestamp', () {
      expect(
        Formatters.elapsedMinutes(DateTime(2026, 8, 7, 11, 58), now: now),
        2,
      );
      expect(
        Formatters.elapsedMinutes(DateTime(2026, 8, 7, 11, 0), now: now),
        60,
      );
    });

    test('clamps to zero for future timestamps', () {
      expect(
        Formatters.elapsedMinutes(DateTime(2026, 8, 7, 12, 5), now: now),
        0,
      );
    });
  });
}
