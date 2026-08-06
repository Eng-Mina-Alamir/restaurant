import '../../cart/domain/entities/cart_item.dart';
import '../../cart/domain/cart_totals.dart';
import '../../../core/domain/enums.dart';
import 'entities/order_entity.dart';
import 'entities/order_item.dart';

/// Builds [OrderEntity] instances from the customer's cart contents.
///
/// Kept as a pure function collection so both the data layer and presentation
/// layer can construct an order without coupling to a specific controller.
abstract final class OrderMapper {
  OrderMapper._();

  /// Converts a [CartItem] into a ready-to-persist [OrderItem].
  ///
  /// Applies [index] to keep a deterministic ordering and stamps the line with
  /// [timestamp].
  static OrderItem toOrderItem(CartItem cart, {required DateTime timestamp}) {
    return OrderItem(
      menuItem: cart.menuItem,
      quantity: cart.quantity,
      selectedModifiers: cart.selectedModifiers,
      specialNotes: cart.specialNotes,
      itemTotal: cart.linePrice,
      addedAt: timestamp,
    );
  }

  /// Builds an [OrderEntity] from the selected [cartItems].
  ///
  /// Money figures are taken from [CartTotals] so tax (and any future
  /// discount) is consistent with what the cart UI displayed.
  static OrderEntity buildForCustomer({
    required String orderId,
    required String restaurantId,
    required List<CartItem> cartItems,
    required DateTime createdAt,
  }) {
    final items = cartItems
        .map((cart) => toOrderItem(cart, timestamp: createdAt))
        .toList();
    final totals = CartTotals.fromItems(cartItems);

    return OrderEntity(
      id: orderId,
      restaurantId: restaurantId,
      orderType: OrderType.takeaway,
      status: OrderStatus.pending,
      items: items,
      subtotal: totals.subtotal,
      taxAmount: totals.taxAmount,
      totalAmount: totals.totalAmount,
      createdAt: createdAt,
      estimatedMinutes: 25,
    );
  }
}
