import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../cart/domain/cart_totals.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Reset the shared cart so the waiter builds a fresh order for this table.
    Future.microtask(() => ref.read(cartControllerProvider.notifier).clear());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final payment = ref.read(selectedPaymentMethodProvider);
    setState(() => _sending = true);

    final orders = ref.read(ordersControllerProvider.notifier);
    final tables = ref.read(tableControllerProvider);
    final tableList = tables.where((t) => t.id == widget.tableId);
    final matchingTable = tableList.isEmpty ? null : tableList.first;
    final isAppending = matchingTable?.status == TableStatus.occupied &&
        matchingTable?.currentOrderId != null;

    if (isAppending) {
      final cartItems = List<CartItem>.of(ref.read(cartControllerProvider));
      final updated = await orders.addItemsToExistingOrder(
        matchingTable!.currentOrderId!,
        cartItems,
      );
      if (updated != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إرسال الأصناف الإضافية للمطبخ لطاولة ${matchingTable.tableNumber}!',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/waiter');
      } else {
        if (!mounted) return;
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.errorCartEmpty)),
        );
      }
    } else {
      final order = await orders.placeOrderForTable(
        widget.tableId,
        paymentMethod: payment,
      );
      if (order != null) {
        await ref
            .read(tableControllerProvider.notifier)
            .occupy(widget.tableId, orderId: order.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${Formatters.formatOrderId(order.id)} '
              '${AppConstants.sentToKitchen}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
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
  }

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(menuControllerProvider);
    final cart = ref.watch(cartControllerProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final table = ref
        .watch(tableControllerProvider)
        .where((t) => t.id == widget.tableId);
    final matchingTable = table.isEmpty ? null : table.first;
    final tableLabel = matchingTable == null ? '' : '${matchingTable.tableNumber}';
    final isAppending = matchingTable?.status == TableStatus.occupied &&
        matchingTable?.currentOrderId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAppending
              ? 'إضافة أصناف — طاولة $tableLabel'
              : '${AppConstants.tableActionTakeOrder} — '
                  '${AppConstants.seats} $tableLabel',
        ),
      ),
      body: menu.when(
        loading: () => const _MenuSkeleton(),
        error: (e, _) => ErrorState(
          message: AppConstants.errorLoadingData,
          errorDetail: e,
          onRetry: () => ref.refresh(menuControllerProvider),
        ),
        data: (data) {
          final items = filterMenu(data, selectedCategory, _query);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: AppConstants.searchMenuHint,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(
                        message: AppConstants.noItemsFound,
                        icon: Icons.search_off,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
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
                unitCount: cart.fold(0, (s, i) => s + i.quantity),
                totalAmount: CartTotals.fromItems(cart).totalAmount,
                sending: _sending,
                paymentMethod: ref.watch(selectedPaymentMethodProvider),
                onPaymentChanged: (m) =>
                    ref.read(selectedPaymentMethodProvider.notifier).state = m,
                onSend: _sendToKitchen,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Shimmer placeholder list mirroring the menu item tiles while they load.
class _MenuSkeleton extends StatelessWidget {
  const _MenuSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 6,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: SkeletonBox(
          width: double.infinity,
          height: 90,
          borderRadius: AppRadius.md,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.itemCount,
    required this.unitCount,
    required this.totalAmount,
    required this.sending,
    required this.paymentMethod,
    required this.onPaymentChanged,
    required this.onSend,
  });

  final int itemCount;
  final int unitCount;
  final double totalAmount;
  final bool sending;
  final PaymentMethod paymentMethod;
  final ValueChanged<PaymentMethod> onPaymentChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final disabled = itemCount == 0 || sending;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  AppConstants.paymentMethodLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                SegmentedButton<PaymentMethod>(
                  segments: const [
                    ButtonSegment(
                      value: PaymentMethod.cash,
                      icon: Icon(Icons.payments_outlined),
                      label: Text(AppConstants.paymentCash),
                    ),
                    ButtonSegment(
                      value: PaymentMethod.card,
                      icon: Icon(Icons.credit_card),
                      label: Text(AppConstants.paymentCard),
                    ),
                  ],
                  selected: {paymentMethod},
                  onSelectionChanged: (selection) =>
                      onPaymentChanged(selection.first),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: disabled ? null : onSend,
              child: sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      itemCount == 0
                          ? AppConstants.cartEmptySend
                          : '$unitCount ${AppConstants.itemCountLabel} — '
                                '${AppConstants.sendToKitchen} • '
                                '${Formatters.formatCurrency(totalAmount)}',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
