import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:restaurant_app/features/delivery/data/services/route_optimization_service.dart';

void main() {
  group('RouteOptimizationService', () {
    const service = RouteOptimizationService();

    // Riyadh coordinates
    const restaurant = LatLng(24.7136, 46.6753); // Olaya
    const stopFar = LatLng(24.8200, 46.7200); // North Riyadh
    const stopNear = LatLng(24.7200, 46.6800); // Near Olaya
    const stopMid = LatLng(24.7500, 46.7000); // Mid distance

    test('calculates accurate distance between coordinates', () {
      final dist = service.distanceBetweenKm(restaurant, stopNear);
      expect(dist, greaterThan(0));
      expect(dist, lessThan(2.0));
    });

    test('optimizes multi-stop route in optimal order of proximity', () {
      final stops = [
        const DeliveryStop(id: 'S-FAR', name: 'العميل البعيد', location: stopFar),
        const DeliveryStop(id: 'S-NEAR', name: 'العميل القريب', location: stopNear),
        const DeliveryStop(id: 'S-MID', name: 'العميل المتوسط', location: stopMid),
      ];

      final result = service.optimizeRoute(
        startLocation: restaurant,
        stops: stops,
      );

      expect(result.orderedStops.length, 3);
      // Nearest neighbor should pick NEAR -> MID -> FAR
      expect(result.orderedStops[0].id, 'S-NEAR');
      expect(result.orderedStops[1].id, 'S-MID');
      expect(result.orderedStops[2].id, 'S-FAR');
      expect(result.totalDistanceKm, greaterThan(10.0));
      expect(result.estimatedDurationMinutes, greaterThan(15));
      expect(result.polylinePoints.length, 4); // start + 3 stops
    });

    test('handles empty stops gracefully', () {
      final result = service.optimizeRoute(
        startLocation: restaurant,
        stops: const [],
      );

      expect(result.orderedStops, isEmpty);
      expect(result.totalDistanceKm, 0.0);
      expect(result.estimatedDurationMinutes, 0);
      expect(result.polylinePoints, [restaurant]);
    });
  });
}
