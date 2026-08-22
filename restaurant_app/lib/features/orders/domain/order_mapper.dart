import '../../cart/domain/entities/cart_item.dart';
import '../../cart/domain/cart_totals.dart';
import '../../../core/domain/enums.dart';
import '../../../core/utils/logger.dart';
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
  /// [timestamp]. Quantity is defensively clamped to >= 1: `copyWith` can
  /// produce non-positive values that bypass controller guards, and a single
  /// bad line must not corrupt the order's money figures.
  static OrderItem toOrderItem(CartItem cart, {required DateTime timestamp}) {
    var quantity = cart.quantity;
    if (quantity < 1) {
      AppLogger.warning(
        'OrderMapper: clamping invalid cart quantity $quantity to 1 for '
        '${cart.menuItem.id}',
      );
      quantity = 1;
    }
    return OrderItem(
      menuItem: cart.menuItem,
      quantity: quantity,
      selectedModifiers: cart.selectedModifiers,
      specialNotes: cart.specialNotes,
      itemTotal: cart.linePrice,
      addedAt: timestamp,
    );
  }

  /// Builds an [OrderEntity] from the selected [cartItems].
  ///
  /// Money figures are taken from [CartTotals] so tax and discount are always
  /// consistent with what the cart UI displayed.
  static OrderEntity buildForCustomer({
    required String orderId,
    required String restaurantId,
    required List<CartItem> cartItems,
    required DateTime createdAt,
    PaymentMethod? paymentMethod,
    double discountAmount = 0.0,
  }) {
    final items = cartItems
        .map((cart) => toOrderItem(cart, timestamp: createdAt))
        .toList();
    final totals = CartTotals.fromItems(
      cartItems,
      discountAmount: discountAmount,
    );

    return OrderEntity(
      id: orderId,
      restaurantId: restaurantId,
      orderType: OrderType.takeaway,
      status: OrderStatus.pending,
      paymentMethod: paymentMethod,
      items: items,
      subtotal: totals.subtotal,
      taxAmount: totals.taxAmount,
      discountAmount: totals.discountAmount,
      totalAmount: totals.totalAmount,
      createdAt: createdAt,
      estimatedMinutes: 25,
    );
  }

  /// Builds a dine-in [OrderEntity] linked to a restaurant [tableId].
  static OrderEntity buildForTable({
    required String orderId,
    required String restaurantId,
    required String tableId,
    required List<CartItem> cartItems,
    required DateTime createdAt,
    PaymentMethod? paymentMethod,
    double discountAmount = 0.0,
  }) {
    final items = cartItems
        .map((cart) => toOrderItem(cart, timestamp: createdAt))
        .toList();
    final totals = CartTotals.fromItems(
      cartItems,
      discountAmount: discountAmount,
    );

    return OrderEntity(
      id: orderId,
      restaurantId: restaurantId,
      tableId: tableId,
      orderType: OrderType.dineIn,
      status: OrderStatus.pending,
      paymentMethod: paymentMethod,
      items: items,
      subtotal: totals.subtotal,
      taxAmount: totals.taxAmount,
      discountAmount: totals.discountAmount,
      totalAmount: totals.totalAmount,
      createdAt: createdAt,
      estimatedMinutes: 20,
    );
  }
}
