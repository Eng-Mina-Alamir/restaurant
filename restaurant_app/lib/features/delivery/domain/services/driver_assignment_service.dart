import 'package:latlong2/latlong.dart';

import '../entities/driver_info.dart';

/// Relative importance of each factor when scoring driver candidates.
///
/// Rationale for the defaults (they intentionally sum to 1.0 so the score
/// stays in `[0, 1]` and remains easy to reason about and log):
/// - [distance] (0.5): the dominant operational cost — a farther driver means
///   longer customer wait time and more fuel.
/// - [load] (0.3): prevents piling runs onto one nearby star driver while
///   peers idle; balances fairness with throughput.
/// - [rating] (0.2): quality signal, deliberately weakest — a slightly
///   lower-rated driver nearby beats a highly rated one across town.
class AssignmentWeights {
  const AssignmentWeights({
    this.distance = 0.5,
    this.load = 0.3,
    this.rating = 0.2,
  });

  /// Weight applied to the normalized distance term (0–1).
  final double distance;

  /// Weight applied to the driver's current-load ratio term (0–1).
  final double load;

  /// Weight applied to the inverse-normalized-rating term (0–1).
  final double rating;
}

/// Outcome of [DriverAssignmentService.assign].
sealed class AssignmentResult {
  const AssignmentResult();
}

/// A driver was selected for dispatch.
final class Assigned extends AssignmentResult {
  const Assigned(this.driverId);

  /// Id of the winning driver.
  final String driverId;
}

/// No driver could be dispatched right now. The order stays undispatched so
/// the manager can still reassign it manually from the dispatch board.
final class Waiting extends AssignmentResult {
  const Waiting(this.reason);

  /// Human-readable (Arabic) explanation for operators.
  final String reason;
}

/// Pure, framework-free hybrid auto-assignment engine for delivery orders.
///
/// Combines hard eligibility filters (availability, concurrency cap, service
/// radius) with a weighted soft score over distance, current load, and driver
/// rating. Fully deterministic: identical inputs always produce the same
/// winner regardless of candidate iteration order (ties break on driver id).
class DriverAssignmentService {
  const DriverAssignmentService();

  /// Reason returned when the eligible pool is empty after filtering.
  static const String noDriversReason = 'لا يوجد سواق متاحون حالياً';

  /// Haversine distances, unrounded: sub-meter precision keeps ranking stable
  /// when candidates sit at nearly identical ranges.
  static const Distance _haversine = DistanceHaversine(roundResult: false);

  /// Lowest possible value of [DriverInfo.rating].
  static const double _minRating = 1.0;

  /// Highest possible value of [DriverInfo.rating].
  static const double _maxRating = 5.0;

  /// Picks the best driver from [candidates], or returns [Waiting] when none
  /// qualifies.
  ///
  /// Eligibility filters:
  /// - [DriverInfo.isAvailable] must be true;
  /// - [DriverInfo.activeAssignments] < [maxConcurrentPerDriver];
  /// - Haversine distance to the restaurant <= [maxDistanceMeters].
  ///
  /// Among eligible drivers the lowest weighted score wins:
  ///
  /// ```
  /// wDistance * (distance / maxDistanceMeters)
  ///   + wLoad * (activeAssignments / maxConcurrentPerDriver)
  ///   + wRating * (1 - normalizedRating)
  /// ```
  ///
  /// Exact score ties break by lexicographic driver id so the outcome never
  /// depends on iteration order.
  AssignmentResult assign({
    required List<DriverInfo> candidates,
    required double restaurantLat,
    required double restaurantLng,
    double maxDistanceMeters = 5000,
    int maxConcurrentPerDriver = 3,
    AssignmentWeights weights = const AssignmentWeights(),
  }) {
    final restaurant = LatLng(restaurantLat, restaurantLng);

    ({DriverInfo driver, double score})? best;

    for (final driver in candidates) {
      if (!driver.isAvailable) continue;
      if (driver.activeAssignments >= maxConcurrentPerDriver) continue;

      final distanceMeters = _haversine.as(
        LengthUnit.Meter,
        restaurant,
        LatLng(driver.latitude, driver.longitude),
      );
      if (distanceMeters > maxDistanceMeters) continue;

      final normalizedDistance = (distanceMeters / maxDistanceMeters).clamp(
        0.0,
        1.0,
      );
      final loadRatio = (driver.activeAssignments / maxConcurrentPerDriver)
          .clamp(0.0, 1.0);
      final normalizedRating =
          ((driver.rating - _minRating) / (_maxRating - _minRating)).clamp(
            0.0,
            1.0,
          );

      // Lower is better: each term measures "badness" of picking this driver.
      final score =
          weights.distance * normalizedDistance +
          weights.load * loadRatio +
          weights.rating * (1.0 - normalizedRating);

      final currentBest = best;
      if (currentBest == null ||
          score < currentBest.score ||
          (score == currentBest.score &&
              driver.id.compareTo(currentBest.driver.id) < 0)) {
        best = (driver: driver, score: score);
      }
    }

    final winner = best;
    if (winner == null) return const Waiting(noDriversReason);
    return Assigned(winner.driver.id);
  }
}
