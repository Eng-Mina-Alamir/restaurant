import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/table_service_request.dart';

/// Repository interface for managing customer table service/assistance requests.
abstract class TableServiceRepository {
  /// Fetches active (unhandled) table service requests.
  Future<Either<Failure, List<TableServiceRequest>>> getActiveRequests();

  /// Creates and persists a new table service request.
  Future<Either<Failure, TableServiceRequest>> createRequest(
    TableServiceRequest request,
  );

  /// Acknowledges/completes a service request by marking it handled.
  Future<Either<Failure, TableServiceRequest>> acknowledgeRequest(
    String requestId, {
    String? waiterId,
    DateTime? handledAt,
  });
}
