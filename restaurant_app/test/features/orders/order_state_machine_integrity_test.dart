import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/network/connectivity_service.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';
import 'package:restaurant_app/core/notifications/new_order_notifier.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';

/// Builds a minimal serializable order for realtime seeding.
Map<String, dynamic> _orderJson(
  String id, {
  String orderType = 'takeaway',
  String? tableId,
}) => <String, dynamic>{
  'id': id,
  'restaurantId': 'demo-restaurant-1',
  'customerId': null,
  'tableId': tableId,
  'waiterId': null,
  'orderType': orderType,
  'items': <Map<String, dynamic>>[],
  'status': 'pending',
  'subtotal': 10.0,
  'taxAmount': 1.5,
  'discountAmount': 0.0,
  'totalAmount': 11.5,
  'paymentMethod': null,
  'deliveryAddress': null,
  'deliveryNotes': null,
  'createdAt': DateTime.now().toIso8601String(),
  'completedAt': null,
  'estimatedMinutes': 20,
};

void main() {
  group('Order State Machine Integrity & Transition Guards', () {
    test('pending status valid and invalid transitions', () {
      const status = OrderStatus.pending;
      expect(status.isTerminal, isFalse);

      expect(status.canTransitionTo(OrderStatus.confirmed), isTrue);
      expect(status.canTransitionTo(OrderStatus.preparing), isTrue);
      expect(status.canTransitionTo(OrderStatus.cancelled), isTrue);
      expect(status.canTransitionTo(OrderStatus.pending), isTrue); // Same state

      // Invalid transitions from pending
      expect(status.canTransitionTo(OrderStatus.ready), isFalse);
      expect(status.canTransitionTo(OrderStatus.served), isFalse);
      expect(status.canTransitionTo(OrderStatus.completed), isFalse);
    });

    test('confirmed status valid and invalid transitions', () {
      const status = OrderStatus.confirmed;
      expect(status.canTransitionTo(OrderStatus.preparing), isTrue);
      expect(status.canTransitionTo(OrderStatus.cancelled), isTrue);

      expect(status.canTransitionTo(OrderStatus.pending), isFalse);
      expect(status.canTransitionTo(OrderStatus.served), isFalse);
      expect(status.canTransitionTo(OrderStatus.completed), isFalse);
    });

    test('preparing status valid and invalid transitions', () {
      const status = OrderStatus.preparing;
      expect(status.canTransitionTo(OrderStatus.ready), isTrue);
      expect(status.canTransitionTo(OrderStatus.cancelled), isTrue);

      expect(status.canTransitionTo(OrderStatus.pending), isFalse);
      expect(status.canTransitionTo(OrderStatus.confirmed), isFalse);
      expect(status.canTransitionTo(OrderStatus.completed), isFalse);
    });

    test('ready status valid and invalid transitions', () {
      const status = OrderStatus.ready;
      expect(status.canTransitionTo(OrderStatus.served), isTrue);
      expect(status.canTransitionTo(OrderStatus.completed), isTrue);
      expect(status.canTransitionTo(OrderStatus.cancelled), isTrue);

      expect(status.canTransitionTo(OrderStatus.pending), isFalse);
      expect(status.canTransitionTo(OrderStatus.preparing), isFalse);
    });

    test(
      'served status requires completed transition and blocks direct cancel',
      () {
        const status = OrderStatus.served;
        expect(status.canTransitionTo(OrderStatus.completed), isTrue);

        // Once served to a customer at the table, waiter cannot arbitrarily cancel it
        expect(status.canTransitionTo(OrderStatus.cancelled), isFalse);
        expect(status.canTransitionTo(OrderStatus.pending), isFalse);
        expect(status.canTransitionTo(OrderStatus.preparing), isFalse);
      },
    );

    test(
      'terminal states (completed, cancelled) block all further transitions',
      () {
        expect(OrderStatus.completed.isTerminal, isTrue);
        expect(OrderStatus.cancelled.isTerminal, isTrue);

        for (final next in OrderStatus.values) {
          if (next == OrderStatus.completed) continue;
          expect(OrderStatus.completed.canTransitionTo(next), isFalse);
        }

        for (final next in OrderStatus.values) {
          if (next == OrderStatus.cancelled) continue;
          expect(OrderStatus.cancelled.canTransitionTo(next), isFalse);
        }
      },
    );

    test(
      'OrderStatus.fromName gracefully handles case insensitivity, variants and unknown strings',
      () {
        expect(OrderStatus.fromName('pending'), OrderStatus.pending);
        expect(OrderStatus.fromName('CONFIRMED'), OrderStatus.confirmed);
        expect(OrderStatus.fromName('Preparing'), OrderStatus.preparing);
        expect(OrderStatus.fromName('ready'), OrderStatus.ready);
        expect(OrderStatus.fromName('Served'), OrderStatus.served);
        expect(OrderStatus.fromName('completed'), OrderStatus.completed);
        expect(OrderStatus.fromName('cancelled'), OrderStatus.cancelled);
        expect(
          OrderStatus.fromName('canceled'),
          OrderStatus.cancelled,
        ); // US English single 'l' variant

        expect(OrderStatus.fromName(null), OrderStatus.pending);
        expect(OrderStatus.fromName('UNKNOWN_XYZ'), OrderStatus.pending);
      },
    );
  });

  group('Realtime out-of-order status guard', () {
    late RealtimeService realtime;
    late OrdersController controller;
    late ConnectivityService connectivity;
    late NewOrderNotifier notifier;

    /// Sends an orderStatusChanged event through the loopback socket.
    void emitStatus(String orderId, String status, [DateTime? updatedAt]) {
      realtime.send(
        jsonEncode({
          'type': 'orderStatusChanged',
          'data': {
            'orderId': orderId,
            'status': status,
            if (updatedAt != null) 'updatedAt': updatedAt.toIso8601String(),
          },
        }),
      );
    }

    Future<void> pump() =>
        Future<void>.delayed(const Duration(milliseconds: 15));

    setUp(() {
      realtime = RealtimeService(wsUrl: 'ws://127.0.0.1:9'); // never connects
      realtime.events.listen((_) {}); // initialize the broadcast controller
      connectivity = ConnectivityService();
      notifier = NewOrderNotifier();
      controller = OrdersController(
        InMemoryOrderRepository(),
        // Cart is unused in these tests; orders arrive via realtime.
        CartController(),
        notifier,
        realtimeService: realtime,
        connectivityService: connectivity,
      );
    });

    tearDown(() {
      controller.dispose();
      notifier.dispose();
      connectivity.dispose();
      realtime.disconnect();
    });

    test(
      'a delayed stale event cannot regress an applied transition',
      () async {
        // Seed the order via realtime (arrives as pending).
        realtime.send(
          jsonEncode({'type': 'orderCreated', 'data': _orderJson('ORD-9001')}),
        );
        await pump();
        expect(controller.state.single.id, 'ORD-9001');
        expect(controller.state.single.status, OrderStatus.pending);

        // Locally apply a transition — stamps the last-applied clock.
        final staleMoment = DateTime.now().subtract(const Duration(seconds: 5));
        await controller.updateStatus('ORD-9001', OrderStatus.preparing);
        await pump();
        expect(controller.state.single.status, OrderStatus.preparing);

        // A DELAYED event (stamped before the applied transition) arrives
        // claiming cancellation. ready→cancelled would be legal, so only the
        // timestamp guard prevents regression here.
        emitStatus('ORD-9001', 'cancelled', staleMoment);
        await pump();

        expect(
          controller.state.single.status,
          OrderStatus.preparing,
          reason: 'Stale event must NOT regress preparing → cancelled',
        );
      },
    );

    test('fresh events still progress the order normally', () async {
      realtime.send(
        jsonEncode({'type': 'orderCreated', 'data': _orderJson('ORD-9002')}),
      );
      await pump();

      final t1 = DateTime.now().add(const Duration(milliseconds: 1));
      emitStatus('ORD-9002', 'confirmed', t1);
      await pump();
      expect(controller.state.single.status, OrderStatus.confirmed);

      final t2 = t1.add(const Duration(milliseconds: 1));
      emitStatus('ORD-9002', 'preparing', t2);
      await pump();
      expect(controller.state.single.status, OrderStatus.preparing);
    });

    test('malformed status payloads are ignored without crashing', () async {
      realtime.send(
        jsonEncode({'type': 'orderCreated', 'data': _orderJson('ORD-9003')}),
      );
      await pump();

      // Missing status / missing id / garbage shapes — none may throw.
      realtime.send(jsonEncode({'type': 'orderStatusChanged', 'data': {}}));
      realtime.send(
        jsonEncode({
          'type': 'orderStatusChanged',
          'data': {'status': 'ready'},
        }),
      );
      realtime.send(
        jsonEncode({
          'type': 'orderStatusChanged',
          'data': {'orderId': 'ORD-9003'},
        }),
      );
      realtime.send('this is not json at all');
      await pump();

      expect(
        controller.state.single.status,
        OrderStatus.pending,
        reason: 'Nothing should be applied from malformed payloads',
      );
      expect(controller.state.length, 1);
    });
  });

  group('Realtime revert-event staleness guard (orderStatusReverted)', () {
    late RealtimeService realtime;
    late OrdersController controller;
    late ConnectivityService connectivity;
    late NewOrderNotifier notifier;

    /// Mirrors [RealtimeService.broadcastOrderStatusChanged]'s wire payload.
    void emitStatus(String orderId, String status, DateTime updatedAt) {
      realtime.send(
        jsonEncode({
          'type': 'orderStatusChanged',
          'data': {
            'orderId': orderId,
            'status': status,
            'updatedAt': updatedAt.toIso8601String(),
          },
        }),
      );
    }

    /// Mirrors RealtimeService.broadcastOrderStatusReverted's wire payload:
    /// `status` carries the restored (earlier) status, `fromStatus` the one
    /// being reverted, and `updatedAt` stamps the event for staleness checks.
    void emitRevert(
      String orderId,
      String fromStatus,
      String toStatus,
      DateTime updatedAt,
    ) {
      realtime.send(
        jsonEncode({
          'type': 'orderStatusReverted',
          'data': {
            'orderId': orderId,
            'id': orderId,
            'fromStatus': fromStatus,
            'status': toStatus,
            'updatedAt': updatedAt.toIso8601String(),
          },
        }),
      );
    }

    Future<void> pump() =>
        Future<void>.delayed(const Duration(milliseconds: 15));

    setUp(() {
      realtime = RealtimeService(wsUrl: 'ws://127.0.0.1:9'); // never connects
      realtime.events.listen((_) {}); // initialize the broadcast controller
      connectivity = ConnectivityService();
      notifier = NewOrderNotifier();
      controller = OrdersController(
        InMemoryOrderRepository(),
        // Cart is unused in these tests; orders arrive via realtime.
        CartController(),
        notifier,
        realtimeService: realtime,
        connectivityService: connectivity,
      );
    });

    tearDown(() {
      controller.dispose();
      notifier.dispose();
      connectivity.dispose();
      realtime.disconnect();
    });

    /// Seeds [orderId] as pending via realtime, then advances it remotely to
    /// ready (pending → preparing → ready) with strictly increasing stamps,
    /// leaving `_statusEventAt[orderId] == t1`.
    Future<DateTime> seedAdvancedToReady(String orderId) async {
      realtime.send(
        jsonEncode({'type': 'orderCreated', 'data': _orderJson(orderId)}),
      );
      await pump();
      final t0 = DateTime.now();
      final t1 = t0.add(const Duration(milliseconds: 1));
      emitStatus(orderId, 'preparing', t0);
      await pump();
      emitStatus(orderId, 'ready', t1);
      await pump();
      expect(controller.state.single.status, OrderStatus.ready);
      return t1;
    }

    test('revert stamped OLDER than lastApplied is dropped', () async {
      const orderId = 'ORD-9101';
      final lastApplied = await seedAdvancedToReady(orderId);

      // Delayed revert with a legal shape (ready→preparing) stamped STRICTLY
      // BEFORE the last applied event: ONLY the staleness guard can reject
      // it — removing the guard would regress the order to preparing and
      // fail this assertion.
      final stale = lastApplied.subtract(const Duration(milliseconds: 1));
      emitRevert(orderId, 'ready', 'preparing', stale);
      await pump();

      expect(
        controller.state.single.status,
        OrderStatus.ready,
        reason:
            'Stale revert must NOT move ready back to preparing '
            '(stamp $stale < applied $lastApplied)',
      );
    });

    test('revert stamped NEWER than lastApplied applies', () async {
      const orderId = 'ORD-9102';
      final lastApplied = await seedAdvancedToReady(orderId);

      final fresh = lastApplied.add(const Duration(milliseconds: 1));
      emitRevert(orderId, 'ready', 'preparing', fresh);
      await pump();

      expect(
        controller.state.single.status,
        OrderStatus.preparing,
        reason: 'A fresh revert event must still be honored',
      );
    });

    test('revert stamped EXACTLY EQUAL to lastApplied is dropped', () async {
      const orderId = 'ORD-9103';
      final lastApplied = await seedAdvancedToReady(orderId);

      // Same-millisecond replay of an already-applied transition: the guard
      // treats "not strictly after" as stale, so this must be dropped —
      // without the guard the legal-shaped revert would apply.
      emitRevert(orderId, 'ready', 'preparing', lastApplied);
      await pump();

      expect(
        controller.state.single.status,
        OrderStatus.ready,
        reason: 'Equal stamps count as stale (isAfter is strict)',
      );
    });

    test('fresh but illegal-shape revert (canRevertTo false) is ignored',
        () async {
      const orderId = 'ORD-9104';
      final lastApplied = await seedAdvancedToReady(orderId);

      // Multi-step backward jump (ready→confirmed) violates the single-step
      // revert rule; even a fresh stamp must not apply it.
      final fresh = lastApplied.add(const Duration(milliseconds: 1));
      emitRevert(orderId, 'ready', 'confirmed', fresh);
      await pump();

      expect(
        controller.state.single.status,
        OrderStatus.ready,
        reason: 'canRevertTo(ready → confirmed) is false; nothing may change',
      );
    });
  });

  group('Outgoing pickup-broadcast contract (updateStatus → ready)', () {
    late RealtimeService realtime;
    late OrdersController controller;
    late ConnectivityService connectivity;
    late NewOrderNotifier notifier;

    /// Every event this service emitted. With no socket open, [RealtimeService.send]
    /// loops broadcasts back onto [events], so these are exactly the events the
    /// controller published to other clients.
    final List<RealtimeEvent> outgoing = [];

    Future<void> pump() =>
        Future<void>.delayed(const Duration(milliseconds: 15));

    List<RealtimeEvent> pickupEvents() => outgoing
        .where((e) => e.type == RealtimeEventType.orderReadyForPickup)
        .toList();

    setUp(() {
      outgoing.clear();
      realtime = RealtimeService(wsUrl: 'ws://127.0.0.1:9'); // never connects
      realtime.events.listen(outgoing.add); // capture outgoing loopback events
      connectivity = ConnectivityService();
      notifier = NewOrderNotifier();
      controller = OrdersController(
        InMemoryOrderRepository(),
        // Cart is unused in these tests; orders arrive via realtime.
        CartController(),
        notifier,
        realtimeService: realtime,
        connectivityService: connectivity,
      );
    });

    tearDown(() {
      controller.dispose();
      notifier.dispose();
      connectivity.dispose();
      realtime.disconnect();
    });

    test(
      'dine-in order advanced to ready emits exactly ONE orderReadyForPickup '
      'carrying orderId, tableId and updatedAt',
      () async {
        realtime.send(
          jsonEncode({
            'type': 'orderCreated',
            'data': _orderJson(
              'ORD-9201',
              orderType: 'dineIn',
              tableId: 't7',
            ),
          }),
        );
        await pump();
        expect(controller.state.single.orderType, OrderType.dineIn);

        await controller.updateStatus('ORD-9201', OrderStatus.ready);
        await pump();

        final pickups = pickupEvents();
        expect(
          pickups,
          hasLength(1),
          reason:
              'Exactly one pickup alert must reach waiter clients — no more '
              '(duplicate chimes) and no fewer (missed handoff)',
        );
        expect(pickups.single.payload['orderId'], 'ORD-9201');
        expect(pickups.single.payload['tableId'], 't7');
        expect(
          DateTime.tryParse(pickups.single.payload['updatedAt'] as String),
          isNotNull,
          reason: 'updatedAt stamps the event for staleness guards',
        );
      },
    );

    test('takeaway order advanced to ready emits NO pickup event', () async {
      realtime.send(
        jsonEncode({'type': 'orderCreated', 'data': _orderJson('ORD-9202')}),
      );
      await pump();
      expect(controller.state.single.orderType, OrderType.takeaway);

      await controller.updateStatus('ORD-9202', OrderStatus.ready);
      await pump();

      expect(
        pickupEvents(),
        isEmpty,
        reason: 'Takeaway orders are collected at the counter — waiters must '
            'never be paged for them',
      );
    });
  });
}
