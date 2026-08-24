import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/features/chat/data/repositories/in_memory_chat_repository.dart';
import 'package:restaurant_app/features/chat/domain/entities/chat_message.dart';
import 'package:restaurant_app/features/chat/domain/repositories/chat_repository.dart';

ChatMessage msg({
  String id = '',
  String orderId = 'ORD-1',
  String senderId = 'cust-1',
  String body = 'Ù…Ø±Ø­Ø¨Ø§Ù‹',
}) => ChatMessage(id: id, orderId: orderId, senderId: senderId, body: body);

void main() {
  group('ChatMessage entity', () {
    test('round-trips through fromMap/toJson', () {
      final original = ChatMessage(
        id: 'uuid-1',
        orderId: 'ORD-9',
        senderId: 'drv-2',
        body: 'ÙˆØµÙ„Øª Ù„Ù„Ø¹Ù†ÙˆØ§Ù†',
        createdAt: DateTime.parse('2026-08-23T10:00:00Z'),
      );
      final restored = ChatMessage.fromMap(original.toJson());
      expect(restored.id, original.id);
      expect(restored.orderId, original.orderId);
      expect(restored.senderId, original.senderId);
      expect(restored.body, original.body);
      expect(restored.createdAt!.toUtc(), original.createdAt!.toUtc());
    });

    test('isValidBody enforces 1..maxBodyLength trimmed', () {
      expect(msg(body: '  ').isValidBody, isFalse);
      expect(msg(body: '').isValidBody, isFalse);
      expect(msg(body: 'x').isValidBody, isTrue);
      expect(msg(body: 'a' * ChatMessage.maxBodyLength).isValidBody, isTrue);
      expect(
        msg(body: 'a' * (ChatMessage.maxBodyLength + 1)).isValidBody,
        isFalse,
      );
    });
  });

  group('InMemoryChatRepository', () {
    late InMemoryChatRepository repo;

    setUp(() => repo = InMemoryChatRepository());

    test(
      'send persists with generated id and timestamp; history returns it',
      () async {
        final result = await repo.send(msg(senderId: 'cust-1'));
        final saved = result.when(
          onLeft: (f) => fail('send should not fail: ${f.message}'),
          onRight: (m) => m,
        );

        expect(saved.id, isNotEmpty);
        expect(saved.createdAt, isNotNull);

        final history = await repo.history('ORD-1');
        expect(
          history.when(
            onLeft: (f) => fail('history failed: ${f.message}'),
            onRight: (l) => l,
          ),
          [saved],
        );
      },
    );

    test('send rejects empty/overlong bodies with ValidationFailure', () async {
      final empty = await repo.send(msg(body: '   '));
      expect(empty.isLeft, isTrue);

      final overlong = await repo.send(
        msg(body: 'a' * (ChatMessage.maxBodyLength + 1)),
      );
      expect(overlong.isLeft, isTrue);

      expect(repo.messagesFor('ORD-1'), isEmpty);
    });

    test('history for unknown order returns empty list', () async {
      final history = await repo.history('ORD-NONE');
      expect(
        history.when(onLeft: (f) => fail('history failed'), onRight: (l) => l),
        isEmpty,
      );
    });

    test('watch emits history snapshot first, then live updates', () async {
      await repo.send(msg(id: 'seed-1'));
      await repo.send(msg(id: 'seed-2'));

      final received = <List<ChatMessage>>[];
      final sub = repo.watch('ORD-1').listen(received.add);
      await Future<void>.delayed(Duration.zero);
      // Snapshot delivered on listen.
      expect(received, hasLength(1));
      expect(received.first.map((m) => m.id), ['seed-1', 'seed-2']);

      await repo.send(msg(id: 'live-3'));
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(2));
      expect(received.last.map((m) => m.id), ['seed-1', 'seed-2', 'live-3']);

      await sub.cancel();
    });

    test(
      'history caps at historyPageSize, keeping the newest window',
      () async {
        const total = ChatRepository.historyPageSize * 2; // 100
        final bigRepo = InMemoryChatRepository(
          seed: List.generate(total, (i) => msg(id: 'seed-${i + 1}')),
        );

        final page = await bigRepo.history('ORD-1');
        final messages = page.when(
          onLeft: (f) => fail('history failed: ${f.message}'),
          onRight: (l) => l,
        );

        // Exactly one page: messages #51..#100 of 100, oldest first — i.e. the
        // FIRST returned id is message #51 of N.
        expect(messages, hasLength(ChatRepository.historyPageSize));
        expect(
          messages.first.id,
          'seed-${total - ChatRepository.historyPageSize + 1}',
        );
        expect(messages.last.id, 'seed-$total');
        expect(
          messages.map((m) => m.id).toList(),
          List.generate(
            ChatRepository.historyPageSize,
            (i) => 'seed-${total - ChatRepository.historyPageSize + i + 1}',
          ),
        );
      },
    );

    test('watch snapshot is capped to the newest window', () async {
      const total = ChatRepository.historyPageSize * 2; // 100
      final bigRepo = InMemoryChatRepository(
        seed: List.generate(total, (i) => msg(id: 'seed-${i + 1}')),
      );

      final received = <List<ChatMessage>>[];
      final sub = bigRepo.watch('ORD-1').listen(received.add);
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.first, hasLength(ChatRepository.historyPageSize));
      expect(received.first.first.id, 'seed-51');
      expect(received.first.last.id, 'seed-$total');

      await sub.cancel();
    });

    test('watch is isolated per order id', () async {
      await repo.send(msg(orderId: 'ORD-A'));
      final receivedA = <List<ChatMessage>>[];
      final subA = repo.watch('ORD-A').listen(receivedA.add);
      await Future<void>.delayed(Duration.zero);

      await repo.send(msg(orderId: 'ORD-B'));
      await Future<void>.delayed(Duration.zero);

      expect(receivedA, hasLength(1)); // only the snapshot; no ORD-B noise
      await subA.cancel();
    });
  });
}
