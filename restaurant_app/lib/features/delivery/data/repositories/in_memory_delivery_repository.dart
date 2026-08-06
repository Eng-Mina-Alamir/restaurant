import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/delivery_assignment.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../delivery_seed_data.dart';

/// In-memory [DeliveryRepository] seeded from [DeliverySeedData].
///
/// Keeps the mutable assignment state so the driver's actions (accept, start,
/// complete) persist within the session.
class InMemoryDeliveryRepository implements DeliveryRepository {
  InMemoryDeliveryRepository()
    : _assignments = <String, DeliveryAssignment>{
        for (final a in DeliverySeedData.buildAssignments()) a.id: a,
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
}
