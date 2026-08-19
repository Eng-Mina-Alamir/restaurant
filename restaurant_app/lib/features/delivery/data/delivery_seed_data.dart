import '../../../core/domain/enums.dart';
import '../domain/entities/delivery_assignment.dart';

/// Static seed data for delivery assignments across Cairo & Giza neighborhoods.
abstract final class DeliverySeedData {
  DeliverySeedData._();

  static List<DeliveryAssignment> _build() => <DeliveryAssignment>[
    DeliveryAssignment(
      id: 'd1',
      orderId: 'ORD-0101',
      driverId: 'driver-demo',
      pickupTime: DateTime.fromMillisecondsSinceEpoch(0),
      deliveryLocation: 'القاهرة - المعادي، شارع 9، عمارة 14',
      customerPhone: '0551234567',
      deliveryStatus: DeliveryStatus.pending,
      deliveryFee: 25,
      routeDistanceMeters: 2400,
    ),
    DeliveryAssignment(
      id: 'd2',
      orderId: 'ORD-0104',
      driverId: 'driver-demo',
      pickupTime: DateTime.fromMillisecondsSinceEpoch(0),
      deliveryLocation: 'الجيزة - الدقي، شارع مصدق، برج الأطباء',
      customerPhone: '0559876543',
      deliveryStatus: DeliveryStatus.accepted,
      deliveryFee: 20,
      routeDistanceMeters: 750,
    ),
  ];

  static List<DeliveryAssignment> buildAssignments() => _build();
}
