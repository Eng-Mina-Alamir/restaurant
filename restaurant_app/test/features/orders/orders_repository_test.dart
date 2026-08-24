import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:restaurant_app/core/data/local_cache_service.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/orders/data/repositories/hive_order_repository.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_status_log_entry.dart';
import 'package:restaurant_app/features/orders/domain/repositories/order_repository.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('orders_repo_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    try {
      await Hive.close();
      await Hive.deleteFromDisk();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Orders Repositories Unit Tests', () {
    late OrderEntity sampleOrder;

    setUp(() {
      sampleOrder = OrderEntity(
        id: 'ORD-TEST-1',
        restaurantId: 'rest-1',
        tableId: 't1',
        customerId: 'c1',
        orderType: OrderType.dineIn,
        status: OrderStatus.pending,
        items: const [],
        subtotal: 100.0,
        taxAmount: 15.0,
        totalAmount: 115.0,
        createdAt: DateTime.now(),
      );
    });

    test('InMemoryOrderRepository creates and retrieves orders', () async {
      final repo = InMemoryOrderRepository();
      final createRes = await repo.createOrder(sampleOrder);
      expect(createRes.isRight, isTrue);

      final listRes = await repo.getOrders();
      expect(listRes.isRight, isTrue);
      final list = (listRes as Right<Failure, List<OrderEntity>>).value;
      expect(list.length, 1);
      expect(list.first.id, 'ORD-TEST-1');
    });

    test(
      'HiveOrderRepository creates and retrieves orders via LocalCacheService',
      () async {
        final box = await Hive.openBox<String>('orders_box_test');
        await box.clear();
        final cache = LocalCacheService(box);
        final repo = HiveOrderRepository(cache);

        final createRes = await repo.createOrder(sampleOrder);
        expect(createRes.isRight, isTrue);

        final listRes = await repo.getOrders();
        expect(listRes.isRight, isTrue);
        final list = (listRes as Right<Failure, List<OrderEntity>>).value;
        expect(list.length, 1);
        expect(list.first.id, 'ORD-TEST-1');
      },
    );
  });

  group('KDS claim and guarded revert (local repositories)', () {
    OrderEntity orderWithStatus(OrderStatus status) => OrderEntity(
      id: 'ORD-KDS-1',
      restaurantId: 'rest-1',
      tableId: 't1',
      orderType: OrderType.dineIn,
      status: status,
      items: const [],
      subtotal: 50.0,
      taxAmount: 7.5,
      totalAmount: 57.5,
      createdAt: DateTime.now(),
    );

    test('InMemory claimOrder assigns kitchen user id', () async {
      final repo = InMemoryOrderRepository();
      await repo.createOrder(orderWithStatus(OrderStatus.pending));

      final claimRes = await repo.claimOrder('ORD-KDS-1', 'chef-9');
      expect(claimRes.isRight, isTrue);
      expect(
        (claimRes as Right<Failure, OrderEntity>).value.assignedKitchenId,
        'chef-9',
      );

      final listRes = await repo.getOrders();
      expect(
        (listRes as Right<Failure, List<OrderEntity>>)
            .value
            .first
            .assignedKitchenId,
        'chef-9',
      );
    });

    test(
      'InMemory revertStatus round-trips guarded moves and logs them',
      () async {
        final repo = InMemoryOrderRepository();
        await repo.createOrder(orderWithStatus(OrderStatus.pending));

        // Illegal revert from pending is rejected.
        final illegal = await repo.revertStatus(
          'ORD-KDS-1',
          OrderStatus.preparing,
          actorId: 'chef-9',
        );
        expect(illegal.isLeft, isTrue);
        expect(repo.statusLog, isEmpty);

        // Legal revert ready → preparing.
        await repo.updateOrderStatus('ORD-KDS-1', OrderStatus.ready);
        final revertRes = await repo.revertStatus(
          'ORD-KDS-1',
          OrderStatus.preparing,
          actorId: 'chef-9',
          reason: 'تم التجهيز بالخطأ',
        );
        expect(revertRes.isRight, isTrue);
        expect(
          (revertRes as Right<Failure, OrderEntity>).value.status,
          OrderStatus.preparing,
        );

        // Terminal target is never allowed.
        final toTerminal = await repo.revertStatus(
          'ORD-KDS-1',
          OrderStatus.completed,
          actorId: 'chef-9',
        );
        expect(toTerminal.isLeft, isTrue);

        // Exactly one audit entry, attributed and flagged as revert.
        expect(repo.statusLog, hasLength(1));
        final entry = repo.statusLog.single;
        expect(entry.orderId, 'ORD-KDS-1');
        expect(entry.fromStatus, OrderStatus.ready);
        expect(entry.toStatus, OrderStatus.preparing);
        expect(entry.actorId, 'chef-9');
        expect(entry.reason, 'تم التجهيز بالخطأ');
        expect(entry.isRevert, isTrue);
      },
    );

    test('Hive claimOrder and revertStatus round-trip through cache', () async {
      final box = await Hive.openBox<String>('orders_claim_box_test');
      await box.clear();
      final repo = HiveOrderRepository(LocalCacheService(box));

      await repo.createOrder(orderWithStatus(OrderStatus.pending));

      final claimRes = await repo.claimOrder('ORD-KDS-1', 'chef-7');
      expect(claimRes.isRight, isTrue);
      expect(
        (claimRes as Right<Failure, OrderEntity>).value.assignedKitchenId,
        'chef-7',
      );

      await repo.updateOrderStatus('ORD-KDS-1', OrderStatus.served);
      final revertRes = await repo.revertStatus(
        'ORD-KDS-1',
        OrderStatus.ready,
        actorId: 'chef-7',
      );
      expect(revertRes.isRight, isTrue);
      expect(
        (revertRes as Right<Failure, OrderEntity>).value.status,
        OrderStatus.ready,
      );
      expect(repo.statusLog.single.fromStatus, OrderStatus.served);

      // Assignment survives a full reload from Hive storage.
      final reloaded = await repo.getOrders();
      expect(
        (reloaded as Right<Failure, List<OrderEntity>>).value.first.status,
        OrderStatus.ready,
      );
      expect(reloaded.value.first.assignedKitchenId, 'chef-7');
    });
  });

  group('Max two reverts per order (التراجع مرتان كحد أقصى)', () {
    const orderId = 'ORD-MAX-REVERT';

    OrderEntity orderWithStatus(String id, OrderStatus status) => OrderEntity(
      id: id,
      restaurantId: 'rest-1',
      tableId: 't1',
      orderType: OrderType.dineIn,
      status: status,
      items: const [],
      subtotal: 50.0,
      taxAmount: 7.5,
      totalAmount: 57.5,
      createdAt: DateTime.now(),
    );

    /// Two legal reverts succeed; a third legal-shape revert is rejected
    /// with the exact Arabic ValidationFailure and leaves the order
    /// untouched.
    Future<void> expectMaxTwoRevertsEnforced(OrderRepository repo) async {
      await repo.createOrder(orderWithStatus(orderId, OrderStatus.pending));

      // Revert #1: ready → preparing (legal).
      await repo.updateOrderStatus(orderId, OrderStatus.ready);
      final first = await repo.revertStatus(
        orderId,
        OrderStatus.preparing,
        actorId: 'chef-a',
      );
      expect(first.isRight, isTrue);
      expect(
        (first as Right<Failure, OrderEntity>).value.status,
        OrderStatus.preparing,
      );

      // Revert #2: served → ready (legal).
      await repo.updateOrderStatus(orderId, OrderStatus.served);
      final second = await repo.revertStatus(
        orderId,
        OrderStatus.ready,
        actorId: 'chef-b',
      );
      expect(second.isRight, isTrue);
      expect(
        (second as Right<Failure, OrderEntity>).value.status,
        OrderStatus.ready,
      );

      // Revert #3: legal shape (ready → preparing) but the quota is spent.
      final third = await repo.revertStatus(
        orderId,
        OrderStatus.preparing,
        actorId: 'chef-c',
      );
      expect(third.isLeft, isTrue);
      final failure = (third as Left<Failure, OrderEntity>).value;
      expect(failure, isA<ValidationFailure>());
      expect(
        failure.message,
        'تم تجاوز الحد المسموح للتراجع عن هذا الطلب (مرتان كحد أقصى)',
      );

      // Order keeps its pre-rejection status and only two audit rows exist.
      final orders = await repo.getOrders();
      expect(
        (orders as Right<Failure, List<OrderEntity>>).value.first.status,
        OrderStatus.ready,
      );
      final trail = await repo.getAuditTrail(orderId);
      expect(
        (trail as Right<Failure, List<OrderStatusLogEntry>>).value,
        hasLength(2),
      );
    }

    test('InMemory rejects the third revert', () async {
      await expectMaxTwoRevertsEnforced(InMemoryOrderRepository());
    });

    test('Hive rejects the third revert (offline)', () async {
      final box = await Hive.openBox<String>('orders_max_revert_box_test');
      await box.clear();
      await expectMaxTwoRevertsEnforced(
        HiveOrderRepository(LocalCacheService(box)),
      );
    });
  });
}
