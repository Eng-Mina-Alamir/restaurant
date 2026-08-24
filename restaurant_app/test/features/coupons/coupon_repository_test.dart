import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/features/coupons/data/repositories/in_memory_coupon_repository.dart';
import 'package:restaurant_app/features/coupons/domain/entities/coupon_entity.dart';

void main() {
  group('Coupon Repository & Entity Unit Tests', () {
    late InMemoryCouponRepository repository;

    setUp(() {
      repository = InMemoryCouponRepository();
    });

    test('getCoupons returns default active coupons', () async {
      final result = await repository.getCoupons();
      expect(result.isRight, isTrue);
      expect((result as Right<Failure, List<CouponEntity>>).value.length, 4);
    });

    test(
      'validateAndGetCoupon accepts valid coupon meeting min order requirement',
      () async {
        final result = await repository.validateAndGetCoupon(
          'WELCOME50',
          100.0,
        );
        expect(result.isRight, isTrue);
        final coupon = (result as Right<Failure, CouponEntity>).value;
        expect(coupon.code, 'WELCOME50');

        final discount = coupon.calculateDiscount(100.0);
        expect(discount, 30.0); // maxDiscountAmount is 30.0
      },
    );

    test('validateAndGetCoupon rejects order below minimum amount', () async {
      final result = await repository.validateAndGetCoupon('WELCOME50', 20.0);
      expect(result.isLeft, isTrue);
    });

    test('validateAndGetCoupon rejects non-existent code', () async {
      final result = await repository.validateAndGetCoupon(
        'NOT_REAL_CODE',
        100.0,
      );
      expect(result.isLeft, isTrue);
    });

    test('createCoupon prevents duplicate codes', () async {
      const duplicate = CouponEntity(
        id: 'cpn-dup',
        code: 'WELCOME50',
        title: 'Duplicate',
        discountType: CouponDiscountType.fixed,
        discountValue: 10.0,
      );

      final result = await repository.createCoupon(duplicate);
      expect(result.isLeft, isTrue);
    });

    test('createCoupon adds new valid coupon', () async {
      const newCoupon = CouponEntity(
        id: 'cpn-brand-new',
        code: 'SUMMER2026',
        title: 'خصم الصيف',
        discountType: CouponDiscountType.fixed,
        discountValue: 20.0,
      );

      final result = await repository.createCoupon(newCoupon);
      expect(result.isRight, isTrue);

      final all = await repository.getCoupons();
      expect(
        (all as Right<Failure, List<CouponEntity>>).value.any(
          (c) => c.code == 'SUMMER2026',
        ),
        isTrue,
      );
    });

    test('incrementUsage increases coupon usage count', () async {
      await repository.incrementUsage('WELCOME50');
      final all = await repository.getCoupons();
      final coupon = (all as Right<Failure, List<CouponEntity>>).value
          .firstWhere((c) => c.code == 'WELCOME50');
      expect(coupon.usageCount, 143);
    });

    test('deleteCoupon removes coupon', () async {
      await repository.deleteCoupon('cpn-1');
      final all = await repository.getCoupons();
      expect(
        (all as Right<Failure, List<CouponEntity>>).value.any(
          (c) => c.id == 'cpn-1',
        ),
        isFalse,
      );
    });
  });
}
