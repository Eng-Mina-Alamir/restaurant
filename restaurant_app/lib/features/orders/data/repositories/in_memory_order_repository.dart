import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';

/// In-memory [OrderRepository] for the offline customer flow.
///
/// Keeps orders for the current session. A future implementation should
/// persist to Hive (LocalCacheService) and/or the backend so orders survive
/// app restarts.
class InMemoryOrderRepository implements OrderRepository {
  InMemoryOrderRepository();

  final List<OrderEntity> _orders = <OrderEntity>[];

  @override
  Future<Either<Failure, OrderEntity>> createOrder(OrderEntity order) async {
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index == -1) {
      _orders.add(order);
    } else {
      _orders[index] = order;
    }
    return Right<Failure, OrderEntity>(order);
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    return Right<Failure, List<OrderEntity>>(List<OrderEntity>.of(_orders));
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      return const Left(NotFoundFailure('الطلب غير موجود'));
    }
    _orders[index] = _orders[index].copyWith(status: status);
    return const Right(null);
  }
}
