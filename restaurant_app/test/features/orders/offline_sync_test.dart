import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:restaurant_app/core/data/offline_queue_service.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/network/connectivity_service.dart';
import 'package:restaurant_app/core/notifications/new_order_notifier.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_status_log_entry.dart';
import 'package:restaurant_app/features/orders/domain/repositories/order_repository.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

/// Wraps a repository and counts createOrder calls per order id.
class _RecordingOrderRepository implements OrderRepository {
  _RecordingOrderRepository(this._inner);

  final OrderRepository _inner;
  final Map<String, int> createCalls = <String, int>{};

  @override
  Future<Either<Failure, OrderEntity>> createOrder(OrderEntity order) async {
    createCalls[order.id] = (createCalls[order.id] ?? 0) + 1;
    return _inner.createOrder(order);
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() => _inner.getOrders();

  @override
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) =>
      _inner.updateOrderStatus(orderId, status);

  @override
  Future<Either<Failure, OrderEntity>> claimOrder(
    String orderId,
    String kitchenUserId,
  ) =>
      _inner.claimOrder(orderId, kitchenUserId);

  @override
  Future<Either<Failure, OrderEntity>> revertStatus(
    String orderId,
    OrderStatus toStatus, {
    required String actorId,
    String? reason,
  }) =>
      _inner.revertStatus(orderId, toStatus, actorId: actorId, reason: reason);

  @override
  Future<Either<Failure, List<OrderStatusLogEntry>>> getAuditTrail(
    String orderId,
  ) =>
      _inner.getAuditTrail(orderId);
}

void main() {
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('offline_sync_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  const burger = MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'وصف',
    price: 30.0,
  );

  group('Offline order queue and sync', () {
    test('queues orders placed while offline and auto-syncs when online', () async {
      final connectivity = ConnectivityService();
      final cart = CartController();
      final repository = InMemoryOrderRepository();
      final notifier = NewOrderNotifier();

      final controller = OrdersController(
        repository,
        cart,
        notifier,
        connectivityService: connectivity,
      );
      addTearDown(controller.dispose);
      addTearDown(connectivity.dispose);
      addTearDown(notifier.dispose);

      // 1. Go offline
      connectivity.goOffline();
      expect(connectivity.isOffline, isTrue);

      // 2. Add item to cart and place order
      cart.addItem(const CartItem(menuItem: burger));
      final order1 = await controller.placeOrder();
      expect(order1, isNotNull);
      expect(controller.pendingSyncCount, 1);
      expect(controller.offlineQueue.first.id, order1?.id);

      // 3. Place another order
      cart.addItem(const CartItem(menuItem: burger, quantity: 2));
      final order2 = await controller.placeOrder();
      expect(order2, isNotNull);
      expect(controller.pendingSyncCount, 2);

      // 4. Go online -> auto syncs and clears queue
      connectivity.goOnline();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.pendingSyncCount, 0);
      expect(controller.offlineQueue, isEmpty);
      expect(controller.state.length, 2);
    });

    test('offline orders are submitted EXACTLY ONCE with persistent queue',
        () async {
      final connectivity = ConnectivityService();
      final cart = CartController();
      final notifier = NewOrderNotifier();
      final queueService = OfflineQueueService();
      await queueService.init();
      await queueService.clear();

      final recordingRepo = _RecordingOrderRepository(
        InMemoryOrderRepository(),
      );

      final controller = OrdersController(
        recordingRepo,
        cart,
        notifier,
        connectivityService: connectivity,
        offlineQueueService: queueService,
      );
      addTearDown(controller.dispose);
      addTearDown(connectivity.dispose);
      addTearDown(notifier.dispose);
      addTearDown(queueService.close);

      // Place an order while offline.
      connectivity.goOffline();
      cart.addItem(const CartItem(menuItem: burger));
      final order = await controller.placeOrder();
      expect(order, isNotNull);
      expect(recordingRepo.createCalls, isEmpty,
          reason: 'Offline placement must not hit the repository');

      // Simulate a flapping reconnect: several online events in a row.
      connectivity.goOnline();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      connectivity.goOffline();
      connectivity.goOnline();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      connectivity.goOnline(); // duplicate online event
      await Future<void>.delayed(const Duration(milliseconds: 60));

      // The single queued order must have been replayed exactly once.
      expect(recordingRepo.createCalls[order!.id], 1,
          reason:
              'Double submission detected: ${recordingRepo.createCalls}');
      expect(queueService.pendingCount, 0);
      expect(controller.pendingSyncCount, 0);
      expect(controller.state.where((o) => o.id == order.id).length, 1);
    });

    test('poison offline orders dead-letter instead of retrying forever',
        () async {
      final connectivity = ConnectivityService();
      final cart = CartController();
      final notifier = NewOrderNotifier();
      final queueService = OfflineQueueService(
        maxAttempts: 3,
        baseBackoff: Duration.zero, // deterministic: no waiting in tests
      );
      await queueService.init();
      await queueService.clear();

      final controller = OrdersController(
        _AlwaysFailingRepository(),
        cart,
        notifier,
        connectivityService: connectivity,
        offlineQueueService: queueService,
      );
      addTearDown(controller.dispose);
      addTearDown(connectivity.dispose);
      addTearDown(notifier.dispose);
      addTearDown(queueService.close);

      connectivity.goOffline();
      cart.addItem(const CartItem(menuItem: burger));
      final order = await controller.placeOrder();
      expect(order, isNotNull);
      expect(queueService.pendingCount, 1);

      // Repeated syncs must eventually give up on the poison entry.
      for (var i = 0; i < 4; i++) {
        await controller.syncOfflineOrders();
      }

      expect(queueService.pendingCount, 0,
          reason: 'Poison entries must be dead-lettered, not retried forever');
      expect(queueService.deadLetteredCount, 1);
    });
  });
}

/// Repository whose createOrder always fails (simulates permanent rejection).
class _AlwaysFailingRepository implements OrderRepository {
  @override
  Future<Either<Failure, OrderEntity>> createOrder(OrderEntity order) async {
    return const Left<Failure, OrderEntity>(
      ServerFailure('validation failed'),
    );
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async =>
      const Right<Failure, List<OrderEntity>>(<OrderEntity>[]);

  @override
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async =>
      const Right<Failure, void>(null);

  @override
  Future<Either<Failure, OrderEntity>> claimOrder(
    String orderId,
    String kitchenUserId,
  ) async =>
      const Left(ServerFailure('permanent rejection'));

  @override
  Future<Either<Failure, OrderEntity>> revertStatus(
    String orderId,
    OrderStatus toStatus, {
    required String actorId,
    String? reason,
  }) async =>
      const Left(ServerFailure('permanent rejection'));

  @override
  Future<Either<Failure, List<OrderStatusLogEntry>>> getAuditTrail(
    String orderId,
  ) async =>
      const Right<Failure, List<OrderStatusLogEntry>>(
        <OrderStatusLogEntry>[],
      );
}

