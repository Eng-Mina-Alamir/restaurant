import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';

/// Server-backed store for per-order random delivery verification codes.
///
/// Contract:
/// - [ensurePin] creates a fresh random code for [orderId] on first call and
///   returns the EXISTING code on later calls (stable per order, random
///   across orders). Used by the customer tracking page.
/// - [verifyPin] returns true only when [code] matches the stored code for
///   [orderId] and the code has not been consumed/expired. Used by the
///   driver's proof-of-delivery dialog.
/// - [invalidatePin] consumes the code after a successful handover so a
///   replayed QR cannot complete a second delivery.
abstract class DeliveryPinRepository {
  Future<Either<Failure, String>> ensurePin(String orderId);
  Future<Either<Failure, String?>> getPin(String orderId);
  Future<Either<Failure, bool>> verifyPin(String orderId, String code);
  Future<Either<Failure, void>> invalidatePin(String orderId);
}
