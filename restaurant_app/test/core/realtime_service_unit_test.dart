import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';

void main() {
  group('RealtimeEvent Parsing Tests', () {
    test('parses orderCreated event correctly', () {
      final raw = jsonEncode({
        'type': 'orderCreated',
        'data': {'id': 'ORD-001', 'total': 150.0},
      });

      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.orderCreated);
      expect(event.payload['id'], 'ORD-001');
      expect(event.payload['total'], 150.0);
    });

    test('parses snake_case event names', () {
      final raw = jsonEncode({
        'event': 'order_status_changed',
        'payload': {'orderId': 'ORD-002', 'status': 'preparing'},
      });

      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.orderStatusChanged);
      expect(event.payload['orderId'], 'ORD-002');
      expect(event.payload['status'], 'preparing');
    });

    test('parses tableStatusChanged event', () {
      final raw = jsonEncode({
        'type': 'tableStatusChanged',
        'data': {'tableId': 'tbl-1', 'status': 'occupied'},
      });

      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.tableStatusChanged);
      expect(event.payload['tableId'], 'tbl-1');
    });

    test('parses driverLocationUpdated event', () {
      final raw = jsonEncode({
        'type': 'driver_location_updated',
        'data': {'driverId': 'drv-1', 'latitude': 24.7136, 'longitude': 46.6753},
      });

      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.driverLocationUpdated);
      expect(event.payload['latitude'], 24.7136);
    });

    test('unknown type falls back to RealtimeEventType.unknown', () {
      final raw = jsonEncode({
        'type': 'someRandomEvent',
        'data': {'foo': 'bar'},
      });

      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.unknown);
    });

    test('handles malformed JSON gracefully', () {
      const raw = 'this is not json { [';
      final event = RealtimeEvent.fromRaw(raw);
      expect(event.type, RealtimeEventType.unknown);
      expect(event.payload['raw'], raw);
    });
  });

  group('RealtimeService Loopback Tests', () {
    late RealtimeService service;

    setUp(() {
      service = RealtimeService(wsUrl: 'ws://localhost:9999/ws');
    });

    tearDown(() {
      service.disconnect();
    });

    test('send loops back event to events stream in offline/demo mode', () async {
      expectLater(
        service.events,
        emits(predicate<RealtimeEvent>((event) {
          return event.type == RealtimeEventType.orderCreated &&
              event.payload['id'] == 'ORD-999';
        })),
      );

      service.broadcastOrderCreated({'id': 'ORD-999', 'subtotal': 50.0});
    });

    test('broadcastOrderStatusChanged emits correct event', () async {
      expectLater(
        service.events,
        emits(predicate<RealtimeEvent>((event) {
          return event.type == RealtimeEventType.orderStatusChanged &&
              event.payload['orderId'] == 'ORD-100' &&
              event.payload['status'] == 'ready';
        })),
      );

      service.broadcastOrderStatusChanged('ORD-100', 'ready');
    });

    test('broadcastTableStatusChanged emits correct event', () async {
      expectLater(
        service.events,
        emits(predicate<RealtimeEvent>((event) {
          return event.type == RealtimeEventType.tableStatusChanged &&
              event.payload['id'] == 'tbl-5';
        })),
      );

      service.broadcastTableStatusChanged({'id': 'tbl-5', 'status': 'available'});
    });

    test('broadcastDriverLocation emits correct event', () async {
      expectLater(
        service.events,
        emits(predicate<RealtimeEvent>((event) {
          return event.type == RealtimeEventType.driverLocationUpdated &&
              event.payload['driverId'] == 'drv-42' &&
              event.payload['latitude'] == 24.7;
        })),
      );

      service.broadcastDriverLocation(
        driverId: 'drv-42',
        latitude: 24.7,
        longitude: 46.7,
      );
    });
  });
}
