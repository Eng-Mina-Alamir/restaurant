import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../customer/presentation/pages/menu_item_detail_sheet.dart';
import '../../../customer/presentation/widgets/menu_item_tile.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/presentation/controllers/menu_controller.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../controllers/table_controller.dart';

/// Waiter order intake: pick items from the menu, review cart, and send the
/// order to the kitchen for a specific table.
class WaiterOrderPage extends ConsumerStatefulWidget {
  const WaiterOrderPage({super.key, required this.tableId});

  final String tableId;

  @override
  ConsumerState<WaiterOrderPage> createState() => _WaiterOrderPageState();
}

class _WaiterOrderPageState extends ConsumerState<WaiterOrderPage> {
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Reset the shared cart so the waiter builds a fresh order for this table.
    Future.microtask(() => ref.read(cartControllerProvider.notifier).clear());
  }

  void _addItem(MenuItem item) {
    if (item.modifierGroups.isEmpty) {
      ref
          .read(cartControllerProvider.notifier)
          .addItem(CartItem(menuItem: item, quantity: 1));
      return;
    }
    MenuItemDetailSheet.show(context, item);
  }

  Future<void> _sendToKitchen() async {
    if (_sending) return;
    setState(() => _sending = true);

    final orders = ref.read(ordersControllerProvider.notifier);
    final order = await orders.placeOrderForTable(widget.tableId);
    if (order != null) {
      await ref
          .read(tableControllerProvider.notifier)
          .occupy(widget.tableId, orderId: order.id);
      // KDS picks up new orders automatically; return to the floor.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('#${order.id} ${AppConstants.sentToKitchen}')),
      );
      context.go('/waiter');
    } else {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.errorCartEmpty)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(menuControllerProvider);
    final cart = ref.watch(cartControllerProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final table = ref
        .watch(tableControllerProvider)
        .where((t) => t.id == widget.tableId);
    final tableLabel = table.isEmpty ? '' : '${table.first.tableNumber}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppConstants.tableActionTakeOrder} — '
          '${AppConstants.seats} $tableLabel',
        ),
      ),
      body: menu.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final items = filterMenu(data, selectedCategory);
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: MenuItemTile(
                        item: item,
                        onTap: () => _addItem(item),
                        onAdd: () => _addItem(item),
                      ),
                    );
                  },
                ),
              ),
              _BottomBar(
                itemCount: cart.length,
                sending: _sending,
                onSend: _sendToKitchen,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.itemCount,
    required this.sending,
    required this.onSend,
  });

  final int itemCount;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: sending ? null : onSend,
          child: sending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  '$itemCount ${AppConstants.itemCountLabel} — '
                  '${AppConstants.sendToKitchen}',
                ),
        ),
      ),
    );
  }
}
