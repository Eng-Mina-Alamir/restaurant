import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';

void main() {
  group('Delivery Complete Flow Integration Test', () {
    test('end-to-end driver lifecycle: assignment -> accept -> start -> update location -> deliver', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final deliveryRepo = container.read(deliveryRepositoryProvider);
      final initialAssignment = DeliveryAssignment(
        id: 'del-flow-1',
        orderId: 'ORD-555',
        driverId: 'driver-demo',
        pickupTime: DateTime.now(),
        deliveryLocation: 'التجمع الخامس، القاهرة',
        customerPhone: '01055554444',
        deliveryStatus: DeliveryStatus.pending,
        deliveryFee: 30.0,
      );

      await deliveryRepo.updateAssignment(initialAssignment);

      final controller = container.read(deliveryControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(deliveryControllerProvider).any((a) => a.id == 'del-flow-1'), isTrue);

      // 1. Accept delivery
      await controller.accept('del-flow-1');
      var assignment = container.read(deliveryControllerProvider).firstWhere((a) => a.id == 'del-flow-1');
      expect(assignment.deliveryStatus, DeliveryStatus.accepted);

      // 2. Start delivery
      await controller.start('del-flow-1');
      assignment = container.read(deliveryControllerProvider).firstWhere((a) => a.id == 'del-flow-1');
      expect(assignment.deliveryStatus, DeliveryStatus.inTransit);

      // 3. Update location
      controller.updateLocation(latitude: 30.0131, longitude: 31.4913);

      // 4. Complete delivery
      await controller.complete('del-flow-1');
      assignment = container.read(deliveryControllerProvider).firstWhere((a) => a.id == 'del-flow-1');
      expect(assignment.deliveryStatus, DeliveryStatus.delivered);
      expect(assignment.deliveredTime, isNotNull);
    });
  });
}
