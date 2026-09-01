import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/printing/ticket_printer_service.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../domain/entities/restaurant_table.dart';
import '../controllers/table_controller.dart';
import '../widgets/course_fire_action_bar.dart';
import '../widgets/split_bill_dialog.dart';
import '../widgets/table_transfer_dialog.dart';
import 'waiter_dashboard_page.dart';

/// Waiter table detail: shows table info, the linked active order (if any)
/// and floor actions (take order, reserve, clean/release).
class TableDetailPage extends ConsumerWidget {
  const TableDetailPage({super.key, required this.tableId});

  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tableControllerProvider);
    RestaurantTable? table;
    for (final t in tables) {
      if (t.id == tableId) table = t;
    }
    if (table == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppConstants.tableDetailTitle)),
        body: const EmptyState(
          message: AppConstants.tableNoOrder,
          icon: Icons.table_restaurant_outlined,
        ),
      );
    }
    final currentTable = table;

    OrderEntity? activeOrder;
    if (currentTable.currentOrderId != null) {
      for (final o in ref.watch(ordersControllerProvider)) {
        if (o.id == currentTable.currentOrderId) activeOrder = o;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppConstants.tableDetailTitle} — '
          '${AppConstants.seats} ${currentTable.tableNumber}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _TableInfoRow(table: currentTable),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppConstants.tableActiveOrder,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (activeOrder == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(AppConstants.tableNoOrder),
              ),
            )
          else
            _ActiveOrderCard(order: activeOrder),
          const SizedBox(height: AppSpacing.lg),
          if (currentTable.status == TableStatus.occupied && activeOrder != null) ...[
            // Course Fire Action Bar
            CourseFireActionBar(
              tableId: tableId,
              tableNumber: currentTable.tableNumber,
              orderId: activeOrder.id,
            ),
            const SizedBox(height: AppSpacing.sm),

            FilledButton.icon(
              onPressed: () => context.push('/waiter/order/$tableId'),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('إضافة أصناف إضافية للطلب'),
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final order = activeOrder;
                      if (order == null) return;
                      final splitResult = await SplitBillDialog.show(
                        context,
                        order: order,
                        tableNumber: currentTable.tableNumber,
                      );
                      if (splitResult != null && splitResult.isFullySettled) {
                        await ref
                            .read(ordersControllerProvider.notifier)
                            .updateStatus(order.id, OrderStatus.completed);
                        await ref
                            .read(tableControllerProvider.notifier)
                            .release(tableId, needsCleaning: true);
                        if (context.mounted) {
                          context.pop();
                        }
                      }
                    },
                    icon: const Icon(Icons.call_split_rounded, color: Color(0xFF3B82F6)),
                    label: const Text('تقسيم الشيك (Split Bill)'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final order = activeOrder;
                      if (order == null) return;
                      TableTransferDialog.show(
                        context,
                        currentTable: currentTable,
                        activeOrderId: order.id,
                      );
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF10B981)),
                    label: const Text('نقل / دمج الطاولة'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            FilledButton.tonalIcon(
              onPressed: () => _showCheckoutDialog(
                context,
                ref,
                currentTable,
                activeOrder!,
              ),
              icon: const Icon(Icons.point_of_sale),
              label: const Text('محاسبة وإخلاء الطاولة (Checkout)'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ] else if (currentTable.status == TableStatus.needsCleaning) ...[
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(tableControllerProvider.notifier)
                    .release(tableId, needsCleaning: false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم تنظيف طاولة ${currentTable.tableNumber} وأصبحت متاحة للزبائن',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.cleaning_services),
              label: const Text('تأكيد نظافة الطاولة وجاهزيتها'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ] else ...[
            FilledButton.icon(
              onPressed: () => context.push('/waiter/order/$tableId'),
              icon: const Icon(Icons.add),
              label: const Text(AppConstants.tableActionTakeOrder),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref
                      .read(tableControllerProvider.notifier)
                      .release(tableId),
                  icon: const Icon(Icons.fullscreen_exit),
                  label: const Text(AppConstants.tableActionRelease),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref
                      .read(tableControllerProvider.notifier)
                      .setReserved(
                        tableId,
                        reserved: currentTable.status != TableStatus.reserved,
                      ),
                  icon: const Icon(Icons.event_available),
                  label: Text(
                    currentTable.status == TableStatus.reserved
                        ? 'إلغاء الحجز'
                        : AppConstants.tableActionReserve,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
    OrderEntity order,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _TableCheckoutDialog(table: table, order: order),
    );
  }
}

class _TableInfoRow extends StatelessWidget {
  const _TableInfoRow({required this.table});

  final RestaurantTable table;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(child: Text('${table.tableNumber}')),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${table.capacity} ${AppConstants.seats}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      table.location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  table.status.labelAr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tableStatusColor(table.status, theme.brightness),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatOrderId(order.id),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(order.status.labelAr),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.quantity} × ${item.menuItem.name}'),
                    ),
                    Text(
                      Formatters.formatCurrency(item.itemTotal),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            const Divider(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppConstants.orderTotalLabel,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  Formatters.formatCurrency(order.totalAmount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (order.paymentMethod != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppConstants.paymentMethodLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    order.paymentMethod!.labelAr,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Table Checkout Dialog ──────────────────────────────────────────────────

class _TableCheckoutDialog extends ConsumerStatefulWidget {
  const _TableCheckoutDialog({required this.table, required this.order});

  final RestaurantTable table;
  final OrderEntity order;

  @override
  ConsumerState<_TableCheckoutDialog> createState() => _TableCheckoutDialogState();
}

class _TableCheckoutDialogState extends ConsumerState<_TableCheckoutDialog> {
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  bool _printInvoice = true;
  bool _processing = false;
  final TextEditingController _discountCtrl = TextEditingController();

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  double get _discountValue {
    final text = _discountCtrl.text.trim();
    if (text.isEmpty) return 0.0;
    return double.tryParse(text) ?? 0.0;
  }

  double get _finalTotal {
    final subtotal = widget.order.subtotal;
    final discount = _discountValue;
    final taxable = (subtotal - discount).clamp(0.0, double.infinity);
    final tax = taxable * 0.15;
    return taxable + tax;
  }

  Future<void> _handleConfirm() async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      final ordersCtrl = ref.read(ordersControllerProvider.notifier);
      final updatedOrder = await ordersCtrl.completeAndPayOrder(
        widget.order.id,
        paymentMethod: _selectedPayment,
        discountAmount: _discountValue > 0 ? _discountValue : null,
      );

      if (_printInvoice && updatedOrder != null) {
        await ref
            .read(ticketPrinterServiceProvider)
            .printCustomerInvoice(
              updatedOrder,
              tableDisplay: '${widget.table.tableNumber}',
            );
      }

      await ref
          .read(tableControllerProvider.notifier)
          .release(widget.table.id, needsCleaning: true);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت المحاسبة بنجاح بمبلغ ${Formatters.formatCurrency(_finalTotal)} لطاولة ${widget.table.tableNumber}!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.receipt_long, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text('محاسبة طاولة ${widget.table.tableNumber}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المجموع الفرعي:'),
                      Text(Formatters.formatCurrency(widget.order.subtotal)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الضريبة المضافة (15%):'),
                      Text(Formatters.formatCurrency(widget.order.taxAmount)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الإجمالي المستحق:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(_finalTotal),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'طريقة الدفع:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('نقدي (Cash)'),
                  avatar: const Icon(Icons.money, size: 16),
                  selected: _selectedPayment == PaymentMethod.cash,
                  onSelected: (val) {
                    if (val) setState(() => _selectedPayment = PaymentMethod.cash);
                  },
                ),
                ChoiceChip(
                  label: const Text('بطاقة / شبكة (Card)'),
                  avatar: const Icon(Icons.credit_card, size: 16),
                  selected: _selectedPayment == PaymentMethod.card,
                  onSelected: (val) {
                    if (val) setState(() => _selectedPayment = PaymentMethod.card);
                  },
                ),
                ChoiceChip(
                  label: const Text('محفظة (Wallet)'),
                  avatar: const Icon(Icons.account_balance_wallet, size: 16),
                  selected: _selectedPayment == PaymentMethod.wallet,
                  onSelected: (val) {
                    if (val) setState(() => _selectedPayment = PaymentMethod.wallet);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _discountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'خصم استثنائي (ريال) - اختياري',
                prefixIcon: Icon(Icons.discount_outlined),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('طباعة الفاتورة الضريبية للعميل'),
              value: _printInvoice,
              onChanged: (val) => setState(() => _printInvoice = val ?? true),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _processing ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _processing ? null : _handleConfirm,
          icon: _processing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: const Text('تأكيد الدفع والإخلاء'),
        ),
      ],
    );
  }
}
