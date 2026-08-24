import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/coupon_entity.dart';
import '../../domain/repositories/coupon_repository.dart';

class InMemoryCouponRepository implements CouponRepository {
  final List<CouponEntity> _coupons = [
    CouponEntity(
      id: 'cpn-1',
      code: 'WELCOME50',
      title: 'خصم الترحيب 50% لأهل مصر',
      discountType: CouponDiscountType.percentage,
      discountValue: 50.0,
      minOrderAmount: 40.0,
      maxDiscountAmount: 30.0,
      validUntil: DateTime.now().add(const Duration(days: 60)),
      usageLimit: 1000,
      usageCount: 142,
      isActive: true,
    ),
    CouponEntity(
      id: 'cpn-2',
      code: 'OM_ELDONYA',
      title: 'خصم أم الدنيا 20%',
      discountType: CouponDiscountType.percentage,
      discountValue: 20.0,
      minOrderAmount: 50.0,
      maxDiscountAmount: 40.0,
      validUntil: DateTime.now().add(const Duration(days: 30)),
      usageLimit: 500,
      usageCount: 89,
      isActive: true,
    ),
    CouponEntity(
      id: 'cpn-3',
      code: 'VIP15',
      title: 'خصم 15 جنيه مباشر لكبار العملاء',
      discountType: CouponDiscountType.fixed,
      discountValue: 15.0,
      minOrderAmount: 60.0,
      validUntil: DateTime.now().add(const Duration(days: 90)),
      usageLimit: 2000,
      usageCount: 310,
      isActive: true,
    ),
    CouponEntity(
      id: 'cpn-4',
      code: 'ELPRINCE',
      title: 'عرض لمة العيلة 25%',
      discountType: CouponDiscountType.percentage,
      discountValue: 25.0,
      minOrderAmount: 80.0,
      maxDiscountAmount: 50.0,
      validUntil: DateTime.now().add(const Duration(days: 45)),
      usageLimit: 800,
      usageCount: 215,
      isActive: true,
    ),
  ];

  @override
  Future<Either<Failure, List<CouponEntity>>> getCoupons() async {
    return right(List.unmodifiable(_coupons));
  }

  @override
  Future<Either<Failure, CouponEntity>> validateAndGetCoupon(
    String code,
    double subtotal,
  ) async {
    final cleanCode = code.trim().toUpperCase();
    final matches = _coupons.where((c) => c.code.toUpperCase() == cleanCode);

    if (matches.isEmpty) {
      return left(
        const Failure.validation(
          'كود الخصم المدخل غير صحيح، يرجى التأكد وإعادة المحاولة',
        ),
      );
    }

    final coupon = matches.first;
    final error = coupon.validate(subtotal);
    if (error != null) {
      return left(Failure.validation(error));
    }

    return right(coupon);
  }

  @override
  Future<Either<Failure, CouponEntity>> createCoupon(
    CouponEntity coupon,
  ) async {
    final cleanCode = coupon.code.trim().toUpperCase();
    if (_coupons.any((c) => c.code.toUpperCase() == cleanCode)) {
      return left(const Failure.validation('كود الخصم هذا مستخدم مسبقاً'));
    }

    _coupons.insert(0, coupon);
    return right(coupon);
  }

  @override
  Future<Either<Failure, CouponEntity>> updateCoupon(
    CouponEntity coupon,
  ) async {
    final index = _coupons.indexWhere((c) => c.id == coupon.id);
    if (index == -1) {
      return left(const Failure.notFound('الكوبون غير موجود'));
    }

    _coupons[index] = coupon;
    return right(coupon);
  }

  @override
  Future<Either<Failure, void>> deleteCoupon(String id) async {
    _coupons.removeWhere((c) => c.id == id);
    return right(null);
  }

  @override
  Future<Either<Failure, void>> incrementUsage(String code) async {
    final index = _coupons.indexWhere(
      (c) => c.code.toUpperCase() == code.trim().toUpperCase(),
    );
    if (index != -1) {
      final current = _coupons[index];
      _coupons[index] = current.copyWith(usageCount: current.usageCount + 1);
    }
    return right(null);
  }
}
