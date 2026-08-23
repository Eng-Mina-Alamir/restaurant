import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_message.dart';

/// Contract for the order-scoped customer ↔ driver conversation.
///
/// Implementations:
/// - [InMemoryChatRepository] — local/demo mode and test fakes.
/// - Supabase impl (follow-up slice) — Postgres table + realtime stream.
abstract class ChatRepository {
  /// Persists [message]; the returned entity carries its final id/timestamp.
  Future<Either<Failure, ChatMessage>> send(ChatMessage message);

  /// Loads the conversation history for an order, oldest first.
  Future<Either<Failure, List<ChatMessage>>> history(String orderId);

  /// Live feed of messages for an order; emits the current snapshot
  /// immediately on subscription, then appends as messages arrive.
  Stream<List<ChatMessage>> watch(String orderId);
}
