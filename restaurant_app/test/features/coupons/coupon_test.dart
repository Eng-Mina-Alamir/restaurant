import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/coupons/data/repositories/in_memory_coupon_repository.dart';
import 'package:restaurant_app/features/coupons/domain/entities/coupon_entity.dart';

void main() {
  group('Coupons & Promo Codes Tests', () {
    late InMemoryCouponRepository repository;

    setUp(() {
      repository = InMemoryCouponRepository();
    });

    test('validates valid percentage coupon and applies discount with cap', () async {
      final result = await repository.validateAndGetCoupon('WELCOME50', 50.0);
      expect(result.isRight, isTrue);
      final coupon = result.when(onLeft: (_) => null, onRight: (c) => c);
      expect(coupon, isNotNull);

      // 50% of 50 = 25 (under max cap 30)
      expect(coupon!.calculateDiscount(50.0), 25.0);

      // 50% of 100 = 50 -> capped at 30.0
      expect(coupon.calculateDiscount(100.0), 30.0);
    });

    test('validates fixed discount coupon', () async {
      final result = await repository.validateAndGetCoupon('VIP15', 70.0);
      expect(result.isRight, isTrue);
      final coupon = result.when(onLeft: (_) => null, onRight: (c) => c);
      expect(coupon!.calculateDiscount(70.0), 15.0);
    });

    test('rejects coupon when subtotal is below minimum order requirement', () async {
      // WELCOME50 minOrderAmount is 40.0
      final result = await repository.validateAndGetCoupon('WELCOME50', 20.0);
      expect(result.isLeft, isTrue);
    });

    test('rejects non-existent coupon code', () async {
      final result = await repository.validateAndGetCoupon('FAKECODE99', 100.0);
      expect(result.isLeft, isTrue);
    });

    test('creates, updates and deletes coupons in manager CRUD', () async {
      const newCoupon = CouponEntity(
        id: 'cpn-custom',
        code: 'SPECIAL10',
        title: 'خصم خاص 10%',
        discountType: CouponDiscountType.percentage,
        discountValue: 10.0,
        minOrderAmount: 30.0,
      );


      final createRes = await repository.createCoupon(newCoupon);
      expect(createRes.isRight, isTrue);

      final listRes = await repository.getCoupons();
      final list = listRes.when(onLeft: (_) => null, onRight: (l) => l);
      expect(list!.any((c) => c.code == 'SPECIAL10'), isTrue);

      // Duplicate code creation is rejected
      final duplicateRes = await repository.createCoupon(newCoupon);
      expect(duplicateRes.isLeft, isTrue);

      // Delete coupon
      await repository.deleteCoupon('cpn-custom');
      final updatedListRes = await repository.getCoupons();
      final updatedList = updatedListRes.when(onLeft: (_) => null, onRight: (l) => l);
      expect(updatedList!.any((c) => c.id == 'cpn-custom'), isFalse);
    });
  });
}
