import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:restaurant_app/core/data/local_cache_service.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/orders/data/repositories/hive_order_repository.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/table_management/data/repositories/hive_table_repository.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<LocalCacheService> freshCache() async {
    final box = await Hive.openBox<String>('cache_test');
    await box.clear();
    return LocalCacheService(box);
  }

  test('LocalCacheService round-trips JSON lists', () async {
    final c = await freshCache();
    await c.writeList('k', [
      {'a': 1},
      {'b': 'two'},
    ]);
    final out = c.readList('k');
    expect(out, hasLength(2));
    expect(out[0]['a'], 1);
    expect(out[1]['b'], 'two');
  });

  test('HiveOrderRepository persists orders across instances', () async {
    final c = await freshCache();
    final repoA = HiveOrderRepository(c);
    await repoA.createOrder(_order);

    final repoB = HiveOrderRepository(c);
    final result = await repoB.getOrders();
    final orders = result.when(onLeft: (_) => null, onRight: (o) => o);
    expect(orders, hasLength(1));
    expect(orders!.first.id, _order.id);
  });

  test('HiveTableRepository seeds first use then persists updates', () async {
    final c = await freshCache();
    final repo = HiveTableRepository(c);
    final first = await repo.getTables();
    final tables = first.when(onLeft: (_) => null, onRight: (t) => t);
    expect(tables, isNotEmpty);

    final updated = tables!.first.copyWith(tableNumber: 99);
    await repo.updateTable(updated);

    final second = await repo.getTables();
    final again = second.when(onLeft: (_) => null, onRight: (t) => t);
    expect(again!.firstWhere((t) => t.id == updated.id).tableNumber, 99);
  });
}

final _order = OrderEntity(
  id: 'ORD-0001',
  restaurantId: 'r1',
  orderType: OrderType.delivery,
  status: OrderStatus.pending,
  items: const [],
  subtotal: 0,
  taxAmount: 0,
  totalAmount: 0,
  createdAt: DateTime(2024),
);
