import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_status_log_entry.dart';
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

  /// In-memory audit trail of guarded reverts, oldest first.
  final List<OrderStatusLogEntry> _statusLog = <OrderStatusLogEntry>[];

  /// Audit entries produced by [revertStatus]. Exposed for tests and
  /// offline inspection.
  List<OrderStatusLogEntry> get statusLog => List.unmodifiable(_statusLog);

  @override
  Future<Either<Failure, OrderEntity>> claimOrder(
    String orderId,
    String kitchenUserId,
  ) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      return const Left(NotFoundFailure('الطلب غير موجود'));
    }
    final claimed = _orders[index].copyWith(assignedKitchenId: kitchenUserId);
    _orders[index] = claimed;
    return Right<Failure, OrderEntity>(claimed);
  }

  @override
  Future<Either<Failure, OrderEntity>> revertStatus(
    String orderId,
    OrderStatus toStatus, {
    required String actorId,
    String? reason,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      return const Left(NotFoundFailure('الطلب غير موجود'));
    }
    final current = _orders[index];
    // Guarded transition: only legal single-step backward moves.
    if (!current.status.canRevertTo(toStatus)) {
      return Left<Failure, OrderEntity>(
        ValidationFailure('لا يمكن التراجع من ${current.status.labelAr}'),
      );
    }
    // Business rule: at most TWO reverts per order (التراجع مرتان كحد أقصى).
    final revertCount = _statusLog
        .where((e) => e.orderId == orderId && e.isRevert)
        .length;
    if (revertCount >= 2) {
      return const Left<Failure, OrderEntity>(
        ValidationFailure(
          'تم تجاوز الحد المسموح للتراجع عن هذا الطلب (مرتان كحد أقصى)',
        ),
      );
    }
    final updated = current.copyWith(status: toStatus);
    _orders[index] = updated;
    _statusLog.add(
      OrderStatusLogEntry(
        orderId: orderId,
        fromStatus: current.status,
        toStatus: toStatus,
        actorId: actorId,
        reason: reason,
        isRevert: true,
        createdAt: DateTime.now(),
      ),
    );
    return Right<Failure, OrderEntity>(updated);
  }

  @override
  Future<Either<Failure, List<OrderStatusLogEntry>>> getAuditTrail(
    String orderId,
  ) async {
    // Appends are chronological, so filtering preserves oldest-first order.
    final trail = _statusLog.where((e) => e.orderId == orderId).toList();
    return Right<Failure, List<OrderStatusLogEntry>>(trail);
  }
}
