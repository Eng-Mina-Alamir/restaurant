import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/environment.dart';
import '../utils/logger.dart';

/// Real-time update event types received from the server.
enum RealtimeEventType {
  orderCreated,
  orderStatusChanged,
  tableStatusChanged,
  driverLocationUpdated,
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
    // Minimal JSON-like parsing without a full json_decode to stay lightweight.
    // In production, replace with proper json.decode + typed models.
    try {
      // Very simple pattern: {"type":"orderCreated","data":{...}}
      final typeMatch = RegExp(r'"type"\s*:\s*"(\w+)"').firstMatch(raw);
      final typeName = typeMatch?.group(1) ?? '';
      final eventType = _typeFromString(typeName);
      return RealtimeEvent(type: eventType, payload: {'raw': raw});
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
        return RealtimeEventType.orderCreated;
      case 'orderStatusChanged':
        return RealtimeEventType.orderStatusChanged;
      case 'tableStatusChanged':
        return RealtimeEventType.tableStatusChanged;
      case 'driverLocationUpdated':
        return RealtimeEventType.driverLocationUpdated;
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
      _channel?.sink.add(message);
    } catch (e) {
      AppLogger.error('RealtimeService: Send failed: $e');
    }
  }

  /// Closes the connection and cleans up resources.
  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _controller?.close();
  }
}

/// Provider exposing a shared [RealtimeService] instance.
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  service.connect();
  ref.onDispose(service.disconnect);
  return service;
});
