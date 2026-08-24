import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/delivery/domain/services/delivery_fee_calculator.dart';

void main() {
  group('Delivery Fee Calculator Tests', () {
    late DeliveryFeeCalculator calculator;

    setUp(() {
      calculator = DeliveryFeeCalculator();
    });

    test('calculates base fee within base distance', () {
      final breakdown = calculator.calculate(
        distanceKm: 2.5,
        orderSubtotal: 50.0,
        timestamp: DateTime(2026, 8, 19, 10, 0), // Off-peak
      );

      expect(breakdown.baseFee, 10.0);
      expect(breakdown.distanceFee, 0.0);
      expect(breakdown.finalFee, 10.0);
      expect(breakdown.isFreeDelivery, isFalse);
    });

    test('adds extra per-km rate above 3km base distance', () {
      // 5 km: base 3 km (10.0) + extra 2 km * 2.0 = 14.0 SAR
      final breakdown = calculator.calculate(
        distanceKm: 5.0,
        orderSubtotal: 60.0,
        timestamp: DateTime(2026, 8, 19, 11, 0), // Off-peak
      );

      expect(breakdown.distanceFee, 4.0);
      expect(breakdown.finalFee, 14.0);
    });

    test('applies peak hour surge multiplier during dinner rush', () {
      // 5 km at 20:00 (dinner rush 1.25x): 14.0 * 1.25 = 17.5 SAR
      final breakdown = calculator.calculate(
        distanceKm: 5.0,
        orderSubtotal: 80.0,
        timestamp: DateTime(2026, 8, 19, 20, 0), // Dinner peak
      );

      expect(breakdown.peakMultiplier, 1.25);
      expect(breakdown.finalFee, 17.5);
    });

    test(
      'qualifies for free delivery when order exceeds 150 SAR threshold',
      () {
        final breakdown = calculator.calculate(
          distanceKm: 8.0,
          orderSubtotal: 180.0,
          timestamp: DateTime(2026, 8, 19, 20, 0),
        );

        expect(breakdown.isFreeDelivery, isTrue);
        expect(breakdown.finalFee, 0.0);
        expect(breakdown.discountAmount > 0, isTrue);
        expect(breakdown.promoReason, isNotNull);
      },
    );

    test('computes geographic distance between coordinates accurately', () {
      // Distance between two points in Riyadh (~5.5 km)
      final distance = DeliveryFeeCalculator.calculateDistanceKm(
        startLat: 24.7136,
        startLng: 46.6753,
        endLat: 24.7500,
        endLng: 46.7100,
      );

      expect(distance > 4.5 && distance < 6.5, isTrue);
    });
  });
}
