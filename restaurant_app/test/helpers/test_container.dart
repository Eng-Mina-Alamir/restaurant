import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_app/features/coupons/data/repositories/in_memory_coupon_repository.dart';
import 'package:restaurant_app/features/coupons/presentation/controllers/coupon_controller.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/inventory/data/repositories/in_memory_inventory_repository.dart';
import 'package:restaurant_app/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:restaurant_app/features/loyalty/data/repositories/in_memory_loyalty_repository.dart';
import 'package:restaurant_app/features/loyalty/presentation/controllers/loyalty_controller.dart';
import 'package:restaurant_app/features/menu/data/menu_seed_data.dart';
import 'package:restaurant_app/features/menu/data/repositories/menu_repository_impl.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu_item.dart';
import 'package:restaurant_app/features/menu/presentation/controllers/menu_controller.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/ratings/data/repositories/in_memory_rating_repository.dart';
import 'package:restaurant_app/features/ratings/presentation/controllers/rating_controller.dart';
import 'package:restaurant_app/features/reservations/data/repositories/in_memory_reservation_repository.dart';
import 'package:restaurant_app/features/reservations/presentation/controllers/reservation_controller.dart';
import 'package:restaurant_app/features/table_management/data/repositories/in_memory_table_repository.dart';
import 'package:restaurant_app/core/supabase/supabase_realtime_service.dart';
import 'package:restaurant_app/features/table_management/data/repositories/in_memory_table_service_repository.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_service_controller.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';
import 'package:restaurant_app/core/di/service_locator.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _TestRealtimeService extends SupabaseRealtimeService {
  _TestRealtimeService()
    : super(
        SupabaseClient(
          SupabaseConfig.url,
          SupabaseConfig.anonKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
}

/// Canonical checkout-fixture menu aligned with the item ids/prices used by
/// controller and widget test fixtures (`b1` @ 28 EGP, `f1` @ 12 EGP).
///
/// Uses [MenuSeedData.restaurantId] so orders built at checkout stay
/// consistent, and MenuSeedData-style Arabic naming/descriptions so any UI
/// text expectations keep matching.
const List<MenuItem> checkoutFixtureItems = <MenuItem>[
  MenuItem(
    id: 'b1',
    categoryId: 'برجر',
    name: 'برجر كلاسيك',
    description: 'لحم بقري بلدي مشوي، جبنة شيدر، خس وطماطم مع صوص خاص',
    price: 28,
  ),
  MenuItem(
    id: 'f1',
    categoryId: 'مقبلات',
    name: 'بطاطس مقلية',
    description: 'بطاطس مقلية ذهبية مقرمشة مع ملح البحر',
    price: 12,
  ),
];

/// The full fixture [Menu] aggregate served when [createTestContainer] is
/// created with `seedCheckoutFixtures: true`.
const Menu checkoutFixtureMenu = Menu(
  restaurantId: MenuSeedData.restaurantId,
  categories: <String>['برجر', 'مقبلات'],
  items: checkoutFixtureItems,
);

/// Builds the [Menu] served when fixture seeding is active, extending the
/// canonical [checkoutFixtureMenu] with [extras].
///
/// Keeps the fixture menu's restaurantId and category list; categories
/// referenced only by extra items are appended at the end so both
/// category-based UIs and id-based lookups succeed. Returns
/// [checkoutFixtureMenu] itself when [extras] is empty.
Menu buildCheckoutFixtureMenu(List<MenuItem> extras) {
  if (extras.isEmpty) return checkoutFixtureMenu;
  final extraCategories = <String>{
    for (final item in extras)
      if (!checkoutFixtureMenu.categories.contains(item.categoryId))
        item.categoryId,
  };
  return Menu(
    restaurantId: checkoutFixtureMenu.restaurantId,
    categories: <String>[...checkoutFixtureMenu.categories, ...extraCategories],
    items: <MenuItem>[...checkoutFixtureItems, ...extras],
  );
}

/// Creates a [ProviderContainer] preconfigured with in-memory test doubles
/// for isolated timeline and integration test runs without remote network calls.
///
/// Pass [seedCheckoutFixtures] to serve [checkoutFixtureMenu] instead of the
/// default [MenuSeedData] menu — required for suites that place orders through
/// [ordersControllerProvider], whose checkout-time revalidation looks items up
/// against the live menu snapshot.
///
/// Pass [extraCheckoutItems] to serve [checkoutFixtureMenu] extended with
/// those items (see [buildCheckoutFixtureMenu]). Passing a non-empty list
/// implies fixture seeding even when [seedCheckoutFixtures] is false. When
/// both parameters are omitted the default [MenuSeedData] menu is served
/// unchanged.
ProviderContainer createTestContainer({
  List<Override> additionalOverrides = const [],
  bool seedCheckoutFixtures = false,
  List<MenuItem> extraCheckoutItems = const [],
}) {
  final serveFixtures = seedCheckoutFixtures || extraCheckoutItems.isNotEmpty;
  return ProviderContainer(
    overrides: [
      menuRepositoryProvider.overrideWithValue(
        serveFixtures
            ? MenuRepositoryImpl(
                initialMenu: buildCheckoutFixtureMenu(extraCheckoutItems),
              )
            : MenuRepositoryImpl(),
      ),
      orderRepositoryProvider.overrideWithValue(InMemoryOrderRepository()),
      deliveryRepositoryProvider.overrideWithValue(
        InMemoryDeliveryRepository(),
      ),
      tableRepositoryProvider.overrideWithValue(InMemoryTableRepository()),
      tableControllerProvider.overrideWith(
        (ref) => TableController(ref.watch(tableRepositoryProvider)),
      ),
      tableServiceControllerProvider.overrideWith(
        (ref) => TableServiceController(InMemoryTableServiceRepository()),
      ),
      supabaseRealtimeServiceProvider.overrideWithValue(_TestRealtimeService()),
      couponRepositoryProvider.overrideWithValue(InMemoryCouponRepository()),
      reservationRepositoryProvider.overrideWithValue(
        InMemoryReservationRepository(),
      ),
      ratingRepositoryProvider.overrideWithValue(InMemoryRatingRepository()),
      inventoryRepositoryProvider.overrideWithValue(
        InMemoryInventoryRepository(),
      ),
      loyaltyRepositoryProvider.overrideWithValue(InMemoryLoyaltyRepository()),
      ...additionalOverrides,
    ],
  );
}

/// Warms up [menuControllerProvider] so checkout-time revalidation can find
/// menu items.
///
/// Required before placing orders in tests because `menuLookup` reads
/// `valueOrNull` and the rejection check runs synchronously before
/// `placeOrder`'s first await — an unprimed provider still reports
/// `AsyncLoading` and every lookup returns null.
Future<void> primeMenuForCheckout(ProviderContainer container) async {
  await container.read(menuControllerProvider.future);
}
