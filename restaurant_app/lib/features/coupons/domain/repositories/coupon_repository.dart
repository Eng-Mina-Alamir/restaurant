import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/coupon_entity.dart';

abstract class CouponRepository {
  Future<Either<Failure, List<CouponEntity>>> getCoupons();

  Future<Either<Failure, CouponEntity>> validateAndGetCoupon(
    String code,
    double subtotal,
  );

  Future<Either<Failure, CouponEntity>> createCoupon(CouponEntity coupon);

  Future<Either<Failure, CouponEntity>> updateCoupon(CouponEntity coupon);

  Future<Either<Failure, void>> deleteCoupon(String id);

  Future<Either<Failure, void>> incrementUsage(String code);
}
