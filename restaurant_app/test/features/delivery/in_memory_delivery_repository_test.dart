import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';

void main() {
  group('InMemoryDeliveryRepository dispatch methods', () {
    late InMemoryDeliveryRepository repo;

    setUp(() {
      repo = InMemoryDeliveryRepository(seed: const []);
    });

    DeliveryAssignment buildAssignment({
      String id = 'del-100',
      String orderId = 'ORD-2000',
    }) {
      return DeliveryAssignment(
        id: id,
        orderId: orderId,
        driverId: 'driver-demo',
        pickupTime: DateTime.fromMillisecondsSinceEpoch(0),
        deliveryLocation: 'القاهرة - مدينة نصر',
        deliveryStatus: DeliveryStatus.pending,
      );
    }

    test('createAssignment stores the assignment and returns it', () async {
      final assignment = buildAssignment();

      final result = await repo.createAssignment(assignment);

      expect(result.isRight, isTrue);
      result.when(onLeft: (_) => fail('expected success'), onRight: (created) {
        expect(created.id, assignment.id);
        expect(created.orderId, assignment.orderId);
        expect(created.assignmentMethod, 'auto');
        expect(created.assignedAt, isNull);
      });
    });

    test('createAssignment + getAssignmentByOrderId round-trip', () async {
      final assignment = buildAssignment();
      await repo.createAssignment(assignment);

      final result = await repo.getAssignmentByOrderId(assignment.orderId);

      expect(result.isRight, isTrue);
      result.when(onLeft: (_) => fail('expected success'), onRight: (loaded) {
        expect(loaded, isNotNull);
        expect(loaded!.id, assignment.id);
        expect(loaded.orderId, assignment.orderId);
        expect(loaded.driverId, assignment.driverId);
        expect(loaded.deliveryStatus, DeliveryStatus.pending);
      });
    });

    test('getAssignmentByOrderId returns null for unknown order', () async {
      await repo.createAssignment(buildAssignment());

      final result = await repo.getAssignmentByOrderId('ORD-DOES-NOT-EXIST');

      expect(result.isRight, isTrue);
      result.when(
        onLeft: (_) => fail('expected success'),
        onRight: (loaded) => expect(loaded, isNull),
      );
    });

    test('createAssignment upserts when the same id is re-dispatched',
        () async {
      final original = buildAssignment();
      await repo.createAssignment(original);

      final updated = original.copyWith(
        deliveryStatus: DeliveryStatus.accepted,
      );
      await repo.createAssignment(updated);

      final result =
          await repo.getAssignmentByOrderId(original.orderId);
      result.when(
        onLeft: (_) => fail('expected success'),
        onRight: (loaded) =>
            expect(loaded!.deliveryStatus, DeliveryStatus.accepted),
      );
    });
  });
}
