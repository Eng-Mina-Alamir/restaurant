import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/utils/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('isValidEmail handles valid and invalid email addresses', () {
      expect(Validators.isValidEmail('user@example.com'), isTrue);
      expect(Validators.isValidEmail('john.doe+test@sub.domain.co'), isTrue);
      expect(Validators.isValidEmail(''), isFalse);
      expect(Validators.isValidEmail(null), isFalse);
      expect(Validators.isValidEmail('invalid-email'), isFalse);
      expect(Validators.isValidEmail('@domain.com'), isFalse);
      expect(Validators.isValidEmail('user@.com'), isFalse);
    });

    test('isValidPhone handles Saudi local and international formats', () {
      expect(Validators.isValidPhone('0501234567'), isTrue);
      expect(Validators.isValidPhone('+966501234567'), isTrue);
      expect(Validators.isValidPhone('00966501234567'), isTrue);
      expect(Validators.isValidPhone('050-123-4567'), isTrue);
      expect(Validators.isValidPhone('050 123 4567'), isTrue);

      expect(Validators.isValidPhone(null), isFalse);
      expect(Validators.isValidPhone(''), isFalse);
      expect(Validators.isValidPhone('0123456789'), isFalse);
      expect(Validators.isValidPhone('+1234567890'), isFalse);
      expect(Validators.isValidPhone('0501234'), isFalse);
    });

    test('isValidOtp checks 6-digit numeric codes', () {
      expect(Validators.isValidOtp('123456'), isTrue);
      expect(Validators.isValidOtp('000000'), isTrue);
      expect(Validators.isValidOtp('999999'), isTrue);

      expect(Validators.isValidOtp('12345'), isFalse);
      expect(Validators.isValidOtp('1234567'), isFalse);
      expect(Validators.isValidOtp('12345a'), isFalse);
      expect(Validators.isValidOtp(null), isFalse);
      expect(Validators.isValidOtp(''), isFalse);
    });

    test('isValidName checks reasonable length and letter presence', () {
      expect(Validators.isValidName('Ahmed'), isTrue);
      expect(Validators.isValidName('أحمد محمد'), isTrue);
      expect(Validators.isValidName('مطعم النخيل'), isTrue);

      expect(Validators.isValidName(null), isFalse);
      expect(Validators.isValidName(''), isFalse);
      expect(Validators.isValidName('   '), isFalse);
      expect(Validators.isValidName('12345'), isFalse);
      expect(Validators.isValidName('a' * 51), isFalse);
    });
  });
}
