import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/delivery_assignment.dart';
import '../entities/driver_info.dart';

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

  /// Persists a new dispatch [assignment] (upsert semantics).
  Future<Either<Failure, DeliveryAssignment>> createAssignment(
    DeliveryAssignment assignment,
  );

  /// Loads the assignment linked to [orderId], or null when none exists.
  Future<Either<Failure, DeliveryAssignment?>> getAssignmentByOrderId(
    String orderId,
  );

  /// Bulk-reads every assignment still relevant to dispatch: everything
  /// except finalized deliveries.
  ///
  /// FAILED rows are deliberately included so the manager board can offer
  /// them for re-assignment; use [getAssignmentByOrderId] for per-order
  /// lookups around writes instead of looping over this method.
  Future<Either<Failure, List<DeliveryAssignment>>> getActiveAssignments();

  /// Lists drivers currently available for dispatch, enriched with their
  /// active (non-terminal) assignment counts.
  Future<Either<Failure, List<DriverInfo>>> getAvailableDrivers();
}
