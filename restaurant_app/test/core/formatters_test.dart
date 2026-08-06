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
}
