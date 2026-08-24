import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/coupons/data/repositories/in_memory_coupon_repository.dart';
import 'package:restaurant_app/features/coupons/domain/entities/coupon_entity.dart';
import 'package:restaurant_app/features/coupons/presentation/controllers/coupon_controller.dart';

void main() {
  group('AppliedCouponNotifier Unit Tests', () {
    test('starts null, can apply and remove coupon', () {
      final notifier = AppliedCouponNotifier();
      expect(notifier.state, isNull);

      final coupon = CouponEntity(
        id: 'cpn-1',
        code: 'PROMO10',
        title: 'خصم 10%',
        discountType: CouponDiscountType.percentage,
        discountValue: 10,
        isActive: true,
        validUntil: DateTime.now().add(const Duration(days: 5)),
      );

      notifier.apply(coupon);
      expect(notifier.state?.code, 'PROMO10');

      notifier.remove();
      expect(notifier.state, isNull);
    });
  });

  group('CouponManagementController Unit Tests', () {
    late InMemoryCouponRepository repo;
    late CouponManagementController controller;

    setUp(() {
      repo = InMemoryCouponRepository();
      controller = CouponManagementController(repo);
    });

    test('loads coupons and can create, update, and delete coupons', () async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.state, isA<AsyncData<List<CouponEntity>>>());
      final initialCount = controller.state.value!.length;

      final newCoupon = CouponEntity(
        id: 'new-cpn',
        code: 'NEW50',
        title: 'خصم 50%',
        discountType: CouponDiscountType.percentage,
        discountValue: 50,
        isActive: true,
        validUntil: DateTime.now().add(const Duration(days: 10)),
      );

      final errCreate = await controller.createCoupon(newCoupon);
      expect(errCreate, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.state.value!.length, initialCount + 1);

      final updatedCoupon = newCoupon.copyWith(discountValue: 60);
      final errUpdate = await controller.updateCoupon(updatedCoupon);
      expect(errUpdate, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(
        controller.state.value!
            .firstWhere((c) => c.id == 'new-cpn')
            .discountValue,
        60,
      );

      await controller.deleteCoupon('new-cpn');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.state.value!.any((c) => c.id == 'new-cpn'), isFalse);
    });
  });
}
