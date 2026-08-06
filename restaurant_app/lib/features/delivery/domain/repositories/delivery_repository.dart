import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/delivery_assignment.dart';

/// Domain contract for delivery assignment access.
///
/// Offline-first: the seed-backed implementation manages the current session's
/// assignments; a future remote implementation syncs with the dispatch API.
abstract class DeliveryRepository {
  /// Loads the assignments for [driverId].
  Future<Either<Failure, List<DeliveryAssignment>>> getAssignments(
    String driverId,
  );

  /// Persists an updated [assignment] (e.g. after a status change).
  Future<Either<Failure, DeliveryAssignment>> updateAssignment(
    DeliveryAssignment assignment,
  );
}
