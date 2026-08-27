import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/network/realtime_service.dart';
import 'package:restaurant_app/features/table_management/domain/entities/table_service_request.dart';
import 'package:restaurant_app/features/table_management/presentation/controllers/table_service_controller.dart';

void main() {
  group('TableServiceController', () {
    test('requestService creates active request and acknowledgeService marks handled', () {
      final realtime = RealtimeService();
      final controller = TableServiceController(realtimeService: realtime);

      expect(controller.activeRequestsCount, equals(0));

      final request = controller.requestService(
        tableId: 'tbl-5',
        tableNumber: 5,
        type: TableServiceType.callWaiter,
        note: 'طلب مناديل إضافية',
      );

      expect(controller.activeRequestsCount, equals(1));
      expect(controller.activeRequestsForTable('tbl-5').length, equals(1));
      expect(request.tableNumber, equals(5));
      expect(request.isHandled, isFalse);

      controller.acknowledgeService(request.id, waiterId: 'waiter-10');

      expect(controller.activeRequestsCount, equals(0));
      expect(controller.state.first.isHandled, isTrue);
      expect(controller.state.first.handledByWaiterId, equals('waiter-10'));
    });
  });
}
