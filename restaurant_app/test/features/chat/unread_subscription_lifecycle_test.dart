import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/chat/domain/entities/chat_message.dart';
import 'package:restaurant_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:restaurant_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:restaurant_app/features/chat/presentation/controllers/unread_chat_controller.dart';

/// Spy [ChatRepository] that counts LIVE watch streams (+1 on listen, −1 on
/// cancel) and records every watched order id — so tests can assert the badge
/// family opens exactly one stream per order AND that
/// [UnreadChatController.dispose] releases each stream when the provider
/// elements are torn down (the leak guard behind the cost-model decision
/// recorded on `unreadChatCountProvider`).
class _SpyChatRepository implements ChatRepository {
  /// Orders passed to [watch], in call order — must contain no duplicates for
  /// distinct counters (one channel per order).
  final List<String> watchedOrders = <String>[];

  int _live = 0;

  /// Number of watch streams currently listened to (not yet cancelled).
  int get liveWatchStreams => _live;

  @override
  Future<Either<Failure, List<ChatMessage>>> history(String orderId) async =>
      const Right<Failure, List<ChatMessage>>([]);

  @override
  Future<Either<Failure, ChatMessage>> send(ChatMessage message) async =>
      Right<Failure, ChatMessage>(message);

  @override
  Stream<List<ChatMessage>> watch(String orderId) {
    watchedOrders.add(orderId);
    late final StreamController<List<ChatMessage>> out;
    out = StreamController<List<ChatMessage>>(
      onListen: () {
        _live++;
        // History-first contract: emit the (empty) baseline snapshot.
        out.add(const <ChatMessage>[]);
      },
      onCancel: () {
        _live--;
      },
    );
    return out.stream;
  }
}

const _driverId = 'drv-1';

ProviderContainer _container(_SpyChatRepository repo) {
  return ProviderContainer(
    overrides: [
      chatRepositoryProvider.overrideWithValue(repo),
      chatCurrentUserIdProvider.overrideWithValue(_driverId),
    ],
  );
}

void main() {
  group('unread badge subscription lifecycle', () {
    test(
      'creating N counters opens N live streams; disposing all closes them',
      () async {
        final repo = _SpyChatRepository();
        final container = _container(repo);

        const orders = <String>['ORD-A', 'ORD-B', 'ORD-C'];
        for (final orderId in orders) {
          container.listen(unreadChatCountProvider(orderId), (_, _) {});
        }
        // Flush the listen-side callbacks of the spy's stream controllers.
        await pumpEventQueue();

        // One watch per order, no duplicate subscriptions, all still live:
        // the per-order channel cost is exactly N for N threads.
        expect(repo.watchedOrders, orders);
        expect(repo.liveWatchStreams, orders.length);

        // Tearing the container down disposes every family element → each
        // UnreadChatController cancels its subscription → zero live streams.
        container.dispose();
        await pumpEventQueue();
        expect(repo.liveWatchStreams, 0);
      },
    );

    test(
      'repeated watches of the same order share a single live stream',
      () async {
        final repo = _SpyChatRepository();
        final container = _container(repo);

        // Two watchers on the SAME order id (e.g. DriverHomePage card + ChatPage
        // notifier read) resolve to ONE family element → one channel total.
        final badge = unreadChatCountProvider('ORD-A');
        container.listen(badge, (_, _) {});
        container.listen(badge, (_, _) {});
        await pumpEventQueue();

        expect(repo.watchedOrders, const <String>['ORD-A']);
        expect(repo.liveWatchStreams, 1);

        container.dispose();
        await pumpEventQueue();
        expect(repo.liveWatchStreams, 0);
      },
    );
  });
}
