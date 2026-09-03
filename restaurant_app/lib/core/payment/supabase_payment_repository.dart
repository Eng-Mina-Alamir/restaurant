import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/supabase_config.dart';
import '../../../core/domain/enums.dart';
import '../../../core/errors/either.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/logger.dart';

/// Supabase-backed persistence for payment transactions.
///
/// Bridges the gap between the in-memory [PaymentService] and the `payments`
/// table in Supabase — every successful payment/refund is written as a row
/// so the manager dashboard, receipts, and reconciliation have durable records.
class SupabasePaymentRepository {
  SupabasePaymentRepository({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  /// Persists a successful payment transaction.
  Future<Either<Failure, void>> recordPayment({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    required String transactionRef,
    required DateTime paidAt,
  }) async {
    try {
      final numericOrderId = int.tryParse(orderId);
      final existing = await _supabase
          .from(SupabaseConfig.paymentsTable)
          .select('id')
          .eq('transaction_ref', transactionRef)
          .limit(1);

      if ((existing as List).isNotEmpty) {
        await _supabase
            .from(SupabaseConfig.paymentsTable)
            .update({
              'order_id': ?numericOrderId,
              'payment_method': method.name,
              'amount': amount,
              'status': 'completed',
              'paid_at': paidAt.toIso8601String(),
            })
            .eq('transaction_ref', transactionRef);
      } else {
        await _supabase.from(SupabaseConfig.paymentsTable).insert({
          'order_id': ?numericOrderId,
          'payment_method': method.name,
          'amount': amount,
          'status': 'completed',
          'transaction_ref': transactionRef,
          'paid_at': paidAt.toIso8601String(),
        });
      }
      return const Right<Failure, void>(null);
    } catch (e) {
      AppLogger.error('SupabasePaymentRepository.recordPayment error: $e');
      return Left<Failure, void>(
        ServerFailure('فشل تسجيل الدفع في السيرفر: $e'),
      );
    }
  }

  /// Persists a refund against an existing payment.
  Future<Either<Failure, void>> recordRefund({
    required String originalTransactionRef,
    required double refundAmount,
    required String refundId,
    String? reason,
  }) async {
    try {
      await _supabase
          .from(SupabaseConfig.paymentsTable)
          .update({
            'refund_amount': refundAmount,
            'refund_reason': reason,
            'status': 'refunded',
          })
          .eq('transaction_ref', originalTransactionRef);
      return const Right<Failure, void>(null);
    } catch (e) {
      AppLogger.error('SupabasePaymentRepository.recordRefund error: $e');
      return Left<Failure, void>(
        ServerFailure('فشل تسجيل الاسترداد: $e'),
      );
    }
  }

  /// Checks if a payment already exists for [orderId] to prevent double-payment.
  Future<bool> hasCompletedPayment(String orderId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.paymentsTable)
          .select('id')
          .eq('order_id', orderId)
          .eq('status', 'completed')
          .limit(1);
      return (response as List).isNotEmpty;
    } catch (e) {
      AppLogger.warning(
        'SupabasePaymentRepository.hasCompletedPayment error: $e',
      );
      return false;
    }
  }
}
