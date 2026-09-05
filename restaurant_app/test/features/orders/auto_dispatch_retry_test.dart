import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/supabase/supabase_realtime_service.dart';
import 'package:restaurant_app/core/utils/logger.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:restaurant_app/features/delivery/domain/entities/driver_info.dart';
import 'package:restaurant_app/features/delivery/domain/services/delivery_fee_calculator.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_container.dart';

/// Canonical checkout burger — must match `checkoutFixtureItems[0]`
/// (`b1` @ 28 EGP) so checkout-time revalidation passes.
const MenuItem _burger = MenuItem(
  id: 'b1',
  categoryId: 'برجر',
  name: 'برجر كلاسيك',
  description: 'لحم بقري بلدي مشوي، جبنة شيدر، خس وطماطم مع صوص خاص',
  price: 28,
);

/// Driver parked ≈222 m north of the restaurant — inside the 5000 m service
/// radius with zero active assignments.
DriverInfo _nearbyDriver(String id) => DriverInfo(
  id: id,
  name: id,
  rating: 5.0,
  latitude: DeliveryFeeCalculator.restaurantLat + 0.002,
  longitude: DeliveryFeeCalculator.restaurantLng,
);

/// Controllable driver pool: [availableDrivers] is returned verbatim by
/// getAvailableDrivers so tests can flip the pool between ticks; every
/// createAssignment is recorded without touching the seeded store.
class _ScriptedDriverPoolRepository extends InMemoryDeliveryRepository {
  List<DriverInfo> availableDrivers = const <DriverInfo>[];
  final List<DeliveryAssignment> createdAssignments = <DeliveryAssignment>[];

  @override
  Future<Either<Failure, List<DriverInfo>>> getAvailableDrivers() async =>
      Right<Failure, List<DriverInfo>>(List.of(availableDrivers));

  @override
  Future<Either<Failure, DeliveryAssignment>> createAssignment(
    DeliveryAssignment assignment,
  ) async {
    createdAssignments.add(assignment);
    return Right<Failure, DeliveryAssignment>(assignment);
  }
}

class _SpyRealtimeService extends SupabaseRealtimeService {
  _SpyRealtimeService()
    : super(
        SupabaseClient(
          SupabaseConfig.url,
          SupabaseConfig.anonKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
}

void main() {
  setUp(() {
    // Deterministic output: silence logger noise from the retry loop.
    AppLogger.enabled = false;
  });

  tearDown(() {
    AppLogger.enabled = true;
  });

  /// Builds the standard checkout container with a scripted (initially
  /// empty) driver pool and a broadcast spy.
  ProviderContainer buildRetryContainer(
    _ScriptedDriverPoolRepository repo,
    _SpyRealtimeService realtime,
  ) {
    return createTestContainer(
      seedCheckoutFixtures: true,
      additionalOverrides: [
        deliveryRepositoryProvider.overrideWithValue(repo),
        supabaseRealtimeServiceProvider.overrideWithValue(realtime),
      ],
    );
  }

  /// Places ONE delivery order through the provider-wired controller and
  /// drives it to ready (firing the auto-dispatch first attempt inside the
  /// same await chain as updateStatus).
  Future<String> placeReadyDeliveryOrder(ProviderContainer container) async {
    await primeMenuForCheckout(container);

    final cart = container.read(cartControllerProvider.notifier);
    cart.addItem(const CartItem(menuItem: _burger));

    final orders = container.read(ordersControllerProvider.notifier);
    final order = await orders.placeOrder(
      orderType: OrderType.delivery,
      deliveryAddress: 'حي النرجس، الرياض',
    );
    expect(order, isNotNull);

    // Legal path only: pending -> preparing -> ready (direct pending ->
    // ready is rejected by the state machine + DB trigger).
    final preparing = await orders.updateStatus(order!.id, OrderStatus.preparing);
    expect(preparing, isNotNull);
    final updated = await orders.updateStatus(order.id, OrderStatus.ready);
    expect(updated, isNotNull);
    expect(updated!.status, OrderStatus.ready);
    return order.id;
  }

  testWidgets(
    'driver pool empty at ready-time queues the order without assigning',
    (tester) async {
      final repo = _ScriptedDriverPoolRepository(); // empty pool on purpose
      final realtime = _SpyRealtimeService();
      final container = buildRetryContainer(repo, realtime);

      final orderId = await placeReadyDeliveryOrder(container);

      // First attempt found nobody available: nothing created
      expect(repo.createdAssignments, isEmpty);
      expect(container.read(ordersControllerProvider).single.id, orderId);

      // …and even a later tick with a still-empty pool keeps it queued.
      repo.availableDrivers = const [];
      await tester.pump(const Duration(seconds: 31));
      await tester.pump();

      expect(repo.createdAssignments, isEmpty);
      expect(container.read(ordersControllerProvider).single.id, orderId);

      container.dispose();
    },
  );

  testWidgets('a driver appearing later is auto-assigned on the next tick', (
    tester,
  ) async {
    final repo = _ScriptedDriverPoolRepository();
    final realtime = _SpyRealtimeService();
    final container = buildRetryContainer(repo, realtime);
    addTearDown(container.dispose);

    final orderId = await placeReadyDeliveryOrder(container);
    expect(repo.createdAssignments, isEmpty); // still queued

    // A driver comes online before the next 30 s retry tick fires.
    repo.availableDrivers = [_nearbyDriver('drv-late')];
    await tester.pump(const Duration(seconds: 31)); // exactly one tick
    await tester.pump(); // settle microtasks

    expect(repo.createdAssignments, hasLength(1));
    final assignment = repo.createdAssignments.single;
    expect(assignment.orderId, orderId);
    expect(assignment.driverId, 'drv-late');
    expect(assignment.assignmentMethod, 'auto');
    expect(assignment.deliveryStatus, DeliveryStatus.pending);

    // Success drained the queue: further ticks must NOT re-dispatch.
    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    expect(repo.createdAssignments, hasLength(1));
  });

  testWidgets('an order cancelled while waiting is dropped without dispatch', (
    tester,
  ) async {
    final repo = _ScriptedDriverPoolRepository();
    final realtime = _SpyRealtimeService();
    final container = buildRetryContainer(repo, realtime);
    addTearDown(container.dispose);

    final orderId = await placeReadyDeliveryOrder(container);

    // Cancel while still queued…
    await container
        .read(ordersControllerProvider.notifier)
        .updateStatus(orderId, OrderStatus.cancelled);

    // …then a driver shows up before the next tick.
    repo.availableDrivers = [_nearbyDriver('drv-too-late')];
    await tester.pump(const Duration(seconds: 31));
    await tester.pump();

    // Terminal orders are dropped silently — never dispatched.
    expect(repo.createdAssignments, isEmpty);
  });

  testWidgets('disposing the container cancels the retry timer', (
    tester,
  ) async {
    final repo = _ScriptedDriverPoolRepository();
    final realtime = _SpyRealtimeService();
    final container = buildRetryContainer(repo, realtime);

    await placeReadyDeliveryOrder(container);
    expect(repo.createdAssignments, isEmpty); // queued, timer armed

    container.dispose();

    repo.availableDrivers = [_nearbyDriver('drv-after-dispose')];
    await tester.pump(const Duration(seconds: 61));
    await tester.pump();

    expect(repo.createdAssignments, isEmpty);
  });
}
