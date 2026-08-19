import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../domain/cart_totals.dart';
import '../../domain/entities/cart_item.dart';

/// Manages the list of [CartItem]s in the customer's cart.
///
/// Items are merged by [CartItem.configKey]: adding the same product
/// configuration again increments its quantity rather than appending a
/// duplicate entry.
class CartController extends StateNotifier<List<CartItem>> {
  CartController() : super(const []);

  /// The table ID set by QR scanning. Null means takeaway / no table.
  String? _tableId;

  /// The table ID currently linked to this cart session (set via QR scan).
  String? get activeTableId => _tableId;

  /// Links this cart session to a dine-in [tableId] (from QR scan).
  void setTableId(String tableId) => _tableId = tableId;

  /// Clears the linked table (e.g. on logout or new session).
  void clearTableId() => _tableId = null;

  /// Number of distinct line items.
  int get itemCount => state.length;

  /// Total count of physical units across all lines.
  int get unitCount => state.fold(0, (sum, item) => sum + item.quantity);

  /// Derived money figures for the current cart contents.
  CartTotals get totals => CartTotals.fromItems(state);

  /// Adds [item], merging with an existing same-configuration entry.
  ///
  /// Unavailable items (currently out of stock) are rejected so customers
  /// cannot add products the kitchen can no longer prepare.
  void addItem(CartItem item) {
    if (item.quantity <= 0 || item.menuItem.id.isEmpty) return;
    if (!item.menuItem.isAvailable) return;
    final index = state.indexWhere((e) => e.configKey == item.configKey);
    if (index == -1) {
      state = [...state, item];
    } else {
      final existing = state[index];
      final merged = existing.copyWith(
        quantity: existing.quantity + item.quantity,
      );
      state = [...state]..[index] = merged;
    }
  }

  /// Increases the quantity of the matching line item.
  void increment(String configKey) {
    _mutate(configKey, (item) => item.copyWith(quantity: item.quantity + 1));
  }

  /// Decreases the quantity of the matching line, removing it at zero.
  void decrement(String configKey) {
    final index = state.indexWhere((e) => e.configKey == configKey);
    if (index == -1) return;
    final existing = state[index];
    if (existing.quantity <= 1) {
      removeItem(configKey);
      return;
    }
    final updated = existing.copyWith(quantity: existing.quantity - 1);
    state = [...state]..[index] = updated;
  }

  /// Removes the line matching [configKey].
  void removeItem(String configKey) {
    state = state.where((e) => e.configKey != configKey).toList();
  }

  /// Empties the cart and clears the linked table.
  void clear() {
    state = const [];
    _tableId = null;
  }

  /// Returns the per-person amount when splitting the total evenly across
  /// [numPersons].
  double splitTotal(int numPersons) {
    if (numPersons <= 0) return totals.totalAmount;
    return totals.totalAmount / numPersons;
  }

  void _mutate(String configKey, CartItem Function(CartItem) transform) {
    final index = state.indexWhere((e) => e.configKey == configKey);
    if (index == -1) return;
    final updated = transform(state[index]);
    state = [...state]..[index] = updated;
  }
}

/// Provider for [CartController].
final cartControllerProvider =
    StateNotifierProvider<CartController, List<CartItem>>((ref) {
      return CartController();
    });

/// The payment method the customer has selected at checkout.
final selectedPaymentMethodProvider = StateProvider<PaymentMethod>(
  (ref) => PaymentMethod.cash,
);

/// The order type (dineIn, takeaway, delivery) selected by the customer.
final selectedOrderTypeProvider = StateProvider<OrderType>(
  (ref) => OrderType.dineIn,
);

/// Exposes the active table id from the cart controller (read-only).
final activeTableIdProvider = Provider<String?>(
  (ref) => ref.watch(cartControllerProvider.notifier).activeTableId,
);
