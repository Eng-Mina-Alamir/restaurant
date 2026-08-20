import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';

void main() {
  group('Order State Machine Integrity & Transition Guards', () {
    test('pending status valid and invalid transitions', () {
      const status = OrderStatus.pending;
      expect(status.isTerminal, isFalse);

      expect(status.canTransitionTo(OrderStatus.confirmed), isTrue);
      expect(status.canTransitionTo(OrderStatus.preparing), isTrue);
      expect(status.canTransitionTo(OrderStatus.cancelled), isTrue);
      expect(status.canTransitionTo(OrderStatus.pending), isTrue); // Same state

      // Invalid transitions from pending
      expect(status.canTransitionTo(OrderStatus.ready), isFalse);
      expect(status.canTransitionTo(OrderStatus.served), isFalse);
      expect(status.canTransitionTo(OrderStatus.completed), isFalse);
    });

    test('confirmed status valid and invalid transitions', () {
      const status = OrderStatus.confirmed;
      expect(status.canTransitionTo(OrderStatus.preparing), isTrue);
      expect(status.canTransitionTo(OrderStatus.cancelled), isTrue);

      expect(status.canTransitionTo(OrderStatus.pending), isFalse);
      expect(status.canTransitionTo(OrderStatus.served), isFalse);
      expect(status.canTransitionTo(OrderStatus.completed), isFalse);
    });

    test('preparing status valid and invalid transitions', () {
      const status = OrderStatus.preparing;
      expect(status.canTransitionTo(OrderStatus.ready), isTrue);
      expect(status.canTransitionTo(OrderStatus.cancelled), isTrue);

      expect(status.canTransitionTo(OrderStatus.pending), isFalse);
      expect(status.canTransitionTo(OrderStatus.confirmed), isFalse);
      expect(status.canTransitionTo(OrderStatus.completed), isFalse);
    });

    test('ready status valid and invalid transitions', () {
      const status = OrderStatus.ready;
      expect(status.canTransitionTo(OrderStatus.served), isTrue);
      expect(status.canTransitionTo(OrderStatus.completed), isTrue);
      expect(status.canTransitionTo(OrderStatus.cancelled), isTrue);

      expect(status.canTransitionTo(OrderStatus.pending), isFalse);
      expect(status.canTransitionTo(OrderStatus.preparing), isFalse);
    });

    test('served status requires completed transition and blocks direct cancel', () {
      const status = OrderStatus.served;
      expect(status.canTransitionTo(OrderStatus.completed), isTrue);

      // Once served to a customer at the table, waiter cannot arbitrarily cancel it
      expect(status.canTransitionTo(OrderStatus.cancelled), isFalse);
      expect(status.canTransitionTo(OrderStatus.pending), isFalse);
      expect(status.canTransitionTo(OrderStatus.preparing), isFalse);
    });

    test('terminal states (completed, cancelled) block all further transitions', () {
      expect(OrderStatus.completed.isTerminal, isTrue);
      expect(OrderStatus.cancelled.isTerminal, isTrue);

      for (final next in OrderStatus.values) {
        if (next == OrderStatus.completed) continue;
        expect(OrderStatus.completed.canTransitionTo(next), isFalse);
      }

      for (final next in OrderStatus.values) {
        if (next == OrderStatus.cancelled) continue;
        expect(OrderStatus.cancelled.canTransitionTo(next), isFalse);
      }
    });

    test('OrderStatus.fromName gracefully handles case insensitivity, variants and unknown strings', () {
      expect(OrderStatus.fromName('pending'), OrderStatus.pending);
      expect(OrderStatus.fromName('CONFIRMED'), OrderStatus.confirmed);
      expect(OrderStatus.fromName('Preparing'), OrderStatus.preparing);
      expect(OrderStatus.fromName('ready'), OrderStatus.ready);
      expect(OrderStatus.fromName('Served'), OrderStatus.served);
      expect(OrderStatus.fromName('completed'), OrderStatus.completed);
      expect(OrderStatus.fromName('cancelled'), OrderStatus.cancelled);
      expect(OrderStatus.fromName('canceled'), OrderStatus.cancelled); // US English single 'l' variant

      expect(OrderStatus.fromName(null), OrderStatus.pending);
      expect(OrderStatus.fromName('UNKNOWN_XYZ'), OrderStatus.pending);
    });
  });
}
