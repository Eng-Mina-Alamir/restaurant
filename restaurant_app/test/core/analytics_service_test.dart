import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/analytics/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService service;

    setUp(() {
      service = AnalyticsService();
    });

    test('logs custom events and specialized e-commerce events', () {
      service.logScreenView('CartPage');
      expect(service.loggedEvents.length, 1);
      expect(service.loggedEvents.first.name, 'screen_view');
      expect(service.loggedEvents.first.parameters['screen_name'], 'CartPage');

      service.logAddToCart(
        itemId: 'm-1',
        itemName: 'برجر دجاج',
        price: 30.0,
        quantity: 2,
      );
      expect(service.loggedEvents.length, 2);
      expect(service.loggedEvents[1].name, 'add_to_cart');
      expect(service.loggedEvents[1].parameters['total'], 60.0);

      service.logOrderPlaced(
        orderId: 'ORD-999',
        totalAmount: 120.0,
        orderType: 'dineIn',
        itemCount: 4,
      );
      expect(service.loggedEvents.length, 3);
      expect(service.loggedEvents[2].name, 'order_placed');

      service.logPaymentCompleted(
        orderId: 'ORD-999',
        amount: 120.0,
        method: 'mada',
      );
      expect(service.loggedEvents.length, 4);
      expect(service.loggedEvents[3].name, 'payment_completed');
    });

    test('records errors with stack trace and reason', () {
      final error = Exception('Network timeout');
      service.recordError(error, reason: 'Failed during API sync');

      expect(service.recordedErrors.length, 1);
      expect(service.recordedErrors.first.exception, error);
      expect(service.recordedErrors.first.reason, 'Failed during API sync');
    });

    test('sets and retains user properties', () {
      service.setUserProperty('role', 'manager');
      service.setUserProperty('tier', 'gold');

      expect(service.userProperties['role'], 'manager');
      expect(service.userProperties['tier'], 'gold');
    });
  });
}
