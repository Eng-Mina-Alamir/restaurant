import '../../../cart/domain/entities/cart_item.dart';
import '../entities/held_order_entity.dart';

/// Pure domain service managing parked / held orders queue.
abstract final class HeldOrderService {
  HeldOrderService._();

  /// Maximum number of orders allowed to be held concurrently.
  static const int kMaxHeldOrders = 15;

  /// Creates a new [HeldOrderEntity] from the given [cartItems].
  static HeldOrderEntity createHeldOrder({
    required List<CartItem> cartItems,
    String? customLabel,
    String? customerPhone,
    int? tableNumber,
    String? notes,
  }) {
    final timestamp = DateTime.now();
    final defaultLabel = tableNumber != null
        ? 'طاولة #$tableNumber'
        : 'زبون تيك أواي #${timestamp.millisecondsSinceEpoch.toString().substring(8)}';

    return HeldOrderEntity(
      id: 'HELD-${timestamp.millisecondsSinceEpoch}',
      label: (customLabel != null && customLabel.trim().isNotEmpty)
          ? customLabel.trim()
          : defaultLabel,
      items: List<CartItem>.from(cartItems),
      parkedAt: timestamp,
      customerPhone: customerPhone,
      tableNumber: tableNumber,
      notes: notes,
    );
  }

  /// Calculates the total value of all currently held orders.
  static double totalHeldValue(List<HeldOrderEntity> heldOrders) {
    return heldOrders.fold<double>(0.0, (acc, ho) => acc + ho.totalAmount);
  }
}
