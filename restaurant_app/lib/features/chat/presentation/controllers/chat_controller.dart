import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/in_memory_chat_repository.dart';
import '../../data/repositories/supabase_chat_repository.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

/// Shared [ChatRepository].
///
/// Uses the live Supabase backend when enabled, otherwise the in-memory store
/// for demo mode / tests (same gate pattern as `deliveryRepositoryProvider`).
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (AppConfig.useSupabase) {
    return SupabaseChatRepository(
      supabase: ref.watch(supabaseClientProvider),
    );
  }
  return InMemoryChatRepository();
});

/// Author id stamped on messages sent from this device.
///
/// Falls back to a demo identity when no Supabase session exists so the
/// customer ↔ driver conversation works in local/demo mode.
final chatCurrentUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(supabaseCurrentUserProvider);
  return user?.id ?? 'customer-demo';
});

/// Manages one order-scoped conversation: history-first load, live updates
/// via [ChatRepository.watch], and validated sends.
///
/// Messages are always exposed sorted oldest-first so the page can render
/// them top-to-bottom without re-sorting.
class ChatController extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  ChatController(this._repository) : super(const AsyncLoading());

  final ChatRepository _repository;

  String? _orderId;
  String _currentUserId = '';
  StreamSubscription<List<ChatMessage>>? _subscription;

  @visibleForTesting
  String? get orderId => _orderId;

  /// Binds the controller to an order's thread. Safe to call again with the
  /// same order — re-binding only happens when the order changes.
  void init(String orderId, String currentUserId) {
    _currentUserId = currentUserId;
    if (_orderId == orderId) return;
    _orderId = orderId;
    _listen();
  }

  void _listen() {
    final orderId = _orderId;
    if (orderId == null) return;
    unawaited(_subscription?.cancel());
    _subscription = _repository.watch(orderId).listen(
          (messages) => state = AsyncData(_sortedOldestFirst(messages)),
          onError: (Object error, StackTrace stackTrace) {
            state = AsyncError(error, stackTrace);
          },
        );
  }

  /// Reloads the thread from scratch (used by the error view's retry).
  void retry() {
    state = const AsyncLoading();
    if (_orderId != null) _listen();
  }

  /// Validates and persists [text] as the current user.
  ///
  /// Returns the localized failure message when rejected, or null on success
  /// (the persisted message flows into state through the watch stream, with a
  /// direct merge as a fast path so the bubble appears immediately).
  Future<String?> send(String text) async {
    final trimmed = text.trim();
    final message = ChatMessage(
      id: '',
      orderId: _orderId ?? '',
      senderId: _currentUserId,
      body: trimmed,
    );
    if (!message.isValidBody || _orderId == null || _currentUserId.isEmpty) {
      return 'الرسالة فارغة أو تتجاوز الحد الأقصى للطول';
    }
    final Either<Failure, ChatMessage> result = await _repository.send(message);
    return result.when(
      onLeft: (failure) => failure.message,
      onRight: (persisted) {
        _merge(persisted);
        return null;
      },
    );
  }

  /// Fast-path append of a just-sent message; dedupes by id because the watch
  /// stream will also deliver it once the repository echoes back.
  void _merge(ChatMessage persisted) {
    final current = state.valueOrNull ?? const <ChatMessage>[];
    if (current.any((m) => m.id == persisted.id)) return;
    state = AsyncData(_sortedOldestFirst([...current, persisted]));
  }

  static List<ChatMessage> _sortedOldestFirst(Iterable<ChatMessage> messages) {
    final list = messages.toList();
    list.sort((a, b) {
      final aCreated = a.createdAt;
      final bCreated = b.createdAt;
      if (aCreated == null && bCreated == null) return 0;
      if (aCreated == null) return -1;
      if (bCreated == null) return 1;
      return aCreated.compareTo(bCreated);
    });
    return List.unmodifiable(list);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}

/// Provider for the conversation of one order (auto-dispose: lives only while
/// a chat page watches it).
final chatControllerProvider = StateNotifierProvider.autoDispose.family<
    ChatController, AsyncValue<List<ChatMessage>>, String>(
  (ref, orderId) => ChatController(ref.watch(chatRepositoryProvider)),
);
