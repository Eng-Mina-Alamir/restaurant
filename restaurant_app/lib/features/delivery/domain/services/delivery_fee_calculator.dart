import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Structured result of dynamic delivery fee calculation.
class DeliveryFeeBreakdown {
  final double distanceKm;
  final double baseFee;
  final double distanceFee;
  final double peakMultiplier;
  final double rawFee;
  final double discountAmount;
  final double finalFee;
  final bool isFreeDelivery;
  final String? promoReason;

  const DeliveryFeeBreakdown({
    required this.distanceKm,
    required this.baseFee,
    required this.distanceFee,
    required this.peakMultiplier,
    required this.rawFee,
    required this.discountAmount,
    required this.finalFee,
    required this.isFreeDelivery,
    this.promoReason,
  });

  @override
  String toString() =>
      'DeliveryFeeBreakdown(distance: ${distanceKm.toStringAsFixed(1)}km, finalFee: $finalFee SAR)';
}

/// Service calculating dynamic delivery fees based on distance, order subtotal,
/// and peak operating hours.
class DeliveryFeeCalculator {
  static const double defaultBaseFee = 10.0;
  static const double baseDistanceKm = 3.0;
  static const double perKmRate = 2.0;
  static const double freeDeliveryThreshold = 150.0;

  /// Restaurant base coordinates (Riyadh central mock coordinates).
  static const double restaurantLat = 24.7136;
  static const double restaurantLng = 46.6753;

  /// Calculates straight-line distance in kilometers using the Haversine formula.
  static double calculateDistanceKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(endLat - startLat);
    final dLng = _degreesToRadians(endLng - startLng);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(startLat)) *
            math.cos(_degreesToRadians(endLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;

  /// Determines peak surge factor based on time of day.
  /// Lunch peak (13:00 - 15:00) -> 1.15x
  /// Dinner peak (19:00 - 22:00) -> 1.25x
  /// Normal -> 1.0x
  static double getPeakSurgeMultiplier(DateTime time) {
    final hour = time.hour;
    if (hour >= 13 && hour < 15) {
      return 1.15;
    } else if (hour >= 19 && hour < 22) {
      return 1.25;
    }
    return 1.0;
  }

  /// Computes full delivery fee breakdown.
  DeliveryFeeBreakdown calculate({
    required double distanceKm,
    required double orderSubtotal,
    DateTime? timestamp,
  }) {
    final time = timestamp ?? DateTime.now();
    final peakMultiplier = getPeakSurgeMultiplier(time);

    const base = defaultBaseFee;
    final extraDistance = math.max(0.0, distanceKm - baseDistanceKm);

    final distFee = extraDistance * perKmRate;

    final raw = (base + distFee) * peakMultiplier;

    // Check free delivery qualification
    if (orderSubtotal >= freeDeliveryThreshold) {
      return DeliveryFeeBreakdown(
        distanceKm: distanceKm,
        baseFee: base,
        distanceFee: distFee,
        peakMultiplier: peakMultiplier,
        rawFee: raw,
        discountAmount: raw,
        finalFee: 0.0,
        isFreeDelivery: true,
        promoReason: 'توصيل مجاني للطلبات فوق $freeDeliveryThreshold ر.س',
      );
    }

    return DeliveryFeeBreakdown(
      distanceKm: distanceKm,
      baseFee: base,
      distanceFee: distFee,
      peakMultiplier: peakMultiplier,
      rawFee: raw,
      discountAmount: 0.0,
      finalFee: double.parse(raw.toStringAsFixed(2)),
      isFreeDelivery: false,
    );
  }
}

final deliveryFeeCalculatorProvider = Provider<DeliveryFeeCalculator>((ref) {
  return DeliveryFeeCalculator();
});
