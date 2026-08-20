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

    test('HiveOrderRepository creates and retrieves orders via LocalCacheService', () async {
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
    });
  });
}
