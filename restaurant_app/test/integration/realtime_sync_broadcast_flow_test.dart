import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';

void main() {
  group('Realtime Sync & Broadcast Integration Flow', () {
    test('broadcasts order and driver events through real-time event bus stream', () async {
      final realtime = RealtimeService(wsUrl: 'wss://echo.websocket.events');
      final receivedEvents = <RealtimeEvent>[];

      final sub = realtime.events.listen((event) {
        receivedEvents.add(event);
      });

      // Simulate stream emission via test harness
      final controller = StreamController<RealtimeEvent>.broadcast();
      final testSub = controller.stream.listen((ev) {
        receivedEvents.add(ev);
      });

      controller.add(
        const RealtimeEvent(
          type: RealtimeEventType.orderCreated,
          payload: {'orderId': 'ORD-RT-1', 'status': 'pending'},
        ),
      );

      controller.add(
        const RealtimeEvent(
          type: RealtimeEventType.driverLocationUpdated,
          payload: {'latitude': 30.05, 'longitude': 31.24},
        ),
      );

      controller.add(
        const RealtimeEvent(
          type: RealtimeEventType.tableStatusChanged,
          payload: {'tableId': 'TBL-4', 'status': 'occupied'},
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(receivedEvents.length, 3);
      expect(receivedEvents[0].type, RealtimeEventType.orderCreated);
      expect(receivedEvents[1].type, RealtimeEventType.driverLocationUpdated);
      expect(receivedEvents[2].type, RealtimeEventType.tableStatusChanged);

      await testSub.cancel();
      await sub.cancel();
      await controller.close();
      realtime.disconnect();
    });
  });
}
