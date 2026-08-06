import '../../../../core/data/local_cache_service.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';

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
      return Left<Failure, OrderEntity>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    try {
      return Right<Failure, List<OrderEntity>>(await _loadAll());
    } catch (e) {
      return Left<Failure, List<OrderEntity>>(CacheFailure(e.toString()));
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
