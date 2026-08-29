import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/network/connectivity_service.dart';
import 'package:restaurant_app/core/network/realtime_event.dart';
import 'package:restaurant_app/core/notifications/new_order_notifier.dart';
import 'package:restaurant_app/core/supabase/supabase_realtime_service.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> _orderJson(
  String id, {
  String status = 'pending',
  String orderType = 'dineIn',
  String? tableId,
  double subtotal = 100.0,
}) => {
  'id': id,
  'restaurant_id': 'rest-test',
  'order_type': orderType,
  'status': status,
  'table_id': tableId ?? 't1',
  'subtotal': subtotal,
  'tax_amount': subtotal * 0.15,
  'discount_amount': 0.0,
  'total_amount': subtotal * 1.15,
  'items_json': const <dynamic>[],
  'created_at': DateTime.now().toIso8601String(),
};

SupabaseRealtimeService _createTestRealtime() {
  final client = SupabaseClient(
    SupabaseConfig.url,
    SupabaseConfig.anonKey,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  return SupabaseRealtimeService(client);
}

void main() {
  group('OrderStatus state machine transitions', () {
    test('canTransitionTo enforces canonical lifecycle progression', () {
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.confirmed), isTrue);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.preparing), isTrue);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.ready), isFalse);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.completed), isFalse);
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.cancelled), isTrue);

      expect(OrderStatus.confirmed.canTransitionTo(OrderStatus.preparing), isTrue);
      expect(OrderStatus.confirmed.canTransitionTo(OrderStatus.ready), isFalse);
      expect(OrderStatus.confirmed.canTransitionTo(OrderStatus.cancelled), isTrue);

      expect(OrderStatus.preparing.canTransitionTo(OrderStatus.ready), isTrue);
      expect(OrderStatus.preparing.canTransitionTo(OrderStatus.served), isFalse);
      expect(OrderStatus.preparing.canTransitionTo(OrderStatus.completed), isFalse);

      expect(OrderStatus.ready.canTransitionTo(OrderStatus.served), isTrue);
      expect(OrderStatus.ready.canTransitionTo(OrderStatus.completed), isTrue);

      expect(OrderStatus.served.canTransitionTo(OrderStatus.completed), isTrue);

      expect(OrderStatus.completed.canTransitionTo(OrderStatus.cancelled), isFalse);
      expect(OrderStatus.completed.canTransitionTo(OrderStatus.preparing), isFalse);
      expect(OrderStatus.cancelled.canTransitionTo(OrderStatus.pending), isFalse);
    });

    test('canRevertTo enforces single-step backward moves only', () {
      expect(OrderStatus.ready.canRevertTo(OrderStatus.preparing), isTrue);
      expect(OrderStatus.served.canRevertTo(OrderStatus.ready), isTrue);

      expect(OrderStatus.ready.canRevertTo(OrderStatus.pending), isFalse);
      expect(OrderStatus.ready.canRevertTo(OrderStatus.confirmed), isFalse);
      expect(OrderStatus.completed.canRevertTo(OrderStatus.served), isFalse);
      expect(OrderStatus.cancelled.canRevertTo(OrderStatus.pending), isFalse);
    });
  });

  group('Realtime out-of-order status guard', () {
    late SupabaseRealtimeService realtime;
    late OrdersController controller;
    late ConnectivityService connectivity;
    late NewOrderNotifier notifier;

    void emitStatus(String orderId, String status, [DateTime? updatedAt]) {
      realtime.emit(
        RealtimeEvent(
          type: RealtimeEventType.orderStatusChanged,
          payload: {
            'orderId': orderId,
            'id': orderId,
            'status': status,
            if (updatedAt != null) 'updatedAt': updatedAt.toIso8601String(),
          },
        ),
      );
    }

    Future<void> pump() =>
        Future<void>.delayed(const Duration(milliseconds: 15));

    setUp(() {
      realtime = _createTestRealtime();
      connectivity = ConnectivityService();
      notifier = NewOrderNotifier();
      controller = OrdersController(
        InMemoryOrderRepository(),
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
      realtime.dispose();
    });

    test(
      'a delayed stale event cannot regress an applied transition',
      () async {
        // Seed the order via realtime
        realtime.emit(
          RealtimeEvent(
            type: RealtimeEventType.orderCreated,
            payload: _orderJson('ORD-9001'),
          ),
        );
        await pump();
        expect(controller.state.single.id, 'ORD-9001');
        expect(controller.state.single.status, OrderStatus.pending);

        // Locally apply a transition — stamps the last-applied clock.
        final staleMoment = DateTime.now().subtract(const Duration(seconds: 5));
        await controller.updateStatus('ORD-9001', OrderStatus.preparing);
        await pump();
        expect(controller.state.single.status, OrderStatus.preparing);

        // Delayed stale event arriving claiming cancellation
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
      realtime.emit(
        RealtimeEvent(
          type: RealtimeEventType.orderCreated,
          payload: _orderJson('ORD-9002'),
        ),
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
      realtime.emit(
        RealtimeEvent(
          type: RealtimeEventType.orderCreated,
          payload: _orderJson('ORD-9003'),
        ),
      );
      await pump();

      realtime.emit(
        const RealtimeEvent(
          type: RealtimeEventType.orderStatusChanged,
          payload: {'garbage': true},
        ),
      );
      await pump();

      expect(controller.state.single.status, OrderStatus.pending);
    });
  });

  group('Realtime status revert deduplication', () {
    late SupabaseRealtimeService realtime;
    late OrdersController controller;
    late ConnectivityService connectivity;
    late NewOrderNotifier notifier;

    void emitStatus(String orderId, String status, [DateTime? updatedAt]) {
      realtime.emit(
        RealtimeEvent(
          type: RealtimeEventType.orderStatusChanged,
          payload: {
            'orderId': orderId,
            'id': orderId,
            'status': status,
            if (updatedAt != null) 'updatedAt': updatedAt.toIso8601String(),
          },
        ),
      );
    }

    void emitRevert(
      String orderId,
      String fromStatus,
      String toStatus,
      DateTime updatedAt,
    ) {
      realtime.emit(
        RealtimeEvent(
          type: RealtimeEventType.orderStatusReverted,
          payload: {
            'orderId': orderId,
            'id': orderId,
            'fromStatus': fromStatus,
            'toStatus': toStatus,
            'status': toStatus,
            'updatedAt': updatedAt.toIso8601String(),
          },
        ),
      );
    }

    Future<void> pump() =>
        Future<void>.delayed(const Duration(milliseconds: 15));

    setUp(() {
      realtime = _createTestRealtime();
      connectivity = ConnectivityService();
      notifier = NewOrderNotifier();
      controller = OrdersController(
        InMemoryOrderRepository(),
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
      realtime.dispose();
    });

    Future<DateTime> seedAdvancedToReady(String orderId) async {
      realtime.emit(
        RealtimeEvent(
          type: RealtimeEventType.orderCreated,
          payload: _orderJson(orderId),
        ),
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

      final stale = lastApplied.subtract(const Duration(milliseconds: 1));
      emitRevert(orderId, 'ready', 'preparing', stale);
      await pump();

      expect(
        controller.state.single.status,
        OrderStatus.ready,
        reason: 'Stale revert must NOT move ready back to preparing',
      );
    });

    test('revert stamped NEWER than lastApplied applies', () async {
      const orderId = 'ORD-9102';
      final lastApplied = await seedAdvancedToReady(orderId);

      final fresh = lastApplied.add(const Duration(milliseconds: 10));
      emitRevert(orderId, 'ready', 'preparing', fresh);
      await pump();

      expect(
        controller.state.single.status,
        OrderStatus.preparing,
        reason: 'Fresh revert should apply',
      );
    });
  });

  group('Waiter pickup alert on dine-in order ready', () {
    late SupabaseRealtimeService realtime;
    late OrdersController controller;
    late ConnectivityService connectivity;
    late NewOrderNotifier notifier;
    final List<RealtimeEvent> outgoing = [];

    Future<void> pump() =>
        Future<void>.delayed(const Duration(milliseconds: 15));

    setUp(() {
      outgoing.clear();
      realtime = _createTestRealtime();
      realtime.events.listen(outgoing.add);
      connectivity = ConnectivityService();
      notifier = NewOrderNotifier();
      controller = OrdersController(
        InMemoryOrderRepository(),
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
      realtime.dispose();
    });

    test('dine-in order updates status correctly', () async {
      realtime.emit(
        RealtimeEvent(
          type: RealtimeEventType.orderCreated,
          payload: _orderJson('ORD-9201', orderType: 'dineIn', tableId: 't7'),
        ),
      );
      await pump();
      expect(controller.state.single.orderType, OrderType.dineIn);

      await controller.updateStatus('ORD-9201', OrderStatus.ready);
      await pump();

      expect(controller.state.single.status, OrderStatus.ready);
    });
  });
}
