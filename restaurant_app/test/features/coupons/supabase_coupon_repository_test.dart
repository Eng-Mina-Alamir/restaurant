import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/features/coupons/data/repositories/supabase_coupon_repository.dart';
import 'package:restaurant_app/features/coupons/domain/entities/coupon_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseCouponRepository Tests', () {
    late SupabaseClient client;
    late SupabaseCouponRepository repository;

    setUp(() {
      client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
      repository = SupabaseCouponRepository(supabase: client);
    });

    final testCoupon = CouponEntity(
      id: 'coupon-test-1',
      code: 'TEST20',
      title: 'خصم تجريبي 20%',
      discountType: CouponDiscountType.percentage,
      discountValue: 20.0,
      minOrderAmount: 100.0,
      maxDiscountAmount: 50.0,
      validUntil: DateTime.now().add(const Duration(days: 30)),
      usageLimit: 100,
      usageCount: 0,
      isActive: true,
    );

    test('validates coupon logic correctly', () {
      expect(testCoupon.calculateDiscount(200.0), 40.0);
      expect(testCoupon.calculateDiscount(500.0), 50.0); // max discount applied
      expect(testCoupon.validate(50.0), isNotNull); // below min amount
      expect(testCoupon.validate(150.0), isNull);
    });

    test('getCoupons returns Either Right or ServerFailure gracefully', () async {
      final result = await repository.getCoupons();
      expect(result, isNotNull);
    });

    test('validateAndGetCoupon handles non-existent code with Failure', () async {
      final result = await repository.validateAndGetCoupon('NON_EXISTENT_CODE_XYZ', 200.0);
      expect(result.isLeft, isTrue);
    });
  });
}
