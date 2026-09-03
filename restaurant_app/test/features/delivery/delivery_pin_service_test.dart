import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/delivery/data/repositories/in_memory_delivery_pin_repository.dart';
import 'package:restaurant_app/features/delivery/domain/services/delivery_pin_service.dart';
import 'package:restaurant_app/features/delivery/domain/services/driver_quick_action_service.dart';

String requireRight(dynamic either) {
  // ignore: avoid_dynamic_calls
  return (either as dynamic).when(
    // ignore: avoid_dynamic_calls
    onLeft: (failure) =>
        throw StateError('expected Right, got Left: $failure'),
    // ignore: avoid_dynamic_calls
    onRight: (value) => value as String,
  ) as String;
}

bool requireRightBool(dynamic either) {
  // ignore: avoid_dynamic_calls
  return (either as dynamic).when(
    // ignore: avoid_dynamic_calls
    onLeft: (failure) =>
        throw StateError('expected Right, got Left: $failure'),
    // ignore: avoid_dynamic_calls
    onRight: (value) => value as bool,
  ) as bool;
}

void main() {
  group('DeliveryPinService (per-order random codes)', () {
    test('generatePin produces distinct 6-digit codes across orders', () {
      final pins = List.generate(
        50,
        (_) => DeliveryPinService.generatePin(),
      ).toSet();
      // Random per order: 50 draws must not collapse to a single value.
      expect(pins.length, greaterThan(1));
      for (final pin in pins) {
        expect(RegExp(r'^\d{6}$').hasMatch(pin), isTrue);
      }
    });

    test('qrPayloadFor + extractCode round-trips the code', () {
      const orderId = 'ORD-0042';
      const code = '482910';
      final payload = DeliveryPinService.qrPayloadFor(
        orderId: orderId,
        code: code,
      );
      expect(payload, 'DELIVERY:ORD-0042:482910');
      expect(DeliveryPinService.extractCode(payload), code);
      expect(DeliveryPinService.extractCode(code), code);
      expect(DeliveryPinService.extractCode('  $code  '), code);
    });

    test('extractCode finds a code inside pasted SMS text', () {
      expect(
        DeliveryPinService.extractCode('كود الاستلام الخاص بك هو 482910 شكراً'),
        '482910',
      );
    });

    test('isValidFormat rejects junk', () {
      expect(DeliveryPinService.isValidFormat('482910'), isTrue);
      expect(DeliveryPinService.isValidFormat('1234'), isTrue);
      expect(DeliveryPinService.isValidFormat(''), isFalse);
      expect(DeliveryPinService.isValidFormat('12'), isFalse);
      expect(DeliveryPinService.isValidFormat('abcdef'), isFalse);
    });
  });

  group('InMemoryDeliveryPinRepository (server semantics)', () {
    test('ensurePin is stable per order but random across orders', () async {
      final repo = InMemoryDeliveryPinRepository();
      final first = requireRight(await repo.ensurePin('ORD-A'));
      final second = requireRight(await repo.ensurePin('ORD-A'));
      expect(second, first);

      final other = requireRight(await repo.ensurePin('ORD-B'));
      // Random across orders (overwhelmingly likely distinct).
      expect(other, isNot(equals(first)));
    });

    test('verifyPin accepts only the exact code (no universal bypass)', () async {
      final repo = InMemoryDeliveryPinRepository();
      final pin = requireRight(await repo.ensurePin('ORD-A'));
      expect(requireRightBool(await repo.verifyPin('ORD-A', pin)), isTrue);
      expect(
        requireRightBool(await repo.verifyPin('ORD-A', '000000')),
        isFalse,
      );
      expect(
        requireRightBool(await repo.verifyPin('ORD-A', '1234')),
        isFalse,
      );
      expect(
        requireRightBool(await repo.verifyPin('ORD-A', 'wrong')),
        isFalse,
      );
    });

    test('invalidatePin consumes the code and rotates on next ensure', () async {
      final repo = InMemoryDeliveryPinRepository();
      final pin = requireRight(await repo.ensurePin('ORD-A'));
      expect(requireRightBool(await repo.verifyPin('ORD-A', pin)), isTrue);
      await repo.invalidatePin('ORD-A');
      // Replay protection: the consumed code no longer verifies.
      expect(requireRightBool(await repo.verifyPin('ORD-A', pin)), isFalse);
      final rotated = requireRight(await repo.ensurePin('ORD-A'));
      expect(rotated, isNot(equals(pin)));
      expect(
        requireRightBool(await repo.verifyPin('ORD-A', rotated)),
        isTrue,
      );
    });
  });

  group('DriverQuickActionService launchable URIs', () {
    test('toTelUri / toWhatsAppUri / toMapsUri parse to launchable URIs', () {
      final tel = DriverQuickActionService.toTelUri('010-9876-5432');
      expect(tel.scheme, 'tel');

      final wa = DriverQuickActionService.toWhatsAppUri(
        phone: '01012345678',
        message: 'وصلت',
      );
      expect(wa.scheme, 'https');
      expect(wa.host, 'wa.me');

      final maps = DriverQuickActionService.toMapsUri(
        latitude: 30.0444,
        longitude: 31.2357,
        label: 'العميل',
      );
      expect(maps.scheme, 'https');
      expect(maps.host, 'www.google.com');
    });
  });
}
