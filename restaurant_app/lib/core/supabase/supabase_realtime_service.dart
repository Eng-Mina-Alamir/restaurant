import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../config/supabase_config.dart';
import '../network/realtime_event.dart';
import '../utils/logger.dart';
import 'supabase_providers.dart';

/// Connects to Supabase Realtime Postgres change streams:
/// - orders (inserts, updates)
/// - tables (inserts, updates, deletes)
/// - driver_locations (inserts, updates)
/// - table_service_requests (inserts, updates)
/// - delivery_assignments (inserts, updates)
/// and emits typed [RealtimeEvent]s to subscribers.
class SupabaseRealtimeService {
  SupabaseRealtimeService(this._supabase);

  final SupabaseClient _supabase;
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _tablesChannel;
  RealtimeChannel? _driverChannel;
  RealtimeChannel? _tableServiceChannel;
  RealtimeChannel? _deliveryAssignmentsChannel;
  StreamController<RealtimeEvent>? _controller;
  bool _isSubscribed = false;

  /// Stream of live real-time events.
  Stream<RealtimeEvent> get stream {
    _controller ??= StreamController<RealtimeEvent>.broadcast();
    return _controller!.stream;
  }

  /// Alias for [stream].
  Stream<RealtimeEvent> get events => stream;

  /// Subscribes to Supabase Realtime channels.
  void subscribe() {
    if (_isSubscribed) return;
    _controller ??= StreamController<RealtimeEvent>.broadcast();
    _isSubscribed = true;

    try {
      // 1. Orders Realtime Channel
      _ordersChannel = _supabase.channel('public:${SupabaseConfig.ordersTable}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConfig.ordersTable,
          callback: (payload) {
            AppLogger.info(
              'Realtime Order Inserted: ${payload.newRecord['id']}',
            );
            _controller?.add(
              RealtimeEvent(
                type: RealtimeEventType.orderCreated,
                payload: payload.newRecord,
              ),
            );
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConfig.ordersTable,
          callback: (payload) {
            AppLogger.info(
              'Realtime Order Updated: ${payload.newRecord['id']} -> ${payload.newRecord['status']}',
            );
            _controller?.add(
              RealtimeEvent(
                type: RealtimeEventType.orderStatusChanged,
                payload: payload.newRecord,
              ),
            );
            // If dineIn order reached ready, also emit orderReadyForPickup for waiter alerts
            if (payload.newRecord['status'] == 'ready' &&
                payload.newRecord['order_type'] == 'dineIn') {
              _controller?.add(
                RealtimeEvent(
                  type: RealtimeEventType.orderReadyForPickup,
                  payload: payload.newRecord,
                ),
              );
            }
          },
        )
        ..subscribe();

      // 2. Tables Realtime Channel
      _tablesChannel = _supabase.channel('public:${SupabaseConfig.tablesTable}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.tablesTable,
          callback: (payload) {
            _controller?.add(
              RealtimeEvent(
                type: RealtimeEventType.tableStatusChanged,
                payload: payload.newRecord.isNotEmpty
                    ? payload.newRecord
                    : payload.oldRecord,
              ),
            );
          },
        )
        ..subscribe();

      // 3. Driver Locations Realtime Channel
      _driverChannel =
          _supabase.channel('public:${SupabaseConfig.driverLocationsTable}')
            ..onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: SupabaseConfig.driverLocationsTable,
              callback: (payload) {
                _controller?.add(
                  RealtimeEvent(
                    type: RealtimeEventType.driverLocationUpdated,
                    payload: payload.newRecord,
                  ),
                );
              },
            )
            ..subscribe();

      // 4. Table Service Requests Channel
      _tableServiceChannel =
          _supabase.channel('public:${SupabaseConfig.tableServiceRequestsTable}')
            ..onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: SupabaseConfig.tableServiceRequestsTable,
              callback: (payload) {
                AppLogger.info(
                  'Realtime Table Service Requested: ${payload.newRecord['id']} for table ${payload.newRecord['table_number']}',
                );
                _controller?.add(
                  RealtimeEvent(
                    type: RealtimeEventType.tableServiceRequested,
                    payload: payload.newRecord,
                  ),
                );
              },
            )
            ..onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: SupabaseConfig.tableServiceRequestsTable,
              callback: (payload) {
                AppLogger.info(
                  'Realtime Table Service Updated: ${payload.newRecord['id']} (is_handled=${payload.newRecord['is_handled']})',
                );
                _controller?.add(
                  RealtimeEvent(
                    type: RealtimeEventType.tableServiceHandled,
                    payload: payload.newRecord,
                  ),
                );
              },
            )
            ..subscribe();

      // 5. Delivery Assignments Channel
      _deliveryAssignmentsChannel =
          _supabase.channel('public:${SupabaseConfig.deliveryAssignmentsTable}')
            ..onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: SupabaseConfig.deliveryAssignmentsTable,
              callback: (payload) {
                AppLogger.info(
                  'Realtime Delivery Assignment Inserted: ${payload.newRecord['id']}',
                );
                _controller?.add(
                  RealtimeEvent(
                    type: RealtimeEventType.deliveryAssignmentCreated,
                    payload: payload.newRecord,
                  ),
                );
              },
            )
            ..onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: SupabaseConfig.deliveryAssignmentsTable,
              callback: (payload) {
                AppLogger.info(
                  'Realtime Delivery Assignment Updated: ${payload.newRecord['id']}',
                );
                _controller?.add(
                  RealtimeEvent(
                    type: RealtimeEventType.deliveryAssignmentUpdated,
                    payload: payload.newRecord,
                  ),
                );
              },
            )
            ..subscribe();
    } catch (e, st) {
      _isSubscribed = false;
      AppLogger.error('Failed to subscribe to Supabase Realtime channels: $e', error: e, stackTrace: st);
    }
  }

  /// Updates driver location in the DB (which triggers Realtime to all clients)
  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    String? orderId,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.driverLocationsTable).upsert({
        'driver_id': driverId,
        'latitude': latitude,
        'longitude': longitude,
        'order_id': orderId,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e, st) {
      AppLogger.error('Failed to update driver location: $e', error: e, stackTrace: st);
    }
  }

  /// Emits a [RealtimeEvent] onto the event stream (used for tests and internal feeds).
  void emit(RealtimeEvent event) {
    _controller ??= StreamController<RealtimeEvent>.broadcast();
    _controller?.add(event);
  }

  void dispose() {
    _isSubscribed = false;
    _ordersChannel?.unsubscribe();
    _tablesChannel?.unsubscribe();
    _driverChannel?.unsubscribe();
    _tableServiceChannel?.unsubscribe();
    _deliveryAssignmentsChannel?.unsubscribe();
    _controller?.close();
  }
}

/// Shared provider for [SupabaseRealtimeService].
final supabaseRealtimeServiceProvider = Provider<SupabaseRealtimeService>((ref) {
  final service = SupabaseRealtimeService(ref.watch(supabaseClientProvider));
  if (AppConfig.useSupabase) {
    service.subscribe();
  }
  ref.onDispose(service.dispose);
  return service;
});
