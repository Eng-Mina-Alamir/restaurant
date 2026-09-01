import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/delivery/domain/entities/delivery_exception_entity.dart';
import 'package:restaurant_app/features/delivery/domain/services/driver_quick_action_service.dart';

void main() {
  group('Driver Quick Actions & Field Communications Tests', () {
    test('Formats Egyptian local phone number for WhatsApp accurately', () {
      final formatted = DriverQuickActionService.formatPhoneForWhatsApp('01012345678');
      expect(formatted, '201012345678');

      final formattedWithPlus = DriverQuickActionService.formatPhoneForWhatsApp('+201122334455');
      expect(formattedWithPlus, '201122334455');
    });

    test('Generates valid WhatsApp URL with encoded Arabic message', () {
      const phone = '01012345678';
      const msg = 'أنا وصلت تحت العمارة حالياً 📍';

      final url = DriverQuickActionService.getWhatsAppUriString(
        phone: phone,
        message: msg,
      );

      expect(url.startsWith('https://wa.me/201012345678?text='), isTrue);
      expect(url.contains('%D8%A3%D9%86%D8%A7'), isTrue); // URL-encoded Arabic
    });

    test('Generates telephone call URI string', () {
      final telUri = DriverQuickActionService.getTelUriString('010-9876-5432');
      expect(telUri, 'tel:01098765432');
    });

    test('Generates external Google Maps directions link with coordinates', () {
      final mapUrl = DriverQuickActionService.getGoogleMapsDirectionsUrl(
        latitude: 30.0444,
        longitude: 31.2357,
        label: 'ميدان التحرير',
      );

      expect(mapUrl, 'https://www.google.com/maps/dir/?api=1&destination=30.0444,31.2357');
    });

    test('Creates and serializes DeliveryExceptionEntity properly', () {
      final now = DateTime.now();
      final exception = DeliveryExceptionEntity(
        id: 'exc-101',
        assignmentId: 'assign-1',
        orderId: 'ord-55',
        driverId: 'drv-7',
        driverName: 'كابتن محمود',
        reason: DeliveryExceptionReason.customerUnreachable,
        callAttemptsCount: 3,
        timestamp: now,
        notes: 'دققت الباب والهاتف مغلق لمدة 5 دقائق',
        returnedToKitchen: true,
      );

      final json = exception.toJson();
      expect(json['id'], 'exc-101');
      expect(json['reason'], 'customerUnreachable');
      expect(json['call_attempts'], 3);
      expect(json['returned_to_kitchen'], true);

      final parsed = DeliveryExceptionEntity.fromJson(json);
      expect(parsed.id, 'exc-101');
      expect(parsed.reason, DeliveryExceptionReason.customerUnreachable);
      expect(parsed.callAttemptsCount, 3);
      expect(parsed.returnedToKitchen, true);
    });
  });
}
