import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_message.dart';

/// Contract for the order-scoped customer ↔ driver conversation.
///
/// Implementations:
/// - [InMemoryChatRepository] — local/demo mode and test fakes.
/// - Supabase impl (follow-up slice) — Postgres table + realtime stream.
abstract class ChatRepository {
  /// Maximum number of messages [history] (and the [watch] snapshot) return —
  /// the newest window of the conversation. Implementations must keep the
  /// result oldest-first within that window.
  static const int historyPageSize = 50;

  /// Persists [message]; the returned entity carries its final id/timestamp.
  Future<Either<Failure, ChatMessage>> send(ChatMessage message);

  /// Loads the conversation history for an order, oldest first.
  ///
  /// Capped at the newest [historyPageSize] messages; older messages outside
  /// that window are never returned.
  Future<Either<Failure, List<ChatMessage>>> history(String orderId);

  /// Live feed of messages for an order; emits the current snapshot
  /// immediately on subscription, then appends as messages arrive.
  Stream<List<ChatMessage>> watch(String orderId);
}
