import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../network/realtime_service.dart';
import '../utils/logger.dart';

/// Connects to Supabase Realtime Postgres change streams (orders, tables, driver locations)
/// and emits typed [RealtimeEvent]s.
class SupabaseRealtimeService {
  SupabaseRealtimeService(this._supabase);

  final SupabaseClient _supabase;
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _tablesChannel;
  RealtimeChannel? _driverChannel;
  StreamController<RealtimeEvent>? _controller;
  bool _isSubscribed = false;

  /// Stream of live real-time events.
  Stream<RealtimeEvent> get events {
    _controller ??= StreamController<RealtimeEvent>.broadcast();
    return _controller!.stream;
  }

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
            AppLogger.info('Realtime Order Inserted: ${payload.newRecord['id']}');
            _controller?.add(RealtimeEvent(
              type: RealtimeEventType.orderCreated,
              payload: payload.newRecord,
            ));
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConfig.ordersTable,
          callback: (payload) {
            AppLogger.info('Realtime Order Updated: ${payload.newRecord['id']} -> ${payload.newRecord['status']}');
            _controller?.add(RealtimeEvent(
              type: RealtimeEventType.orderStatusChanged,
              payload: payload.newRecord,
            ));
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
            _controller?.add(RealtimeEvent(
              type: RealtimeEventType.tableStatusChanged,
              payload: payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord,
            ));
          },
        )
        ..subscribe();

      // 3. Driver Locations Realtime Channel
      _driverChannel = _supabase.channel('public:${SupabaseConfig.driverLocationsTable}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.driverLocationsTable,
          callback: (payload) {
            _controller?.add(RealtimeEvent(
              type: RealtimeEventType.driverLocationUpdated,
              payload: payload.newRecord,
            ));
          },
        )
        ..subscribe();
    } catch (e) {
      AppLogger.error('Failed to subscribe to Supabase Realtime channels: $e');
    }
  }

  /// Broadcasts an order creation event
  Future<void> broadcastOrderCreated(Map<String, dynamic> orderJson) async {
    _controller?.add(RealtimeEvent(
      type: RealtimeEventType.orderCreated,
      payload: orderJson,
    ));
  }

  /// Broadcasts an order status change
  Future<void> broadcastOrderStatusChanged(String orderId, String statusName) async {
    _controller?.add(RealtimeEvent(
      type: RealtimeEventType.orderStatusChanged,
      payload: {'id': orderId, 'status': statusName},
    ));
  }

  /// Broadcasts a table status change
  Future<void> broadcastTableStatusChanged(Map<String, dynamic> tableJson) async {
    _controller?.add(RealtimeEvent(
      type: RealtimeEventType.tableStatusChanged,
      payload: tableJson,
    ));
  }

  /// Broadcasts driver coordinates
  Future<void> broadcastDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.driverLocationsTable).upsert({
        'driver_id': driverId,
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    _controller?.add(RealtimeEvent(
      type: RealtimeEventType.driverLocationUpdated,
      payload: {
        'driverId': driverId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
  }

  void dispose() {
    _isSubscribed = false;
    _ordersChannel?.unsubscribe();
    _tablesChannel?.unsubscribe();
    _driverChannel?.unsubscribe();
    _controller?.close();
  }
}
