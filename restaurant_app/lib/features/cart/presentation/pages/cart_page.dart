import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../presentation/controllers/cart_controller.dart';
import '../../domain/cart_totals.dart';
import '../../domain/entities/cart_item.dart';

/// Shows the cart contents with quantity controls and a totals footer.
class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _placing = false;

  Future<void> _checkout(BuildContext context) async {
    if (_placing) return;
    final payment = ref.read(selectedPaymentMethodProvider);
    setState(() => _placing = true);
    final order = await ref
        .read(ordersControllerProvider.notifier)
        .placeOrder(paymentMethod: payment);
    if (!context.mounted) return;
    setState(() => _placing = false);
    if (order != null) {
      context.push('/customer/order-confirmation', extra: order);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final totals = ref.watch(
      cartControllerProvider.select((items) => _totalsOf(items)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.cartTitle)),
      body: cart.isEmpty
          ? const EmptyState(
              message: AppConstants.cartEmpty,
              icon: Icons.shopping_cart_outlined,
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return _CartLine(
                        item: item,
                        onIncrement: () => ref
                            .read(cartControllerProvider.notifier)
                            .increment(item.configKey),
                        onDecrement: () => ref
                            .read(cartControllerProvider.notifier)
                            .decrement(item.configKey),
                        onRemove: () => ref
                            .read(cartControllerProvider.notifier)
                            .removeItem(item.configKey),
                      );
                    },
                  ),
                ),
                _TotalsFooter(
                  subtotal: totals.subtotal,
                  taxAmount: totals.taxAmount,
                  totalAmount: totals.totalAmount,
                  placing: _placing,
                  paymentMethod: ref.watch(selectedPaymentMethodProvider),
                  onPaymentChanged: (m) =>
                      ref.read(selectedPaymentMethodProvider.notifier).state =
                          m,
                  onCheckout: () => _checkout(context),
                ),
              ],
            ),
    );
  }

  static _TotalsData _totalsOf(List<CartItem> items) {
    final totals = CartTotals.fromItems(items);
    return _TotalsData(
      subtotal: totals.subtotal,
      taxAmount: totals.taxAmount,
      totalAmount: totals.totalAmount,
    );
  }
}

class _TotalsData {
  const _TotalsData({
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
  });

  final double subtotal;
  final double taxAmount;
  final double totalAmount;
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modifiers = item.selectedModifiers.map((m) => m.name).join('، ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.menuItem.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (modifiers.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      modifiers,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (item.specialNotes?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${AppConstants.specialNotesLabel}: ${item.specialNotes}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Formatters.formatCurrency(item.linePrice),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.outlined(
                  icon: const Icon(Icons.remove),
                  onPressed: onDecrement,
                ),
                Text('${item.quantity}'),
                IconButton.outlined(
                  icon: const Icon(Icons.add),
                  onPressed: onIncrement,
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: AppConstants.delete,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsFooter extends StatelessWidget {
  const _TotalsFooter({
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.placing,
    required this.paymentMethod,
    required this.onPaymentChanged,
    required this.onCheckout,
  });

  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final bool placing;
  final PaymentMethod paymentMethod;
  final ValueChanged<PaymentMethod> onPaymentChanged;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PaymentSelector(
              paymentMethod: paymentMethod,
              onChanged: onPaymentChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            _Row(
              label: AppConstants.totalLabel,
              value: Formatters.formatCurrency(subtotal),
            ),
            const SizedBox(height: AppSpacing.xs),
            _Row(
              label: AppConstants.taxLabel,
              value: Formatters.formatCurrency(taxAmount),
            ),
            const Divider(height: AppSpacing.lg),
            _Row(
              label: AppConstants.orderTotalLabel,
              value: Formatters.formatCurrency(totalAmount),
              emphasized: true,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              // 30s guard so the trailing async _checkout can complete
              // without leaving the button disabled.
              onPressed: placing ? null : onCheckout,
              child: placing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppConstants.checkout),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSelector extends StatelessWidget {
  const _PaymentSelector({
    required this.paymentMethod,
    required this.onChanged,
  });

  final PaymentMethod paymentMethod;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: emphasized
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )
              : theme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: emphasized
              ? theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                )
              : theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
