import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

/// Local/demo binding of [ChatRepository]: in-memory store keyed by order id.
///
/// Used behind the `AppConfig.useSupabase` gate (demo mode) and as the
/// canonical fake in widget/unit tests.
class InMemoryChatRepository implements ChatRepository {
  InMemoryChatRepository({List<ChatMessage> seed = const []}) {
    for (final m in seed) {
      _store.putIfAbsent(m.orderId, () => []).add(m);
    }
  }

  final Map<String, List<ChatMessage>> _store = {};

  /// One shared broadcast bus per order — every watcher forwards from it.
  final Map<String, StreamController<List<ChatMessage>>> _buses = {};

  int _counter = 0;

  /// Test seam: current stored messages for an order.
  @visibleForTesting
  List<ChatMessage> messagesFor(String orderId) =>
      List.unmodifiable(_store[orderId] ?? const []);

  List<ChatMessage> _snapshot(String orderId) {
    final all = _store[orderId] ?? const <ChatMessage>[];
    // Cap to the newest [ChatRepository.historyPageSize] window; the store is
    // append-ordered (oldest first), so slicing the tail preserves ordering.
    if (all.length <= ChatRepository.historyPageSize) {
      return List.unmodifiable(all);
    }
    return List.unmodifiable(
      all.sublist(all.length - ChatRepository.historyPageSize),
    );
  }

  StreamController<List<ChatMessage>> _busFor(String orderId) =>
      _buses.putIfAbsent(
        orderId,
        () => StreamController<List<ChatMessage>>.broadcast(),
      );

  void _emit(String orderId) {
    final bus = _buses[orderId];
    if (bus != null && !bus.isClosed) bus.add(_snapshot(orderId));
  }

  @override
  Future<Either<Failure, ChatMessage>> send(ChatMessage message) async {
    if (!message.isValidBody) {
      return const Left(
        ValidationFailure('الرسالة فارغة أو تتجاوز الحد الأقصى للطول'),
      );
    }
    _counter += 1;
    final persisted = message.copyWith(
      id: message.id.isNotEmpty ? message.id : 'CHAT-MSG-$_counter',
      createdAt: message.createdAt ?? DateTime.now(),
    );
    _store.putIfAbsent(persisted.orderId, () => []).add(persisted);
    _emit(persisted.orderId);
    return Right(persisted);
  }

  /// Loads the conversation history for an order, oldest first.
  ///
  /// Returns at most the newest [ChatRepository.historyPageSize] messages.
  @override
  Future<Either<Failure, List<ChatMessage>>> history(String orderId) async {
    return Right(_snapshot(orderId));
  }

  /// History-first feed: the newest-window snapshot (capped like [history])
  /// is delivered synchronously on listen (buffered by the single-subscription
  /// wrapper), then live updates are forwarded from the per-order broadcast
  /// bus until cancellation.
  @override
  Stream<List<ChatMessage>> watch(String orderId) {
    late final StreamController<List<ChatMessage>> out;
    late final StreamSubscription<List<ChatMessage>> busSub;

    out = StreamController<List<ChatMessage>>(
      onListen: () {
        out.add(_snapshot(orderId));
        busSub = _busFor(orderId).stream.listen(
              out.add,
              onError: out.addError,
              onDone: out.close,
            );
      },
      onPause: () => busSub.pause(),
      onResume: () => busSub.resume(),
      onCancel: () => busSub.cancel(),
    );
    return out.stream;
  }
}
