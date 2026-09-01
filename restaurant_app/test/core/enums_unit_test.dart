import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';

void main() {
  group('OrderType Enum', () {
    test('labelAr returns valid arabic names for all types', () {
      expect(OrderType.dineIn.labelAr.isNotEmpty, isTrue);
      expect(OrderType.takeaway.labelAr.isNotEmpty, isTrue);
      expect(OrderType.delivery.labelAr.isNotEmpty, isTrue);
    });

    test('fromName handles various string inputs and fallback', () {
      expect(OrderType.fromName('dineIn'), OrderType.dineIn);
      expect(OrderType.fromName('dine_in'), OrderType.dineIn);
      expect(OrderType.fromName('takeaway'), OrderType.takeaway);
      expect(OrderType.fromName('take_away'), OrderType.takeaway);
      expect(OrderType.fromName('delivery'), OrderType.delivery);
      expect(OrderType.fromName(null), OrderType.dineIn);
      expect(OrderType.fromName('unknown'), OrderType.dineIn);
    });
  });

  group('OrderStatus Enum', () {
    test('labelAr returns valid arabic string', () {
      for (final status in OrderStatus.values) {
        expect(status.labelAr.isNotEmpty, isTrue);
      }
    });

    test('isTerminal is true only for completed and cancelled', () {
      expect(OrderStatus.pending.isTerminal, isFalse);
      expect(OrderStatus.confirmed.isTerminal, isFalse);
      expect(OrderStatus.preparing.isTerminal, isFalse);
      expect(OrderStatus.ready.isTerminal, isFalse);
      expect(OrderStatus.served.isTerminal, isFalse);
      expect(OrderStatus.completed.isTerminal, isTrue);
      expect(OrderStatus.cancelled.isTerminal, isTrue);
    });

    test('fromName handles synonyms, variants, and null', () {
      expect(OrderStatus.fromName('pending'), OrderStatus.pending);
      expect(OrderStatus.fromName('confirmed'), OrderStatus.confirmed);
      expect(OrderStatus.fromName('preparing'), OrderStatus.preparing);
      expect(OrderStatus.fromName('ready'), OrderStatus.ready);
      expect(OrderStatus.fromName('served'), OrderStatus.served);
      expect(OrderStatus.fromName('completed'), OrderStatus.completed);
      expect(OrderStatus.fromName('cancelled'), OrderStatus.cancelled);
      expect(OrderStatus.fromName('canceled'), OrderStatus.cancelled);
      expect(OrderStatus.fromName(null), OrderStatus.pending);
      expect(OrderStatus.fromName('non_existent'), OrderStatus.pending);
    });
  });

  group('TableStatus Enum', () {
    test('labelAr returns valid arabic string', () {
      for (final status in TableStatus.values) {
        expect(status.labelAr.isNotEmpty, isTrue);
      }
    });

    test('fromName maps properly and provides default', () {
      expect(TableStatus.fromName('available'), TableStatus.available);
      expect(TableStatus.fromName('occupied'), TableStatus.occupied);
      expect(TableStatus.fromName('reserved'), TableStatus.reserved);
      expect(TableStatus.fromName('needscleaning'), TableStatus.needsCleaning);
      expect(TableStatus.fromName('needs_cleaning'), TableStatus.needsCleaning);
      expect(TableStatus.fromName(null), TableStatus.available);
      expect(TableStatus.fromName('random_status'), TableStatus.available);
    });
  });

  group('UserRole Enum', () {
    test('labelAr and homeRoute provide valid non-empty mapping', () {
      for (final role in UserRole.values) {
        expect(role.labelAr.isNotEmpty, isTrue);
        expect(role.homeRoute.startsWith('/'), isTrue);
      }
      expect(UserRole.customer.homeRoute, '/customer');
      expect(UserRole.waiter.homeRoute, '/waiter');
      expect(UserRole.kitchen.homeRoute, '/kds');
      expect(UserRole.manager.homeRoute, '/manager');
      expect(UserRole.admin.homeRoute, '/manager');
      expect(UserRole.driver.homeRoute, '/driver');
      expect(UserRole.cashier.homeRoute, '/cashier');
    });

    test('fromName matches aliases and defaults to customer', () {
      expect(UserRole.fromName('customer'), UserRole.customer);
      expect(UserRole.fromName('waiter'), UserRole.waiter);
      expect(UserRole.fromName('kitchen'), UserRole.kitchen);
      expect(UserRole.fromName('kds'), UserRole.kitchen);
      expect(UserRole.fromName('manager'), UserRole.manager);
      expect(UserRole.fromName('admin'), UserRole.admin);
      expect(UserRole.fromName('driver'), UserRole.driver);
      expect(UserRole.fromName(null), UserRole.customer);
      expect(UserRole.fromName('invalid_role'), UserRole.customer);
    });
  });

  group('PaymentMethod Enum', () {
    test('labelAr returns correct labels', () {
      for (final method in PaymentMethod.values) {
        expect(method.labelAr.isNotEmpty, isTrue);
      }
    });

    test('fromName parses names properly', () {
      expect(PaymentMethod.fromName('cash'), PaymentMethod.cash);
      expect(PaymentMethod.fromName('card'), PaymentMethod.card);
      expect(PaymentMethod.fromName('wallet'), PaymentMethod.wallet);
      expect(PaymentMethod.fromName('online'), PaymentMethod.online);
      expect(PaymentMethod.fromName(null), PaymentMethod.cash);
      expect(PaymentMethod.fromName('crypto'), PaymentMethod.cash);
    });
  });

  group('DeliveryStatus Enum', () {
    test('labelAr returns correct labels', () {
      for (final status in DeliveryStatus.values) {
        expect(status.labelAr.isNotEmpty, isTrue);
      }
    });

    test('fromName maps synonyms correctly', () {
      expect(DeliveryStatus.fromName('pending'), DeliveryStatus.pending);
      expect(DeliveryStatus.fromName('accepted'), DeliveryStatus.accepted);
      expect(DeliveryStatus.fromName('pickedup'), DeliveryStatus.pickedUp);
      expect(DeliveryStatus.fromName('picked_up'), DeliveryStatus.pickedUp);
      expect(DeliveryStatus.fromName('intransit'), DeliveryStatus.inTransit);
      expect(DeliveryStatus.fromName('in_transit'), DeliveryStatus.inTransit);
      expect(DeliveryStatus.fromName('delivering'), DeliveryStatus.inTransit);
      expect(DeliveryStatus.fromName('delivered'), DeliveryStatus.delivered);
      expect(DeliveryStatus.fromName('failed'), DeliveryStatus.failed);
      expect(DeliveryStatus.fromName('cancelled'), DeliveryStatus.failed);
      expect(DeliveryStatus.fromName(null), DeliveryStatus.pending);
      expect(DeliveryStatus.fromName('unknown'), DeliveryStatus.pending);
    });
  });
}
