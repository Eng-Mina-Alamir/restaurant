import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/delivery_pin_repository.dart';
import '../../domain/services/delivery_pin_service.dart';

/// In-memory [DeliveryPinRepository] for offline/demo/tests.
///
/// Mirrors the Supabase semantics: one stable random code per order until
/// [invalidatePin] consumes it, after which the next [ensurePin] mints a
/// FRESH code (rotation — never reuses the old one).
class InMemoryDeliveryPinRepository implements DeliveryPinRepository {
  InMemoryDeliveryPinRepository({Map<String, String>? seed})
    : _pins = Map<String, String>.from(seed ?? const {});

  final Map<String, String> _pins;
  final Set<String> _consumed = <String>{};

  @override
  Future<Either<Failure, String>> ensurePin(String orderId) async {
    final existing = _pins[orderId];
    if (existing != null && !_consumed.contains(orderId)) {
      return Right<Failure, String>(existing);
    }
    final fresh = DeliveryPinService.generatePin();
    _pins[orderId] = fresh;
    _consumed.remove(orderId);
    return Right<Failure, String>(fresh);
  }

  @override
  Future<Either<Failure, String?>> getPin(String orderId) async {
    if (_consumed.contains(orderId)) {
      return const Right<Failure, String?>(null);
    }
    return Right<Failure, String?>(_pins[orderId]);
  }

  @override
  Future<Either<Failure, bool>> verifyPin(String orderId, String code) async {
    final normalized = DeliveryPinService.extractCode(code);
    if (!DeliveryPinService.isValidFormat(normalized)) {
      return const Right<Failure, bool>(false);
    }
    final stored = _pins[orderId];
    if (stored == null || _consumed.contains(orderId)) {
      return const Right<Failure, bool>(false);
    }
    return Right<Failure, bool>(stored == normalized);
  }

  @override
  Future<Either<Failure, void>> invalidatePin(String orderId) async {
    _consumed.add(orderId);
    return const Right<Failure, void>(null);
  }
}
