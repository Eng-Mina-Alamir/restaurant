import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';

void main() {
  group('Delivery Flow Integration', () {
    test('Driver lifecycle: Pending -> Accepted -> InTransit -> Delivered', () async {
      final assignment = DeliveryAssignment(
        id: 'DEL-101',
        orderId: 'ORD-500',
        driverId: 'driver-1',
        pickupTime: DateTime.now(),
        deliveryStatus: DeliveryStatus.pending,
        deliveryLocation: 'حي النخيل - الرياض',
      );
      final repository = InMemoryDeliveryRepository(seed: [assignment]);

      final controller = DeliveryController(repository, 'driver-1');
      addTearDown(controller.dispose);

      // 1. Initial pending state
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.state.length, 1);
      expect(controller.state.first.deliveryStatus, DeliveryStatus.pending);

      // 2. Accept assignment
      await controller.accept('DEL-101');
      expect(controller.state.first.deliveryStatus, DeliveryStatus.accepted);

      // 3. Start delivery (in transit) & update GPS
      await controller.start('DEL-101');
      expect(controller.state.first.deliveryStatus, DeliveryStatus.inTransit);

      controller.updateLocation(latitude: 24.7136, longitude: 46.6753);

      // 4. Complete delivery with proof
      await controller.complete('DEL-101');
      expect(controller.state.first.deliveryStatus, DeliveryStatus.delivered);
      expect(controller.state.first.deliveredTime, isNotNull);
    });
  });
}
