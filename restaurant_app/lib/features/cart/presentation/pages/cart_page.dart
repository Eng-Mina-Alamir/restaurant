import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/spacing.dart';
import '../../presentation/controllers/cart_controller.dart';
import '../../domain/cart_totals.dart';
import '../../domain/entities/cart_item.dart';

/// Shows the cart contents with quantity controls and a totals footer.
class CartPage extends ConsumerWidget {
  const CartPage({super.key, this.onCheckout});

  /// Called when the user taps "إتمام الطلب". When `null`, a placeholder
  /// snackbar is shown.
  final void Function(BuildContext context)? onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final totals = ref.watch(
      cartControllerProvider.select((items) => _totalsOf(items)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.cartTitle)),
      body: cart.isEmpty
          ? const Center(child: Text(AppConstants.cartEmpty))
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
                  onCheckout: () {
                    final handler = onCheckout;
                    if (handler != null) {
                      handler(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('إتمام الطلب قريباً')),
                      );
                    }
                  },
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
    required this.onCheckout,
  });

  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Row(
              label: AppConstants.totalLabel,
              value: Formatters.formatCurrency(subtotal),
            ),
            const SizedBox(height: AppSpacing.xs),
            _Row(
              label: 'الضريبة (15%)',
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
              onPressed: onCheckout,
              child: const Text(AppConstants.checkout),
            ),
          ],
        ),
      ),
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
