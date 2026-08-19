import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../utils/logger.dart';

/// A lightweight Hive-backed queue that stores serialized operation payloads
/// for later replay when network connectivity is restored.
///
/// Usage pattern:
/// 1. When offline: call [enqueue] with the JSON payload of the operation.
/// 2. When online:  call [drainWith] to replay all queued operations.
class OfflineQueueService {
  static const String _boxName = 'offline_queue';

  Box<String>? _box;

  /// Opens the Hive box. Must be called once before using the service.
  ///
  /// Safe to call multiple times (idempotent).
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    try {
      _box = await Hive.openBox<String>(_boxName);
      AppLogger.info('OfflineQueueService: Opened box – ${_box!.length} pending ops');
    } catch (e) {
      AppLogger.error('OfflineQueueService: Failed to open box: $e');
    }
  }

  /// Returns true if there are pending queued operations.
  bool get hasPending => (_box?.length ?? 0) > 0;

  /// Number of queued operations.
  int get pendingCount => _box?.length ?? 0;

  /// Enqueues a JSON-serializable [payload] for later replay.
  ///
  /// [operationType] is a string tag such as `'createOrder'` or
  /// `'updateTableStatus'` used to route the operation during drain.
  Future<void> enqueue({
    required String operationType,
    required Map<String, dynamic> payload,
  }) async {
    if (_box == null || !_box!.isOpen) await init();
    final key = '${DateTime.now().millisecondsSinceEpoch}_$operationType';
    final value = jsonEncode({'type': operationType, 'payload': payload});
    await _box?.put(key, value);
    AppLogger.info('OfflineQueueService: Enqueued $operationType – key=$key');
  }

  /// Replays all pending operations by calling [handler] for each entry.
  ///
  /// [handler] receives the operation type and payload. If it returns `true`
  /// the entry is removed from the queue; if `false` it is kept for retry.
  Future<int> drainWith(
    Future<bool> Function(String operationType, Map<String, dynamic> payload)
        handler,
  ) async {
    if (_box == null || !_box!.isOpen) await init();
    if (_box == null) return 0;
    final keys = _box!.keys.toList();
    int replayed = 0;

    for (final key in keys) {
      final raw = _box!.get(key as String);
      if (raw == null) continue;

      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final opType = decoded['type'] as String;
        final payload = decoded['payload'] as Map<String, dynamic>;

        final success = await handler(opType, payload);
        if (success) {
          await _box!.delete(key);
          replayed++;
          AppLogger.info('OfflineQueueService: Replayed $opType – key=$key');
        }
      } catch (e) {
        AppLogger.error('OfflineQueueService: Failed to replay $key: $e');
      }
    }

    AppLogger.info(
      'OfflineQueueService: Drain complete – $replayed/${keys.length} replayed',
    );
    return replayed;
  }

  /// Clears all pending operations (use with caution).
  Future<void> clear() async {
    await _box?.clear();
    AppLogger.info('OfflineQueueService: Queue cleared');
  }

  /// Closes the underlying Hive box.
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}

final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  return OfflineQueueService();
});
