import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/core/network/realtime_event.dart';
import 'package:restaurant_app/core/supabase/supabase_realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseRealtimeService Unit Tests', () {
    late SupabaseClient client;
    late SupabaseRealtimeService service;

    setUp(() {
      client = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.anonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      service = SupabaseRealtimeService(client);
    });

    tearDown(() {
      service.dispose();
    });

    test('emit orderCreated delivers event on stream', () async {
      final emittedEvents = <RealtimeEvent>[];
      final sub = service.events.listen(emittedEvents.add);
      addTearDown(sub.cancel);

      const event = RealtimeEvent(
        type: RealtimeEventType.orderCreated,
        payload: {'id': 'ORD-1001', 'total_amount': 250.0},
      );
      service.emit(event);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emittedEvents.length, 1);
      expect(emittedEvents.first.type, RealtimeEventType.orderCreated);
      expect(emittedEvents.first.payload['id'], 'ORD-1001');
    });

    test('emit orderStatusChanged delivers event on stream', () async {
      final emittedEvents = <RealtimeEvent>[];
      final sub = service.events.listen(emittedEvents.add);
      addTearDown(sub.cancel);

      const event = RealtimeEvent(
        type: RealtimeEventType.orderStatusChanged,
        payload: {'id': 'ORD-1002', 'status': 'preparing'},
      );
      service.emit(event);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emittedEvents.length, 1);
      expect(emittedEvents.first.type, RealtimeEventType.orderStatusChanged);
      expect(emittedEvents.first.payload['id'], 'ORD-1002');
      expect(emittedEvents.first.payload['status'], 'preparing');
    });

    test('emit tableStatusChanged delivers event on stream', () async {
      final emittedEvents = <RealtimeEvent>[];
      final sub = service.events.listen(emittedEvents.add);
      addTearDown(sub.cancel);

      const event = RealtimeEvent(
        type: RealtimeEventType.tableStatusChanged,
        payload: {'id': 't1', 'status': 'occupied', 'tableNumber': 1},
      );
      service.emit(event);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emittedEvents.length, 1);
      expect(emittedEvents.first.type, RealtimeEventType.tableStatusChanged);
      expect(emittedEvents.first.payload['id'], 't1');
      expect(emittedEvents.first.payload['status'], 'occupied');
    });

    test('emit driverLocationUpdated delivers event on stream', () async {
      final emittedEvents = <RealtimeEvent>[];
      final sub = service.events.listen(emittedEvents.add);
      addTearDown(sub.cancel);

      const event = RealtimeEvent(
        type: RealtimeEventType.driverLocationUpdated,
        payload: {
          'driverId': 'drv-1',
          'latitude': 30.0444,
          'longitude': 31.2357,
        },
      );
      service.emit(event);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emittedEvents.length, 1);
      expect(emittedEvents.first.type, RealtimeEventType.driverLocationUpdated);
      expect(emittedEvents.first.payload['driverId'], 'drv-1');
      expect(emittedEvents.first.payload['latitude'], 30.0444);
      expect(emittedEvents.first.payload['longitude'], 31.2357);
    });

    test('emit tableServiceRequested delivers event on stream', () async {
      final emittedEvents = <RealtimeEvent>[];
      final sub = service.events.listen(emittedEvents.add);
      addTearDown(sub.cancel);

      const event = RealtimeEvent(
        type: RealtimeEventType.tableServiceRequested,
        payload: {
          'id': 'REQ-1',
          'table_id': 't1',
          'table_number': 1,
          'type': 'callWaiter',
        },
      );
      service.emit(event);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emittedEvents.length, 1);
      expect(emittedEvents.first.type, RealtimeEventType.tableServiceRequested);
      expect(emittedEvents.first.payload['table_number'], 1);
    });

    test('subscribe can be called safely without crashing', () {
      expect(() => service.subscribe(), returnsNormally);
      // Double subscription should be idempotent
      expect(() => service.subscribe(), returnsNormally);
    });
  });
}
