import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../restaurant/domain/entities/restaurant_entity.dart';

/// Supabase-backed repository for the single restaurant profile row.
///
/// Single-row setup model: the app instance is tied to
/// [SupabaseConfig.defaultRestaurantId] and the manager edits that row only.
/// No insert/delete, no logo upload (per product decision).
/// Source of truth is always Supabase — no seed, no Hive mirror.
class SupabaseRestaurantRepository {
  SupabaseRestaurantRepository(
    this._supabase, {
    String Function()? restaurantIdProvider,
  }) : _restaurantIdProvider = restaurantIdProvider;

  final SupabaseClient _supabase;
  final String Function()? _restaurantIdProvider;

  String get _restaurantId =>
      _restaurantIdProvider?.call() ?? SupabaseConfig.defaultRestaurantId;

  /// Registers a new SaaS restaurant tenant and assigns the current user as admin.
  Future<Either<Failure, Map<String, dynamic>>> registerNewTenant({
    required String name,
    String? address,
    String? phone,
    String currency = 'ج.م',
    String? vatNumber,
  }) async {
    try {
      final response = await _supabase.rpc(
        'register_new_tenant',
        params: {
          'p_name': name,
          'p_address': address ?? 'الفرع الرئيسي',
          'p_phone': phone ?? '0000000000',
          'p_currency': currency,
          'p_vat_number': vatNumber,
        },
      );
      return Right(Map<String, dynamic>.from(response as Map));
    } catch (e, st) {
      AppLogger.error(
        'Supabase registerNewTenant error: $e',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure('فشل إنشاء المطعم الجديد: $e'));
    }
  }

  Future<Either<Failure, RestaurantEntity>> getRestaurant() async {
    try {
      final raw = await _supabase
          .from(SupabaseConfig.restaurantsTable)
          .select()
          .eq('id', _restaurantId)
          .single();
      return Right(_mapToEntity(Map<String, dynamic>.from(raw as Map)));
    } catch (e, st) {
      AppLogger.error(
        'Supabase getRestaurant error: $e',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure('فشل تحميل بيانات المطعم: $e'));
    }
  }

  Future<Either<Failure, int>> getActualTablesCount() async {
    try {
      try {
        final rpcCount = await _supabase.rpc('restaurant_actual_tables_count');
        if (rpcCount is num) {
          return Right(rpcCount.toInt());
        }
      } catch (_) {
        // Fallback to direct count if RPC isn't available
      }
      final response = await _supabase
          .from(SupabaseConfig.tablesTable)
          .select('id');
      return Right((response as List).length);
    } catch (e, st) {
      AppLogger.warning(
        'Supabase getActualTablesCount error: $e',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure('فشل حساب عدد الطاولات الفعلي: $e'));
    }
  }

  Future<Either<Failure, RestaurantEntity>> updateRestaurant({
    required String name,
    required String address,
    required String phone,
    required String openTime,
    required String closeTime,
    required double latitude,
    required double longitude,
    required int totalTables,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name.trim(),
        'address': address.trim(),
        'phone': phone.trim(),
        'open_time': openTime,
        'close_time': closeTime,
        'latitude': latitude,
        'longitude': longitude,
        'total_tables': totalTables,
        'updated_at': DateTime.now().toIso8601String(),
      };
      final raw = await _supabase
          .from(SupabaseConfig.restaurantsTable)
          .update(payload)
          .eq('id', _restaurantId)
          .select()
          .single();
      return Right(_mapToEntity(Map<String, dynamic>.from(raw as Map)));
    } catch (e, st) {
      AppLogger.error(
        'Supabase updateRestaurant error: $e',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure('فشل حفظ بيانات المطعم: $e'));
    }
  }

  RestaurantEntity _mapToEntity(Map<String, dynamic> map) {
    return RestaurantEntity(
      id: map['id']?.toString() ?? _restaurantId,
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      logoUrl: map['logo_url'] as String?,
      hours: BusinessHours(
        openTime: map['open_time'] as String? ?? '10:00',
        closeTime: map['close_time'] as String? ?? '23:00',
      ),
      totalTables: (map['total_tables'] as num?)?.toInt() ?? 0,
    );
  }
}
