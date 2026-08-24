import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:restaurant_app/core/data/offline_queue_service.dart';

void main() {
  late Directory tempDir;
  late OfflineQueueService service;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_idempotency_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    service = OfflineQueueService();
    await service.init();
    await service.clear();
  });

  tearDown(() async {
    await service.close();
  });

  group('Offline Queue Idempotency Tests', () {
    test('enqueue with unique idempotencyKey adds new item', () async {
      final added = await service.enqueue(
        operationType: 'createOrder',
        payload: {'orderId': 'ORD-999', 'subtotal': 120.0},
        idempotencyKey: 'idem-ord-999',
      );

      expect(added, isTrue);
      expect(service.pendingCount, 1);
    });

    test(
      'enqueue with duplicate idempotencyKey ignores duplicate entry',
      () async {
        final first = await service.enqueue(
          operationType: 'createOrder',
          payload: {'orderId': 'ORD-1000', 'subtotal': 50.0},
          idempotencyKey: 'idem-ord-1000',
        );
        expect(first, isTrue);
        expect(service.pendingCount, 1);

        // Attempt duplicate enqueue with same idempotencyKey
        final duplicate = await service.enqueue(
          operationType: 'createOrder',
          payload: {'orderId': 'ORD-1000', 'subtotal': 50.0},
          idempotencyKey: 'idem-ord-1000',
        );
        expect(duplicate, isFalse);
        expect(service.pendingCount, 1); // Remains 1!
      },
    );

    test('different idempotency keys are both accepted and enqueued', () async {
      final added1 = await service.enqueue(
        operationType: 'createOrder',
        payload: {'orderId': 'ORD-1'},
        idempotencyKey: 'key-1',
      );
      final added2 = await service.enqueue(
        operationType: 'createOrder',
        payload: {'orderId': 'ORD-2'},
        idempotencyKey: 'key-2',
      );

      expect(added1, isTrue);
      expect(added2, isTrue);
      expect(service.pendingCount, 2);
    });
  });
}
