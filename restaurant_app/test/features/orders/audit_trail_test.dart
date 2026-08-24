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
    tempDir = Directory.systemTemp.createTempSync('audit_trail_test');
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

  /// Seeds two guarded reverts on [orderId] (ready→preparing, then
  /// served→ready) and one revert on a sibling order, proving per-order
  /// filtering.
  Future<void> seedReverts(OrderRepository repo, String orderId) async {
    await repo.createOrder(orderWithStatus(orderId, OrderStatus.pending));
    await repo.createOrder(orderWithStatus('ORD-OTHER', OrderStatus.pending));

    // Sibling order gets its own revert entry.
    await repo.updateOrderStatus('ORD-OTHER', OrderStatus.ready);
    await repo.revertStatus(
      'ORD-OTHER',
      OrderStatus.preparing,
      actorId: 'chef-x',
    );

    // Target order: two sequential reverts.
    await repo.updateOrderStatus(orderId, OrderStatus.ready);
    await repo.revertStatus(
      orderId,
      OrderStatus.preparing,
      actorId: 'chef-a',
      reason: 'تم التجهيز بالخطأ',
    );
    await repo.updateOrderStatus(orderId, OrderStatus.served);
    await repo.revertStatus(orderId, OrderStatus.ready, actorId: 'chef-b');
  }

  void expectTrailMatchesSeed(List<OrderStatusLogEntry> trail, String orderId) {
    // Only this order's entries are returned, oldest first (append order).
    expect(trail, hasLength(2));
    expect(trail.every((e) => e.orderId == orderId), isTrue);
    expect(trail.every((e) => e.isRevert), isTrue);

    final first = trail[0];
    expect(first.fromStatus, OrderStatus.ready);
    expect(first.toStatus, OrderStatus.preparing);
    expect(first.actorId, 'chef-a');
    expect(first.reason, 'تم التجهيز بالخطأ');

    final second = trail[1];
    expect(second.fromStatus, OrderStatus.served);
    expect(second.toStatus, OrderStatus.ready);
    expect(second.actorId, 'chef-b');

    expect(
      first.createdAt.isAfter(second.createdAt),
      isFalse,
      reason: 'entries must be ordered oldest-first by created_at',
    );
  }

  group('getAuditTrail (local repositories)', () {
    test(
      'InMemoryOrderRepository returns seeded entries oldest-first',
      () async {
        final repo = InMemoryOrderRepository();
        await seedReverts(repo, 'ORD-AUDIT-1');

        final res = await repo.getAuditTrail('ORD-AUDIT-1');
        expect(res.isRight, isTrue);
        final trail = (res as Right<Failure, List<OrderStatusLogEntry>>).value;
        expectTrailMatchesSeed(trail, 'ORD-AUDIT-1');
      },
    );

    test('HiveOrderRepository returns seeded entries oldest-first', () async {
      final box = await Hive.openBox<String>('audit_trail_box_test');
      await box.clear();
      final repo = HiveOrderRepository(LocalCacheService(box));

      await seedReverts(repo, 'ORD-AUDIT-2');

      final res = await repo.getAuditTrail('ORD-AUDIT-2');
      expect(res.isRight, isTrue);
      final trail = (res as Right<Failure, List<OrderStatusLogEntry>>).value;
      expectTrailMatchesSeed(trail, 'ORD-AUDIT-2');
    });

    test(
      'InMemoryOrderRepository returns empty trail for unknown order',
      () async {
        final repo = InMemoryOrderRepository();
        await seedReverts(repo, 'ORD-AUDIT-3');

        final res = await repo.getAuditTrail('ORD-UNKNOWN');
        expect(res.isRight, isTrue);
        expect(
          (res as Right<Failure, List<OrderStatusLogEntry>>).value,
          isEmpty,
        );
      },
    );

    test('HiveOrderRepository returns empty trail for unknown order', () async {
      final box = await Hive.openBox<String>('audit_trail_unknown_box_test');
      await box.clear();
      final repo = HiveOrderRepository(LocalCacheService(box));

      await seedReverts(repo, 'ORD-AUDIT-4');

      final res = await repo.getAuditTrail('ORD-UNKNOWN');
      expect(res.isRight, isTrue);
      expect((res as Right<Failure, List<OrderStatusLogEntry>>).value, isEmpty);
    });
  });
}
