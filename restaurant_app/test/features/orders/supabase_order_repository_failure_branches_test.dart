import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:restaurant_app/core/data/local_cache_service.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/orders/data/repositories/supabase_order_repository.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_status_log_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Builds a minimal order for the offline failure-branch scenarios.
OrderEntity _order(String id) => OrderEntity(
  id: id,
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

/// Cache key used by [SupabaseOrderRepository] (`_cacheKey` is private).
const String _ordersCacheKey = 'orders_v1';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('supabase_repo_fail_branch');
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

  // Loopback refusals can take multiple seconds on firewalled hosts
  // (observed errno 1225 delays up to ~15 s); give every test ample headroom.
  const testTimeout = Timeout.factor(6);

  group('SupabaseOrderRepository offline failure branches', () {
    // Port 9 (discard protocol) on loopback: connection is refused
    // deterministically without any network egress (same pattern as the
    // realtime integrity suite).
    final supabase = SupabaseClient('http://127.0.0.1:9', 'offline-anon');

    late LocalCacheService cache;
    late SupabaseOrderRepository repo;

    setUp(() async {
      final box = await Hive.openBox<String>('supabase_fail_branch_box');
      await box.clear();
      cache = LocalCacheService(box);
      repo = SupabaseOrderRepository(supabase: supabase, cache: cache);
    });

    test(
      'createOrder returns Left(ServerFailure) AND still caches the order locally',
      timeout: testTimeout,
      () async {
        final result = await repo.createOrder(_order('ORD-OFFLINE-1'));

        expect(result.isLeft, isTrue);
        final failure = (result as Left<Failure, OrderEntity>).value;
        expect(failure, isA<ServerFailure>());

        // The order must NOT be lost: it survives in the local cache...
        final cachedRows = cache.readList(_ordersCacheKey);
        expect(
          cachedRows.map((row) => row['id']),
          contains('ORD-OFFLINE-1'),
          reason: 'failed remote creates must still be persisted locally',
        );

        // ...and round-trips back into a valid domain entity.
        final restored = OrderEntity.fromJson(
          cachedRows.firstWhere((row) => row['id'] == 'ORD-OFFLINE-1'),
        );
        expect(restored.id, 'ORD-OFFLINE-1');
        expect(restored.totalAmount, 115.0);
      },
    );

    test(
      'claimOrder failure returns Left(ServerFailure) without crashing',
      timeout: testTimeout,
      () async {
        final result = await repo.claimOrder('ORD-GHOST-1', 'chef-1');

        expect(result.isLeft, isTrue);
        expect(
          (result as Left<Failure, OrderEntity>).value,
          isA<ServerFailure>(),
        );
      },
    );

    test(
      'updateOrderStatus failure returns Left(ServerFailure) without crashing',
      timeout: testTimeout,
      () async {
        final result = await repo.updateOrderStatus(
          'ORD-GHOST-2',
          OrderStatus.preparing,
        );

        expect(result.isLeft, isTrue);
        result.when(
          onLeft: (failure) => expect(failure, isA<ServerFailure>()),
          onRight: (_) =>
              fail('updateOrderStatus must not succeed while offline'),
        );
      },
    );

    test(
      'getAuditTrail failure returns Left(ServerFailure) without crashing',
      timeout: testTimeout,
      () async {
        final result = await repo.getAuditTrail('ORD-GHOST-3');

        expect(result.isLeft, isTrue);
        expect(
          (result as Left<Failure, List<OrderStatusLogEntry>>).value,
          isA<ServerFailure>(),
        );
      },
    );

    test(
      'getOrders falls back to the local cache when the remote fetch fails after priming',
      timeout: testTimeout,
      () async {
        // Prime the cache exactly as an earlier successful sync would have.
        await cache.writeList(_ordersCacheKey, [
          _order('ORD-CACHED-1').toJson(),
        ]);

        final result = await repo.getOrders();

        // Offline reads degrade gracefully to cache instead of failing.
        expect(
          result.isRight,
          isTrue,
          reason: 'getOrders must serve cached data when remote fails',
        );
        final orders = (result as Right<Failure, List<OrderEntity>>).value;
        expect(orders.map((o) => o.id), contains('ORD-CACHED-1'));
        expect(orders.single.totalAmount, 115.0);
      },
    );

    test(
      'end-to-end offline flow: failed create is still readable via getOrders cache fallback',
      timeout: testTimeout,
      () async {
        final createResult = await repo.createOrder(_order('ORD-OFFLINE-2'));
        expect(createResult.isLeft, isTrue);

        final listResult = await repo.getOrders();
        expect(listResult.isRight, isTrue);
        final orders = (listResult as Right<Failure, List<OrderEntity>>).value;
        expect(orders.map((o) => o.id), contains('ORD-OFFLINE-2'));
      },
    );
  });
}
