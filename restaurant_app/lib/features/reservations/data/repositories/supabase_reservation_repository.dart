import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/reservation_entity.dart';
import '../../domain/repositories/reservation_repository.dart';

class SupabaseReservationRepository implements ReservationRepository {
  SupabaseReservationRepository({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  final List<ReservationEntity> _cachedReservations = [];

  @override
  Future<Either<Failure, List<ReservationEntity>>> getReservations() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.reservationsTable)
          .select()
          .order('reservation_time', ascending: true);

      final List<ReservationEntity> reservations = [];
      for (final raw in (response as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        reservations.add(_mapToReservationEntity(map));
      }
      _cachedReservations.clear();
      _cachedReservations.addAll(reservations);
      return Right(reservations);
    } catch (e, st) {
      AppLogger.warning('Supabase getReservations fallback: $e', error: e, stackTrace: st);
      return Right(List.unmodifiable(_cachedReservations));
    }
  }

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static String? _sanitizeUuid(String? input) {
    if (input == null || input.isEmpty) return null;
    if (_uuidRegex.hasMatch(input)) return input;
    return null;
  }

  @override
  Future<Either<Failure, ReservationEntity>> createReservation(
    ReservationEntity reservation,
  ) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final payload = {
        'id': reservation.id,
        'user_id': _sanitizeUuid(currentUserId),
        'customer_name': reservation.customerName,
        'phone': reservation.customerPhone,
        'party_size': reservation.guestCount,
        'reservation_time': reservation.reservationTime.toIso8601String(),
        'table_id': _sanitizeUuid(reservation.tableId),
        'table_number': reservation.tableNumber,
        'status': reservation.status.name,
        'notes': reservation.notes,
        'created_at': reservation.createdAt.toIso8601String(),
      };

      try {
        await _supabase.from(SupabaseConfig.reservationsTable).insert(payload);
      } catch (e) {
        if (e.toString().contains('phone') || e.toString().contains('PGRST204')) {
          final legacyPayload = Map<String, dynamic>.from(payload)
            ..remove('phone')
            ..['customer_phone'] = reservation.customerPhone;
          await _supabase.from(SupabaseConfig.reservationsTable).insert(legacyPayload);
        } else {
          rethrow;
        }
      }

      _cachedReservations.add(reservation);
      return Right(reservation);
    } catch (e, st) {
      AppLogger.warning('Supabase createReservation fallback: $e', error: e, stackTrace: st);
      _cachedReservations.add(reservation);
      return Right(reservation);
    }
  }

  @override
  Future<Either<Failure, ReservationEntity>> updateStatus(
    String id,
    ReservationStatus status,
  ) async {
    try {
      await _supabase
          .from(SupabaseConfig.reservationsTable)
          .update({'status': status.name})
          .eq('id', id);

      final updatedRaw = await _supabase
          .from(SupabaseConfig.reservationsTable)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (updatedRaw != null) {
        return Right(_mapToReservationEntity(Map<String, dynamic>.from(updatedRaw)));
      }

      return const Left(NotFoundFailure('الحجز غير موجود'));
    } catch (e, st) {
      AppLogger.error('Supabase updateStatus reservation error', error: e, stackTrace: st);
      return Left(ServerFailure('فشل تحديث حالة الحجز: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelReservation(String id) async {
    try {
      await _supabase
          .from(SupabaseConfig.reservationsTable)
          .update({'status': ReservationStatus.cancelled.name})
          .eq('id', id);
      return const Right(null);
    } catch (e, st) {
      AppLogger.error('Supabase cancelReservation error', error: e, stackTrace: st);
      return Left(ServerFailure('فشل إلغاء الحجز: $e'));
    }
  }

  ReservationEntity _mapToReservationEntity(Map<String, dynamic> map) {
    final statusName = map['status'] as String? ?? 'confirmed';
    final status = ReservationStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => ReservationStatus.confirmed,
    );

    return ReservationEntity(
      id: map['id']?.toString() ?? '',
      customerName: map['customer_name'] as String? ?? '',
      customerPhone: map['phone'] as String? ?? '',
      tableId: map['table_id'] as String? ?? 't1',
      tableNumber: (map['table_number'] as num?)?.toInt() ?? 1,
      guestCount: (map['party_size'] as num?)?.toInt() ?? 2,
      reservationTime: map['reservation_time'] != null
          ? DateTime.tryParse(map['reservation_time'] as String) ?? DateTime.now()
          : DateTime.now(),
      notes: map['notes'] as String?,
      status: status,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
