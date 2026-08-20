import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/errors/either.dart';

void main() {
  group('Either Type Tests', () {
    test('Left holds error and returns correct flags', () {
      final Either<String, int> result = left('error message');

      expect(result.isLeft, isTrue);
      expect(result.isRight, isFalse);
      expect((result as Left<String, int>).value, 'error message');
    });

    test('Right holds value and returns correct flags', () {
      final Either<String, int> result = right(42);

      expect(result.isLeft, isFalse);
      expect(result.isRight, isTrue);
      expect((result as Right<String, int>).value, 42);
    });

    test('when pattern matching works for Left', () {
      const Either<String, int> result = Left('failure');

      final output = result.when(
        onLeft: (err) => 'Handled error: $err',
        onRight: (val) => 'Handled value: $val',
      );

      expect(output, 'Handled error: failure');
    });

    test('when pattern matching works for Right', () {
      const Either<String, int> result = Right(100);

      final output = result.when(
        onLeft: (err) => 'Handled error: $err',
        onRight: (val) => 'Handled value: $val',
      );

      expect(output, 'Handled value: 100');
    });
  });
}
