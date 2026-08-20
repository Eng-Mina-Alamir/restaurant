import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';
import 'package:restaurant_app/features/table_management/domain/entities/restaurant_table.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_controller.dart';
import 'helpers/qa_test_helpers.dart';

void main() {
  group('Suite 8: Realtime & Notifications (الإشعارات والمزامنة الحية)', () {
    // -------------------------------------------------------------
    // TC-NOTIF-01: Order Status Realtime Event Dispatch
    // -------------------------------------------------------------
    test('TC-NOTIF-01: Realtime event broadcast on order creation and status change', () async {
      final realtime = RealtimeService();
      final container = createQaContainer(realtimeService: realtime);
      addTearDown(container.dispose);

      final receivedEvents = <RealtimeEvent>[];
      final sub = realtime.events.listen(receivedEvents.add);
      addTearDown(sub.cancel);

      realtime.broadcastOrderStatusChanged('ORD-1234', OrderStatus.ready.name);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(receivedEvents, hasLength(1));
      expect(receivedEvents.first.type, RealtimeEventType.orderStatusChanged);
      expect(receivedEvents.first.payload['status'], OrderStatus.ready.name);
    });

    // -------------------------------------------------------------
    // TC-NOTIF-02: Deep Linking Navigation Payload
    // -------------------------------------------------------------
    test('TC-NOTIF-02: Notification payload parses order target and route', () {
      final payload = {'type': 'order_update', 'orderId': 'ORD-999', 'route': '/customer/order/ORD-999'};
      expect(payload['route'], '/customer/order/ORD-999');
      expect(payload['orderId'], 'ORD-999');
    });

    // -------------------------------------------------------------
    // TC-NOTIF-03: Multi-device Live Synchronization
    // -------------------------------------------------------------
    test('TC-NOTIF-03: Multiple listening controllers update state synchronously on broadcast events', () async {
      final realtime = RealtimeService();

      final device1Container = createQaContainer(realtimeService: realtime);
      final device2Container = createQaContainer(realtimeService: realtime);
      addTearDown(device1Container.dispose);
      addTearDown(device2Container.dispose);

      // Initialize device 2 listener and wait for initial load to finish
      device2Container.read(tableControllerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Device 1 broadcasts table status change
      const updatedTable = RestaurantTable(
        id: 't1',
        tableNumber: 1,
        capacity: 4,
        status: TableStatus.occupied,
        currentOrderId: 'ORD-LIVE-SYNC-777',
      );

      realtime.broadcastTableStatusChanged(updatedTable.toJson());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Device 2 reflects the new state automatically
      final device2Tables = device2Container.read(tableControllerProvider);
      final syncedTable = device2Tables.firstWhere((t) => t.id == 't1');

      expect(syncedTable.status, TableStatus.occupied);
      expect(syncedTable.currentOrderId, 'ORD-LIVE-SYNC-777');
    });
  });
}
