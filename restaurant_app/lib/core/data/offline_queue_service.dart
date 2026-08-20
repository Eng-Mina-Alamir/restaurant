import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../utils/logger.dart';

/// Offline operations queue backed by a persistent Hive box with seamless
/// in-memory fallback when Hive is uninitialized (e.g. pure unit test runners).
class OfflineQueueService {
  static const String _boxName = 'offline_queue';

  Box<String>? _box;
  final Map<String, String> _memoryQueue = {};

  /// Opens the Hive box. Must be called once before using the service.
  ///
  /// Safe to call multiple times (idempotent).
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    try {
      _box = await Hive.openBox<String>(_boxName);
      AppLogger.info('OfflineQueueService: Opened box – ${_box!.length} pending ops');
    } catch (e) {
      _box = null;
    }
  }

  /// Returns true if there are pending queued operations.
  bool get hasPending => (_box?.length ?? _memoryQueue.length) > 0;

  /// Number of queued operations.
  int get pendingCount => _box?.length ?? _memoryQueue.length;

  static int _seq = 0;

  /// Enqueues a JSON-serializable [payload] for later replay.
  ///
  /// [operationType] is a string tag such as `'createOrder'` or
  /// `'updateTableStatus'` used to route the operation during drain.
  /// If [idempotencyKey] is provided, prevents duplicate entries with the same key.
  Future<bool> enqueue({
    required String operationType,
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) async {
    try {
      if (_box == null || !_box!.isOpen) {
        await init();
      }

      final values = _box != null && _box!.isOpen ? _box!.values : _memoryQueue.values;
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        for (final raw in values) {
          try {
            final decoded = jsonDecode(raw) as Map<String, dynamic>;
            if (decoded['idempotencyKey'] == idempotencyKey) {
              AppLogger.info(
                'OfflineQueueService: Duplicate idempotency key $idempotencyKey skipped',
              );
              return false;
            }
          } catch (_) {}
        }
      }

      final seq = ++_seq;
      final key = '${DateTime.now().microsecondsSinceEpoch}_${seq}_$operationType';
      final value = jsonEncode({
        'type': operationType,
        'payload': payload,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      });

      if (_box != null && _box!.isOpen) {
        await _box!.put(key, value);
      } else {
        _memoryQueue[key] = value;
      }
      AppLogger.info('OfflineQueueService: Enqueued $operationType – key=$key');
      return true;
    } catch (e) {
      AppLogger.warning('OfflineQueueService: enqueue failed: $e');
      return false;
    }
  }

  /// Alias for [drain] for backward compatibility.
  Future<int> drainWith(
    Future<bool> Function(String operationType, Map<String, dynamic> payload) handler,
  ) => drain(handler);

  /// Replays all pending operations by calling [handler] for each entry.
  ///
  /// Removes entries that return `true` from [handler].
  /// Returns the number of successfully replayed operations.
  Future<int> drain(
    Future<bool> Function(String type, Map<String, dynamic> payload) handler,
  ) async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }

    if (_box != null && _box!.isOpen) {
      final keys = _box!.keys.toList();
      var replayed = 0;

      for (final key in keys) {
        final raw = _box!.get(key);
        if (raw == null) continue;

        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final type = decoded['type'] as String;
          final payload = decoded['payload'] as Map<String, dynamic>;

          final success = await handler(type, payload);
          if (success) {
            await _box!.delete(key);
            replayed++;
          }
        } catch (e) {
          AppLogger.warning('OfflineQueueService: Failed to replay $key: $e');
        }
      }

      AppLogger.info(
        'OfflineQueueService: Drain complete – $replayed/${keys.length} replayed',
      );
      return replayed;
    } else {
      final keys = _memoryQueue.keys.toList();
      var replayed = 0;

      for (final key in keys) {
        final raw = _memoryQueue[key];
        if (raw == null) continue;

        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final type = decoded['type'] as String;
          final payload = decoded['payload'] as Map<String, dynamic>;

          final success = await handler(type, payload);
          if (success) {
            _memoryQueue.remove(key);
            replayed++;
          }
        } catch (e) {
          AppLogger.warning('OfflineQueueService: Failed to replay $key: $e');
        }
      }

      AppLogger.info(
        'OfflineQueueService: Drain complete – $replayed/${keys.length} replayed',
      );
      return replayed;
    }
  }

  /// Clears all pending operations (use with caution).
  Future<void> clear() async {
    await _box?.clear();
    _memoryQueue.clear();
    AppLogger.info('OfflineQueueService: Queue cleared');
  }

  /// Closes the underlying Hive box.
  Future<void> close() async {
    await _box?.close();
    _box = null;
    _memoryQueue.clear();
  }
}

final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  return OfflineQueueService();
});
