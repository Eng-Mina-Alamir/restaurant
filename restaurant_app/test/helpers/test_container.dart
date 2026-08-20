import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_app/features/coupons/data/repositories/in_memory_coupon_repository.dart';
import 'package:restaurant_app/features/coupons/presentation/controllers/coupon_controller.dart';
import 'package:restaurant_app/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:restaurant_app/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:restaurant_app/features/loyalty/data/repositories/in_memory_loyalty_repository.dart';
import 'package:restaurant_app/features/loyalty/presentation/controllers/loyalty_controller.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/ratings/data/repositories/in_memory_rating_repository.dart';
import 'package:restaurant_app/features/ratings/presentation/controllers/rating_controller.dart';
import 'package:restaurant_app/features/reservations/data/repositories/in_memory_reservation_repository.dart';
import 'package:restaurant_app/features/reservations/presentation/controllers/reservation_controller.dart';
import 'package:restaurant_app/features/table_management/data/repositories/in_memory_table_repository.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';

import 'package:restaurant_app/core/di/service_locator.dart';
import 'package:restaurant_app/features/menu/data/repositories/menu_repository_impl.dart';

/// Creates a [ProviderContainer] preconfigured with in-memory test doubles
/// for isolated timeline and integration test runs without remote network calls.
ProviderContainer createTestContainer({
  List<Override> additionalOverrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      menuRepositoryProvider.overrideWithValue(MenuRepositoryImpl()),
      orderRepositoryProvider.overrideWithValue(InMemoryOrderRepository()),
      tableRepositoryProvider.overrideWithValue(InMemoryTableRepository()),
      couponRepositoryProvider.overrideWithValue(InMemoryCouponRepository()),
      reservationRepositoryProvider.overrideWithValue(InMemoryReservationRepository()),
      ratingRepositoryProvider.overrideWithValue(InMemoryRatingRepository()),
      inventoryRepositoryProvider.overrideWithValue(InMemoryInventoryRepository()),
      loyaltyRepositoryProvider.overrideWithValue(InMemoryLoyaltyRepository()),
      ...additionalOverrides,
    ],
  );
}
