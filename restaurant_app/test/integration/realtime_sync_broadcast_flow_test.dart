import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';

void main() {
  group('Realtime Sync & Broadcast Integration Flow', () {
    test(
      'broadcasts order and driver events through real-time event bus stream',
      () async {
        // Demo/test mode: with no channel ever connected, every send()/broadcast*()
        // loops the event straight back onto [RealtimeService.events].
        final realtime = RealtimeService();

        // Subscribe before broadcasting so delivery cannot race listener
        // registration; assertions resolve purely on stream delivery, with no
        // wall-clock delays.
        final expectation = expectLater(
          realtime.events,
          emitsInOrder(<Matcher>[
            isA<RealtimeEvent>()
                .having((e) => e.type, 'type', RealtimeEventType.orderCreated)
                .having(
                  (e) => e.payload['orderId'],
                  'payload.orderId',
                  'ORD-RT-1',
                )
                .having(
                  (e) => e.payload['status'],
                  'payload.status',
                  'pending',
                ),
            isA<RealtimeEvent>()
                .having(
                  (e) => e.type,
                  'type',
                  RealtimeEventType.driverLocationUpdated,
                )
                .having(
                  (e) => e.payload['driverId'],
                  'payload.driverId',
                  'DRV-7',
                )
                .having((e) => e.payload['latitude'], 'payload.latitude', 30.05)
                .having(
                  (e) => e.payload['longitude'],
                  'payload.longitude',
                  31.24,
                )
                .having(
                  (e) => e.payload['orderId'],
                  'payload.orderId',
                  'ORD-RT-1',
                ),
            isA<RealtimeEvent>()
                .having(
                  (e) => e.type,
                  'type',
                  RealtimeEventType.tableStatusChanged,
                )
                .having((e) => e.payload['tableId'], 'payload.tableId', 'TBL-4')
                .having(
                  (e) => e.payload['status'],
                  'payload.status',
                  'occupied',
                ),
          ]),
        );

        realtime.broadcastOrderCreated(const {
          'orderId': 'ORD-RT-1',
          'status': 'pending',
        });
        realtime.broadcastDriverLocation(
          driverId: 'DRV-7',
          latitude: 30.05,
          longitude: 31.24,
          orderId: 'ORD-RT-1',
        );
        realtime.broadcastTableStatusChanged(const {
          'tableId': 'TBL-4',
          'status': 'occupied',
        });

        await expectation;

        realtime.disconnect();
      },
    );
  });
}
