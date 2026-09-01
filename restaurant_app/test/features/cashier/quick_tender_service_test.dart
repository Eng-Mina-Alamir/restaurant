import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/features/cashier/domain/services/quick_tender_service.dart';

void main() {
  group('QuickTenderService', () {
    test('calculateSuggestedTenders generates smart bill denominations for 340 EGP', () {
      final suggestions = QuickTenderService.calculateSuggestedTenders(340.0);

      // Exact (340), Next 50 (350), Next 100 (400), Big Bill (500)
      expect(suggestions, contains(340.0));
      expect(suggestions, contains(350.0));
      expect(suggestions, contains(400.0));
      expect(suggestions, contains(500.0));
    });

    test('calculateSuggestedTenders for low bill amount (e.g. 35 EGP)', () {
      final suggestions = QuickTenderService.calculateSuggestedTenders(35.0);

      expect(suggestions, contains(35.0)); // exact
      expect(suggestions, contains(50.0)); // 50 bill
      expect(suggestions, contains(100.0)); // 100 bill
    });

    test('calculateChangeDue correctly calculates change for 500 EGP tendered on 320 EGP bill', () {
      final change = QuickTenderService.calculateChangeDue(
        totalDue: 320.0,
        tenderedAmount: 500.0,
      );

      expect(change, equals(180.0));
    });

    test('calculateChangeDue returns 0.0 when tendered amount is less than total due', () {
      final change = QuickTenderService.calculateChangeDue(
        totalDue: 300.0,
        tenderedAmount: 250.0,
      );

      expect(change, equals(0.0));
    });

    test('isTenderSufficient verifies sufficient payment', () {
      expect(
        QuickTenderService.isTenderSufficient(totalDue: 200.0, tenderedAmount: 200.0),
        isTrue,
      );
      expect(
        QuickTenderService.isTenderSufficient(totalDue: 200.0, tenderedAmount: 250.0),
        isTrue,
      );
      expect(
        QuickTenderService.isTenderSufficient(totalDue: 200.0, tenderedAmount: 190.0),
        isFalse,
      );
    });
  });
}
