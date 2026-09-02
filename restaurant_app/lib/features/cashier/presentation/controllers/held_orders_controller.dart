import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../data/repositories/supabase_cashier_repository.dart';
import '../../domain/entities/held_order_entity.dart';
import '../../domain/services/held_order_service.dart';

/// Manages the queue of parked / held orders at the cashier terminal.
class HeldOrdersController extends StateNotifier<List<HeldOrderEntity>> {
  HeldOrdersController([this._repository]) : super(const []) {
    loadHeldOrders();
  }

  final SupabaseCashierRepository? _repository;

  Future<void> loadHeldOrders() async {
    if (_repository == null) return;
    final result = await _repository.getHeldOrders();
    result.when(
      onLeft: (_) {},
      onRight: (list) {
        if (mounted) state = list;
      },
    );
  }

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
    _repository?.saveHeldOrder(heldOrder);
    return heldOrder;
  }

  /// Recalls and removes a held order by [heldOrderId] to restore it into the active cart.
  HeldOrderEntity? recallOrder(String heldOrderId) {
    final match = state.where((h) => h.id == heldOrderId);
    if (match.isEmpty) return null;

    final heldOrder = match.first;
    state = state.where((h) => h.id != heldOrderId).toList();
    _repository?.deleteHeldOrder(heldOrderId);
    return heldOrder;
  }

  /// Discards / deletes a held order without restoring it.
  void discardHeldOrder(String heldOrderId) {
    state = state.where((h) => h.id != heldOrderId).toList();
    _repository?.deleteHeldOrder(heldOrderId);
  }

  /// Number of currently held orders.
  int get heldCount => state.length;
}

/// Riverpod provider for [HeldOrdersController].
final heldOrdersControllerProvider =
    StateNotifierProvider<HeldOrdersController, List<HeldOrderEntity>>((ref) {
      final repo = ref.watch(supabaseCashierRepositoryProvider);
      return HeldOrdersController(repo);
    });

