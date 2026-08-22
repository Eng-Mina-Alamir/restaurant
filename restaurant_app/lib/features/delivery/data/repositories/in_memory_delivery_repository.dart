import '../../../../core/domain/enums.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/delivery_assignment.dart';
import '../../domain/entities/driver_info.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../delivery_seed_data.dart';

/// In-memory [DeliveryRepository] seeded from [DeliverySeedData].
///
/// Keeps the mutable assignment state so the driver's actions (accept, start,
/// complete) persist within the session.
class InMemoryDeliveryRepository implements DeliveryRepository {
  InMemoryDeliveryRepository({List<DeliveryAssignment>? seed})
    : _assignments = <String, DeliveryAssignment>{
        for (final a in seed ?? DeliverySeedData.buildAssignments()) a.id: a,
      };

  final Map<String, DeliveryAssignment> _assignments;

  @override
  Future<Either<Failure, List<DeliveryAssignment>>> getAssignments(
    String driverId,
  ) async {
    final list = _assignments.values
        .where((a) => a.driverId == driverId)
        .toList();
    return Right<Failure, List<DeliveryAssignment>>(list);
  }

  @override
  Future<Either<Failure, DeliveryAssignment>> updateAssignment(
    DeliveryAssignment assignment,
  ) async {
    _assignments[assignment.id] = assignment;
    return Right<Failure, DeliveryAssignment>(assignment);
  }

  @override
  Future<Either<Failure, DeliveryAssignment>> createAssignment(
    DeliveryAssignment assignment,
  ) async {
    _assignments[assignment.id] = assignment;
    return Right<Failure, DeliveryAssignment>(assignment);
  }

  @override
  Future<Either<Failure, DeliveryAssignment?>> getAssignmentByOrderId(
    String orderId,
  ) async {
    DeliveryAssignment? match;
    for (final a in _assignments.values) {
      if (a.orderId == orderId) {
        match = a;
        break;
      }
    }
    return Right<Failure, DeliveryAssignment?>(match);
  }

  @override
  Future<Either<Failure, List<DriverInfo>>> getAvailableDrivers() async {
    // Local mode has no profiles table: derive drivers from the seeded /
    // stored assignments and count their active (non-terminal) runs.
    const terminal = {DeliveryStatus.delivered, DeliveryStatus.failed};
    final activeCounts = <String, int>{};
    for (final a in _assignments.values) {
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
  }
}
