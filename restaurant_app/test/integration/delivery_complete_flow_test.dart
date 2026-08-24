import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/delivery/domain/repositories/delivery_repository.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import '../helpers/test_container.dart';

/// Builds the pending assignment under test, linked to [orderId] ORD-555.
DeliveryAssignment _assignment(String id) => DeliveryAssignment(
  id: id,
  orderId: 'ORD-555',
  driverId: 'driver-demo',
  pickupTime: DateTime.now(),
  deliveryLocation: 'التجمع الخامس، القاهرة',
  customerPhone: '01055554444',
  deliveryStatus: DeliveryStatus.pending,
  deliveryFee: 30.0,
);

/// Seeds ORD-555 as a READY delivery order (kitchen finished, waiting for
/// pickup) in an isolated in-memory order repository.
Future<InMemoryOrderRepository> _seedReadyOrder() async {
  final repo = InMemoryOrderRepository();
  await repo.createOrder(
    OrderEntity(
      id: 'ORD-555',
      restaurantId: 'rest-test',
      orderType: OrderType.delivery,
      status: OrderStatus.ready,
      createdAt: DateTime.now(),
    ),
  );
  return repo;
}

/// driver-demo's active (non-terminal) run count as reported by
/// [DeliveryRepository.getAvailableDrivers]. A driver with zero active runs
/// drops off the board entirely, which counts as 0 here.
Future<int> _activeRunsForDemo(DeliveryRepository repo) async {
  final drivers = await repo.getAvailableDrivers();
  return drivers.when(
    onLeft: (_) => -1,
    onRight: (list) {
      for (final d in list) {
        if (d.id == 'driver-demo') return d.activeAssignments;
      }
      return 0;
    },
  );
}

void main() {
  group('Delivery Complete Flow Integration Test', () {
    test(
      'end-to-end driver lifecycle: assignment -> accept -> start -> update location -> deliver',
      () async {
        final container = createTestContainer();
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

        expect(
          container
              .read(deliveryControllerProvider)
              .any((a) => a.id == 'del-flow-1'),
          isTrue,
        );

        // 1. Accept delivery
        await controller.accept('del-flow-1');
        var assignment = container
            .read(deliveryControllerProvider)
            .firstWhere((a) => a.id == 'del-flow-1');
        expect(assignment.deliveryStatus, DeliveryStatus.accepted);

        // 2. Start delivery
        await controller.start('del-flow-1');
        assignment = container
            .read(deliveryControllerProvider)
            .firstWhere((a) => a.id == 'del-flow-1');
        expect(assignment.deliveryStatus, DeliveryStatus.inTransit);

        // 3. Update location
        controller.updateLocation(latitude: 30.0131, longitude: 31.4913);

        // 4. Complete delivery
        await controller.complete('del-flow-1');
        assignment = container
            .read(deliveryControllerProvider)
            .firstWhere((a) => a.id == 'del-flow-1');
        expect(assignment.deliveryStatus, DeliveryStatus.delivered);
        expect(assignment.deliveredTime, isNotNull);
      },
    );

    test(
      'wired controller: completing a delivery completes the parent order '
      'and frees the driver capacity slot',
      () async {
        // ── Seed: ORD-555 is ready (kitchen done) and assigned for delivery.
        final orderRepo = await _seedReadyOrder();
        final deliveryRepo = InMemoryDeliveryRepository(seed: const []);
        await deliveryRepo.updateAssignment(_assignment('del-wired-1'));

        final container = createTestContainer(
          additionalOverrides: [
            orderRepositoryProvider.overrideWithValue(orderRepo),
            deliveryRepositoryProvider.overrideWithValue(deliveryRepo),
          ],
        );
        addTearDown(container.dispose);

        // Sanity: the pending assignment keeps driver-demo busy (1 active run).
        expect(await _activeRunsForDemo(deliveryRepo), 1);

        // ── Run: assign -> accept -> start -> complete through the wired
        // deliveryControllerProvider (its onDelivered hook advances the
        // parent order).
        final controller = container.read(deliveryControllerProvider.notifier);
        await Future<void>.delayed(Duration.zero);

        await controller.accept('del-wired-1');
        await controller.start('del-wired-1');
        await controller.complete('del-wired-1');

        // (a) The repository reports ORD-555 completed (ready → completed).
        final orders = (await orderRepo.getOrders()).when(
          onLeft: (_) => <OrderEntity>[],
          onRight: (list) => list,
        );
        expect(orders, hasLength(1));
        expect(orders.first.id, 'ORD-555');
        expect(orders.first.status, OrderStatus.completed);

        // (b) The terminal assignment freed driver-demo's capacity slot.
        expect(await _activeRunsForDemo(deliveryRepo), 0);
      },
    );

    test(
      'unwired controller (null onDelivered): completing leaves the parent '
      'order untouched',
      () async {
        final orderRepo = await _seedReadyOrder();
        final deliveryRepo = InMemoryDeliveryRepository(seed: const []);
        await deliveryRepo.updateAssignment(_assignment('del-unwired-1'));

        // Direct construction WITHOUT the hook: assignment-only behaviour.
        final controller = DeliveryController(deliveryRepo, 'driver-demo');
        addTearDown(controller.dispose);
        await Future<void>.delayed(Duration.zero);

        await controller.accept('del-unwired-1');
        await controller.start('del-unwired-1');
        await controller.complete('del-unwired-1');

        final orders = (await orderRepo.getOrders()).when(
          onLeft: (_) => <OrderEntity>[],
          onRight: (list) => list,
        );
        expect(orders.first.status, OrderStatus.ready);
      },
    );
  });
}
