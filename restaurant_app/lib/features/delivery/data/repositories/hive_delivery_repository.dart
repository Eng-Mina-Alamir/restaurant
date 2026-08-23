import '../../../../core/data/local_cache_service.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/delivery_assignment.dart';
import '../../domain/entities/driver_info.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../delivery_seed_data.dart';

/// Hive-persisted [DeliveryRepository].
///
/// Seeds assignments from [DeliverySeedData] on first use, then persists driver
/// status transitions across restarts.
class HiveDeliveryRepository implements DeliveryRepository {
  HiveDeliveryRepository(this._cache);

  static const String cacheKey = 'deliveries_v1';

  final LocalCacheService _cache;

  @override
  Future<Either<Failure, List<DeliveryAssignment>>> getAssignments(
    String driverId,
  ) async {
    try {
      final all = await _load();
      final list = all.where((a) => a.driverId == driverId).toList();
      return Right<Failure, List<DeliveryAssignment>>(list);
    } catch (e) {
      return Left<Failure, List<DeliveryAssignment>>(
        CacheFailure(e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, DeliveryAssignment>> updateAssignment(
    DeliveryAssignment assignment,
  ) async {
    try {
      final all = await _load();
      final index = all.indexWhere((a) => a.id == assignment.id);
      if (index == -1) {
        all.add(assignment);
      } else {
        all[index] = assignment;
      }
      await _cache.writeList(cacheKey, all.map((a) => a.toJson()).toList());
      return Right<Failure, DeliveryAssignment>(assignment);
    } catch (e) {
      return Left<Failure, DeliveryAssignment>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DeliveryAssignment>> createAssignment(
    DeliveryAssignment assignment,
  ) => updateAssignment(assignment);

  @override
  Future<Either<Failure, DeliveryAssignment?>> getAssignmentByOrderId(
    String orderId,
  ) async {
    try {
      final all = await _load();
      DeliveryAssignment? match;
      for (final a in all) {
        if (a.orderId == orderId) {
          match = a;
          break;
        }
      }
      return Right<Failure, DeliveryAssignment?>(match);
    } catch (e) {
      return Left<Failure, DeliveryAssignment?>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DeliveryAssignment>>> getActiveAssignments() async {
    try {
      // Delivered rows leave the dispatch board's scope; failed ones stay
      // visible so the manager can re-assign them.
      const settled = {DeliveryStatus.delivered};
      final all = await _load();
      final list =
          all.where((a) => !settled.contains(a.deliveryStatus)).toList();
      return Right<Failure, List<DeliveryAssignment>>(list);
    } catch (e) {
      return Left<Failure, List<DeliveryAssignment>>(
        CacheFailure(e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, List<DriverInfo>>> getAvailableDrivers() async {
    try {
      // Local mode has no profiles table: derive drivers from the cached /
      // seeded assignments and count their active (non-terminal) runs.
      const terminal = {DeliveryStatus.delivered, DeliveryStatus.failed};
      final all = await _load();
      final activeCounts = <String, int>{};
      for (final a in all) {
        if (!terminal.contains(a.deliveryStatus)) {
          activeCounts[a.driverId] = (activeCounts[a.driverId] ?? 0) + 1;
        }
      }
      final drivers = activeCounts.entries
          .map(
            (entry) => DriverInfo(
              id: entry.key,
              name: entry.key,
              rating: 5.0,
              activeAssignments: entry.value,
              isAvailable: true,
            ),
          )
          .toList();
      return Right<Failure, List<DriverInfo>>(drivers);
    } catch (e) {
      return Left<Failure, List<DriverInfo>>(CacheFailure(e.toString()));
    }
  }

  Future<List<DeliveryAssignment>> _load() async {
    var list = _cache
        .readList(cacheKey)
        .map(DeliveryAssignment.fromJson)
        .toList();
    if (list.isEmpty) {
      list = DeliverySeedData.buildAssignments();
      await _cache.writeList(cacheKey, list.map((a) => a.toJson()).toList());
    }
    return list;
  }
}
