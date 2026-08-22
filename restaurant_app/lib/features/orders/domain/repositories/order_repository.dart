import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/order_entity.dart';
import '../entities/order_status_log_entry.dart';

/// Domain contract for order persistence.
///
/// Offline-first for now: the in-memory [OrderRepository] keeps placed orders
/// for the current session so downstream screens (confirmation, order list)
/// can read them without a live backend.
abstract class OrderRepository {
  /// Persists a freshly created [order] (e.g. from the customer's cart).
  Future<Either<Failure, OrderEntity>> createOrder(OrderEntity order);

  /// Returns all orders placed in the current session, oldest first.
  Future<Either<Failure, List<OrderEntity>>> getOrders();

  /// Updates the status of an existing order.
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  );

  /// Claims [orderId] for the kitchen chef [kitchenUserId] (استلام الطلب),
  /// persisting the assignment on `orders.assigned_kitchen_id` so other KDS
  /// clients stop seeing the ticket.
  Future<Either<Failure, OrderEntity>> claimOrder(
    String orderId,
    String kitchenUserId,
  );

  /// Moves [orderId] BACK to [toStatus] (operator correction, e.g.
  /// ready → preparing) after validating `current.canRevertTo(toStatus)`.
  ///
  /// Returns a failure when the transition is not a legal revert; on success
  /// an [OrderStatusLogEntry] audit row (`is_revert: true`) is recorded with
  /// [actorId] and optional [reason].
  Future<Either<Failure, OrderEntity>> revertStatus(
    String orderId,
    OrderStatus toStatus, {
    required String actorId,
    String? reason,
  });
}
