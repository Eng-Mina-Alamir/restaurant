import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:restaurant_app/core/data/offline_queue_service.dart';

void main() {
  late Directory tempDir;
  late OfflineQueueService service;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_queue_test');
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

  group('OfflineQueueService Tests', () {
    test('initial state has no pending items', () {
      expect(service.hasPending, isFalse);
      expect(service.pendingCount, 0);
    });

    test('enqueue adds item to queue', () async {
      await service.enqueue(
        operationType: 'createOrder',
        payload: {'orderId': 'ORD-123', 'amount': 45.0},
      );

      expect(service.hasPending, isTrue);
      expect(service.pendingCount, 1);
    });

    test('drainWith replays items and deletes when handler returns true', () async {
      await service.enqueue(
        operationType: 'createOrder',
        payload: {'orderId': 'ORD-001'},
      );
      await service.enqueue(
        operationType: 'updateTableStatus',
        payload: {'tableId': 'tbl-1', 'status': 'occupied'},
      );

      expect(service.pendingCount, 2);

      final replayedTypes = <String>[];
      final replayedCount = await service.drainWith((type, payload) async {
        replayedTypes.add(type);
        return true; // Successfully processed
      });

      expect(replayedCount, 2);
      expect(replayedTypes, ['createOrder', 'updateTableStatus']);
      expect(service.hasPending, isFalse);
      expect(service.pendingCount, 0);
    });

    test('drainWith retains items when handler returns false', () async {
      await service.enqueue(
        operationType: 'createOrder',
        payload: {'orderId': 'ORD-FAIL'},
      );

      final replayedCount = await service.drainWith((type, payload) async {
        return false; // Failed to replay, keep in queue
      });

      expect(replayedCount, 0);
      expect(service.hasPending, isTrue);
      expect(service.pendingCount, 1);
    });

    test('clear empties the queue', () async {
      await service.enqueue(
        operationType: 'createOrder',
        payload: {'orderId': 'ORD-1'},
      );
      await service.enqueue(
        operationType: 'createOrder',
        payload: {'orderId': 'ORD-2'},
      );

      expect(service.pendingCount, 2);
      await service.clear();
      expect(service.pendingCount, 0);
      expect(service.hasPending, isFalse);
    });
  });
}
