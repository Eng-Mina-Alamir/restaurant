import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repositories/delivery_pin_repository.dart';
import '../../domain/services/delivery_pin_service.dart';
import '../../domain/services/driver_quick_action_service.dart';

/// Supabase-backed [DeliveryPinRepository] using the
/// `delivery_verification_codes` table (see migration
/// `delivery_verification_codes.sql`).
///
/// Resilience: when the table does not exist yet (migration not applied —
/// Postgrest `42P01`), every method falls back to the legacy deterministic
/// PIN so existing builds keep working instead of crashing. The fallback is
/// logged as a warning so the missing migration is visible in logs.
class SupabaseDeliveryPinRepository implements DeliveryPinRepository {
  SupabaseDeliveryPinRepository({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  static const Duration _codeTtl = Duration(hours: 12);

  bool _isMissingTable(Object e) =>
      e.toString().contains('42P01') ||
      e.toString().contains('delivery_verification_codes') &&
          (e.toString().contains('does not exist') ||
              e.toString().contains('Could not find the table'));

  // ignore: deprecated_member_use_from_same_package
  String _legacyFallback(String orderId) =>
      DriverQuickActionService.getOrderDeliveryPin(orderId);

  @override
  Future<Either<Failure, String>> ensurePin(String orderId) async {
    try {
      final existing = await _supabase
          .from(SupabaseConfig.deliveryVerificationCodesTable)
          .select('code, expires_at, used_at')
          .eq('order_id', orderId)
          .limit(1);
      final rows = existing as List;
      if (rows.isNotEmpty) {
        final row = Map<String, dynamic>.from(rows.first as Map);
        final usedAt = row['used_at'];
        final expiresAt = row['expires_at'] != null
            ? DateTime.tryParse(row['expires_at'].toString())
            : null;
        final code = row['code']?.toString();
        final fresh =
            code != null &&
            code.isNotEmpty &&
            usedAt == null &&
            (expiresAt == null || expiresAt.isAfter(DateTime.now()));
        if (fresh) return Right<Failure, String>(code);
        // Consumed/expired → mint a FRESH code below (rotation).
      }

      final now = DateTime.now();
      final pin = DeliveryPinService.generatePin();
      await _supabase
          .from(SupabaseConfig.deliveryVerificationCodesTable)
          .upsert({
            'order_id': orderId,
            'code': pin,
            'created_at': now.toIso8601String(),
            'expires_at': now.add(_codeTtl).toIso8601String(),
            'used_at': null,
            'attempts': 0,
          }, onConflict: 'order_id');
      return Right<Failure, String>(pin);
    } catch (e) {
      if (_isMissingTable(e)) {
        AppLogger.warning(
          'delivery_verification_codes table missing — using legacy PIN '
          'fallback for $orderId. Apply the migration.',
        );
        // ignore: deprecated_member_use_from_same_package
        return Right<Failure, String>(_legacyFallback(orderId));
      }
      AppLogger.error('Supabase ensurePin error: $e (orderId=$orderId)');
      return Left<Failure, String>(
        ServerFailure('فشل تجهيز كود الاستلام: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, String?>> getPin(String orderId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.deliveryVerificationCodesTable)
          .select('code, expires_at, used_at')
          .eq('order_id', orderId)
          .limit(1);
      final rows = response as List;
      if (rows.isEmpty) return const Right<Failure, String?>(null);
      final row = Map<String, dynamic>.from(rows.first as Map);
      if (row['used_at'] != null) return const Right<Failure, String?>(null);
      final expiresAt = row['expires_at'] != null
          ? DateTime.tryParse(row['expires_at'].toString())
          : null;
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        return const Right<Failure, String?>(null);
      }
      return Right<Failure, String?>(row['code']?.toString());
    } catch (e) {
      if (_isMissingTable(e)) {
        // ignore: deprecated_member_use_from_same_package
        return Right<Failure, String?>(_legacyFallback(orderId));
      }
      AppLogger.error('Supabase getPin error: $e (orderId=$orderId)');
      return Left<Failure, String?>(
        ServerFailure('فشل جلب كود الاستلام: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPin(String orderId, String code) async {
    final normalized = DeliveryPinService.extractCode(code);
    if (!DeliveryPinService.isValidFormat(normalized)) {
      return const Right<Failure, bool>(false);
    }
    try {
      final response = await _supabase
          .from(SupabaseConfig.deliveryVerificationCodesTable)
          .select('code, expires_at, used_at')
          .eq('order_id', orderId)
          .limit(1);
      final rows = response as List;
      if (rows.isEmpty) return const Right<Failure, bool>(false);
      final row = Map<String, dynamic>.from(rows.first as Map);
      if (row['used_at'] != null) return const Right<Failure, bool>(false);
      final expiresAt = row['expires_at'] != null
          ? DateTime.tryParse(row['expires_at'].toString())
          : null;
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        return const Right<Failure, bool>(false);
      }
      final matches = row['code']?.toString() == normalized;
      if (!matches) {
        try {
          final current = await _supabase
              .from(SupabaseConfig.deliveryVerificationCodesTable)
              .select('attempts')
              .eq('order_id', orderId)
              .limit(1);
          final attemptRows = current as List;
          final prev = attemptRows.isEmpty
              ? 0
              : ((attemptRows.first as Map)['attempts'] as num?)?.toInt() ?? 0;
          await _supabase
              .from(SupabaseConfig.deliveryVerificationCodesTable)
              .update({'attempts': prev + 1})
              .eq('order_id', orderId);
        } catch (_) {}
      }
      return Right<Failure, bool>(matches);
    } catch (e) {
      if (_isMissingTable(e)) {
        // ignore: deprecated_member_use_from_same_package
        return Right<Failure, bool>(
          // ignore: deprecated_member_use_from_same_package
          _legacyFallback(orderId) == normalized,
        );
      }
      AppLogger.error('Supabase verifyPin error: $e (orderId=$orderId)');
      return Left<Failure, bool>(ServerFailure('فشل التحقق من الكود: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> invalidatePin(String orderId) async {
    try {
      await _supabase
          .from(SupabaseConfig.deliveryVerificationCodesTable)
          .update({'used_at': DateTime.now().toIso8601String()})
          .eq('order_id', orderId);
      return const Right<Failure, void>(null);
    } catch (e) {
      if (_isMissingTable(e)) return const Right<Failure, void>(null);
      AppLogger.error('Supabase invalidatePin error: $e (orderId=$orderId)');
      return Left<Failure, void>(ServerFailure('فشل إبطال الكود: $e'));
    }
  }
}
