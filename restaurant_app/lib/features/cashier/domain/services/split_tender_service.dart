import '../../../../core/domain/enums.dart';
import '../entities/split_tender_payment_entity.dart';

/// Pure domain service managing and validating multi-tender / split payments.
abstract final class SplitTenderService {
  SplitTenderService._();

  /// Adds a new payment share to an existing [result].
  static SplitTenderResult addPaymentShare({
    required SplitTenderResult currentResult,
    required PaymentMethod method,
    required double amount,
    String? referenceNumber,
    double? tenderedAmount,
    double changeDue = 0.0,
  }) {
    if (amount <= 0) return currentResult;

    final share = SplitTenderShare(
      id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      method: method,
      amount: amount,
      referenceNumber: referenceNumber,
      tenderedAmount: tenderedAmount,
      changeDue: changeDue,
      paidAt: DateTime.now(),
    );

    final updatedPayments = [...currentResult.payments, share];

    return SplitTenderResult(
      orderId: currentResult.orderId,
      totalAmountDue: currentResult.totalAmountDue,
      payments: updatedPayments,
    );
  }

  /// Verifies if the cumulative payments cover the total bill amount.
  static bool validatePaymentSettled(SplitTenderResult result) {
    return result.isFullyPaid;
  }
}
