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
Map<String, dynamic> _orderJson(String id) => <String, dynamic>{
  'id': id,
  'restaurantId': 'demo-restaurant-1',
  'customerId': null,
  'tableId': null,
  'waiterId': null,
  'orderType': 'takeaway',
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
}
