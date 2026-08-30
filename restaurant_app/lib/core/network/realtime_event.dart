import 'dart:convert';

/// Real-time update event types received from the server.
enum RealtimeEventType {
  orderCreated,
  orderStatusChanged,
  orderStatusReverted,
  orderReadyForPickup,
  tableStatusChanged,
  tableServiceRequested,
  tableServiceHandled,
  driverLocationUpdated,
  deliveryAssignmentCreated,
  deliveryAssignmentUpdated,
  unknown,
}

/// A single real-time event.
class RealtimeEvent {
  const RealtimeEvent({required this.type, required this.payload});

  final RealtimeEventType type;
  final Map<String, dynamic> payload;

  factory RealtimeEvent.fromRaw(String raw) {
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final typeName =
            (decoded['type'] ?? decoded['event'])?.toString() ?? '';
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
      case 'orderReadyForPickup':
      case 'order_ready_for_pickup':
        return RealtimeEventType.orderReadyForPickup;
      case 'tableStatusChanged':
      case 'table_status_changed':
        return RealtimeEventType.tableStatusChanged;
      case 'tableServiceRequested':
      case 'table_service_requested':
        return RealtimeEventType.tableServiceRequested;
      case 'tableServiceHandled':
      case 'table_service_handled':
        return RealtimeEventType.tableServiceHandled;
      case 'driverLocationUpdated':
      case 'driver_location_updated':
        return RealtimeEventType.driverLocationUpdated;
      case 'deliveryAssignmentCreated':
      case 'delivery_assignment_created':
        return RealtimeEventType.deliveryAssignmentCreated;
      case 'deliveryAssignmentUpdated':
      case 'delivery_assignment_updated':
        return RealtimeEventType.deliveryAssignmentUpdated;
      default:
        return RealtimeEventType.unknown;
    }
  }
}
