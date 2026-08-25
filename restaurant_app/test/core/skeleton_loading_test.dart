import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';
import 'package:restaurant_app/features/coupons/data/repositories/in_memory_coupon_repository.dart';
import 'package:restaurant_app/features/coupons/domain/entities/coupon_entity.dart';
import 'package:restaurant_app/features/coupons/presentation/controllers/coupon_controller.dart';
import 'package:restaurant_app/features/coupons/presentation/pages/coupon_management_page.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/loyalty/data/repositories/in_memory_loyalty_repository.dart';
import 'package:restaurant_app/features/loyalty/domain/entities/loyalty_entity.dart';
import 'package:restaurant_app/features/loyalty/presentation/controllers/loyalty_controller.dart';
import 'package:restaurant_app/features/loyalty/presentation/pages/loyalty_page.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/controllers/dispatch_controller.dart';
import 'package:restaurant_app/features/manager_dashboard/presentation/pages/dispatch_board_page.dart';
import 'package:restaurant_app/features/menu/domain/entities/menu.dart';
import 'package:restaurant_app/features/menu/presentation/controllers/menu_controller.dart'
    as menu;
import 'package:restaurant_app/features/menu/presentation/pages/menu_management_page.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/shared/animations/shimmer_loading.dart';

import '../helpers/test_container.dart';

// ── Never-loading doubles ─────────────────────────────────────────────────────
//
// Each double pins its page's controller in the initial AsyncLoading state so
// the full-page skeleton branch can be asserted (mirrors the
// NeverEmittingChatRepository pattern used by chat_page_test.dart).

/// Repository whose account lookup never completes.
class _NeverLoadingLoyaltyRepository extends InMemoryLoyaltyRepository {
  @override
  Future<Either<Failure, LoyaltyAccount>> getAccount(String userId) =>
      Completer<Either<Failure, LoyaltyAccount>>().future;
}

/// Controller stuck on the initial loading state forever.
class _HangingLoyaltyController extends LoyaltyController {
  _HangingLoyaltyController()
    : super(repository: _NeverLoadingLoyaltyRepository(), userId: 'test-user');
}

/// Menu source that never resolves, keeping the menu controller loading.
class _HangingMenuController extends menu.MenuController {
  @override
  Future<Menu> build() => Completer<Menu>().future;
}

/// Repository whose coupons lookup never completes.
class _NeverLoadingCouponRepository extends InMemoryCouponRepository {
  @override
  Future<Either<Failure, List<CouponEntity>>> getCoupons() =>
      Completer<Either<Failure, List<CouponEntity>>>().future;
}

/// Controller stuck on the initial loading state forever.
class _HangingCouponController extends CouponManagementController {
  _HangingCouponController() : super(_NeverLoadingCouponRepository());
}

/// Read-only orders source so [dispatchControllerProvider] initializes without
/// side effects (same pattern as dispatch_board_page_test.dart).
class _OrdersControllerStub extends StateNotifier<List<OrderEntity>>
    implements OrdersController {
  _OrdersControllerStub(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Dispatch controller whose refresh never finishes: the base constructor
/// eagerly calls [refresh], which would otherwise flip straight into data —
/// the override keeps the board on its initial loading state.
class _HangingDispatchController extends DispatchController {
  _HangingDispatchController(
    super.repository,
    super.realtimeService, {
    required super.ordersSource,
  });

  @override
  Future<void> refresh() => Completer<void>().future;
}

void main() {
  group('Full-page loading skeletons (design-system MASTER.md §4.3)', () {
    Future<void> pumpPage(
      WidgetTester tester,
      Widget child,
      List<Override> overrides,
    ) async {
      final container = createTestContainer(additionalOverrides: [
        // Static orders source so the dispatch provider initializes without
        // scheduling refresh timers (same pattern as dispatch_board_page_test).
        ordersControllerProvider.overrideWith((ref) => _OrdersControllerStub(const [])),
        ...overrides,
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: child),
        ),
      );
      // One frame for the initial build, one for the loading shell.
      await tester.pump();
      await tester.pump();
    }

    testWidgets('LoyaltyPage renders shimmer skeleton while loading', (
      tester,
    ) async {
      await pumpPage(tester, const LoyaltyPage(), [
        loyaltyControllerProvider.overrideWith((ref) => _HangingLoyaltyController()),
      ]);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ShimmerLoading), findsWidgets);
      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(SkeletonCircle), findsWidgets);
    });

    testWidgets('DispatchBoardPage renders shimmer skeleton while loading', (
      tester,
    ) async {
      await pumpPage(tester, const DispatchBoardPage(), [
        dispatchControllerProvider.overrideWith(
          (ref) => _HangingDispatchController(
            ref.watch(deliveryRepositoryProvider),
            ref.watch(realtimeServiceProvider),
            ordersSource: () => const [],
          ),
        ),
      ]);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ShimmerLoading), findsWidgets);
      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('MenuManagementPage renders shimmer skeleton while loading', (
      tester,
    ) async {
      await pumpPage(tester, const MenuManagementPage(), [
        menu.menuControllerProvider.overrideWith(_HangingMenuController.new),
      ]);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ShimmerLoading), findsWidgets);
      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(SkeletonCircle), findsWidgets);
    });

    testWidgets(
      'CouponManagementPage renders shimmer skeleton while loading',
      (tester) async {
        await pumpPage(tester, const CouponManagementPage(), [
          couponManagementControllerProvider.overrideWith(
            (ref) => _HangingCouponController(),
          ),
        ]);

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(ShimmerLoading), findsWidgets);
        expect(find.byType(SkeletonBox), findsWidgets);
        expect(find.byType(SkeletonCircle), findsWidgets);
      },
    );
  });
}
