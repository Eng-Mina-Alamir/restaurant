import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/network/realtime_event.dart';
import 'package:restaurant_app/core/supabase/supabase_realtime_service.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/delivery/domain/repositories/delivery_repository.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/controllers/dispatch_controller.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_container.dart';

/// Seeds a read-only orders list so [dispatchControllerProvider]'s
/// `ordersSource` closure observes exactly the fixture orders.
class OrdersControllerMock extends StateNotifier<List<OrderEntity>>
    implements OrdersController {
  OrdersControllerMock(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake realtime service for dispatch controller unit tests.
class SpyRealtimeService extends SupabaseRealtimeService {
  SpyRealtimeService()
    : super(
        SupabaseClient(
          SupabaseConfig.url,
          SupabaseConfig.anonKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
}

/// Feeds synthetic events straight onto [events].
class LoopbackRealtimeService extends SpyRealtimeService {
  void broadcastDeliveryAssignmentCreated(Map<String, dynamic> assignmentJson) {
    emit(
      RealtimeEvent(
        type: RealtimeEventType.deliveryAssignmentCreated,
        payload: assignmentJson,
      ),
    );
  }
}

/// Always rejects writes while reads behave like the real in-memory store.
class FailingCreateAssignmentRepository extends InMemoryDeliveryRepository {
  FailingCreateAssignmentRepository({super.seed});

  static const rejectionMessage = 'رفض قاعدة البيانات إنشاء التكليف';

  @override
  Future<Either<Failure, DeliveryAssignment>> createAssignment(
    DeliveryAssignment assignment,
  ) async =>
      const Left<Failure, DeliveryAssignment>(ServerFailure(rejectionMessage));
}

/// Counts bulk vs per-order reads to pin down the board-refresh N+1 fix.
class CountingBulkRepository extends InMemoryDeliveryRepository {
  CountingBulkRepository({super.seed});

  int bulkCalls = 0;
  int perOrderLookups = 0;

  @override
  Future<Either<Failure, List<DeliveryAssignment>>> getActiveAssignments() {
    bulkCalls++;
    return super.getActiveAssignments();
  }

  @override
  Future<Either<Failure, DeliveryAssignment?>> getAssignmentByOrderId(
    String orderId,
  ) {
    perOrderLookups++;
    return super.getAssignmentByOrderId(orderId);
  }
}

/// Counts refresh invocations so debounced scheduling can be asserted exactly.
///
/// The counter starts DISABLED on purpose: the base constructor dispatches
/// `refresh()` virtually BEFORE this subclass's field initializers run, so a
/// plain int field would be read while uninitialized. [markBaseline] arms it.
class RefreshSpyDispatchController extends DispatchController {
  RefreshSpyDispatchController(
    super.repository,
    super.realtimeService, {
    required super.ordersSource,
  });

  int? _refreshCalls;

  /// Refresh passes since [markBaseline] (excludes the constructor pass).
  int get refreshCalls => _refreshCalls ?? 0;

  void markBaseline() => _refreshCalls = 0;

  @override
  Future<void> refresh() {
    if (_refreshCalls != null) _refreshCalls = _refreshCalls! + 1;
    return super.refresh();
  }
}

/// Mirrors the production dispatch wiring (repository + realtime + orders
/// listener) against a [RefreshSpyDispatchController].
final spyDispatchControllerProvider =
    StateNotifierProvider<
      RefreshSpyDispatchController,
      AsyncValue<DispatchBoardState>
    >((ref) {
      final controller = RefreshSpyDispatchController(
        ref.watch(deliveryRepositoryProvider),
        ref.watch(supabaseRealtimeServiceProvider),
        ordersSource: () => ref.read(ordersControllerProvider),
      );
      ref.listen(
        ordersControllerProvider,
        (_, _) => controller.scheduleRefresh(),
      );
      return controller;
    });

OrderEntity buildOrder({
  required String id,
  OrderType orderType = OrderType.delivery,
  OrderStatus status = OrderStatus.ready,
}) {
  return OrderEntity(
    id: id,
    restaurantId: 'rest-1',
    orderType: orderType,
    status: status,
    deliveryAddress: 'القاهرة - المعادي، شارع 9',
    createdAt: DateTime.now(),
  );
}

DeliveryAssignment buildSeedAssignment({
  required String orderId,
  String? id,
  String driverId = 'driver-original',
  DeliveryStatus status = DeliveryStatus.failed,
}) {
  return DeliveryAssignment(
    id: id ?? 'ASG-$orderId-seed',
    orderId: orderId,
    driverId: driverId,
    pickupTime: DateTime.now(),
    deliveryLocation: 'القاهرة - المعادي، شارع 9',
    deliveryStatus: status,
    assignmentMethod: 'auto',
    assignedAt: DateTime.now(),
  );
}

ProviderContainer buildDispatchContainer({
  required List<OrderEntity> orders,
  DeliveryRepository? repository,
  SpyRealtimeService? realtimeService,
}) {
  return createTestContainer(
    additionalOverrides: [
      // Replace the default (unseeded) in-memory repo when the test needs
      // specific seed assignments or failure injection.
      if (repository != null)
        deliveryRepositoryProvider.overrideWithValue(repository),
      if (realtimeService != null)
        supabaseRealtimeServiceProvider.overrideWithValue(realtimeService),
      ordersControllerProvider.overrideWith(
        (ref) => OrdersControllerMock(orders),
      ),
    ],
  );
}

void main() {
  group('DispatchController', () {
    test('classification: undispatched vs failed vs excluded orders', () async {
      final container = buildDispatchContainer(
        orders: [
          buildOrder(id: 'ORD-A'), // ready delivery, no assignment yet.
          buildOrder(id: 'ORD-B'), // ready delivery, failed assignment.
          buildOrder(id: 'ORD-C', orderType: OrderType.dineIn), // not delivery.
          buildOrder(id: 'ORD-D', status: OrderStatus.pending), // too early.
          buildOrder(id: 'ORD-E'), // ready delivery already dispatched.
        ],
        repository: InMemoryDeliveryRepository(
          seed: [
            buildSeedAssignment(orderId: 'ORD-B'),
            buildSeedAssignment(
              orderId: 'ORD-E',
              id: 'ASG-ORD-E-live',
              driverId: 'driver-busy',
              status: DeliveryStatus.inTransit,
            ),
          ],
        ),
      );
      addTearDown(container.dispose);

      final controller = container.read(dispatchControllerProvider.notifier);
      await controller.refresh();
      final state = container.read(dispatchControllerProvider).requireValue;

      expect(state.undispatchedOrders.map((o) => o.id), ['ORD-A']);
      expect(state.failedAssignments, hasLength(1));
      expect(state.failedAssignments.single.order.id, 'ORD-B');
      expect(
        state.failedAssignments.single.assignment.deliveryStatus,
        DeliveryStatus.failed,
      );
      // ORD-E (in-transit assignment), dine-in ORD-C and pending ORD-D are all skipped.
      expect(
        state.undispatchedOrders.map((o) => o.id),
        isNot(contains(anyOf('ORD-C', 'ORD-D', 'ORD-E'))),
      );
      // Drivers are derived from ACTIVE (non-terminal) assignments only:
      // driver-busy is in transit, but driver-original's failed run no
      // longer counts as an active one.
      expect(state.availableDrivers.map((d) => d.id), ['driver-busy']);
    });

    test('manual assign on undispatched order creates pending manual '
        'assignment and broadcasts it', () async {
      final realtime = SpyRealtimeService();
      final repo = InMemoryDeliveryRepository(seed: const []);
      final container = buildDispatchContainer(
        orders: [buildOrder(id: 'ORD-A')],
        repository: repo,
        realtimeService: realtime,
      );
      addTearDown(container.dispose);

      final controller = container.read(dispatchControllerProvider.notifier);
      await controller.refresh();

      final ok = await controller.assignDriver('ORD-A', 'driver-9');
      expect(ok, isTrue);

      final created = (await repo.getAssignmentByOrderId('ORD-A')).when(
        onLeft: (f) => fail('lookup should not fail'),
        onRight: (a) => a!,
      );
      expect(created.assignmentMethod, 'manual');
      expect(created.deliveryStatus, DeliveryStatus.pending);
      expect(created.driverId, 'driver-9');
      expect(created.orderId, 'ORD-A');
      expect(created.id, startsWith('ASG-ORD-A-'));
      expect(created.assignedAt, isNotNull);

      // Refresh moved the order out of the undispatched bucket.
      final state = container.read(dispatchControllerProvider).requireValue;
      expect(state.undispatchedOrders, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test(
      'repository rejection surfaces error state without throwing',
      () async {
        final realtime = SpyRealtimeService();
        final container = buildDispatchContainer(
          orders: [buildOrder(id: 'ORD-A')],
          repository: FailingCreateAssignmentRepository(seed: const []),
          realtimeService: realtime,
        );
        addTearDown(container.dispose);

        final controller = container.read(dispatchControllerProvider.notifier);
        await controller.refresh();

        final ok = await controller.assignDriver('ORD-A', 'driver-9');
        expect(ok, isFalse);

        final state = container.read(dispatchControllerProvider).requireValue;
        expect(
          state.errorMessage,
          FailingCreateAssignmentRepository.rejectionMessage,
        );
        expect(state.undispatchedOrders.map((o) => o.id), ['ORD-A']);
      },
    );

    test(
      'refresh classifies from ONE bulk read with zero per-order lookups',
      () async {
        final repo = CountingBulkRepository(
          seed: [
            buildSeedAssignment(orderId: 'ORD-B'),
            buildSeedAssignment(
              orderId: 'ORD-E',
              id: 'ASG-ORD-E-live',
              driverId: 'driver-busy',
              status: DeliveryStatus.inTransit,
            ),
          ],
        );
        final container = buildDispatchContainer(
          orders: [
            buildOrder(id: 'ORD-A'),
            buildOrder(id: 'ORD-B'),
            buildOrder(id: 'ORD-C'),
          ],
          repository: repo,
        );
        addTearDown(container.dispose);

        // Reading the provider fires an initial refresh from the constructor;
        // reset the counters so only the explicit pass below is measured.
        final controller = container.read(dispatchControllerProvider.notifier);
        repo.bulkCalls = 0;
        repo.perOrderLookups = 0;

        await controller.refresh();

        expect(repo.bulkCalls, 1);
        expect(repo.perOrderLookups, 0);

        // The single bulk read still classifies every candidate correctly.
        final state = container.read(dispatchControllerProvider).requireValue;
        expect(state.undispatchedOrders.map((o) => o.id), ['ORD-A', 'ORD-C']);
        expect(state.failedAssignments.single.order.id, 'ORD-B');
      },
    );

    test('reassigning a failed assignment preserves the original id '
        '(upsert, no fork)', () async {
      final realtime = SpyRealtimeService();
      const originalId = 'ASG-fail-1';
      final repo = InMemoryDeliveryRepository(
        seed: [buildSeedAssignment(orderId: 'ORD-B', id: originalId)],
      );
      final container = buildDispatchContainer(
        orders: [buildOrder(id: 'ORD-B')],
        repository: repo,
        realtimeService: realtime,
      );
      addTearDown(container.dispose);

      final controller = container.read(dispatchControllerProvider.notifier);
      await controller.refresh();

      final boardState = container
          .read(dispatchControllerProvider)
          .requireValue;
      expect(boardState.failedAssignments.single.assignment.id, originalId);

      final ok = await controller.assignDriver('ORD-B', 'driver-new');
      expect(ok, isTrue);

      final reassigned = (await repo.getAssignmentByOrderId('ORD-B')).when(
        onLeft: (f) => fail('lookup should not fail'),
        onRight: (a) => a!,
      );
      expect(reassigned.id, originalId); // SAME row, not a forked one.
      expect(reassigned.driverId, 'driver-new');
      expect(reassigned.deliveryStatus, DeliveryStatus.pending);
      expect(reassigned.assignmentMethod, 'manual');

      // Exactly one stored row exists for the new driver and none remain
      // under the original driver — the failed row was overwritten in place.
      final newDriverRows = (await repo.getAssignments('driver-new')).when(
        onLeft: (f) => fail('lookup should not fail'),
        onRight: (list) => list,
      );
      expect(newDriverRows, hasLength(1));
      expect(newDriverRows.single.id, originalId);
    });

    test(
      'orders mutated AFTER construction reclassify within the debounce window',
      () {
        fakeAsync((async) {
          final repo = CountingBulkRepository(seed: const []);
          // Disposed inside the fake zone so timer/subscription teardown
          // happens against fake time; no addTearDown here.
          final container = buildDispatchContainer(
            orders: [buildOrder(id: 'ORD-A')],
            repository: repo,
          );

          container.read(dispatchControllerProvider.notifier);
          async.flushMicrotasks(); // settle constructor refresh
          var board = container.read(dispatchControllerProvider).requireValue;
          expect(board.undispatchedOrders.map((o) => o.id), ['ORD-A']);
          final bulkCallsAfterCtorRefresh = repo.bulkCalls;

          // Simulate realtime landing a new ready delivery order.
          final mock =
              container.read(ordersControllerProvider.notifier)
                  as OrdersControllerMock;
          mock.state = [...mock.state, buildOrder(id: 'ORD-F')];

          // Halfway through the window: nothing re-classified yet.
          async.elapse(const Duration(milliseconds: 200));
          board = container.read(dispatchControllerProvider).requireValue;
          expect(board.undispatchedOrders.map((o) => o.id), ['ORD-A']);

          // Past the debounce window: exactly ONE extra refresh pass picked
          // up the new order.
          async.elapse(const Duration(milliseconds: 250));
          async.flushMicrotasks();
          board = container.read(dispatchControllerProvider).requireValue;
          expect(board.undispatchedOrders.map((o) => o.id), ['ORD-A', 'ORD-F']);
          expect(repo.bulkCalls, bulkCallsAfterCtorRefresh + 1);

          container.dispose();
        });
      },
    );

    test('synthetic deliveryAssignmentCreated via realtime loopback triggers '
        'a debounced refresh', () {
      fakeAsync((async) {
        final realtime = LoopbackRealtimeService();
        final repo = CountingBulkRepository(seed: const []);
        final container = buildDispatchContainer(
          orders: [buildOrder(id: 'ORD-A')],
          repository: repo,
          realtimeService: realtime,
        );

        container.read(dispatchControllerProvider.notifier);
        async.flushMicrotasks(); // settle constructor refresh
        final bulkCallsAfterCtorRefresh = repo.bulkCalls;

        // A remote assignment lands while this client never called
        // assignDriver — the events subscription must still re-classify.
        realtime.broadcastDeliveryAssignmentCreated({
          'id': 'ASG-synthetic-1',
          'orderId': 'ORD-A',
          'driverId': 'driver-remote',
        });

        async.elapse(const Duration(milliseconds: 450));
        async.flushMicrotasks();

        expect(repo.bulkCalls, bulkCallsAfterCtorRefresh + 1);

        container.dispose();
      });
    });

    test('a burst of 3 rapid order mutations collapses into EXACTLY one '
        'debounced refresh pass', () {
      fakeAsync((async) {
        final container = createTestContainer(
          additionalOverrides: [
            ordersControllerProvider.overrideWith(
              (ref) => OrdersControllerMock([buildOrder(id: 'ORD-A')]),
            ),
            spyDispatchControllerProvider,
          ],
        );

        final controller = container.read(
          spyDispatchControllerProvider.notifier,
        );
        async.flushMicrotasks(); // settle constructor refresh
        controller.markBaseline();
        expect(controller.refreshCalls, 0);

        final mock =
            container.read(ordersControllerProvider.notifier)
                as OrdersControllerMock;
        mock.state = [...mock.state, buildOrder(id: 'ORD-B')];
        mock.state = [...mock.state, buildOrder(id: 'ORD-C')];
        mock.state = [...mock.state, buildOrder(id: 'ORD-D')];

        // Burst armed the debounce but the window keeps restarting; nothing
        // fires before quiet.
        expect(controller.refreshCalls, 0);

        async.elapse(const Duration(milliseconds: 450));
        async.flushMicrotasks();

        expect(controller.refreshCalls, 1);
        final board = container
            .read(spyDispatchControllerProvider)
            .requireValue;
        expect(board.undispatchedOrders.map((o) => o.id), [
          'ORD-A',
          'ORD-B',
          'ORD-C',
          'ORD-D',
        ]);

        container.dispose();
      });
    });
  });
}
