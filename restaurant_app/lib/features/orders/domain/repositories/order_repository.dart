import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/order_entity.dart';

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
}
