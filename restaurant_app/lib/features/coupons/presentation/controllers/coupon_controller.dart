import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_config.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../data/repositories/in_memory_coupon_repository.dart';
import '../../data/repositories/supabase_coupon_repository.dart';
import '../../domain/entities/coupon_entity.dart';
import '../../domain/repositories/coupon_repository.dart';

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  if (AppConfig.useSupabase) {
    return SupabaseCouponRepository(
      supabase: ref.watch(supabaseClientProvider),
    );
  }
  return InMemoryCouponRepository();
});

/// Holds the currently applied coupon in the cart / checkout.
class AppliedCouponNotifier extends StateNotifier<CouponEntity?> {
  AppliedCouponNotifier() : super(null);

  void apply(CouponEntity coupon) => state = coupon;

  void remove() => state = null;
}

final appliedCouponProvider =
    StateNotifierProvider<AppliedCouponNotifier, CouponEntity?>((ref) {
      return AppliedCouponNotifier();
    });

/// Controller for managing coupons catalog (CRUD for manager).
class CouponManagementController
    extends StateNotifier<AsyncValue<List<CouponEntity>>> {
  final CouponRepository _repository;

  CouponManagementController(this._repository)
    : super(const AsyncValue.loading()) {
    loadCoupons();
  }

  Future<void> loadCoupons() async {
    state = const AsyncValue.loading();
    final result = await _repository.getCoupons();
    result.when(
      onLeft: (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      onRight: (coupons) => state = AsyncValue.data(coupons),
    );
  }

  Future<String?> createCoupon(CouponEntity coupon) async {
    final result = await _repository.createCoupon(coupon);
    return result.when(
      onLeft: (failure) => failure.message,
      onRight: (_) {
        loadCoupons();
        return null;
      },
    );
  }

  Future<String?> updateCoupon(CouponEntity coupon) async {
    final result = await _repository.updateCoupon(coupon);
    return result.when(
      onLeft: (failure) => failure.message,
      onRight: (_) {
        loadCoupons();
        return null;
      },
    );
  }

  Future<void> deleteCoupon(String id) async {
    await _repository.deleteCoupon(id);
    loadCoupons();
  }
}

final couponManagementControllerProvider =
    StateNotifierProvider<
      CouponManagementController,
      AsyncValue<List<CouponEntity>>
    >((ref) {
      final repo = ref.watch(couponRepositoryProvider);
      return CouponManagementController(repo);
    });
