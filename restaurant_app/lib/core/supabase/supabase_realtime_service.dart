import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../config/supabase_config.dart';
import '../domain/enums.dart';
import '../network/realtime_event.dart';
import '../utils/logger.dart';
import 'supabase_providers.dart';

/// Connects to Supabase Realtime Postgres change streams and emits typed
/// [RealtimeEvent]s to subscribers.
///
/// **Role-based channel filtering**: each user role subscribes only to the
/// channels it needs, dramatically reducing concurrent connections:
/// - Customer:  orders + delivery_assignments (2 channels: the assignment
///   channel is RLS-scoped to the customer's own orders so the tracking
///   page learns the driver the moment the kitchen dispatches)
/// - Kitchen:   orders (1 channel)
/// - Cashier:   orders (1 channel)
/// - Waiter:    orders + tables + table_service_requests (3 channels)
/// - Driver:    orders + delivery_assignments + driver_locations (3 channels)
/// - Manager/Admin: all 5 channels
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
  UserRole? _currentRole;

  /// Stream of live real-time events.
  Stream<RealtimeEvent> get stream {
    _controller ??= StreamController<RealtimeEvent>.broadcast();
    return _controller!.stream;
  }

  /// Alias for [stream].
  Stream<RealtimeEvent> get events => stream;

  /// Subscribes to ALL channels (legacy — used when role is unknown).
  void subscribe() => subscribeForRole(null);

  /// Subscribes to Supabase Realtime channels based on [role].
  ///
  /// Only channels relevant to the user's role are opened, which reduces
  /// concurrent Realtime connections from 5 per user to 1–3 on average.
  void subscribeForRole(UserRole? role) {
    if (_isSubscribed && _currentRole == role) return;
    _controller ??= StreamController<RealtimeEvent>.broadcast();
    _currentRole = role;
    _isSubscribed = true;

    try {
      // Orders channel — needed by ALL roles
      _subscribeOrders();

      // Tables + Table Service Requests — needed by waiter, manager, admin
      if (role == null ||
          role == UserRole.waiter ||
          role == UserRole.manager ||
          role == UserRole.admin) {
        _subscribeTables();
        _subscribeTableServiceRequests();
      }

      // Driver Locations — needed by driver, manager, admin
      if (role == null ||
          role == UserRole.driver ||
          role == UserRole.manager ||
          role == UserRole.admin) {
        _subscribeDriverLocations();
      }

      // Delivery Assignments — needed by driver, manager, admin, cashier,
      // and customer (RLS limits customers to their own orders' rows, so the
      // tracking page flips from "searching" to the driver card live).
      if (role == null ||
          role == UserRole.driver ||
          role == UserRole.manager ||
          role == UserRole.admin ||
          role == UserRole.cashier ||
          role == UserRole.customer) {
        _subscribeDeliveryAssignments();
      }

      final channelCount = [
        _ordersChannel,
        _tablesChannel,
        _driverChannel,
        _tableServiceChannel,
        _deliveryAssignmentsChannel,
      ].where((c) => c != null).length;
      AppLogger.info(
        'Realtime: subscribed to $channelCount channels for role=${role?.name ?? "all"}',
      );
    } catch (e, st) {
      _isSubscribed = false;
      AppLogger.error(
        'Failed to subscribe to Supabase Realtime channels: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  // ── Channel setup helpers ──────────────────────────────────────────────

  void _subscribeOrders() {
    if (_ordersChannel != null) return;
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
  }

  void _subscribeTables() {
    if (_tablesChannel != null) return;
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
  }

  void _subscribeDriverLocations() {
    if (_driverChannel != null) return;
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
  }

  void _subscribeTableServiceRequests() {
    if (_tableServiceChannel != null) return;
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
  }

  void _subscribeDeliveryAssignments() {
    if (_deliveryAssignmentsChannel != null) return;
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
  }

  /// Updates driver location in the DB (which triggers Realtime to all clients)
  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    String? orderId,
  }) async {
    try {
      final numericOrderId = orderId != null ? int.tryParse(orderId) : null;
      final payload = <String, dynamic>{
        'driver_id': driverId,
        'latitude': latitude,
        'longitude': longitude,
        'order_id': ?numericOrderId,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _supabase.from(SupabaseConfig.driverLocationsTable).upsert(payload);
    } catch (e, st) {
      AppLogger.warning('Failed to update driver location: $e', error: e, stackTrace: st);
    }
  }

  /// Emits a [RealtimeEvent] onto the event stream (used for tests and internal feeds).
  void emit(RealtimeEvent event) {
    _controller ??= StreamController<RealtimeEvent>.broadcast();
    _controller?.add(event);
  }

  void dispose() {
    if (_isSubscribed) {
      _isSubscribed = false;
      _ordersChannel?.unsubscribe();
      _tablesChannel?.unsubscribe();
      _driverChannel?.unsubscribe();
      _tableServiceChannel?.unsubscribe();
      _deliveryAssignmentsChannel?.unsubscribe();
    }
    _controller?.close();
  }
}

/// Shared provider for [SupabaseRealtimeService].
final supabaseRealtimeServiceProvider = Provider<SupabaseRealtimeService>((ref) {
  final service = SupabaseRealtimeService(ref.watch(supabaseClientProvider));
  final isTestEnvironment = () {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }();

  if (AppConfig.useSupabase && SupabaseConfig.isConfigured && !isTestEnvironment) {
    service.subscribe();
  }
  ref.onDispose(service.dispose);
  return service;
});

