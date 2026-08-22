import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/domain/enums.dart';

void main() {
  group('OrderStatus.canRevertTo', () {
    test('exhaustively: only ready→preparing and served→ready are allowed',
        () {
      for (final current in OrderStatus.values) {
        for (final previous in OrderStatus.values) {
          final expected =
              (current == OrderStatus.ready &&
                      previous == OrderStatus.preparing) ||
                  (current == OrderStatus.served &&
                      previous == OrderStatus.ready);
          expect(
            current.canRevertTo(previous),
            expected,
            reason: '$current.canRevertTo($previous) should be $expected',
          );
        }
      }
    });

    test('terminal statuses never revert from any status', () {
      for (final previous in OrderStatus.values) {
        expect(
          OrderStatus.completed.canRevertTo(previous),
          isFalse,
          reason: 'completed.canRevertTo($previous) must be false',
        );
        expect(
          OrderStatus.cancelled.canRevertTo(previous),
          isFalse,
          reason: 'cancelled.canRevertTo($previous) must be false',
        );
      }
    });

    test('no status can revert to a terminal status', () {
      for (final current in OrderStatus.values) {
        expect(
          current.canRevertTo(OrderStatus.completed),
          isFalse,
          reason: '$current.canRevertTo(completed) must be false',
        );
        expect(
          current.canRevertTo(OrderStatus.cancelled),
          isFalse,
          reason: '$current.canRevertTo(cancelled) must be false',
        );
      }
    });

    test('the two allowed reverts hold explicitly', () {
      expect(OrderStatus.ready.canRevertTo(OrderStatus.preparing), isTrue);
      expect(OrderStatus.served.canRevertTo(OrderStatus.ready), isTrue);
    });

    test('multi-step or unrelated backward moves are rejected', () {
      // Skipping a step backwards is not allowed.
      expect(OrderStatus.served.canRevertTo(OrderStatus.preparing), isFalse);
      expect(OrderStatus.completed.canRevertTo(OrderStatus.served), isFalse);
      // Same-status "revert" is not a revert.
      expect(OrderStatus.ready.canRevertTo(OrderStatus.ready), isFalse);
      expect(OrderStatus.served.canRevertTo(OrderStatus.served), isFalse);
    });

    group('canTransitionTo remains unchanged by revert support', () {
      test('forward transitions still work', () {
        expect(OrderStatus.pending.canTransitionTo(OrderStatus.confirmed),
            isTrue);
        expect(OrderStatus.confirmed.canTransitionTo(OrderStatus.preparing),
            isTrue);
        expect(OrderStatus.preparing.canTransitionTo(OrderStatus.ready),
            isTrue);
        expect(OrderStatus.ready.canTransitionTo(OrderStatus.served), isTrue);
        expect(OrderStatus.served.canTransitionTo(OrderStatus.completed),
            isTrue);
        expect(OrderStatus.pending.canTransitionTo(OrderStatus.cancelled),
            isTrue);
      });

      test('backward moves are still rejected by canTransitionTo', () {
        expect(OrderStatus.ready.canTransitionTo(OrderStatus.preparing),
            isFalse);
        expect(OrderStatus.served.canTransitionTo(OrderStatus.ready), isFalse);
        expect(OrderStatus.served.canTransitionTo(OrderStatus.pending),
            isFalse);
      });

      test('terminal states still reject all transitions out', () {
        for (final next in OrderStatus.values) {
          expect(
            OrderStatus.completed.canTransitionTo(next),
            next == OrderStatus.completed,
            reason: 'completed.canTransitionTo($next)',
          );
          expect(
            OrderStatus.cancelled.canTransitionTo(next),
            next == OrderStatus.cancelled,
            reason: 'cancelled.canTransitionTo($next)',
          );
        }
      });
    });
  });
}
