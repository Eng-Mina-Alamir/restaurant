import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/errors/either.dart';
import 'package:restaurant_app/core/errors/failures.dart';
import 'package:restaurant_app/core/utils/logger.dart';
import 'package:restaurant_app/features/cart/domain/entities/cart_item.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_status_log_entry.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

import '../helpers/test_container.dart';

/// Chef identities exercising the multi-chef KDS flow.
const String _chefA = 'chef-alice';
const String _chefB = 'chef-bob';

/// Extracts the Right payload or returns [onLeftResult] on a Left.
///
/// Small local shim so assertions stay readable without repeating casts.
T _unwrap<T>(
  Either<Failure, T> result,
  T onLeftResult,
) =>
    result.when(onLeft: (_) => onLeftResult, onRight: (value) => value);

void main() {
  setUp(() {
    AppLogger.enabled = false;
  });

  tearDown(() {
    AppLogger.enabled = true;
  });

  test(
      'KDS claim scopes visibility per chef and guarded reverts are capped at '
      'two with an oldest-first isRevert audit trail',
      () async {
    // The repository instance is created HERE (instead of inside
    // createTestContainer) so the audit-trail assertions read the exact same
    // store the controller persists through — no network, no wall-clock waits.
    final orderRepo = InMemoryOrderRepository();
    final container = createTestContainer(
      seedCheckoutFixtures: true,
      additionalOverrides: [
        orderRepositoryProvider.overrideWithValue(orderRepo),
      ],
    );
    addTearDown(container.dispose);

    /// Filtered-view simulation of kds_page: each chef sees unclaimed active
    /// tickets plus the ones they personally claimed
    /// (assignedKitchenId == null || == currentUserId).
    List<OrderEntity> visibleTo(String chefId) => container
        .read(ordersControllerProvider)
        .where((o) => !o.status.isTerminal)
        .where(
          (o) => o.assignedKitchenId == null || o.assignedKitchenId == chefId,
        )
        .toList();

    // ── 1) Place a DINE-IN order through the real cart → checkout providers
    //       (fixture menu primed for checkout-time revalidation), then walk
    //       pending → preparing → ready exactly as the KDS advance button does.
    await primeMenuForCheckout(container);
    container.read(cartControllerProvider.notifier).addItem(
          CartItem(menuItem: checkoutFixtureItems.first),
        );

    final orders = container.read(ordersControllerProvider.notifier);
    final order = await orders.placeOrderForTable('T-12');
    expect(order, isNotNull);
    expect(order!.orderType, OrderType.dineIn);
    expect(order.tableId, 'T-12');
    expect(order.status, OrderStatus.pending);
    expect(order.assignedKitchenId, isNull);
    expect(container.read(cartControllerProvider), isEmpty);

    // Unclaimed tickets are visible to EVERY chef before a claim lands.
    expect(
      visibleTo(_chefA).map((o) => o.id),
      contains(order.id),
    );
    expect(
      visibleTo(_chefB).map((o) => o.id),
      contains(order.id),
    );

    final preparing =
        await orders.updateStatus(order.id, OrderStatus.preparing);
    expect(preparing?.status, OrderStatus.preparing);

    final ready = await orders.updateStatus(order.id, OrderStatus.ready);
    expect(ready?.status, OrderStatus.ready);

    // ── 2) Chef A claims the ticket (استلام الطلب): optimistic stamp AND
    //       persisted assignment must both carry chefA's id.
    final claimed = await orders.claim(order.id, kitchenUserId: _chefA);
    expect(claimed?.assignedKitchenId, _chefA);
    expect(orders.orderById(order.id)?.assignedKitchenId, _chefA);

    final storedAfterClaim =
        _unwrap(await orderRepo.getOrders(), <OrderEntity>[]);
    expect(
      storedAfterClaim.singleWhere((o) => o.id == order.id).assignedKitchenId,
      _chefA,
    );

    // ── 3) Filtered-view simulation: once claimed, the order is EXCLUDED from
    //       chefB's view but still visible to the claiming chef.
    expect(
      visibleTo(_chefB).map((o) => o.id),
      isNot(contains(order.id)),
    );
    expect(
      visibleTo(_chefA).map((o) => o.id),
      contains(order.id),
    );

    // ── 4) FIRST guarded revert ready → preparing (legal): succeeds and the
    //       repository audit trail gains one isRevert entry attributed to the
    //       acting chef. A DISTINCT actor/reason per revert makes the
    //       oldest-first ordering assertion below unambiguous.
    const firstReason = 'تم تجهيز الطبق بالخطأ – تراجع أول';
    final revert1 = await orders.revertStatus(
      order.id,
      OrderStatus.preparing,
      actorId: _chefA,
      reason: firstReason,
    );
    expect(revert1?.status, OrderStatus.preparing);

    var trail =
        _unwrap(await orderRepo.getAuditTrail(order.id), <OrderStatusLogEntry>[]);
    expect(trail, hasLength(1));
    expect(trail.single.isRevert, isTrue);
    expect(trail.single.actorId, _chefA);
    expect(trail.single.fromStatus, OrderStatus.ready);
    expect(trail.single.toStatus, OrderStatus.preparing);
    expect(trail.single.reason, firstReason);

    // ── 5) SECOND revert cycle: re-advance to ready, revert again (still
    //       within the two-revert quota) — succeeds. Then re-advance once more
    //       so the THIRD attempt has a legal shape (ready → preparing) and can
    //     reach the quota rule instead of being stopped by the domain guard.
    final reReady = await orders.updateStatus(order.id, OrderStatus.ready);
    expect(reReady?.status, OrderStatus.ready);

    const secondReason = 'نقص مكونات – تراجع ثانٍ';
    final revert2 = await orders.revertStatus(
      order.id,
      OrderStatus.preparing,
      actorId: _chefB,
      reason: secondReason,
    );
    expect(revert2?.status, OrderStatus.preparing);

    final reReadyAgain = await orders.updateStatus(order.id, OrderStatus.ready);
    expect(reReadyAgain?.status, OrderStatus.ready);

    // Third attempt: quota spent → the controller rolls back its optimistic
    // update and reports null; the order stays READY.
    final revert3 = await orders.revertStatus(
      order.id,
      OrderStatus.preparing,
      actorId: _chefA,
      reason: 'يجب أن يُرفض',
    );
    expect(revert3, isNull);
    expect(orders.orderById(order.id)?.status, OrderStatus.ready);

    // Same attempt straight against the repository pins the rejection type:
    // ValidationFailure with the max-two-reverts message.
    final directThird = await orderRepo.revertStatus(
      order.id,
      OrderStatus.preparing,
      actorId: _chefA,
    );
    expect(directThird.isLeft, isTrue);
    final failure = (directThird as Left<Failure, OrderEntity>).value;
    expect(failure, isA<ValidationFailure>());
    expect(
      failure.message,
      'تم تجاوز الحد المسموح للتراجع عن هذا الطلب (مرتان كحد أقصى)',
    );
    expect(orders.orderById(order.id)?.status, OrderStatus.ready);

    // ── 6) Audit trail: exactly TWO entries, BOTH flagged isRevert, returned
    //       OLDEST-FIRST (revert #1 by chefA precedes revert #2 by chefB).
    trail = _unwrap(await orderRepo.getAuditTrail(order.id), <OrderStatusLogEntry>[]);
    expect(trail, hasLength(2));
    expect(trail.every((e) => e.isRevert), isTrue);
    expect(trail[0].actorId, _chefA);
    expect(trail[0].reason, firstReason);
    expect(trail[1].actorId, _chefB);
    expect(trail[1].reason, secondReason);
    // Oldest-first also holds chronologically: timestamps never go backwards.
    final createdAts = <DateTime>[for (final e in trail) e.createdAt];
    for (var i = 1; i < createdAts.length; i++) {
      expect(
        createdAts[i].isBefore(createdAts[i - 1]),
        isFalse,
        reason: 'audit trail must be ordered oldest-first',
      );
    }

    // Rejected third attempt logged nothing extra anywhere in the store.
    expect(orderRepo.statusLog.where((e) => e.orderId == order.id),
        hasLength(2));

    // Claimed ownership survives the whole revert saga.
    final storedAtEnd = _unwrap(await orderRepo.getOrders(), <OrderEntity>[]);
    expect(
      storedAtEnd.singleWhere((o) => o.id == order.id).assignedKitchenId,
      _chefA,
    );
    expect(storedAtEnd.singleWhere((o) => o.id == order.id).status,
        OrderStatus.ready);
  });
}
