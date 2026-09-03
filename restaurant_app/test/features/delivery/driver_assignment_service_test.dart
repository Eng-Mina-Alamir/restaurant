import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/notifications/new_order_notifier.dart';
import 'package:restaurant_app/core/utils/logger.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/delivery/domain/entities/driver_info.dart';
import 'package:restaurant_app/features/delivery/domain/repositories/delivery_repository.dart';
import 'package:restaurant_app/features/delivery/domain/services/driver_assignment_service.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

void main() {
  // Riyadh Olaya mock restaurant coordinates (matches
  // DeliveryFeeCalculator.restaurantLat/Lng).
  const restaurantLat = 24.7136;
  const restaurantLng = 46.6753;

  // With earthRadius = 6378137 (latlong2's equatorial radius):
  //   1° latitude ≈ 111,319 m → meters(deg) ≈ deg * 111,319.
  const service = DriverAssignmentService();

  /// Driver positioned [degLat] north of the restaurant.
  DriverInfo driverAt(
    String id, {
    double degLat = 0,
    double rating = 5.0,
    int activeAssignments = 0,
    bool isAvailable = true,
  }) {
    return DriverInfo(
      id: id,
      name: id,
      rating: rating,
      latitude: restaurantLat + degLat,
      longitude: restaurantLng,
      activeAssignments: activeAssignments,
      isAvailable: isAvailable,
    );
  }

  group('DriverAssignmentService', () {
    test('ranks the genuinely nearest free driver first', () {
      final candidates = [
        driverAt('drv-far', degLat: 0.03), // ≈ 3340 m
        driverAt('drv-near', degLat: 0.005), // ≈ 557 m
        driverAt('drv-mid', degLat: 0.02), // ≈ 2226 m
      ];

      final result = service.assign(
        candidates: candidates,
        restaurantLat: restaurantLat,
        restaurantLng: restaurantLng,
      );

      expect(result, isA<Assigned>());
      expect((result as Assigned).driverId, 'drv-near');
    });

    test('load-balancing beats raw distance when distances are equal-ish', () {
      // Thresholds (default weights 0.5/0.3/0.2, equal ratings):
      // One extra active assignment costs wLoad/maxConcurrent = 0.1 score,
      // which offsets up to 0.1/wDistance*maxDistance = 1000 m. So an idle
      // driver may sit up to ~1000 m FARTHER per extra assignment the
      // nearer rival carries and still win. Here the rival carries 2
      // assignments (break-even ≈ 2000 m); the actual gap is ≈ 1002 m —
      // a wide margin inside "equal-ish".
      final nearButLoaded = driverAt(
        'drv-near-loaded',
        degLat: 0.004, // ≈ 445 m
        activeAssignments: 2,
      );
      final fartherButFree = driverAt('drv-far-free', degLat: 0.013);

      final result = service.assign(
        candidates: [nearButLoaded, fartherButFree],
        restaurantLat: restaurantLat,
        restaurantLng: restaurantLng,
      );

      expect(result, isA<Assigned>());
      expect((result as Assigned).driverId, 'drv-far-free');
    });

    test('excludes drivers already holding the concurrency cap', () {
      final capped = driverAt(
        'drv-capped',
        degLat: 0.004, // nearest by far
        activeAssignments: 3, // == maxConcurrentPerDriver
      );
      final free = driverAt('drv-free', degLat: 0.03); // ≈ 3340 m

      final result = service.assign(
        candidates: [capped, free],
        restaurantLat: restaurantLat,
        restaurantLng: restaurantLng,
      );

      expect(result, isA<Assigned>());
      expect((result as Assigned).driverId, 'drv-free');
    });

    test('a fully-capped pool yields Waiting even with close drivers', () {
      final result = service.assign(
        candidates: [
          driverAt('drv-a', degLat: 0.001, activeAssignments: 3),
          driverAt('drv-b', degLat: 0.002, activeAssignments: 4),
        ],
        restaurantLat: restaurantLat,
        restaurantLng: restaurantLng,
      );

      expect(result, isA<Waiting>());
    });

    test('excludes drivers beyond the service radius', () {
      // ≈ 5566 m — beyond the default 5000 m cap.
      final outOfRange = driverAt('drv-out-of-range', degLat: 0.05);

      final alone = service.assign(
        candidates: [outOfRange],
        restaurantLat: restaurantLat,
        restaurantLng: restaurantLng,
      );
      expect(alone, isA<Waiting>());

      final mixed = service.assign(
        candidates: [
          outOfRange,
          driverAt('drv-in-range', degLat: 0.02), // ≈ 2226 m
        ],
        restaurantLat: restaurantLat,
        restaurantLng: restaurantLng,
      );
      expect(mixed, isA<Assigned>());
      expect((mixed as Assigned).driverId, 'drv-in-range');
    });

    test('honors an inclusive distance boundary at the cap', () {
      // ≈ 557 m driver with tighter caps around it.
      final candidate = [driverAt('drv-edge', degLat: 0.005)];

      final inside = service.assign(
        candidates: candidate,
        restaurantLat: restaurantLat,
        restaurantLng: restaurantLng,
        maxDistanceMeters: 600,
      );
      expect(inside, isA<Assigned>());

      final outside = service.assign(
        candidates: candidate,
        restaurantLat: restaurantLat,
        restaurantLng: restaurantLng,
        maxDistanceMeters: 550,
      );
      expect(outside, isA<Waiting>());
    });

    test('rating weight breaks ties between equidistant drivers', () {
      // Mirror positions ⇒ identical Haversine distance (~557 m each).
      // The LOW-rated driver has the lexicographically smaller id, so a win
      // by 'b-high' can only come from the rating term.
      final lowRated = driverAt('a-low', degLat: 0.005, rating: 3.0);
      final highRated = driverAt('b-high', degLat: -0.005, rating: 5.0);

      final result = service.assign(
        candidates: [lowRated, highRated],
        restaurantLat: restaurantLat,
        restaurantLng: restaurantLng,
      );

      expect(result, isA<Assigned>());
      expect((result as Assigned).driverId, 'b-high');
    });

    test('rating-dominant weights make quality beat proximity', () {
      // weights(distance: 0.2, rating: 0.8): near-but-mediocre scores
      // 0.2*0.111 + 0.8*0.5 = 0.42 vs far-and-excellent 0.2*0.445 = 0.09.
      final nearMediocre = driverAt(
        'drv-near-mediocre',
        degLat: 0.005,
        rating: 3.0,
      );
      final farExcellent = driverAt(
        'drv-far-excellent',
        degLat: 0.02,
        rating: 5.0,
      );

      final result = service.assign(
        candidates: [nearMediocre, farExcellent],
        restaurantLat: restaurantLat,
        restaurantLng: restaurantLng,
        weights: const AssignmentWeights(distance: 0.2, load: 0, rating: 0.8),
      );

      expect(result, isA<Assigned>());
      expect((result as Assigned).driverId, 'drv-far-excellent');
    });

    test('empty pool yields the Arabic waiting reason', () {
      final result = service.assign(
        candidates: const [],
        restaurantLat: restaurantLat,
        restaurantLng: restaurantLng,
      );

      expect(result, isA<Waiting>());
      expect((result as Waiting).reason, 'لا يوجد سواق متاحون حالياً');
    });

    test('unavailable drivers are filtered down to Waiting', () {
      final result = service.assign(
        candidates: [
          driverAt('drv-offline', degLat: 0.001, isAvailable: false),
        ],
        restaurantLat: restaurantLat,
        restaurantLng: restaurantLng,
      );

      expect(result, isA<Waiting>());
      expect(
        (result as Waiting).reason,
        DriverAssignmentService.noDriversReason,
      );
    });

    test('deterministic: identical inputs always elect the same winner', () {
      final candidates = [
        driverAt('drv-e', degLat: 0.01, rating: 4.2),
        driverAt('drv-a', degLat: 0.006, rating: 4.6),
        driverAt('drv-c', degLat: 0.008, rating: 5.0, activeAssignments: 1),
        driverAt('drv-b', degLat: 0.007, rating: 3.9),
        driverAt('drv-d', degLat: 0.025, rating: 4.8),
      ];

      // Same list, different iteration orders (reversed + rotations) across
      // repeated runs — the winner must never change.
      final winners = <String>{};
      var rotated = List<DriverInfo>.of(candidates);
      for (var run = 0; run < 10; run++) {
        final order = run.isEven
            ? List<DriverInfo>.of(rotated)
            : List<DriverInfo>.of(rotated.reversed);
        final result = service.assign(
          candidates: order,
          restaurantLat: restaurantLat,
          restaurantLng: restaurantLng,
        );
        expect(result, isA<Assigned>());
        winners.add((result as Assigned).driverId);
        rotated = [...rotated.skip(1), rotated.first];
      }

      expect(winners.length, 1);
    });
  });

  group('delivery-ready auto-dispatch (capture)', () {
    const burger = MenuItem(
      id: 'm1',
      categoryId: 'burgers',
      name: 'برجر دجاج',
      description: 'لذيذ',
      price: 30.0,
    );

    late _CapturingDeliveryRepository deliveryRepo;
    late OrdersController controller;
    late CartController cart;
    late NewOrderNotifier notifier;
    int hookInvocations = 0;

    /// Mirrors the production wiring in [ordersControllerProvider]: rank
    /// drivers with [DriverAssignmentService], then create ONE assignment.
    Future<void> dispatchLikeProvider(OrderEntity order) async {
      hookInvocations++;
      final driversResult = await deliveryRepo.getAvailableDrivers();
      final drivers = driversResult.when(
        onLeft: (_) => <DriverInfo>[],
        onRight: (list) => list,
      );
      switch (service.assign(
        candidates: drivers,
        restaurantLat: restaurantLat,
        restaurantLng: restaurantLng,
      )) {
        case Waiting():
          return;
        case Assigned(:final driverId):
          final now = DateTime.now();
          await deliveryRepo.createAssignment(
            DeliveryAssignment(
              id: 'ASG-${order.id}',
              orderId: order.id,
              driverId: driverId,
              pickupTime: now,
              deliveryLocation: order.deliveryAddress ?? '',
              deliveryStatus: DeliveryStatus.pending,
              assignmentMethod: 'auto',
              assignedAt: now,
            ),
          );
      }
    }

    setUp(() {
      AppLogger.enabled = false;
      deliveryRepo = _CapturingDeliveryRepository([
        driverAt('drv-auto', degLat: 0.002),
      ]);
      cart = CartController();
      notifier = NewOrderNotifier();
      hookInvocations = 0;
      controller = OrdersController(
        InMemoryOrderRepository(),
        cart,
        notifier,
        onDeliveryOrderReady: dispatchLikeProvider,
      );
    });

    tearDown(() {
      controller.dispose();
      notifier.dispose();
      AppLogger.enabled = true;
    });

    test(
      'exactly one createAssignment fires when a delivery order hits ready',
      () async {
        cart.addItem(const CartItem(menuItem: burger, quantity: 1));
        final order = await controller.placeOrder(
          orderType: OrderType.delivery,
          deliveryAddress: 'حي النرجس، الرياض',
        );
        expect(order, isNotNull);

        // Preparing: no dispatch yet.
        await controller.updateStatus(order!.id, OrderStatus.preparing);
        expect(hookInvocations, 0);
        expect(deliveryRepo.createdAssignments, isEmpty);

        // Ready: exactly one assignment, for the winning driver.
        await controller.updateStatus(order.id, OrderStatus.ready);
        expect(hookInvocations, 1);
        expect(deliveryRepo.createCallCount, 1);

        final assignment = deliveryRepo.createdAssignments.single;
        expect(assignment.orderId, order.id);
        expect(assignment.driverId, 'drv-auto');
        expect(assignment.assignmentMethod, 'auto');
        expect(assignment.deliveryStatus, DeliveryStatus.pending);

        // Later transitions do not re-dispatch the same order.
        await controller.updateStatus(order.id, OrderStatus.served);
        expect(hookInvocations, 1);
        expect(deliveryRepo.createCallCount, 1);
      },
    );

    test('non-delivery orders reaching ready never dispatch', () async {
      cart.addItem(const CartItem(menuItem: burger, quantity: 1));
      final dineIn = await controller.placeOrderForTable('table-7');

      await controller.updateStatus(dineIn!.id, OrderStatus.ready);

      expect(hookInvocations, 0);
      expect(deliveryRepo.createCallCount, 0);
    });

    test(
      'a failing dispatch hook never breaks the status-update path',
      () async {
        var brokenHookCalls = 0;
        final brokenCart = CartController();
        final breakingController = OrdersController(
          InMemoryOrderRepository(),
          brokenCart,
          NewOrderNotifier(),
          onDeliveryOrderReady: (o) async {
            brokenHookCalls++;
            throw StateError('dispatch backend exploded');
          },
        );

        try {
          brokenCart.addItem(const CartItem(menuItem: burger, quantity: 1));
          final order =
              await breakingController.placeOrder(orderType: OrderType.delivery);
          final updated = await breakingController.updateStatus(
            order!.id,
            OrderStatus.ready,
          );

          // Status transition completed despite the hook blowing up…
          expect(updated, isNotNull);
          expect(updated!.status, OrderStatus.ready);
          // …and the hook really was invoked before failing.
          expect(brokenHookCalls, 1);
        } finally {
          breakingController.dispose();
        }

        // Sanity: the well-behaved controller was untouched by this scenario.
        expect(deliveryRepo.createCallCount, 0);
      },
    );
  });
}

/// Records every [createAssignment] call; everything else is a stub.
class _CapturingDeliveryRepository implements DeliveryRepository {
  _CapturingDeliveryRepository(this._drivers);

  final List<DriverInfo> _drivers;
  final List<DeliveryAssignment> createdAssignments = [];

  int get createCallCount => createdAssignments.length;

  @override
  Future<Either<Failure, DeliveryAssignment>> createAssignment(
    DeliveryAssignment assignment,
  ) async {
    createdAssignments.add(assignment);
    return Right<Failure, DeliveryAssignment>(assignment);
  }

  @override
  Future<Either<Failure, DeliveryAssignment?>> getAssignmentByOrderId(
    String orderId,
  ) async {
    for (final a in createdAssignments) {
      if (a.orderId == orderId) return Right<Failure, DeliveryAssignment?>(a);
    }
    return const Right<Failure, DeliveryAssignment?>(null);
  }

  @override
  Future<Either<Failure, List<DeliveryAssignment>>>
  getActiveAssignments() async {
    return const Right<Failure, List<DeliveryAssignment>>([]);
  }

  @override
  Future<Either<Failure, List<DeliveryAssignment>>> getAssignments(
    String driverId,
  ) async {
    return Right<Failure, List<DeliveryAssignment>>(
      createdAssignments.where((a) => a.driverId == driverId).toList(),
    );
  }

  @override
  Future<Either<Failure, List<DriverInfo>>> getAvailableDrivers() async {
    return Right<Failure, List<DriverInfo>>(List.of(_drivers));
  }

  @override
  Future<Either<Failure, DeliveryAssignment>> updateAssignment(
    DeliveryAssignment assignment,
  ) async {
    return Right<Failure, DeliveryAssignment>(assignment);
  }
}
