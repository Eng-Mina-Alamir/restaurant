import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/table_service_request.dart';
import '../../domain/repositories/table_service_repository.dart';

/// In-memory implementation of [TableServiceRepository] for offline/demo use.
class InMemoryTableServiceRepository implements TableServiceRepository {
  final List<TableServiceRequest> _requests = [];

  @override
  Future<Either<Failure, List<TableServiceRequest>>> getActiveRequests() async {
    return Right<Failure, List<TableServiceRequest>>(
      _requests.where((r) => !r.isHandled).toList(),
    );
  }

  @override
  Future<Either<Failure, TableServiceRequest>> createRequest(
    TableServiceRequest request,
  ) async {
    _requests.insert(0, request);
    return Right<Failure, TableServiceRequest>(request);
  }

  @override
  Future<Either<Failure, TableServiceRequest>> acknowledgeRequest(
    String requestId, {
    String? waiterId,
    DateTime? handledAt,
  }) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      return const Left<Failure, TableServiceRequest>(
        NotFoundFailure('طلب المساعدة غير موجود'),
      );
    }

    final updated = _requests[index].copyWith(
      isHandled: true,
      handledAt: handledAt ?? DateTime.now(),
      handledByWaiterId: waiterId,
    );
    _requests[index] = updated;
    return Right<Failure, TableServiceRequest>(updated);
  }
}
