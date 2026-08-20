import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/config/constants.dart';

void main() {
  group('AppConstants Tests', () {
    test('constants are non-empty strings', () {
      expect(AppConstants.loginButton, isNotEmpty);
      expect(AppConstants.orderConfirmationTitle, isNotEmpty);
      expect(AppConstants.cartTitle, isNotEmpty);
      expect(AppConstants.menuTitle, isNotEmpty);
      expect(AppConstants.tablesTitle, isNotEmpty);
      expect(AppConstants.kdsTitle, isNotEmpty);
      expect(AppConstants.managerTitle, isNotEmpty);
      expect(AppConstants.driverTitle, isNotEmpty);
      expect(AppConstants.errorConnection, isNotEmpty);
      expect(AppConstants.errorServer, isNotEmpty);
    });

    test('OrderStatusAr maps known and fallback statuses', () {
      expect(OrderStatusAr.labelOf('pending'), 'قيد الانتظار');
      expect(OrderStatusAr.labelOf('confirmed'), 'مؤكد');
      expect(OrderStatusAr.labelOf('preparing'), 'قيد التحضير');
      expect(OrderStatusAr.labelOf('ready'), 'جاهز');
      expect(OrderStatusAr.labelOf('delivering'), 'قيد التوصيل');
      expect(OrderStatusAr.labelOf('delivered'), 'تم التوصيل');
      expect(OrderStatusAr.labelOf('completed'), 'مكتمل');
      expect(OrderStatusAr.labelOf('cancelled'), 'ملغي');
      expect(OrderStatusAr.labelOf('unknown_status'), 'unknown_status');
    });
  });
}
