import '../../../core/domain/enums.dart';
import '../domain/entities/delivery_assignment.dart';

/// Static seed data for delivery assignments used by the offline flow.
///
/// `DateTime` is not const-constructible, so the assignments are built lazily
/// via [buildAssignments] rather than a const list.
abstract final class DeliverySeedData {
  DeliverySeedData._();

  static List<DeliveryAssignment> _build() => <DeliveryAssignment>[
    DeliveryAssignment(
      id: 'd1',
      orderId: 'ORD-0101',
      driverId: 'driver-demo',
      pickupTime: DateTime.fromMillisecondsSinceEpoch(0),
      deliveryLocation: 'شارع الملك فهد، 12',
      deliveryStatus: DeliveryStatus.pending,
      deliveryFee: 15,
      routeDistanceMeters: 2400,
    ),
    DeliveryAssignment(
      id: 'd2',
      orderId: 'ORD-0104',
      driverId: 'driver-demo',
      pickupTime: DateTime.fromMillisecondsSinceEpoch(0),
      deliveryLocation: 'حي النرجس، 88',
      deliveryStatus: DeliveryStatus.accepted,
      deliveryFee: 12,
      routeDistanceMeters: 750,
    ),
  ];

  static List<DeliveryAssignment> buildAssignments() => _build();
}
