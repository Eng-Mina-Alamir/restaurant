import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/app_cache.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_controller.dart';

/// Persistence seam for per-user/per-order read receipts.
///
/// Implementations:
/// - [InMemoryChatReadStateStore] — session-only fallback (used when no Hive
///   cache is available, and as the hermetic fake in tests).
/// - [LocalCacheChatReadStateStore] — Hive-backed via [LocalCacheService];
///   survives app restarts.
abstract class ChatReadStateStore {
  /// Returns the ISO-8601 last-read timestamp for this user+order thread, or
  /// null when the thread was never opened.
  String? readLastReadAt({required String userId, required String orderId});

  Future<void> writeLastReadAt({
    required String userId,
    required String orderId,
    required DateTime at,
  });
}

/// Volatile implementation: counts reset on restart by definition.
class InMemoryChatReadStateStore implements ChatReadStateStore {
  final Map<String, DateTime> _lastReadAt = {};

  String _key(String userId, String orderId) => '$userId\u0000$orderId';

  @override
  String? readLastReadAt({required String userId, required String orderId}) {
    final at = _lastReadAt[_key(userId, orderId)];
    return at?.toIso8601String();
  }

  @override
  Future<void> writeLastReadAt({
    required String userId,
    required String orderId,
    required DateTime at,
  }) async {
    _lastReadAt[_key(userId, orderId)] = at;
  }
}

/// Hive-backed implementation. When [cache] is null (cache not initialized —
/// e.g. very early startup or test harnesses) every operation degrades to a
/// no-op so callers never crash; combine with [InMemoryChatReadStateStore]
/// semantics by falling back at the provider level instead when possible.
class LocalCacheChatReadStateStore implements ChatReadStateStore {
  LocalCacheChatReadStateStore(this._cache);

  final LocalCacheService? _cache;

  static String _key(String userId, String orderId) =>
      'chat_last_read_${userId}_$orderId';

  @override
  String? readLastReadAt({required String userId, required String orderId}) {
    final cache = _cache;
    if (cache == null) return null;
    try {
      return cache.readString(_key(userId, orderId));
    } catch (e) {
      AppLogger.warning('ChatReadState: read failed ($e); treating as unread');
      return null;
    }
  }

  @override
  Future<void> writeLastReadAt({
    required String userId,
    required String orderId,
    required DateTime at,
  }) async {
    final cache = _cache;
    if (cache == null) return;
    try {
      await cache.writeString(_key(userId, orderId), at.toIso8601String());
    } catch (e) {
      AppLogger.warning('ChatReadState: write failed ($e); badge may '
          'recount after restart');
    }
  }
}

/// Unread-message counters for order chat threads.
///
/// One counter per [unreadChatCountProvider] instance (family keyed by
/// order id). Each counter subscribes to [ChatRepository.watch] exactly once.
/// The first emission establishes the baseline: pre-existing messages are
/// counted as unread ONLY when their [ChatMessage.createdAt] is newer than
/// the persisted last-read receipt ([ChatReadStateStore]) — so messages that
/// arrived while the app was closed survive a restart. Every newly arriving
/// message authored by someone other than the current device user
/// ([chatCurrentUserIdProvider]) increments the count. [markRead] resets the
/// count to zero AND persists the receipt — the thread page calls it on entry
/// and exit so opening the conversation clears its badge permanently.
///
/// v1 limitation retained where timestamps are missing: messages without a
/// parseable createdAt can only be classified from live traffic onward.
/// When no cache service is bound ([localCacheServiceProvider] yields null)
/// the store falls back to in-memory behavior — badge becomes a session hint.
class UnreadChatController extends StateNotifier<int> {
  UnreadChatController({
    required ChatRepository repository,
    required String Function() currentUserId,
    ChatReadStateStore? readStateStore,
  })  : _repository = repository,
        _currentUserId = currentUserId,
        _readStateStore = readStateStore ?? InMemoryChatReadStateStore(),
        super(0);

  final ChatRepository _repository;
  final String Function() _currentUserId;
  final ChatReadStateStore _readStateStore;

  StreamSubscription<List<ChatMessage>>? _subscription;

  /// Order id bound in [start]; needed for the persistence key.
  String? _orderId;

  /// Message ids already classified, so repeated full-list snapshots from the
  /// watch stream never recount old messages after a [markRead].
  final Set<String> _seenMessageIds = <String>{};

  /// Whether the history-first baseline snapshot has been consumed.
  bool _hasBaseline = false;

  /// Binds this counter to an order's live feed. Called once by the provider
  /// factory at construction.
  void start(String orderId) {
    _orderId = orderId;
    _subscription = _repository.watch(orderId).listen(
          _onMessages,
          // The badge degrades gracefully to a possibly-stale count instead
          // of crashing the app; the thread page surfaces stream failures
          // itself through ChatController's error state.
          onError: (Object _, StackTrace __) {},
        );
  }

  Future<void> _onMessages(List<ChatMessage> messages) async {
    // The watch subscription may deliver an in-flight event while the
    // provider is being torn down.
    if (!mounted) return;

    final currentUserId = _currentUserId();
    var unread = state;

    if (!_hasBaseline) {
      _hasBaseline = true;
      final persisted =
          _readStateStore.readLastReadAt(userId: currentUserId, orderId: _orderId!);
      final lastReadAt =
          persisted == null ? null : DateTime.tryParse(persisted)?.toLocal();
      for (final message in messages) {
        _seenMessageIds.add(message.id);
        if (_isUnreadOnBaseline(message, lastReadAt, currentUserId)) {
          unread += 1;
        }
      }
      state = unread;
      return;
    }

    for (final message in messages) {
      if (_seenMessageIds.add(message.id) &&
          message.senderId != currentUserId) {
        unread += 1;
      }
    }
    state = unread;
  }

  /// Baseline classification: a pre-existing message is "unread" only when it
  /// is foreign-authored AND provably newer than the persisted receipt.
  bool _isUnreadOnBaseline(
    ChatMessage message,
    DateTime? lastReadAt,
    String currentUserId,
  ) {
    if (message.senderId == currentUserId) return false;
    if (lastReadAt == null || message.createdAt == null) return false;
    return message.createdAt!.isAfter(lastReadAt);
  }

  /// Clears the unread count for this order and persists the receipt
  /// (idempotent). Safe to call after disposal (e.g. from a deferred
  /// page-dispose hook): it becomes a no-op for the counter while still
  /// attempting the receipt write.
  void markRead() {
    final orderId = _orderId;
    if (orderId != null) {
      unawaited(_persistReceipt(orderId));
    }
    if (!mounted) return;
    state = 0;
  }

  Future<void> _persistReceipt(String orderId) async {
    try {
      await _readStateStore.writeLastReadAt(
        userId: _currentUserId(),
        orderId: orderId,
        at: DateTime.now(),
      );
    } catch (e) {
      AppLogger.warning('ChatReadState: receipt persist failed ($e)');
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}

/// Read-receipt store binding: Hive-backed when the app cache is initialized,
/// degrading to in-memory semantics otherwise. Override in tests to inject
/// [InMemoryChatReadStateStore] instances shared across simulated sessions.
final chatReadStateStoreProvider = Provider<ChatReadStateStore>((ref) {
  return LocalCacheChatReadStateStore(ref.watch(localCacheServiceProvider));
});

/// Unread-message badge count for one order's chat thread (v2: read receipts
/// persist through the [chatReadStateStoreProvider] store when available, so
/// counts survive restarts; with no cache bound the behavior degrades to the
/// v1 session-scoped hint).
///
/// The provider element disposes the [StateNotifier] itself, whose overridden
/// [UnreadChatController.dispose] cancels the watch subscription.
final unreadChatCountProvider =
    StateNotifierProvider.family<UnreadChatController, int, String>((
  ref,
  orderId,
) {
  return UnreadChatController(
    repository: ref.watch(chatRepositoryProvider),
    currentUserId: () => ref.read(chatCurrentUserIdProvider),
    readStateStore: ref.watch(chatReadStateStoreProvider),
  )..start(orderId);
});
