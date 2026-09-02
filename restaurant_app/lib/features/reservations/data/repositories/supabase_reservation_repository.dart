import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/reservation_entity.dart';
import '../../domain/repositories/reservation_repository.dart';

class SupabaseReservationRepository implements ReservationRepository {
  SupabaseReservationRepository({
    required SupabaseClient supabase,
    LocalCacheService? cache,
  })  : _supabase = supabase,
        _cache = cache;

  final SupabaseClient _supabase;
  final LocalCacheService? _cache;

  static const String _reservationsCacheKey = 'reservations_v1';

  @override
  Future<Either<Failure, List<ReservationEntity>>> getReservations() async {
    try {
      final cutoff = DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String();
      final response = await _supabase
          .from(SupabaseConfig.reservationsTable)
          .select()
          .gte('reservation_time', cutoff)
          .order('reservation_time', ascending: true)
          .limit(200);

      final List<ReservationEntity> reservations = [];
      for (final raw in (response as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        reservations.add(_mapToReservationEntity(map));
      }

      final cache = _cache;
      if (cache != null) {
        await cache.writeList(
          _reservationsCacheKey,
          reservations.map((r) => {
            'id': r.id,
            'customerName': r.customerName,
            'customerPhone': r.customerPhone,
            'guestCount': r.guestCount,
            'reservationTime': r.reservationTime.toIso8601String(),
            'tableId': r.tableId,
            'tableNumber': r.tableNumber,
            'status': r.status.name,
            'notes': r.notes,
            'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
        );
      }

      return Right(reservations);
    } catch (e, st) {
      AppLogger.warning('Supabase getReservations fallback: $e', error: e, stackTrace: st);
      final cache = _cache;
      if (cache != null) {
        final cached = cache.readList(_reservationsCacheKey);
        if (cached.isNotEmpty) {
          final list = cached.map((map) => ReservationEntity(
            id: map['id']?.toString() ?? '',
            customerName: map['customerName'] as String? ?? '',
            customerPhone: map['customerPhone'] as String? ?? '',
            guestCount: (map['guestCount'] as num?)?.toInt() ?? 2,
            reservationTime: map['reservationTime'] != null
                ? DateTime.parse(map['reservationTime'] as String)
                : DateTime.now(),
            tableId: map['tableId']?.toString() ?? '',
            tableNumber: (map['tableNumber'] as num?)?.toInt() ?? 1,
            status: ReservationStatus.values.firstWhere(
              (s) => s.name == map['status'],
              orElse: () => ReservationStatus.pending,
            ),
            notes: map['notes'] as String?,
            createdAt: map['createdAt'] != null
                ? DateTime.parse(map['createdAt'] as String)
                : DateTime.now(),
          )).toList();
          return Right(list);
        }
      }
      return const Right([]);
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
      final parsedTableId = int.tryParse(reservation.tableId.replaceAll(RegExp(r'[^0-9]'), ''));
      final payload = {
        'user_id': _sanitizeUuid(currentUserId),
        'customer_name': reservation.customerName,
        'phone': reservation.customerPhone,
        'party_size': reservation.guestCount,
        'reservation_time': reservation.reservationTime.toIso8601String(),
        'table_id': parsedTableId,
        'table_number': reservation.tableNumber,
        'status': reservation.status.name,
        'notes': reservation.notes,
        'created_at': reservation.createdAt.toIso8601String(),
        'restaurant_id': SupabaseConfig.defaultRestaurantId,
      };

      Map<String, dynamic> response;
      try {
        final res = await _supabase.from(SupabaseConfig.reservationsTable).insert(payload).select().single();
        response = Map<String, dynamic>.from(res);
      } catch (e) {
        if (e.toString().contains('phone') ||
            e.toString().contains('PGRST204')) {
          final legacyPayload = Map<String, dynamic>.from(payload)
            ..remove('phone')
            ..['customer_phone'] = reservation.customerPhone;
          final res = await _supabase
              .from(SupabaseConfig.reservationsTable)
              .insert(legacyPayload)
              .select()
              .single();
          response = Map<String, dynamic>.from(res);
        } else {
          rethrow;
        }
      }

      final created = reservation.copyWith(
        id: response['id']?.toString() ?? reservation.id,
      );
      return Right(created);
    } catch (e, st) {
      AppLogger.error('Supabase createReservation error', error: e, stackTrace: st);
      return Left(ServerFailure('فشل إنشاء الحجز: $e'));
    }
  }

  @override
  Future<Either<Failure, ReservationEntity>> updateStatus(
    String id,
    ReservationStatus status,
  ) async {
    try {
      final parsedId = int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), ''));
      final query = _supabase.from(SupabaseConfig.reservationsTable).update({
        'status': status.name,
      });

      Map<String, dynamic> response;
      if (parsedId != null) {
        final res = await query.eq('id', parsedId).select().single();
        response = Map<String, dynamic>.from(res);
      } else {
        final res = await query.eq('id', id).select().single();
        response = Map<String, dynamic>.from(res);
      }

      return Right(_mapToReservationEntity(response));
    } catch (e, st) {
      AppLogger.error('Supabase updateStatus error', error: e, stackTrace: st);
      return Left(ServerFailure('فشل تحديث حالة الحجز: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelReservation(String id) async {
    final result = await updateStatus(id, ReservationStatus.cancelled);
    return result.when(
      onLeft: (f) => Left(f),
      onRight: (_) => const Right(null),
    );
  }

  ReservationEntity _mapToReservationEntity(Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'pending';
    final status = ReservationStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => ReservationStatus.pending,
    );

    return ReservationEntity(
      id: map['id']?.toString() ?? '',
      customerName: map['customer_name'] as String? ?? 'عميل',
      customerPhone: map['phone'] as String? ??
          map['customer_phone'] as String? ??
          '',
      guestCount: (map['party_size'] as num?)?.toInt() ??
          (map['guest_count'] as num?)?.toInt() ??
          2,
      reservationTime: map['reservation_time'] != null
          ? DateTime.tryParse(map['reservation_time'] as String) ??
                DateTime.now()
          : DateTime.now(),
      tableId: map['table_id']?.toString() ?? '',
      tableNumber: (map['table_number'] as num?)?.toInt() ?? 1,
      status: status,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
