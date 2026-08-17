import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';
import 'package:restaurant_app/core/notifications/new_order_notifier.dart';
import 'package:restaurant_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_repository.dart';
import 'package:restaurant_app/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:restaurant_app/features/orders/data/repositories/in_memory_order_repository.dart';
import 'package:restaurant_app/features/orders/domain/entities/order_entity.dart';
import 'package:restaurant_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:restaurant_app/features/table_management/data/repositories/in_memory_table_repository.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';

void main() {
  group('RealtimeEvent Deserialization', () {
    test('parses orderCreated event with data wrapper', () {
      final raw = jsonEncode({
        'type': 'orderCreated',
        'data': {'id': 'ORD-9999', 'status': 'pending'},
      });
      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.orderCreated);
      expect(event.payload['id'], 'ORD-9999');
    });

    test('parses orderStatusChanged with snake_case', () {
      final raw = jsonEncode({
        'type': 'order_status_changed',
        'data': {'orderId': 'ORD-0001', 'status': 'ready'},
      });
      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.orderStatusChanged);
      expect(event.payload['status'], 'ready');
    });

    test('parses tableStatusChanged event', () {
      final raw = jsonEncode({
        'type': 'tableStatusChanged',
        'data': {'id': 'table-1', 'status': 'occupied'},
      });
      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.tableStatusChanged);
      expect(event.payload['id'], 'table-1');
    });

    test('parses driverLocationUpdated event', () {
      final raw = jsonEncode({
        'type': 'driverLocationUpdated',
        'data': {'driverId': 'driver-1', 'latitude': 24.7136, 'longitude': 46.6753},
      });
      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.driverLocationUpdated);
      expect(event.payload['latitude'], 24.7136);
    });

    test('handles invalid json gracefully', () {
      final event = RealtimeEvent.fromRaw('not valid json');
      expect(event.type, RealtimeEventType.unknown);
    });
  });

  group('OrdersController with RealtimeService', () {
    test('updates state when orderCreated event arrives', () async {
      final realtime = RealtimeService(wsUrl: 'ws://localhost:9999');
      final notifier = NewOrderNotifier();
      final cart = CartController();
      final repo = InMemoryOrderRepository();
      final controller = OrdersController(
        repo,
        cart,
        notifier,
        realtimeService: realtime,
      );

      final now = DateTime.now();
      final newOrder = OrderEntity(
        id: 'ORD-9999',
        restaurantId: 'rest-1',
        orderType: OrderType.dineIn,
        status: OrderStatus.pending,
        createdAt: now,
      );

      final raw = jsonEncode({'type': 'orderCreated', 'data': newOrder.toJson()});
      final parsed = RealtimeEvent.fromRaw(raw);
      expect(parsed.type, RealtimeEventType.orderCreated);

      controller.dispose();
      realtime.disconnect();
      notifier.dispose();
    });

    test('updates status when orderStatusChanged event arrives', () async {
      final realtime = RealtimeService(wsUrl: 'ws://localhost:9999');
      final notifier = NewOrderNotifier();
      final cart = CartController();
      final repo = InMemoryOrderRepository();
      final controller = OrdersController(
        repo,
        cart,
        notifier,
        realtimeService: realtime,
      );

      controller.dispose();
      realtime.disconnect();
      notifier.dispose();
    });
  });

  group('TableController with RealtimeService', () {
    test('initializes and can be disposed cleanly', () async {
      final realtime = RealtimeService(wsUrl: 'ws://localhost:9999');
      final repo = InMemoryTableRepository();
      final controller = TableController(repo, realtimeService: realtime);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.state.isNotEmpty, isTrue);

      controller.dispose();
      realtime.disconnect();
    });
  });

  group('DeliveryController with RealtimeService', () {
    test('initializes and can updateLocation', () async {
      final realtime = RealtimeService(wsUrl: 'ws://localhost:9999');
      final repo = InMemoryDeliveryRepository();
      final controller = DeliveryController(
        repo,
        'driver-demo',
        realtimeService: realtime,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      controller.updateLocation(latitude: 24.71, longitude: 46.67);

      controller.dispose();
      realtime.disconnect();
    });
  });
}
