import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/domain/entities/cart_item.dart';
import '../../domain/entities/held_order_entity.dart';
import '../../domain/services/held_order_service.dart';

/// Manages the in-memory queue of parked / held orders at the cashier terminal.
class HeldOrdersController extends StateNotifier<List<HeldOrderEntity>> {
  HeldOrdersController() : super(const []);

  /// Parks the current [cartItems] in the held orders queue.
  HeldOrderEntity? holdOrder({
    required List<CartItem> cartItems,
    String? customLabel,
    String? customerPhone,
    int? tableNumber,
    String? notes,
  }) {
    if (cartItems.isEmpty) return null;
    if (state.length >= HeldOrderService.kMaxHeldOrders) return null;

    final heldOrder = HeldOrderService.createHeldOrder(
      cartItems: cartItems,
      customLabel: customLabel,
      customerPhone: customerPhone,
      tableNumber: tableNumber,
      notes: notes,
    );

    state = [heldOrder, ...state];
    return heldOrder;
  }

  /// Recalls and removes a held order by [heldOrderId] to restore it into the active cart.
  HeldOrderEntity? recallOrder(String heldOrderId) {
    final match = state.where((h) => h.id == heldOrderId);
    if (match.isEmpty) return null;

    final heldOrder = match.first;
    state = state.where((h) => h.id != heldOrderId).toList();
    return heldOrder;
  }

  /// Discards / deletes a held order without restoring it.
  void discardHeldOrder(String heldOrderId) {
    state = state.where((h) => h.id != heldOrderId).toList();
  }

  /// Number of currently held orders.
  int get heldCount => state.length;
}

/// Riverpod provider for [HeldOrdersController].
final heldOrdersControllerProvider =
    StateNotifierProvider<HeldOrdersController, List<HeldOrderEntity>>((ref) {
      return HeldOrdersController();
    });
