import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';

void main() {
  group('DeliveryAssignment Entity Tests', () {
    test('round-trip JSON serialization with date converters', () {
      final now = DateTime(2026, 8, 19, 14, 0);
      final assignment = DeliveryAssignment(
        id: 'del-101',
        orderId: 'ORD-900',
        driverId: 'drv-7',
        pickupTime: now,
        deliveredTime: now.add(const Duration(minutes: 30)),
        deliveryLocation: 'المعادي، القاهرة',
        customerPhone: '01012345678',
        latitude: 29.9602,
        longitude: 31.2569,
        deliveryStatus: DeliveryStatus.delivered,
        deliveryFee: 25.0,
        routeDistanceMeters: 4500.0,
      );

      final json = assignment.toJson();
      expect(json['id'], 'del-101');
      expect(json['deliveryStatus'], 'delivered');
      expect(json['latitude'], 29.9602);

      final deserialized = DeliveryAssignment.fromJson(json);
      expect(deserialized.id, 'del-101');
      expect(deserialized.deliveryStatus, DeliveryStatus.delivered);
      expect(deserialized.customerPhone, '01012345678');
      expect(deserialized.deliveryFee, 25.0);
    });
  });
}
