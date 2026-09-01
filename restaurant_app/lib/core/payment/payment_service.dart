import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../domain/enums.dart';
import '../supabase/supabase_providers.dart';
import '../utils/logger.dart';
import 'mock_payment_gateway.dart';
import 'payment_gateway.dart';
import 'supabase_payment_repository.dart';

/// Stored record of a processed payment transaction.
class PaymentTransactionRecord {
  const PaymentTransactionRecord({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.isSuccess,
    required this.authorizationCode,
    required this.timestamp,
  });

  final String id;
  final String orderId;
  final double amount;
  final PaymentMethod method;
  final bool isSuccess;
  final String authorizationCode;
  final DateTime timestamp;
}

/// Service managing payment workflows and transaction auditing.
///
/// When a [SupabasePaymentRepository] is supplied, every successful payment
/// and refund is also persisted to the `payments` table in Supabase so the
/// data survives app restarts and is available for manager reports.
class PaymentService {
  PaymentService([PaymentGateway? gateway, this._paymentRepo])
    : _gateway = gateway ?? MockPaymentGateway();

  final PaymentGateway _gateway;
  final SupabasePaymentRepository? _paymentRepo;
  final List<PaymentTransactionRecord> _transactions = [];

  List<PaymentTransactionRecord> get transactions =>
      List.unmodifiable(_transactions);

  /// Executes payment for an order.
  ///
  /// On success the transaction is stored both in-memory AND in Supabase
  /// (when the repository is available). A duplicate-payment guard prevents
  /// accidental double charges.
  Future<PaymentResult> payForOrder({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    String? phone,
  }) async {
    // Guard: prevent double payment
    final repo = _paymentRepo;
    if (repo != null) {
      final alreadyPaid = await repo.hasCompletedPayment(orderId);
      if (alreadyPaid) {
        AppLogger.warning('payForOrder: duplicate payment blocked for $orderId');
        return PaymentResult.failure(
          'هذا الطلب تم دفعه بالفعل — لا يمكن الدفع مرتين',
        );
      }
    }

    AppLogger.info(
      'Processing payment of $amount SAR for order $orderId via ${method.name}',
    );

    final request = PaymentRequest(
      orderId: orderId,
      amount: amount,
      method: method,
      customerPhone: phone,
    );

    final result = await _gateway.processPayment(request);

    if (result.isSuccess) {
      final txnId =
          result.transactionId ??
          'TXN-${DateTime.now().millisecondsSinceEpoch}';
      final record = PaymentTransactionRecord(
        id: txnId,
        orderId: orderId,
        amount: amount,
        method: method,
        isSuccess: true,
        authorizationCode: result.authorizationCode ?? '',
        timestamp: result.timestamp,
      );
      _transactions.add(record);
      AppLogger.info('Payment succeeded: $txnId');

      // Persist to Supabase (best-effort — payment already succeeded)
      if (repo != null) {
        final persistResult = await repo.recordPayment(
          orderId: orderId,
          amount: amount,
          method: method,
          transactionRef: txnId,
          paidAt: result.timestamp,
        );
        if (persistResult.isLeft) {
          AppLogger.warning(
            'Payment succeeded but Supabase persistence failed for $txnId',
          );
        }
      }
    } else {
      AppLogger.warning('Payment failed: ${result.errorMessage}');
    }

    return result;
  }

  /// Refunds a transaction.
  Future<RefundResult> refund({
    required String transactionId,
    required double amount,
    String? reason,
  }) async {
    AppLogger.info('Refunding $amount SAR for transaction $transactionId');
    final result = await _gateway.refund(transactionId, amount);

    // Persist refund to Supabase
    final repo = _paymentRepo;
    if (result.isSuccess && repo != null) {
      await repo.recordRefund(
        originalTransactionRef: transactionId,
        refundAmount: amount,
        refundId: result.refundId ?? 'REF-unknown',
        reason: reason,
      );
    }

    return result;
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  SupabasePaymentRepository? paymentRepo;
  if (AppConfig.useSupabase) {
    try {
      paymentRepo = SupabasePaymentRepository(
        supabase: ref.watch(supabaseClientProvider),
      );
    } catch (_) {
      // Supabase not initialized (tests/offline)
    }
  }
  return PaymentService(null, paymentRepo);
});
