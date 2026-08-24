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

    test(
      'drainWith replays items and deletes when handler returns true',
      () async {
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
      },
    );

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

    group('hardening: FIFO, poison protection, backoff', () {
      test('drain replays entries in strict FIFO order', () async {
        final order = <String>[];
        for (var i = 1; i <= 5; i++) {
          await service.enqueue(
            operationType: 'createOrder',
            payload: {'orderId': 'ORD-$i'},
          );
        }

        await service.drainWith((type, payload) async {
          order.add(payload['orderId'] as String);
          return true;
        });

        expect(order, ['ORD-1', 'ORD-2', 'ORD-3', 'ORD-4', 'ORD-5']);
      });

      test(
        'permanently failing entries are dead-lettered after maxAttempts',
        () async {
          await service.enqueue(
            operationType: 'createOrder',
            payload: {'orderId': 'ORD-POISON'},
            idempotencyKey: 'poison-key',
          );

          final deadLettered = <Map<String, dynamic>>[];
          var attempts = 0;

          // Zero backoff so each drain performs exactly one attempt.
          for (var i = 0; i < 3; i++) {
            final replayed = await service.drain(
              (type, payload) async {
                attempts++;
                return false;
              },
              maxAttempts: 4,
              baseBackoff: Duration.zero,
            );
            expect(replayed, 0);
            expect(
              service.pendingCount,
              1,
              reason: 'Entry must stay queued while under maxAttempts',
            );
          }
          expect(attempts, 3);
          expect(service.deadLetteredCount, 0);

          // Fourth failure crosses maxAttempts=4 → dead-lettered and removed.
          final replayed = await service.drain(
            (type, payload) async => false,
            maxAttempts: 4,
            baseBackoff: Duration.zero,
            onDeadLetter: (type, payload, attemptCount) =>
                deadLettered.add(payload),
          );

          expect(replayed, 0);
          expect(service.deadLetteredCount, 1);
          expect(
            service.hasPending,
            isFalse,
            reason: 'Dead-lettered entries must be removed from the queue',
          );
          expect(deadLettered.single['orderId'], 'ORD-POISON');
        },
      );

      test(
        'entries inside their backoff window are skipped, not lost',
        () async {
          await service.enqueue(
            operationType: 'createOrder',
            payload: {'orderId': 'ORD-BACKOFF'},
          );

          var calls = 0;
          // Default 2s base backoff: first failure arms a retry delay.
          await service.drain((type, payload) async {
            calls++;
            return false;
          }, maxAttempts: 99);
          expect(calls, 1);

          // Immediate second drain: entry exists but is not yet due.
          await service.drain((type, payload) async {
            calls++;
            return false;
          }, maxAttempts: 99);

          expect(
            calls,
            1,
            reason: 'Backed-off entries must be skipped until due',
          );
          expect(
            service.pendingCount,
            1,
            reason: 'Skipped entries must be retained',
          );
        },
      );

      test(
        'corrupt JSON entries are dropped instead of blocking the queue',
        () async {
          await service.enqueue(
            operationType: 'createOrder',
            payload: {'orderId': 'ORD-GOOD'},
          );
          await service.debugInjectRaw('{corrupt json!!');

          var processed = 0;
          final replayed = await service.drainWith((type, payload) async {
            processed++;
            return true;
          });

          expect(processed, 1, reason: 'Only the healthy entry is replayed');
          expect(replayed, 1);
          expect(service.hasPending, isFalse);
        },
      );
    });
  });
}
