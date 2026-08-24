import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:restaurant_app/features/delivery/data/services/route_optimization_service.dart';

void main() {
  group('RouteOptimizationService Edge Cases Tests', () {
    const service = RouteOptimizationService();
    const restaurant = LatLng(24.7136, 46.6753); // Riyadh Center (Olaya)

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

    test('handles single stop cleanly', () {
      const stop = DeliveryStop(
        id: 'S-1',
        name: 'عميل مفرد',
        location: LatLng(24.7300, 46.6900),
      );

      final result = service.optimizeRoute(
        startLocation: restaurant,
        stops: [stop],
        minutesPerStop: 5,
      );

      expect(result.orderedStops.length, 1);
      expect(result.orderedStops.first.id, 'S-1');
      expect(result.totalDistanceKm, greaterThan(0.0));
      expect(result.estimatedDurationMinutes, greaterThan(5));
      expect(result.polylinePoints.length, 2); // start + stop
    });

    test(
      'handles multiple stops with identical coordinates (same building/tower)',
      () {
        const locationTower = LatLng(24.7200, 46.6800);
        const stops = [
          DeliveryStop(
            id: 'S-TOWER-1',
            name: 'شقة 401',
            location: locationTower,
          ),
          DeliveryStop(
            id: 'S-TOWER-2',
            name: 'شقة 802',
            location: locationTower,
          ),
          DeliveryStop(
            id: 'S-TOWER-3',
            name: 'شقة 1205',
            location: locationTower,
          ),
        ];

        final result = service.optimizeRoute(
          startLocation: restaurant,
          stops: stops,
          minutesPerStop: 3,
        );

        expect(result.orderedStops.length, 3);
        // Distance between identical points is 0, so total distance equals distance to tower once
        final singleLeg = service.distanceBetweenKm(restaurant, locationTower);
        expect(result.totalDistanceKm, closeTo(singleLeg, 0.1));
        // Duration: travel time + 3 * 3 = 9 mins
        expect(result.estimatedDurationMinutes, greaterThan(9));
      },
    );

    test(
      'safely falls back when negative or zero speed/per-stop values are passed',
      () {
        const stop = DeliveryStop(
          id: 'S-1',
          name: 'عميل',
          location: LatLng(24.7300, 46.6900),
        );

        final result = service.optimizeRoute(
          startLocation: restaurant,
          stops: [stop],
          averageSpeedKmH: -10, // Invalid speed
          minutesPerStop: -5, // Invalid offset
        );

        expect(result.orderedStops.length, 1);
        expect(result.totalDistanceKm, greaterThan(0.0));
        expect(result.estimatedDurationMinutes, greaterThan(0));
      },
    );

    test('isWithinDeliveryRadius enforces geographic service boundary', () {
      // 5 km away -> in radius
      const closeCustomer = LatLng(24.7300, 46.6900);
      expect(
        service.isWithinDeliveryRadius(
          restaurant,
          closeCustomer,
          maxRadiusKm: 25.0,
        ),
        isTrue,
      );

      // Al-Kharj / Far location (~80 km away) -> out of radius
      const farLocation = LatLng(24.1500, 47.3000);
      expect(
        service.isWithinDeliveryRadius(
          restaurant,
          farLocation,
          maxRadiusKm: 30.0,
        ),
        isFalse,
      );
    });
  });
}
