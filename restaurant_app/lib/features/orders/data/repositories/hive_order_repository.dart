import '../../../../core/data/local_cache_service.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_status_log_entry.dart';
import '../../domain/repositories/order_repository.dart';
import '../../../../core/utils/logger.dart';

/// Hive-persisted [OrderRepository].
///
/// Orders survive app restarts by serializing each [OrderEntity] to JSON and
/// storing the list under a single box key.
class HiveOrderRepository implements OrderRepository {
  HiveOrderRepository(this._cache);

  static const String cacheKey = 'orders_v1';

  final LocalCacheService _cache;

  @override
  Future<Either<Failure, OrderEntity>> createOrder(OrderEntity order) async {
    try {
      final all = await _loadAll();
      final index = all.indexWhere((o) => o.id == order.id);
      if (index == -1) {
        all.add(order);
      } else {
        all[index] = order;
      }
      await _saveAll(all);
      return Right<Failure, OrderEntity>(order);
    } catch (e) {
      AppLogger.warning(
        'HiveOrderRepository.createOrder failed for order ${order.id}: $e',
      );
      return const Left<Failure, OrderEntity>(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    try {
      return Right<Failure, List<OrderEntity>>(await _loadAll());
    } catch (e) {
      AppLogger.warning('HiveOrderRepository.getOrders failed to load: $e');
      return const Left<Failure, List<OrderEntity>>(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    try {
      final all = await _loadAll();
      final index = all.indexWhere((o) => o.id == orderId);
      if (index == -1) {
        return const Left(NotFoundFailure('الطلب غير موجود'));
      }
      all[index] = all[index].copyWith(status: status);
      await _saveAll(all);
      return const Right(null);
    } catch (e) {
      AppLogger.warning(
        'HiveOrderRepository.updateOrderStatus failed for order $orderId: $e',
      );
      return const Left<Failure, void>(CacheFailure());
    }
  }

  /// In-memory audit trail (session-scoped; Hive has no log box).
  final List<OrderStatusLogEntry> _statusLog = <OrderStatusLogEntry>[];

  /// Audit entries produced by [revertStatus], oldest first. Exposed for
  /// tests and offline inspection.
  List<OrderStatusLogEntry> get statusLog =>
      List.unmodifiable(_statusLog);

  @override
  Future<Either<Failure, OrderEntity>> claimOrder(
    String orderId,
    String kitchenUserId,
  ) async {
    try {
      final all = await _loadAll();
      final index = all.indexWhere((o) => o.id == orderId);
      if (index == -1) {
        return const Left(NotFoundFailure('الطلب غير موجود'));
      }
      final claimed =
          all[index].copyWith(assignedKitchenId: kitchenUserId);
      all[index] = claimed;
      await _saveAll(all);
      return Right<Failure, OrderEntity>(claimed);
    } catch (e) {
      AppLogger.warning(
        'HiveOrderRepository.claimOrder failed for order $orderId: $e',
      );
      return const Left<Failure, OrderEntity>(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> revertStatus(
    String orderId,
    OrderStatus toStatus, {
    required String actorId,
    String? reason,
  }) async {
    try {
      final all = await _loadAll();
      final index = all.indexWhere((o) => o.id == orderId);
      if (index == -1) {
        return const Left(NotFoundFailure('الطلب غير موجود'));
      }
      final current = all[index];
      // Guarded transition: only legal single-step backward moves.
      if (!current.status.canRevertTo(toStatus)) {
        return Left<Failure, OrderEntity>(
          ValidationFailure('لا يمكن التراجع من ${current.status.labelAr}'),
        );
      }
      // Business rule: at most TWO reverts per order (التراجع مرتان كحد أقصى).
      final revertCount =
          _statusLog.where((e) => e.orderId == orderId && e.isRevert).length;
      if (revertCount >= 2) {
        return const Left<Failure, OrderEntity>(
          ValidationFailure(
            'تم تجاوز الحد المسموح للتراجع عن هذا الطلب (مرتان كحد أقصى)',
          ),
        );
      }
      final updated = current.copyWith(status: toStatus);
      all[index] = updated;
      await _saveAll(all);
      _statusLog.add(OrderStatusLogEntry(
        orderId: orderId,
        fromStatus: current.status,
        toStatus: toStatus,
        actorId: actorId,
        reason: reason,
        isRevert: true,
        createdAt: DateTime.now(),
      ));
      return Right<Failure, OrderEntity>(updated);
    } catch (e) {
      AppLogger.warning(
        'HiveOrderRepository.revertStatus failed for order $orderId: $e',
      );
      return const Left<Failure, OrderEntity>(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<OrderStatusLogEntry>>> getAuditTrail(
    String orderId,
  ) async {
    try {
      // Appends are chronological, so filtering preserves oldest-first order.
      final trail = _statusLog.where((e) => e.orderId == orderId).toList();
      return Right<Failure, List<OrderStatusLogEntry>>(trail);
    } catch (e) {
      AppLogger.warning(
        'HiveOrderRepository.getAuditTrail failed for order $orderId: $e',
      );
      return const Left<Failure, List<OrderStatusLogEntry>>(CacheFailure());
    }
  }

  Future<List<OrderEntity>> _loadAll() async {
    return _cache.readList(cacheKey).map(OrderEntity.fromJson).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> _saveAll(List<OrderEntity> orders) async {
    await _cache.writeList(cacheKey, orders.map((o) => o.toJson()).toList());
  }
}
