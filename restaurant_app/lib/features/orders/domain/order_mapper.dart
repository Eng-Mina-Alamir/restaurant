import '../../cart/domain/entities/cart_item.dart';
import '../../cart/domain/cart_totals.dart';
import '../../../core/domain/enums.dart';
import '../../../core/utils/financial_calculator.dart';
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
  ///
  /// [orderType] defaults to takeaway when null, preserving the historical
  /// behavior of this mapper. [deliveryAddress] / [deliveryNotes] only carry
  /// meaning for [OrderType.delivery] orders but are persisted whenever given.
  static OrderEntity buildForCustomer({
    required String orderId,
    required String restaurantId,
    required List<CartItem> cartItems,
    required DateTime createdAt,
    String? customerId,
    PaymentMethod? paymentMethod,
    double discountAmount = 0.0,
    OrderType? orderType,
    String? deliveryAddress,
    String? deliveryNotes,
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
      customerId: customerId,
      orderType: orderType ?? OrderType.takeaway,
      status: OrderStatus.pending,
      paymentMethod: paymentMethod,
      items: items,
      subtotal: totals.subtotal,
      taxAmount: totals.taxAmount,
      discountAmount: totals.discountAmount,
      totalAmount: totals.totalAmount,
      deliveryAddress: deliveryAddress,
      deliveryNotes: deliveryNotes,
      createdAt: createdAt,
      estimatedMinutes: 25,
    );
  }

  /// Builds a delivery [OrderEntity] destined to [deliveryAddress].
  ///
  /// Mirrors [buildForTable]: the order type is fixed to
  /// [OrderType.delivery], the address is mandatory, and the estimated
  /// preparation-plus-transit time is ~40 minutes.
  static OrderEntity buildForDelivery({
    required String orderId,
    required String restaurantId,
    required String deliveryAddress,
    required List<CartItem> cartItems,
    required DateTime createdAt,
    String? customerId,
    PaymentMethod? paymentMethod,
    double discountAmount = 0.0,
    String? deliveryNotes,
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
      customerId: customerId,
      orderType: OrderType.delivery,
      status: OrderStatus.pending,
      paymentMethod: paymentMethod,
      items: items,
      subtotal: totals.subtotal,
      taxAmount: totals.taxAmount,
      discountAmount: totals.discountAmount,
      totalAmount: totals.totalAmount,
      deliveryAddress: deliveryAddress,
      deliveryNotes: deliveryNotes,
      createdAt: createdAt,
      estimatedMinutes: 40,
    );
  }

  /// Builds a dine-in [OrderEntity] linked to a restaurant [tableId].
  static OrderEntity buildForTable({
    required String orderId,
    required String restaurantId,
    required String tableId,
    required List<CartItem> cartItems,
    required DateTime createdAt,
    String? customerId,
    String? waiterId,
    PaymentMethod? paymentMethod,
    double discountAmount = 0.0,
    String? deliveryNotes,
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
      customerId: customerId,
      tableId: tableId,
      waiterId: waiterId,
      orderType: OrderType.dineIn,
      status: OrderStatus.pending,
      paymentMethod: paymentMethod,
      items: items,
      subtotal: totals.subtotal,
      taxAmount: totals.taxAmount,
      discountAmount: totals.discountAmount,
      totalAmount: totals.totalAmount,
      deliveryNotes: deliveryNotes,
      createdAt: createdAt,
      estimatedMinutes: 20,
    );
  }

  /// Appends new [newCartItems] to an [existingOrder], recalculating financial totals.
  static OrderEntity appendItems({
    required OrderEntity existingOrder,
    required List<CartItem> newCartItems,
    required DateTime timestamp,
  }) {
    final newOrderItems = newCartItems
        .map((cart) => toOrderItem(cart, timestamp: timestamp))
        .toList();
    final combinedItems = [...existingOrder.items, ...newOrderItems];

    // Recompute financials from combined items
    final subtotal = combinedItems.fold<double>(
      0.0,
      (sum, item) => sum + item.itemTotal,
    );
    final discount = existingOrder.discountAmount;
    final taxable = FinancialCalculator.roundCurrency(
      (subtotal - discount).clamp(0.0, double.infinity),
    );
    final taxAmount = FinancialCalculator.calculateVat(taxable);
    final totalAmount = FinancialCalculator.roundCurrency(taxable + taxAmount);

    return existingOrder.copyWith(
      items: combinedItems,
      subtotal: subtotal,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
    );
  }
}
