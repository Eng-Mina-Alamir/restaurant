import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/coupon_entity.dart';
import '../../domain/repositories/coupon_repository.dart';

class SupabaseCouponRepository implements CouponRepository {
  SupabaseCouponRepository({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  static final List<CouponEntity> _initialSeedCoupons = [
    const CouponEntity(
      id: 'cpn-01',
      code: 'WELCOME20',
      title: 'خصم ترحيبي 20%',
      discountType: CouponDiscountType.percentage,
      discountValue: 20.0,
      minOrderAmount: 50.0,
      maxDiscountAmount: 40.0,
      usageLimit: 100,
      usageCount: 12,
      isActive: true,
    ),
    const CouponEntity(
      id: 'cpn-02',
      code: 'SUMMER50',
      title: 'عرض الصيف 50 ج.م',
      discountType: CouponDiscountType.fixed,
      discountValue: 50.0,
      minOrderAmount: 150.0,
      usageLimit: 50,
      usageCount: 8,
      isActive: true,
    ),
    const CouponEntity(
      id: 'cpn-03',
      code: 'VIP30',
      title: 'خصم كبار العملاء 30%',
      discountType: CouponDiscountType.percentage,
      discountValue: 30.0,
      minOrderAmount: 100.0,
      maxDiscountAmount: 60.0,
      usageLimit: 200,
      usageCount: 45,
      isActive: true,
    ),
  ];

  List<CouponEntity>? _cachedCoupons;

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
      if (coupons.isEmpty) {
        _cachedCoupons = List.of(_initialSeedCoupons);
        return Right(_cachedCoupons!);
      }
      _cachedCoupons = coupons;
      return Right(coupons);
    } catch (e, st) {
      AppLogger.warning('Supabase getCoupons fallback: $e', error: e, stackTrace: st);
      _cachedCoupons ??= List.of(_initialSeedCoupons);
      return Right(List.unmodifiable(_cachedCoupons!));
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
        final list = _cachedCoupons ?? _initialSeedCoupons;
        final matched = list.where((c) => c.code.toUpperCase() == cleanCode);
        if (matched.isEmpty) {
          return const Left(
            ValidationFailure('كود الخصم المدخل غير صحيح، يرجى التأكد وإعادة المحاولة'),
          );
        }
        coupon = matched.first;
      }

      final error = coupon.validate(subtotal);
      if (error != null) {
        return Left(ValidationFailure(error));
      }

      return Right(coupon);
    } catch (e, st) {
      AppLogger.warning('Supabase validateAndGetCoupon fallback: $e', error: e, stackTrace: st);
      final cleanCode = code.trim().toUpperCase();
      final list = _cachedCoupons ?? _initialSeedCoupons;
      final matched = list.where((c) => c.code.toUpperCase() == cleanCode);
      if (matched.isEmpty) {
        return const Left(
          ValidationFailure('كود الخصم المدخل غير صحيح، يرجى التأكد وإعادة المحاولة'),
        );
      }
      final coupon = matched.first;
      final error = coupon.validate(subtotal);
      if (error != null) {
        return Left(ValidationFailure(error));
      }
      return Right(coupon);
    }
  }

  @override
  Future<Either<Failure, CouponEntity>> createCoupon(CouponEntity coupon) async {
    try {
      final cleanCode = coupon.code.trim().toUpperCase();
      final payload = {
        'id': coupon.id,
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

      await _supabase.from(SupabaseConfig.couponsTable).insert(payload);
      return Right(coupon);
    } catch (e, st) {
      AppLogger.error('Supabase createCoupon error', error: e, stackTrace: st);
      return Left(ServerFailure('فشل إنشاء الكوبون: $e'));
    }
  }

  @override
  Future<Either<Failure, CouponEntity>> updateCoupon(CouponEntity coupon) async {
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
      await _supabase
          .from(SupabaseConfig.couponsTable)
          .delete()
          .eq('id', id);
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
      AppLogger.error('Supabase incrementUsage error', error: e, stackTrace: st);
      return Left(ServerFailure('فشل تحديث عدد مرات استخدام الكوبون: $e'));
    }
  }

  CouponEntity _mapToCouponEntity(Map<String, dynamic> map) {
    final discountTypeStr = map['discount_type'] as String?;
    final discountType = discountTypeStr == 'fixed'
        ? CouponDiscountType.fixed
        : CouponDiscountType.percentage;

    final discountVal = (map['discount_value'] as num?)?.toDouble() ??
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
