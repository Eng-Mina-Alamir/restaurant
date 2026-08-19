import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../coupons/domain/entities/coupon_entity.dart';
import '../../../coupons/presentation/controllers/coupon_controller.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../presentation/controllers/cart_controller.dart';
import '../../domain/cart_totals.dart';
import '../../domain/entities/cart_item.dart';
import '../widgets/split_bill_sheet.dart';

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

  void _emptyCartBrowse() => context.go('/customer');

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider);
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final rawSubtotal =
        cart.fold<double>(0, (sum, item) => sum + item.linePrice);
    final discountAmount = appliedCoupon != null
        ? appliedCoupon.calculateDiscount(rawSubtotal)
        : 0.0;
    final totals = CartTotals.fromItems(cart, discountAmount: discountAmount);


    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.cartTitle),
        actions: [
          if (cart.isNotEmpty)
            IconButton(
              tooltip: 'تقسيم الفاتورة',
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: () => showSplitBillSheet(context),
            ),
          if (cart.isNotEmpty)
            IconButton(
              tooltip: AppConstants.clearCart,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () {
                ref.read(cartControllerProvider.notifier).clear();
                ref.read(appliedCouponProvider.notifier).remove();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppConstants.cartCleared)),
                );
              },
            ),
        ],
      ),
      body: cart.isEmpty
          ? EmptyState(
              message: AppConstants.cartEmpty,
              icon: Icons.shopping_cart_outlined,
              actionLabel: AppConstants.cartEmptyBrowse,
              onAction: _emptyCartBrowse,
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
                  discountAmount: totals.discountAmount,
                  appliedCoupon: appliedCoupon,
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

class _TotalsFooter extends ConsumerStatefulWidget {
  const _TotalsFooter({
    required this.subtotal,
    required this.discountAmount,
    required this.appliedCoupon,
    required this.taxAmount,
    required this.totalAmount,
    required this.placing,
    required this.paymentMethod,
    required this.onPaymentChanged,
    required this.onCheckout,
  });

  final double subtotal;
  final double discountAmount;
  final CouponEntity? appliedCoupon;
  final double taxAmount;
  final double totalAmount;
  final bool placing;
  final PaymentMethod paymentMethod;
  final ValueChanged<PaymentMethod> onPaymentChanged;
  final VoidCallback onCheckout;

  @override
  ConsumerState<_TotalsFooter> createState() => _TotalsFooterState();
}

class _TotalsFooterState extends ConsumerState<_TotalsFooter> {
  final _couponController = TextEditingController();
  bool _validating = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => _validating = true);
    final repo = ref.read(couponRepositoryProvider);
    final result = await repo.validateAndGetCoupon(code, widget.subtotal);
    if (!mounted) return;
    setState(() => _validating = false);

    result.when(
      onLeft: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
      onRight: (coupon) {
        ref.read(appliedCouponProvider.notifier).apply(coupon);
        _couponController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 تم تطبيق كود الخصم "${coupon.code}" بنجاح!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(


      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Coupon / Promo Code Input ──
            if (widget.appliedCoupon == null)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'أدخل كود الخصم (مثال: WELCOME50)',
                        prefixIcon: const Icon(Icons.local_offer_outlined),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.tonal(
                    onPressed: _validating ? null : _applyCoupon,
                    child: _validating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('تطبيق'),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'كوبون: ${widget.appliedCoupon!.code} (${widget.appliedCoupon!.title})',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                      tooltip: 'إلغاء الكوبون',
                      onPressed: () {
                        ref.read(appliedCouponProvider.notifier).remove();
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.md),
            _PaymentSelector(
              paymentMethod: widget.paymentMethod,
              onChanged: widget.onPaymentChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            _Row(
              label: AppConstants.subtotalLabel,
              value: Formatters.formatCurrency(widget.subtotal),
            ),
            if (widget.discountAmount > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              _Row(
                label: 'خصم الكوبون',
                value: '- ${Formatters.formatCurrency(widget.discountAmount)}',
                valueColor: Colors.green,
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            _Row(
              label: AppConstants.taxLabel,
              value: Formatters.formatCurrency(widget.taxAmount),
            ),
            const Divider(height: AppSpacing.lg),
            _Row(
              label: AppConstants.orderTotalLabel,
              value: Formatters.formatCurrency(widget.totalAmount),
              emphasized: true,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: widget.placing ? null : widget.onCheckout,
              child: widget.placing
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
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

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
                  color: valueColor ?? theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: valueColor != null ? FontWeight.bold : null,
                ),
        ),
      ],
    );
  }
}

