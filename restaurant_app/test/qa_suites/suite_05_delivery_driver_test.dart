import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'helpers/qa_test_helpers.dart';

void main() {
  group('Suite 5: Delivery Driver Flow (تجربة مندوب التوصيل)', () {
    // -------------------------------------------------------------
    // TC-DRV-01: Available Delivery Orders List
    // -------------------------------------------------------------
    test('TC-DRV-01: Driver receives delivery assignment details with address, phone, and total amount', () async {
      final assignment = DeliveryAssignment(
        id: 'del-qa-01',
        orderId: 'ORD-9876',
        driverId: 'driver-demo',
        deliveryStatus: DeliveryStatus.pending,
        customerPhone: '01012345678',
        deliveryLocation: 'شارع النصر، عمارة 15، شقة 4',
        latitude: 30.0444,
        longitude: 31.2357,
        deliveryFee: 25.0,
        pickupTime: DateTime.now(),
      );

      expect(assignment.customerPhone, '01012345678');
      expect(assignment.deliveryLocation, contains('شارع النصر'));
      expect(assignment.deliveryFee, 25.0);
      expect(assignment.deliveryStatus, DeliveryStatus.pending);
    });

    // -------------------------------------------------------------
    // TC-DRV-02: Accept and Start Pickup
    // -------------------------------------------------------------
    test('TC-DRV-02: Driver accepts assignment and starts delivery transit', () async {
      final container = createQaContainer();
      addTearDown(container.dispose);

      final deliveryRepo = container.read(deliveryRepositoryProvider);
      final initial = DeliveryAssignment(
        id: 'del-flow-1',
        orderId: 'ORD-5555',
        driverId: 'driver-demo',
        deliveryStatus: DeliveryStatus.pending,
        customerPhone: '01099887766',
        deliveryLocation: 'المعادي - شارع 9',
        latitude: 29.955,
        longitude: 31.265,
        deliveryFee: 30.0,
        pickupTime: DateTime.now(),
      );

      await deliveryRepo.updateAssignment(initial);

      final deliveryNotifier = container.read(deliveryControllerProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Accept
      await deliveryNotifier.accept('del-flow-1');
      var list = container.read(deliveryControllerProvider);
      var current = list.firstWhere((a) => a.id == 'del-flow-1');
      expect(current.deliveryStatus, DeliveryStatus.accepted);

      // Start Transit
      await deliveryNotifier.start('del-flow-1');
      list = container.read(deliveryControllerProvider);
      current = list.firstWhere((a) => a.id == 'del-flow-1');
      expect(current.deliveryStatus, DeliveryStatus.inTransit);
    });

    // -------------------------------------------------------------
    // TC-DRV-03: Driver GPS Location Updates
    // -------------------------------------------------------------
    test('TC-DRV-03: Driver updates live GPS coordinates during transit', () {
      final container = createQaContainer();
      addTearDown(container.dispose);

      final deliveryNotifier = container.read(deliveryControllerProvider.notifier);
      expect(() => deliveryNotifier.updateLocation(latitude: 30.050, longitude: 31.240), returnsNormally);
    });

    // -------------------------------------------------------------
    // TC-DRV-04: Delivery Confirmation & Order Finalization
    // -------------------------------------------------------------
    test('TC-DRV-04: Driver confirms delivery and timestamps completion', () async {
      final container = createQaContainer();
      addTearDown(container.dispose);

      final deliveryRepo = container.read(deliveryRepositoryProvider);
      final assignment = DeliveryAssignment(
        id: 'del-complete-1',
        orderId: 'ORD-7777',
        driverId: 'driver-demo',
        deliveryStatus: DeliveryStatus.inTransit,
        customerPhone: '01122334455',
        deliveryLocation: 'مدينة نصر - عباس العقاد',
        latitude: 30.065,
        longitude: 31.345,
        deliveryFee: 35.0,
        pickupTime: DateTime.now(),
      );

      await deliveryRepo.updateAssignment(assignment);

      final deliveryNotifier = container.read(deliveryControllerProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Complete
      await deliveryNotifier.complete('del-complete-1');

      final list = container.read(deliveryControllerProvider);
      final completed = list.firstWhere((a) => a.id == 'del-complete-1');
      expect(completed.deliveryStatus, DeliveryStatus.delivered);
      expect(completed.deliveredTime, isNotNull);
    });
  });
}
