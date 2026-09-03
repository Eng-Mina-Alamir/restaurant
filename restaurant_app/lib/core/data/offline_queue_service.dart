import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../utils/logger.dart';

/// Offline operations queue backed by a persistent Hive box with seamless
/// in-memory fallback when Hive is uninitialized (e.g. pure unit test runners).
///
/// Hardening guarantees:
/// * **FIFO replay** — entries are drained in enqueue order (timestamp+seq key).
/// * **Poison protection** — entries that repeatedly fail are retried with
///   exponential backoff and dead-lettered (dropped with a loud log) after
///   [drain]'s `maxAttempts`, so one permanently-broken payload can never
///   block the queue forever.
class OfflineQueueService {
  static const String _boxName = 'offline_queue';

  /// Creates the queue.
  ///
  /// [maxAttempts] and [baseBackoff] control poison-message handling:
  /// entries failing [maxAttempts] times are dead-lettered, with exponential
  /// waits of [baseBackoff]×2ⁿ between attempts. Tests typically pass
  /// `baseBackoff: Duration.zero` for deterministic behavior.
  OfflineQueueService({
    this.maxAttempts = 5,
    this.baseBackoff = const Duration(seconds: 2),
  });

  final int maxAttempts;
  final Duration baseBackoff;

  Box<String>? _box;
  final Map<String, String> _memoryQueue = {};

  /// Number of operations dead-lettered (permanently dropped) so far.
  int get deadLetteredCount => _deadLettered;
  int _deadLettered = 0;

  /// Opens the Hive box. Must be called once before using the service.
  ///
  /// Safe to call multiple times (idempotent).
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    try {
      _box = await Hive.openBox<String>(_boxName);
      AppLogger.info(
        'OfflineQueueService: Opened box – ${_box!.length} pending ops',
      );
    } catch (e) {
      // Falling back to memory means queued ops die with the process — this
      // must never happen silently.
      _box = null;
      AppLogger.warning(
        'OfflineQueueService: Hive init failed ($e). '
        'Queue degraded to volatile in-memory mode; pending ops will be lost '
        'if the app is killed.',
      );
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

      final values = _box != null && _box!.isOpen
          ? _box!.values
          : _memoryQueue.values;
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
      final key =
          '${DateTime.now().microsecondsSinceEpoch}_${seq}_$operationType';
      final value = jsonEncode({
        'type': operationType,
        'payload': payload,
        'idempotencyKey': ?idempotencyKey,
        'attempts': 0,
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
    Future<bool> Function(String operationType, Map<String, dynamic> payload)
    handler,
  ) => drain(handler);

  /// Replays all due pending operations by calling [handler] for each entry,
  /// strictly in FIFO order.
  ///
  /// Entries whose handler returns `true` are removed.
  /// Entries that fail get an attempt counter; after [maxAttempts] failures
  /// they are dead-lettered (removed + logged + [onDeadLetter]).
  /// Between attempts an exponential backoff delay applies, so flapping
  /// connectivity cannot cause infinite hot retry loops. Per-call overrides
  /// fall back to the constructor-configured values.
  ///
  /// Returns the number of successfully replayed operations.
  Future<int> drain(
    Future<bool> Function(String type, Map<String, dynamic> payload) handler, {
    int? maxAttempts,
    Duration? baseBackoff,
    void Function(String type, Map<String, dynamic> payload, int attempts)?
    onDeadLetter,
  }) async {
    final effectiveMaxAttempts = maxAttempts ?? this.maxAttempts;
    final effectiveBaseBackoff = baseBackoff ?? this.baseBackoff;
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    final useBox = _box != null && _box!.isOpen;

    // FIFO: keys are "<micros>_<seq>_<type>" — sort numerically by timestamp.
    final keys = <String>[...(useBox ? _box!.keys : _memoryQueue.keys)]
      ..sort(_compareQueueKeys);
    var replayed = 0;
    var skippedForBackoff = 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    Future<void> deleteKey(String key) async =>
        useBox ? _box!.delete(key) : _memoryQueue.remove(key);
    Future<void> putEntry(String key, String value) async =>
        useBox ? _box!.put(key, value) : _memoryQueue[key] = value;

    for (final key in keys) {
      final raw = useBox ? _box!.get(key) : _memoryQueue[key];
      if (raw == null) continue;

      Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(raw) as Map<String, dynamic>;
      } on FormatException catch (e) {
        // Unparseable entry can never succeed — drop it instead of blocking.
        AppLogger.error('OfflineQueueService: Dropping corrupt entry $key: $e');
        await deleteKey(key);
        continue;
      }

      final type = decoded['type'] as String? ?? '';
      final payload = decoded['payload'];
      if (type.isEmpty || payload is! Map<String, dynamic>) {
        AppLogger.error('OfflineQueueService: Dropping malformed entry $key');
        await deleteKey(key);
        continue;
      }

      // Respect backoff: not yet due.
      final nextAttemptAt = (decoded['nextAttemptAt'] as num?)?.toInt() ?? 0;
      if (nextAttemptAt > now) {
        skippedForBackoff++;
        continue;
      }

      bool success;
      try {
        success = await handler(type, payload);
      } catch (e) {
        AppLogger.warning(
          'OfflineQueueService: handler threw for $type ($key): $e',
        );
        success = false;
      }

      if (success) {
        await deleteKey(key);
        replayed++;
        continue;
      }

      // Failure path: count attempt, back off, or dead-letter.
      final attempts = ((decoded['attempts'] as num?)?.toInt() ?? 0) + 1;
      if (attempts >= effectiveMaxAttempts) {
        await deleteKey(key);
        _deadLettered++;
        AppLogger.error(
          'OfflineQueueService: DEAD-LETTERED $type ($key) after $attempts '
          'attempts. Payload: ${jsonEncode(payload)}',
        );
        onDeadLetter?.call(type, payload, attempts);
        continue;
      }

      decoded['attempts'] = attempts;
      decoded['nextAttemptAt'] =
          now + _backoffDelay(attempts, effectiveBaseBackoff).inMilliseconds;
      await putEntry(key, jsonEncode(decoded));
      AppLogger.info(
        'OfflineQueueService: $type failed (attempt $attempts/$effectiveMaxAttempts); '
        'retrying after backoff',
      );
    }

    AppLogger.info(
      'OfflineQueueService: Drain complete – $replayed replayed, '
      '$skippedForBackoff awaiting backoff, ${keys.length} seen',
    );
    return replayed;
  }

  /// Exponential backoff: base, base×2, base×4, ... capped at 5 minutes.
  Duration _backoffDelay(int attempts, Duration base) {
    if (base <= Duration.zero) return Duration.zero;
    final multiplier = 1 << (min(attempts, 8) - 1);
    final capped = min(
      base.inMilliseconds * multiplier,
      const Duration(minutes: 5).inMilliseconds,
    );
    return Duration(milliseconds: capped);
  }

  /// Test hook: injects a raw (possibly corrupt) entry into the active store.
  @visibleForTesting
  Future<void> debugInjectRaw(String rawValue) async {
    if (_box == null || !_box!.isOpen) await init();
    final key = '${DateTime.now().microsecondsSinceEpoch}_${++_seq}_corrupt';
    if (_box != null && _box!.isOpen) {
      await _box!.put(key, rawValue);
    } else {
      _memoryQueue[key] = rawValue;
    }
  }

  /// Numeric comparator over `"<micros>_<seq>_<type>"` queue keys so replay
  /// order matches enqueue order regardless of Hive's internal ordering.
  static int _compareQueueKeys(String a, String b) {
    final aTs = int.tryParse(a.split('_').first) ?? 0;
    final bTs = int.tryParse(b.split('_').first) ?? 0;
    if (aTs != bTs) return aTs.compareTo(bTs);
    final aSeq = int.tryParse(a.split('_').elementAt(1)) ?? 0;
    final bSeq = int.tryParse(b.split('_').elementAt(1)) ?? 0;
    return aSeq.compareTo(bSeq);
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

final pendingSyncCountProvider = Provider<int>((ref) {
  return ref.watch(offlineQueueServiceProvider).pendingCount;
});
