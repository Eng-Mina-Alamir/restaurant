import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/chat/domain/entities/chat_message.dart';
import 'package:restaurant_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:restaurant_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:restaurant_app/features/chat/presentation/controllers/unread_chat_controller.dart';
import 'package:restaurant_app/features/chat/presentation/pages/chat_page.dart';

ChatMessage msg({
  required String id,
  String orderId = 'ORD-1',
  required String senderId,
  required String body,
}) =>
    ChatMessage(
      id: id,
      orderId: orderId,
      senderId: senderId,
      body: body,
    );

/// Minimal controllable [ChatRepository]: seeded history plus a [receive]
/// seam that pushes a message onto the order's live feed — no send
/// validation or persistence side effects beyond the in-test store.
///
/// Mirrors the history-first contract of [InMemoryChatRepository.watch]:
/// the current snapshot is emitted immediately on listen, then updates.
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({List<ChatMessage> seed = const []}) {
    for (final m in seed) {
      _store.putIfAbsent(m.orderId, () => []).add(m);
    }
  }

  final Map<String, List<ChatMessage>> _store = {};
  final Map<String, StreamController<List<ChatMessage>>> _buses = {};

  StreamController<List<ChatMessage>> _busFor(String orderId) =>
      _buses.putIfAbsent(
        orderId,
        () => StreamController<List<ChatMessage>>.broadcast(),
      );

  /// Test seam: appends [message] to the store and emits the new snapshot on
  /// the live feed.
  void receive(ChatMessage message) {
    _store.putIfAbsent(message.orderId, () => []).add(message);
    final bus = _buses[message.orderId];
    if (bus != null && !bus.isClosed) bus.add(_snapshot(message.orderId));
  }

  List<ChatMessage> _snapshot(String orderId) =>
      List.unmodifiable(_store[orderId] ?? const <ChatMessage>[]);

  @override
  Future<Either<Failure, List<ChatMessage>>> history(String orderId) async =>
      Right(_snapshot(orderId));

  @override
  Future<Either<Failure, ChatMessage>> send(ChatMessage message) async {
    _store.putIfAbsent(message.orderId, () => []).add(message);
    _buses[message.orderId]?.add(_snapshot(message.orderId));
    return Right(message);
  }

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

const _driverId = 'drv-1';
const _customerId = 'cust-1';

ProviderContainer _container(
  FakeChatRepository repo, {
  ChatReadStateStore? readStateStore,
}) {
  return ProviderContainer(
    overrides: [
      chatRepositoryProvider.overrideWithValue(repo),
      chatCurrentUserIdProvider.overrideWithValue(_driverId),
      if (readStateStore != null)
        chatReadStateStoreProvider.overrideWithValue(readStateStore),
    ],
  );
}

/// Probe standing in for DriverHomePage's card: watches the same family
/// provider the badge renders from and exposes the count as text.
class BadgeProbePage extends ConsumerWidget {
  const BadgeProbePage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadChatCountProvider(orderId));
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('غير مقروءة:$count'),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChatPage(orderId: orderId),
                ),
              ),
              child: const Text('فتح المحادثة'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  group('UnreadChatController counting', () {
    test('ignores baseline history and counts foreign messages after it',
        () async {
      final repo = FakeChatRepository(
        seed: [msg(id: 'm0', senderId: _customerId, body: 'رسالة قديمة')],
      );
      final container = _container(repo);
      addTearDown(container.dispose);

      final badge = unreadChatCountProvider('ORD-1');
      container.listen(badge, (_, __) {});
      // Flush the initial (history-baseline) snapshot delivered on listen.
      await pumpEventQueue();
      expect(container.read(badge), 0);

      repo.receive(msg(id: 'm1', senderId: _customerId, body: 'أهلاً'));
      await pumpEventQueue();
      expect(container.read(badge), 1);
    });

    test("own messages never increment the counter", () async {
      final repo = FakeChatRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      final badge = unreadChatCountProvider('ORD-1');
      container.listen(badge, (_, __) {});
      await pumpEventQueue();

      repo.receive(msg(id: 'm1', senderId: _driverId, body: 'على الطريق'));
      await pumpEventQueue();
      expect(container.read(badge), 0);

      repo.receive(msg(id: 'm2', senderId: _customerId, body: 'تمام'));
      await pumpEventQueue();
      expect(container.read(badge), 1);

      repo.receive(msg(id: 'm3', senderId: _driverId, body: 'وصلت'));
      await pumpEventQueue();
      expect(container.read(badge), 1);
    });

    test('repeated snapshots of the same message id are not recounted',
        () async {
      final repo = FakeChatRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      final badge = unreadChatCountProvider('ORD-1');
      container.listen(badge, (_, __) {});
      await pumpEventQueue();

      final foreign = msg(id: 'm1', senderId: _customerId, body: 'مرتين؟');
      repo.receive(foreign);
      await pumpEventQueue();
      expect(container.read(badge), 1);

      // The repository echoes full snapshots; the same id must not double.
      repo.receive(foreign.copyWith(body: 'مرتين؟'));
      await pumpEventQueue();
      expect(container.read(badge), 1);
    });

    test('markRead zeroes the count and later messages still count',
        () async {
      final repo = FakeChatRepository();
      final container = _container(repo);
      addTearDown(container.dispose);

      final badge = unreadChatCountProvider('ORD-1');
      container.listen(badge, (_, __) {});
      await pumpEventQueue();

      repo.receive(msg(id: 'm1', senderId: _customerId, body: 'واحدة'));
      repo.receive(msg(id: 'm2', senderId: _customerId, body: 'اثنتين'));
      await pumpEventQueue();
      expect(container.read(badge), 2);

      container.read(badge.notifier).markRead();
      expect(container.read(badge), 0);

      // Old ids must stay classified after the reset (no phantom recount).
      repo.receive(msg(id: 'm3', senderId: _customerId, body: 'ثالثة'));
      await pumpEventQueue();
      expect(container.read(badge), 1);
    });
  });

  group('unread badge widget integration', () {
    Future<void> pumpProbe(WidgetTester tester, FakeChatRepository repo) async {
      final container = _container(repo);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BadgeProbePage(orderId: 'ORD-1')),
        ),
      );
      await tester.pump();
    }

    testWidgets('opening the ChatPage clears that order badge', (tester) async {
      final repo = FakeChatRepository(
        seed: [msg(id: 'm0', senderId: _customerId, body: 'قديمة')],
      );

      await pumpProbe(tester, repo);
      expect(find.textContaining('غير مقروءة:0'), findsOneWidget);

      // Two pumps: the snapshot travels bus → wrapper → listener before the
      // rebuild, and each fake-async pump drains one hop.
      repo.receive(msg(id: 'm1', senderId: _customerId, body: 'جديدة'));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('غير مقروءة:1'), findsOneWidget);

      // Push the real thread page; its initState calls markRead.
      await tester.tap(find.text('فتح المحادثة'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatPage), findsOneWidget);

      // A message landing while the thread is open is cleared on exit too.
      repo.receive(msg(id: 'm2', senderId: _customerId, body: 'أخرى'));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Back on the cards: badge reset by ChatPage init/dispose markRead.
      expect(find.textContaining('غير مقروءة:0'), findsOneWidget);
    });
  });

  group('persistent read receipts (v2)', () {
    test('foreign message newer than the receipt counts after a restart',
        () async {
      final store = InMemoryChatReadStateStore();
      final repo = FakeChatRepository();

      // Session 1: baseline, markRead persists a receipt at ~now.
      final session1 = _container(repo, readStateStore: store);
      addTearDown(session1.dispose);
      final badge1 = unreadChatCountProvider('ORD-1');
      session1.listen(badge1, (_, __) {});
      await pumpEventQueue();
      session1.read(badge1.notifier).markRead();
      await pumpEventQueue(); // receipt write is async fire-and-forget

      // A foreign message lands AFTER the receipt (while "app closed").
      repo.receive(
        msg(
          id: 'm-offline',
          senderId: _customerId,
          body: 'وصلت أثناء الإغلاق',
        ).copyWith(createdAt: DateTime.now().add(const Duration(seconds: 1))),
      );

      // Session 2 (restart): fresh container over the SAME store + repo.
      final session2 = _container(repo, readStateStore: store);
      addTearDown(session2.dispose);
      final badge2 = unreadChatCountProvider('ORD-1');
      session2.listen(badge2, (_, __) {});
      await pumpEventQueue();
      expect(session2.read(badge2), 1);
    });

    test('messages older than the receipt are not recounted after restart',
        () async {
      final store = InMemoryChatReadStateStore();
      final older = msg(
        id: 'm-old',
        senderId: _customerId,
        body: 'قبل الإيصال',
      ).copyWith(createdAt: DateTime.now().subtract(const Duration(hours: 1)));
      final repo = FakeChatRepository(seed: [older]);

      // Session 1: open (baseline consumes m-old as seen), then markRead —
      // the persisted receipt is now NEWER than m-old's timestamp.
      final session1 = _container(repo, readStateStore: store);
      addTearDown(session1.dispose);
      final badge1 = unreadChatCountProvider('ORD-1');
      session1.listen(badge1, (_, __) {});
      await pumpEventQueue();
      session1.read(badge1.notifier).markRead();
      await pumpEventQueue();

      // Session 2 (restart): m-old predates the receipt → not recounted.
      final session2 = _container(repo, readStateStore: store);
      addTearDown(session2.dispose);
      final badge2 = unreadChatCountProvider('ORD-1');
      session2.listen(badge2, (_, __) {});
      await pumpEventQueue();
      expect(session2.read(badge2), 0);
    });

    test('null-timestamp messages stay unattributed on restart baseline',
        () async {
      final store = InMemoryChatReadStateStore();
      final repo = FakeChatRepository(
        seed: [msg(id: 'm-notime', senderId: _customerId, body: 'بلا وقت')],
      );

      final session = _container(repo, readStateStore: store);
      addTearDown(session.dispose);
      final badge = unreadChatCountProvider('ORD-1');
      session.listen(badge, (_, __) {});
      await pumpEventQueue();
      // No createdAt → cannot prove it arrived after any receipt → not counted.
      expect(session.read(badge), 0);
    });
  });
}
