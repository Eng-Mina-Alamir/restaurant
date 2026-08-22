import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config/app_config.dart';
import '../../config/environment.dart';
import '../utils/logger.dart';

/// Real-time update event types received from the server.
enum RealtimeEventType {
  orderCreated,
  orderStatusChanged,
  orderStatusReverted,
  tableStatusChanged,
  driverLocationUpdated,
  deliveryAssignmentCreated,
  unknown,
}

/// A single real-time event deserialized from the WebSocket channel.
class RealtimeEvent {
  const RealtimeEvent({
    required this.type,
    required this.payload,
  });

  final RealtimeEventType type;
  final Map<String, dynamic> payload;

  factory RealtimeEvent.fromRaw(String raw) {
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final typeName = (decoded['type'] ?? decoded['event'])?.toString() ?? '';
        final eventType = _typeFromString(typeName);
        final payloadData = decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : (decoded['payload'] is Map<String, dynamic>
                ? decoded['payload'] as Map<String, dynamic>
                : decoded);
        return RealtimeEvent(type: eventType, payload: payloadData);
      }
      return RealtimeEvent(
        type: RealtimeEventType.unknown,
        payload: {'raw': raw},
      );
    } catch (_) {
      return RealtimeEvent(
        type: RealtimeEventType.unknown,
        payload: {'raw': raw},
      );
    }
  }

  static RealtimeEventType _typeFromString(String s) {
    switch (s) {
      case 'orderCreated':
      case 'order_created':
        return RealtimeEventType.orderCreated;
      case 'orderStatusChanged':
      case 'order_status_changed':
        return RealtimeEventType.orderStatusChanged;
      case 'orderStatusReverted':
      case 'order_status_reverted':
        return RealtimeEventType.orderStatusReverted;
      case 'tableStatusChanged':
      case 'table_status_changed':
        return RealtimeEventType.tableStatusChanged;
      case 'driverLocationUpdated':
      case 'driver_location_updated':
        return RealtimeEventType.driverLocationUpdated;
      case 'deliveryAssignmentCreated':
      case 'delivery_assignment_created':
        return RealtimeEventType.deliveryAssignmentCreated;
      default:
        return RealtimeEventType.unknown;
    }
  }
}

/// Manages the WebSocket connection to the backend real-time API.
///
/// Consumers listen to [events] stream to receive live updates.
/// The service auto-reconnects on disconnect with exponential back-off.
class RealtimeService {
  RealtimeService({String? wsUrl})
      : _wsUrl = wsUrl ?? EnvironmentConfig.wsUrl;

  final String _wsUrl;

  WebSocketChannel? _channel;
  StreamController<RealtimeEvent>? _controller;
  bool _disposed = false;
  int _retryDelay = 1;
  Timer? _reconnectTimer;

  /// Stream of incoming real-time events. Listeners must call [connect] first.
  Stream<RealtimeEvent> get events {
    _controller ??= StreamController<RealtimeEvent>.broadcast();
    return _controller!.stream;
  }

  /// Opens the WebSocket connection.
  void connect() {
    if (_disposed) return;
    _controller ??= StreamController<RealtimeEvent>.broadcast();
    _doConnect();
  }

  void _doConnect() {
    if (_disposed) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _retryDelay = 1; // reset on success
      _channel!.stream.listen(
        (message) {
          if (message is String) {
            final event = RealtimeEvent.fromRaw(message);
            _controller?.add(event);
          }
        },
        onError: (error) {
          AppLogger.error('RealtimeService: WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          AppLogger.warning('RealtimeService: WebSocket closed – reconnecting in ${_retryDelay}s');
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      AppLogger.error('RealtimeService: Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _retryDelay), () {
      _retryDelay = (_retryDelay * 2).clamp(1, 30);
      _doConnect();
    });
  }

  /// Sends a raw [message] string to the server.
  void send(String message) {
    try {
      if (_channel != null) {
        _channel?.sink.add(message);
      } else {
        // In demo / test mode without an active remote socket, loop back to the stream
        final event = RealtimeEvent.fromRaw(message);
        _controller?.add(event);
      }
    } catch (e) {
      AppLogger.error('RealtimeService: Send failed: $e');
    }
  }

  /// Broadcasts a typed event with payload to the WebSocket server.
  void sendEvent(String type, Map<String, dynamic> data) {
    final msg = jsonEncode({'type': type, 'data': data});
    send(msg);
  }

  /// Broadcasts a newly created order.
  void broadcastOrderCreated(Map<String, dynamic> orderJson) {
    sendEvent('orderCreated', orderJson);
  }

  /// Broadcasts a newly dispatched delivery assignment.
  void broadcastDeliveryAssignmentCreated(
    Map<String, dynamic> assignmentJson,
  ) {
    sendEvent('deliveryAssignmentCreated', assignmentJson);
  }

  /// Broadcasts an updated order status.
  ///
  /// [updatedAt] stamps the event so receivers can discard stale/out-of-order
  /// deliveries instead of regressing an order's state.
  void broadcastOrderStatusChanged(
    String orderId,
    String statusName, {
    DateTime? updatedAt,
  }) {
    sendEvent('orderStatusChanged', {
      'orderId': orderId,
      'id': orderId,
      'status': statusName,
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    });
  }

  /// Broadcasts an intentional backward status move (operator correction).
  ///
  /// Mirrors [broadcastOrderStatusChanged]: [fromStatus] is the status being
  /// reverted, [toStatus] is the restored (earlier) status, and [updatedAt]
  /// stamps the event so receivers can discard stale deliveries.
  void broadcastOrderStatusReverted(
    String orderId,
    String fromStatus,
    String toStatus, {
    DateTime? updatedAt,
  }) {
    sendEvent('orderStatusReverted', {
      'orderId': orderId,
      'id': orderId,
      'status': toStatus,
      'fromStatus': fromStatus,
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    });
  }

  /// Broadcasts an updated table status.
  void broadcastTableStatusChanged(Map<String, dynamic> tableJson) {
    sendEvent('tableStatusChanged', tableJson);
  }

  /// Broadcasts a driver location update.
  ///
  /// [orderId], when provided, scopes the update to a specific delivery so
  /// customer tracking pages can filter events belonging to their own order
  /// instead of reacting to every driver on the road.
  void broadcastDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    String? orderId,
  }) {
    sendEvent('driverLocationUpdated', {
      'driverId': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
      if (orderId != null) 'orderId': orderId,
    });
  }

  /// Closes the connection and cleans up resources.
  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _channel?.sink.close();
    _controller?.close();
  }
}

/// Provider exposing a shared [RealtimeService] instance.
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  if (!AppConfig.useDemoAuth && !AppConfig.useSupabase) {
    service.connect();
  }
  ref.onDispose(service.disconnect);
  return service;
});
