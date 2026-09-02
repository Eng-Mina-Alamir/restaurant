import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/data/local_cache_service.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/coupon_entity.dart';
import '../../domain/repositories/coupon_repository.dart';

class SupabaseCouponRepository implements CouponRepository {
  SupabaseCouponRepository({
    required SupabaseClient supabase,
    LocalCacheService? cache,
  })  : _supabase = supabase,
        _cache = cache;

  final SupabaseClient _supabase;
  final LocalCacheService? _cache;

  static const String _couponsCacheKey = 'coupons_v1';

  @override
  Future<Either<Failure, List<CouponEntity>>> getCoupons() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.couponsTable)
          .select()
          .order('code');

      final List<CouponEntity> coupons = [];
      for (final raw in (response as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        coupons.add(_mapToCouponEntity(map));
      }

      final cache = _cache;
      if (cache != null) {
        await cache.writeList(
          _couponsCacheKey,
          coupons.map((c) => {
            'id': c.id,
            'code': c.code,
            'title': c.title,
            'discountType': c.discountType.name,
            'discountValue': c.discountValue,
            'minOrderAmount': c.minOrderAmount,
            'maxDiscountAmount': c.maxDiscountAmount,
            'validUntil': c.validUntil?.toIso8601String(),
            'usageLimit': c.usageLimit,
            'usageCount': c.usageCount,
            'isActive': c.isActive,
          }).toList(),
        );
      }

      return Right(coupons);
    } catch (e, st) {
      AppLogger.warning('Supabase getCoupons fallback: $e', error: e, stackTrace: st);
      final cache = _cache;
      if (cache != null) {
        final cached = cache.readList(_couponsCacheKey);
        if (cached.isNotEmpty) {
          final coupons = cached.map((map) => CouponEntity(
            id: map['id']?.toString() ?? '',
            code: map['code'] as String? ?? '',
            title: map['title'] as String? ?? '',
            discountType: CouponDiscountType.values.firstWhere(
              (t) => t.name == map['discountType'],
              orElse: () => CouponDiscountType.percentage,
            ),
            discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0.0,
            minOrderAmount: (map['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
            maxDiscountAmount: (map['maxDiscountAmount'] as num?)?.toDouble(),
            validUntil: map['validUntil'] != null
                ? DateTime.tryParse(map['validUntil'] as String)
                : null,
            usageLimit: (map['usageLimit'] as num?)?.toInt(),
            usageCount: (map['usageCount'] as num?)?.toInt() ?? 0,
            isActive: map['isActive'] as bool? ?? true,
          )).toList();
          return Right(coupons);
        }
      }
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, CouponEntity>> validateAndGetCoupon(
    String code,
    double subtotal,
  ) async {
    try {
      final cleanCode = code.trim().toUpperCase();
      final response = await _supabase
          .from(SupabaseConfig.couponsTable)
          .select()
          .eq('code', cleanCode)
          .maybeSingle();

      CouponEntity coupon;
      if (response != null) {
        coupon = _mapToCouponEntity(Map<String, dynamic>.from(response));
      } else {
        return const Left(
          ValidationFailure(
            'كود الخصم المدخل غير صحيح، يرجى التأكد وإعادة المحاولة',
          ),
        );
      }

      final error = coupon.validate(subtotal);
      if (error != null) {
        return Left(ValidationFailure(error));
      }

      return Right(coupon);
    } catch (e, st) {
      AppLogger.warning('Supabase validateAndGetCoupon fallback: $e', error: e, stackTrace: st);
      final cache = _cache;
      if (cache != null) {
        final cleanCode = code.trim().toUpperCase();
        final cached = cache.readList(_couponsCacheKey);
        final matches = cached.where((m) => (m['code'] as String?)?.toUpperCase() == cleanCode);
        if (matches.isNotEmpty) {
          final map = matches.first;
          final coupon = CouponEntity(
            id: map['id']?.toString() ?? '',
            code: map['code'] as String? ?? '',
            title: map['title'] as String? ?? '',
            discountType: CouponDiscountType.values.firstWhere(
              (t) => t.name == map['discountType'],
              orElse: () => CouponDiscountType.percentage,
            ),
            discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0.0,
            minOrderAmount: (map['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
            maxDiscountAmount: (map['maxDiscountAmount'] as num?)?.toDouble(),
            validUntil: map['validUntil'] != null
                ? DateTime.tryParse(map['validUntil'] as String)
                : null,
            usageLimit: (map['usageLimit'] as num?)?.toInt(),
            usageCount: (map['usageCount'] as num?)?.toInt() ?? 0,
            isActive: map['isActive'] as bool? ?? true,
          );
          final error = coupon.validate(subtotal);
          if (error != null) return Left(ValidationFailure(error));
          return Right(coupon);
        }
      }
      return const Left(
        ValidationFailure(
          'كود الخصم المدخل غير صحيح، يرجى التأكد وإعادة المحاولة',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, CouponEntity>> createCoupon(
    CouponEntity coupon,
  ) async {
    try {
      final cleanCode = coupon.code.trim().toUpperCase();
      final payload = {
        'code': cleanCode,
        'title': coupon.title,
        'discount_type': coupon.discountType.name,
        'discount_value': coupon.discountValue,
        'discount_percent': coupon.discountType == CouponDiscountType.percentage
            ? coupon.discountValue
            : 0.0,
        'min_order_amount': coupon.minOrderAmount,
        'max_discount': coupon.maxDiscountAmount,
        'usage_limit': coupon.usageLimit,
        'usage_count': coupon.usageCount,
        'is_active': coupon.isActive,
        'expires_at': coupon.validUntil?.toIso8601String(),
      };

      final response = await _supabase
          .from(SupabaseConfig.couponsTable)
          .insert(payload)
          .select()
          .single();

      final created = coupon.copyWith(
        id: response['id']?.toString() ?? coupon.id,
      );
      return Right(created);
    } catch (e, st) {
      AppLogger.error('Supabase createCoupon error', error: e, stackTrace: st);
      return Left(ServerFailure('فشل إنشاء الكوبون: $e'));
    }
  }

  @override
  Future<Either<Failure, CouponEntity>> updateCoupon(
    CouponEntity coupon,
  ) async {
    try {
      final payload = {
        'code': coupon.code.trim().toUpperCase(),
        'title': coupon.title,
        'discount_type': coupon.discountType.name,
        'discount_value': coupon.discountValue,
        'discount_percent': coupon.discountType == CouponDiscountType.percentage
            ? coupon.discountValue
            : 0.0,
        'min_order_amount': coupon.minOrderAmount,
        'max_discount': coupon.maxDiscountAmount,
        'usage_limit': coupon.usageLimit,
        'usage_count': coupon.usageCount,
        'is_active': coupon.isActive,
        'expires_at': coupon.validUntil?.toIso8601String(),
      };

      await _supabase
          .from(SupabaseConfig.couponsTable)
          .update(payload)
          .eq('id', coupon.id);

      return Right(coupon);
    } catch (e, st) {
      AppLogger.error('Supabase updateCoupon error', error: e, stackTrace: st);
      return Left(ServerFailure('فشل تحديث الكوبون: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCoupon(String id) async {
    try {
      await _supabase.from(SupabaseConfig.couponsTable).delete().eq('id', id);
      return const Right(null);
    } catch (e, st) {
      AppLogger.error('Supabase deleteCoupon error', error: e, stackTrace: st);
      return Left(ServerFailure('فشل حذف الكوبون: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> incrementUsage(String code) async {
    try {
      final cleanCode = code.trim().toUpperCase();
      final current = await _supabase
          .from(SupabaseConfig.couponsTable)
          .select('usage_count')
          .eq('code', cleanCode)
          .maybeSingle();

      if (current != null) {
        final count = (current['usage_count'] as num?)?.toInt() ?? 0;
        await _supabase
            .from(SupabaseConfig.couponsTable)
            .update({'usage_count': count + 1})
            .eq('code', cleanCode);
      }
      return const Right(null);
    } catch (e, st) {
      AppLogger.error(
        'Supabase incrementUsage error',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure('فشل تحديث عدد مرات استخدام الكوبون: $e'));
    }
  }

  CouponEntity _mapToCouponEntity(Map<String, dynamic> map) {
    final discountTypeStr = map['discount_type'] as String?;
    final discountType = discountTypeStr == 'fixed'
        ? CouponDiscountType.fixed
        : CouponDiscountType.percentage;

    final discountVal =
        (map['discount_value'] as num?)?.toDouble() ??
        (map['discount_percent'] as num?)?.toDouble() ??
        0.0;

    return CouponEntity(
      id: map['id']?.toString() ?? '',
      code: map['code'] as String? ?? '',
      title: map['title'] as String? ?? 'كود خصم ${map['code']}',
      discountType: discountType,
      discountValue: discountVal,
      minOrderAmount: (map['min_order_amount'] as num?)?.toDouble() ?? 0.0,
      maxDiscountAmount: (map['max_discount'] as num?)?.toDouble(),
      validUntil: map['expires_at'] != null
          ? DateTime.tryParse(map['expires_at'] as String)
          : null,
      usageLimit: (map['usage_limit'] as num?)?.toInt(),
      usageCount: (map['usage_count'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
