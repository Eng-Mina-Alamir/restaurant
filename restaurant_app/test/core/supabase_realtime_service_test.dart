import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';
import 'package:restaurant_app/core/supabase/supabase_realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseRealtimeService Unit Tests', () {
    late SupabaseClient client;
    late SupabaseRealtimeService service;

    setUp(() {
      client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
      service = SupabaseRealtimeService(client);
    });

    tearDown(() {
      service.dispose();
    });

    test('broadcastOrderCreated emits orderCreated event on stream', () async {
      final emittedEvents = <RealtimeEvent>[];
      final sub = service.events.listen(emittedEvents.add);
      addTearDown(sub.cancel);

      final payload = {'id': 'ORD-1001', 'total_amount': 250.0};
      await service.broadcastOrderCreated(payload);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emittedEvents.length, 1);
      expect(emittedEvents.first.type, RealtimeEventType.orderCreated);
      expect(emittedEvents.first.payload['id'], 'ORD-1001');
    });

    test('broadcastOrderStatusChanged emits orderStatusChanged event on stream', () async {
      final emittedEvents = <RealtimeEvent>[];
      final sub = service.events.listen(emittedEvents.add);
      addTearDown(sub.cancel);

      await service.broadcastOrderStatusChanged('ORD-1002', 'preparing');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emittedEvents.length, 1);
      expect(emittedEvents.first.type, RealtimeEventType.orderStatusChanged);
      expect(emittedEvents.first.payload['id'], 'ORD-1002');
      expect(emittedEvents.first.payload['status'], 'preparing');
    });

    test('broadcastTableStatusChanged emits tableStatusChanged event on stream', () async {
      final emittedEvents = <RealtimeEvent>[];
      final sub = service.events.listen(emittedEvents.add);
      addTearDown(sub.cancel);

      final tablePayload = {'id': 't1', 'status': 'occupied', 'tableNumber': 1};
      await service.broadcastTableStatusChanged(tablePayload);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emittedEvents.length, 1);
      expect(emittedEvents.first.type, RealtimeEventType.tableStatusChanged);
      expect(emittedEvents.first.payload['id'], 't1');
      expect(emittedEvents.first.payload['status'], 'occupied');
    });

    test('broadcastDriverLocation emits driverLocationUpdated event on stream', () async {
      final emittedEvents = <RealtimeEvent>[];
      final sub = service.events.listen(emittedEvents.add);
      addTearDown(sub.cancel);

      await service.broadcastDriverLocation(
        driverId: 'drv-1',
        latitude: 30.0444,
        longitude: 31.2357,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emittedEvents.length, 1);
      expect(emittedEvents.first.type, RealtimeEventType.driverLocationUpdated);
      expect(emittedEvents.first.payload['driverId'], 'drv-1');
      expect(emittedEvents.first.payload['latitude'], 30.0444);
      expect(emittedEvents.first.payload['longitude'], 31.2357);
    });

    test('subscribe can be called safely without crashing', () {
      expect(() => service.subscribe(), returnsNormally);
      // Double subscription should be idempotent
      expect(() => service.subscribe(), returnsNormally);
    });
  });
}
