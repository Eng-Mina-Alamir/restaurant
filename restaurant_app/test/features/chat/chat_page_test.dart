import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/chat/data/repositories/in_memory_chat_repository.dart';
import 'package:restaurant_app/features/chat/domain/entities/chat_message.dart';
import 'package:restaurant_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:restaurant_app/features/chat/presentation/pages/chat_page.dart';

ChatMessage msg({
  required String id,
  String orderId = 'ORD-1',
  required String senderId,
  required String body,
  DateTime? createdAt,
}) =>
    ChatMessage(
      id: id,
      orderId: orderId,
      senderId: senderId,
      body: body,
      createdAt: createdAt,
    );

/// Repository whose sends always fail — drives the SnackBar error path.
class FailingChatRepository extends InMemoryChatRepository {
  @override
  Future<Either<Failure, ChatMessage>> send(ChatMessage message) async =>
      const Left<Failure, ChatMessage>(
        ServerFailure('فشل إرسال الرسالة'),
      );
}

Future<void> pumpChatPage(
  WidgetTester tester,
  InMemoryChatRepository repo, {
  String orderId = 'ORD-1',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repo),
        chatCurrentUserIdProvider.overrideWithValue('cust-1'),
      ],
      child: MaterialApp(home: ChatPage(orderId: orderId)),
    ),
  );
  // History-first load + a settle frame.
  await tester.pump();
  await tester.pump();
}

void main() {
  group('ChatPage bubbles', () {
    testWidgets('renders seeded messages oldest-first', (tester) async {
      final repo = InMemoryChatRepository(
        seed: [
          msg(
            id: 'm2',
            senderId: 'drv-1',
            body: 'وصلت للعنوان',
            createdAt: DateTime(2026, 8, 23, 10, 5),
          ),
          msg(
            id: 'm1',
            senderId: 'cust-1',
            body: 'أنا في انتظارك',
            createdAt: DateTime(2026, 8, 23, 10, 0),
          ),
        ],
      );

      await pumpChatPage(tester, repo);

      expect(find.text('أنا في انتظارك'), findsOneWidget);
      expect(find.text('وصلت للعنوان'), findsOneWidget);

      // Oldest message sits above the newer one despite seed order.
      final older = tester.getCenter(find.text('أنا في انتظارك'));
      final newer = tester.getCenter(find.text('وصلت للعنوان'));
      expect(older.dy, lessThan(newer.dy));
    });

    testWidgets('aligns own messages right and others left', (tester) async {
      final repo = InMemoryChatRepository(
        seed: [
          msg(
            id: 'm1',
            senderId: 'cust-1',
            body: 'رسالتي',
            createdAt: DateTime(2026, 8, 23, 10, 0),
          ),
          msg(
            id: 'm2',
            senderId: 'drv-1',
            body: 'رسالة السائق',
            createdAt: DateTime(2026, 8, 23, 10, 1),
          ),
        ],
      );

      await pumpChatPage(tester, repo);

      final mine = find.text('رسالتي');
      final theirs = find.text('رسالة السائق');
      expect(mine, findsOneWidget);
      expect(theirs, findsOneWidget);

      // RTL-agnostic check: my bubble's center sits on its own half.
      final screenWidth =
          (tester.view.physicalSize / tester.view.devicePixelRatio).width;
      expect(tester.getCenter(mine).dx, greaterThan(screenWidth / 2));
      expect(tester.getCenter(theirs).dx, lessThan(screenWidth / 2));
    });
  });

  group('ChatPage sending', () {
    testWidgets('typing + send appends bubble and persists to repository',
        (tester) async {
      final repo = InMemoryChatRepository();

      await pumpChatPage(tester, repo);

      await tester.enterText(find.byType(TextField), 'مرحباً');
      // Rebuild so the send button flips to its enabled state.
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump();

      expect(find.text('مرحباً'), findsOneWidget);
      expect(
        repo.messagesFor('ORD-1').any((m) => m.body == 'مرحباً'),
        isTrue,
      );
      // Input cleared after sending.
      final field =
          tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('send is disabled while input is empty', (tester) async {
      final repo = InMemoryChatRepository();

      await pumpChatPage(tester, repo);

      IconButton sendButton() => tester.widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.send),
              matching: find.byType(IconButton),
            ),
          );

      expect(sendButton().onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'x');
      await tester.pump();
      expect(sendButton().onPressed, isNotNull);
    });

    testWidgets('shows a snack bar when the repository rejects the send',
        (tester) async {
      await pumpChatPage(tester, FailingChatRepository());

      await tester.enterText(find.byType(TextField), 'مرحباً');
      // Rebuild so the send button flips to its enabled state.
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('فشل إرسال الرسالة'), findsOneWidget);
      // Rejected messages never become bubbles.
      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });
}
