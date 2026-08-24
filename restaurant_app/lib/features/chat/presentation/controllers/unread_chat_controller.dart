import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_controller.dart';

/// Session-scoped unread-message counters for order chat threads.
///
/// One counter per [unreadChatCountProvider] instance (family keyed by
/// order id). Each counter subscribes to [ChatRepository.watch] exactly once,
/// ignores the first emission (the history baseline), then counts every newly
/// arriving message authored by someone other than the current device user
/// ([chatCurrentUserIdProvider]). [UnreadChatController.markRead] resets the
/// count to zero — the thread page calls it on entry and exit so opening the
/// conversation clears its badge.
///
/// v1 limitation (deliberate scope cut): counts are in-memory only. They
/// reset on app restart, and messages that arrived before a given order's
/// counter was first watched cannot be attributed retroactively (the badge
/// only reflects live traffic from subscription time onward). Persisting
/// per-user read receipts is deferred future work — treat the badge as a
/// session hint, not a source of truth.
class UnreadChatController extends StateNotifier<int> {
  UnreadChatController({
    required ChatRepository repository,
    required String Function() currentUserId,
  })  : _repository = repository,
        _currentUserId = currentUserId,
        super(0);

  final ChatRepository _repository;
  final String Function() _currentUserId;

  StreamSubscription<List<ChatMessage>>? _subscription;

  /// Message ids already classified, so repeated full-list snapshots from the
  /// watch stream never recount old messages after a [markRead].
  final Set<String> _seenMessageIds = <String>{};

  /// Whether the history-first baseline snapshot has been consumed; that
  /// first emission is ignored by design (pre-existing history is not
  /// "unread").
  bool _hasBaseline = false;

  /// Binds this counter to an order's live feed. Called once by the provider
  /// factory at construction.
  void start(String orderId) {
    _subscription = _repository.watch(orderId).listen(
          _onMessages,
          // The badge degrades gracefully to a possibly-stale count instead
          // of crashing the app; the thread page surfaces stream failures
          // itself through ChatController's error state.
          onError: (Object _, StackTrace __) {},
        );
  }

  void _onMessages(List<ChatMessage> messages) {
    // The watch subscription may deliver an in-flight event while the
    // provider is being torn down.
    if (!mounted) return;
    if (!_hasBaseline) {
      _hasBaseline = true;
      _seenMessageIds.addAll(messages.map((m) => m.id));
      return;
    }
    final currentUserId = _currentUserId();
    var unread = state;
    for (final message in messages) {
      if (_seenMessageIds.add(message.id) &&
          message.senderId != currentUserId) {
        unread += 1;
      }
    }
    state = unread;
  }

  /// Clears the unread count for this order (idempotent). Safe to call after
  /// disposal (e.g. from a deferred page-dispose hook): it becomes a no-op.
  void markRead() {
    if (!mounted) return;
    state = 0;
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}

/// Unread-message badge count for one order's chat thread (session-scoped:
/// intentionally NOT auto-dispose, so the count survives navigating away from
/// the driver home and back within the same app session).
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
  )..start(orderId);
});
