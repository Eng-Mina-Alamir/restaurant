import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// A delivery destination or waypoint along a driver's route.
class DeliveryStop {
  const DeliveryStop({
    required this.id,
    required this.name,
    required this.location,
    this.address = '',
    this.isCompleted = false,
  });

  final String id;
  final String name;
  final LatLng location;
  final String address;
  final bool isCompleted;

  DeliveryStop copyWith({
    String? id,
    String? name,
    LatLng? location,
    String? address,
    bool? isCompleted,
  }) {
    return DeliveryStop(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      address: address ?? this.address,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// The calculated optimal itinerary for multi-stop delivery.
class OptimizedRouteResult {
  const OptimizedRouteResult({
    required this.orderedStops,
    required this.totalDistanceKm,
    required this.estimatedDurationMinutes,
    required this.polylinePoints,
  });

  final List<DeliveryStop> orderedStops;
  final double totalDistanceKm;
  final int estimatedDurationMinutes;
  final List<LatLng> polylinePoints;
}

/// Service providing route optimization and multi-stop planning for drivers.
class RouteOptimizationService {
  const RouteOptimizationService();

  static const Distance _distanceCalculator = Distance();

  /// Calculates geodesic distance between two points in kilometers.
  double distanceBetweenKm(LatLng p1, LatLng p2) {
    return _distanceCalculator.as(LengthUnit.Kilometer, p1, p2);
  }

  /// Computes the optimal visiting order for [stops] starting from [startLocation].
  ///
  /// Employs a Greedy Nearest Neighbor Traveling Salesperson (TSP) heuristic
  /// for optimal path finding and fuel/time efficiency.
  OptimizedRouteResult optimizeRoute({
    required LatLng startLocation,
    required List<DeliveryStop> stops,
    double averageSpeedKmH = 35.0,
    int minutesPerStop = 5,
  }) {
    if (stops.isEmpty) {
      return OptimizedRouteResult(
        orderedStops: const [],
        totalDistanceKm: 0.0,
        estimatedDurationMinutes: 0,
        polylinePoints: [startLocation],
      );
    }

    final remaining = List<DeliveryStop>.of(stops);
    final ordered = <DeliveryStop>[];
    final polyline = <LatLng>[startLocation];

    var currentPoint = startLocation;
    double totalKm = 0.0;

    while (remaining.isNotEmpty) {
      int nearestIndex = 0;
      double minDistance = double.infinity;

      for (int i = 0; i < remaining.length; i++) {
        final dist = distanceBetweenKm(currentPoint, remaining[i].location);
        if (dist < minDistance) {
          minDistance = dist;
          nearestIndex = i;
        }
      }

      final nextStop = remaining.removeAt(nearestIndex);
      ordered.add(nextStop);
      polyline.add(nextStop.location);
      totalKm += minDistance;
      currentPoint = nextStop.location;
    }

    // Total travel time + service time at each delivery location
    final travelMinutes = ((totalKm / averageSpeedKmH) * 60).ceil();
    final totalDuration = travelMinutes + (ordered.length * minutesPerStop);

    return OptimizedRouteResult(
      orderedStops: ordered,
      totalDistanceKm: double.parse(totalKm.toStringAsFixed(2)),
      estimatedDurationMinutes: totalDuration,
      polylinePoints: polyline,
    );
  }
}

final routeOptimizationServiceProvider =
    Provider<RouteOptimizationService>((ref) {
  return const RouteOptimizationService();
});
