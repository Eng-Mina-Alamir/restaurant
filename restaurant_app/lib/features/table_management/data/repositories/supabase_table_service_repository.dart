import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/table_service_request.dart';
import '../../domain/repositories/table_service_repository.dart';

/// Supabase-backed implementation of [TableServiceRepository].
class SupabaseTableServiceRepository implements TableServiceRepository {
  SupabaseTableServiceRepository(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<Either<Failure, List<TableServiceRequest>>> getActiveRequests() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.tableServiceRequestsTable)
          .select()
          .eq('is_handled', false)
          .order('requested_at', ascending: false);

      final list = (response as List)
          .map(
            (row) => TableServiceRequest.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();

      return Right<Failure, List<TableServiceRequest>>(list);
    } catch (e, st) {
      AppLogger.error(
        'Supabase getActiveRequests failed: $e',
        error: e,
        stackTrace: st,
      );
      return Left<Failure, List<TableServiceRequest>>(
        ServerFailure('فشل جلب طلبات المساعدة: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, TableServiceRequest>> createRequest(
    TableServiceRequest request,
  ) async {
    try {
      final payload = request.toJson()..remove('id');
      final response = await _supabase
          .from(SupabaseConfig.tableServiceRequestsTable)
          .insert(payload)
          .select()
          .single();

      final created = request.copyWith(
        id: response['id']?.toString() ?? request.id,
      );
      return Right<Failure, TableServiceRequest>(created);
    } catch (e, st) {
      AppLogger.error(
        'Supabase createRequest failed: $e',
        error: e,
        stackTrace: st,
      );
      return Left<Failure, TableServiceRequest>(
        ServerFailure('فشل إرسال طلب المساعدة: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, TableServiceRequest>> acknowledgeRequest(
    String requestId, {
    String? waiterId,
    DateTime? handledAt,
  }) async {
    try {
      final now = handledAt ?? DateTime.now();
      final updates = <String, dynamic>{
        'is_handled': true,
        'handled_at': now.toIso8601String(),
      };
      if (waiterId != null && waiterId.isNotEmpty) {
        updates['handled_by_waiter_id'] = waiterId;
      }

      final response = await _supabase
          .from(SupabaseConfig.tableServiceRequestsTable)
          .update(updates)
          .eq('id', requestId)
          .select();

      final rows = response as List;
      if (rows.isNotEmpty) {
        final updated = TableServiceRequest.fromJson(
          Map<String, dynamic>.from(rows.first as Map),
        );
        return Right<Failure, TableServiceRequest>(updated);
      }

      return const Left<Failure, TableServiceRequest>(
        NotFoundFailure('طلب المساعدة غير موجود'),
      );
    } catch (e, st) {
      AppLogger.error(
        'Supabase acknowledgeRequest failed: $e',
        error: e,
        stackTrace: st,
      );
      return Left<Failure, TableServiceRequest>(
        ServerFailure('فشل تحديث طلب المساعدة: $e'),
      );
    }
  }
}
