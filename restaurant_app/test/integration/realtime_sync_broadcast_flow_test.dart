import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/supabase_config.dart';
import 'package:restaurant_app/core/network/realtime_event.dart';
import 'package:restaurant_app/core/supabase/supabase_realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Realtime Sync & Broadcast Integration Flow', () {
    test(
      'delivers order, driver, and table events through real-time event stream',
      () async {
        final client = SupabaseClient(
          SupabaseConfig.url,
          SupabaseConfig.anonKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        final realtime = SupabaseRealtimeService(client);

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

        realtime.emit(const RealtimeEvent(
          type: RealtimeEventType.orderCreated,
          payload: {
            'orderId': 'ORD-RT-1',
            'status': 'pending',
          },
        ));
        realtime.emit(const RealtimeEvent(
          type: RealtimeEventType.driverLocationUpdated,
          payload: {
            'driverId': 'DRV-7',
            'latitude': 30.05,
            'longitude': 31.24,
            'orderId': 'ORD-RT-1',
          },
        ));
        realtime.emit(const RealtimeEvent(
          type: RealtimeEventType.tableStatusChanged,
          payload: {
            'tableId': 'TBL-4',
            'status': 'occupied',
          },
        ));

        await expectation;

        realtime.dispose();
      },
    );
  });
}
