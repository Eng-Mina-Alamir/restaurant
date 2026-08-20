import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/coupons/domain/entities/coupon_entity.dart';

void main() {
  group('Coupon Boundary & Edge Cases Unit Tests', () {
    test('matchesCode handles lowercase, uppercase, and leading/trailing whitespace', () {
      const coupon = CouponEntity(
        id: 'c-1',
        code: 'PROMO2026',
        title: 'خصم رأس السنة',
        discountType: CouponDiscountType.percentage,
        discountValue: 20.0,
      );

      expect(coupon.matchesCode('PROMO2026'), isTrue);
      expect(coupon.matchesCode('promo2026'), isTrue);
      expect(coupon.matchesCode('  Promo2026  '), isTrue);
      expect(coupon.matchesCode('\tPROMO2026\n'), isTrue);
      expect(coupon.matchesCode('OTHERCODE'), isFalse);
      expect(coupon.matchesCode(null), isFalse);
    });

    test('Fixed discount larger than subtotal is clamped to exact subtotal (no negative total)', () {
      const largeFixedCoupon = CouponEntity(
        id: 'c-large',
        code: 'SAVE100',
        title: 'قسيمة 100 ريال',
        discountType: CouponDiscountType.fixed,
        discountValue: 100.0,
      );

      // Subtotal 40 SAR -> Discount should be 40 SAR (not 100 SAR)
      final discount = largeFixedCoupon.calculateDiscount(40.0);
      expect(discount, 40.0);
    });

    test('Percentage discount with max cap enforces maximum limit accurately', () {
      const cappedPercentCoupon = CouponEntity(
        id: 'c-cap',
        code: 'HALFPRICE',
        title: 'خصم 50% بحد أقصى 30 ريال',
        discountType: CouponDiscountType.percentage,
        discountValue: 50.0,
        maxDiscountAmount: 30.0,
      );

      // 50% of 40 SAR = 20 SAR (< 30 SAR max)
      expect(cappedPercentCoupon.calculateDiscount(40.0), 20.0);

      // 50% of 100 SAR = 50 SAR -> capped at 30 SAR
      expect(cappedPercentCoupon.calculateDiscount(100.0), 30.0);
    });

    test('validUntil expiration rejects expired coupons and accepts active ones', () {
      final now = DateTime.now();
      final expiredCoupon = CouponEntity(
        id: 'c-exp',
        code: 'EXPIRED',
        title: 'منتهي',
        discountType: CouponDiscountType.fixed,
        discountValue: 15.0,
        validUntil: now.subtract(const Duration(seconds: 5)),
      );

      expect(expiredCoupon.validate(50.0), isNotNull);
      expect(expiredCoupon.validate(50.0), contains('انتهت صلاحية'));
      expect(expiredCoupon.calculateDiscount(50.0), 0.0);

      final activeCoupon = CouponEntity(
        id: 'c-act',
        code: 'ACTIVE',
        title: 'فعال',
        discountType: CouponDiscountType.fixed,
        discountValue: 15.0,
        validUntil: now.add(const Duration(hours: 2)),
      );

      expect(activeCoupon.validate(50.0), isNull);
      expect(activeCoupon.calculateDiscount(50.0), 15.0);
    });

    test('usageLimit boundary enforces max redemption count', () {
      const exhaustedCoupon = CouponEntity(
        id: 'c-used',
        code: 'MAXED',
        title: 'مستنفذ',
        discountType: CouponDiscountType.fixed,
        discountValue: 20.0,
        usageLimit: 10,
        usageCount: 10,
      );

      expect(exhaustedCoupon.validate(50.0), isNotNull);
      expect(exhaustedCoupon.validate(50.0), contains('للحد الأقصى'));
      expect(exhaustedCoupon.calculateDiscount(50.0), 0.0);

      final availableCoupon = exhaustedCoupon.copyWith(usageCount: 9);
      expect(availableCoupon.validate(50.0), isNull);
      expect(availableCoupon.calculateDiscount(50.0), 20.0);
    });

    test('minOrderAmount requirement enforces minimum order threshold', () {
      const minSpendCoupon = CouponEntity(
        id: 'c-min',
        code: 'BIGORDER',
        title: 'للطلبات الكبيرة',
        discountType: CouponDiscountType.fixed,
        discountValue: 25.0,
        minOrderAmount: 100.0,
      );

      expect(minSpendCoupon.validate(80.0), isNotNull);
      expect(minSpendCoupon.validate(80.0), contains('الحد الأدنى لتطبيق هذا الكود هو 100.0 ريال'));
      expect(minSpendCoupon.calculateDiscount(80.0), 0.0);

      expect(minSpendCoupon.validate(100.0), isNull);
      expect(minSpendCoupon.calculateDiscount(100.0), 25.0);
    });

    test('handles 0 and negative subtotal gracefully', () {
      const coupon = CouponEntity(
        id: 'c-safe',
        code: 'SAVE10',
        title: 'خصم 10',
        discountType: CouponDiscountType.fixed,
        discountValue: 10.0,
      );

      expect(coupon.calculateDiscount(0.0), 0.0);
      expect(coupon.calculateDiscount(-30.0), 0.0);
    });
  });
}
