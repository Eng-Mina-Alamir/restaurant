import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../domain/entities/shift_entity.dart';
import '../controllers/shift_controller.dart';

/// Full-featured Cashier Shift & Cash Drawer Management Page (Z-Report & X-Report).
class ShiftManagementPage extends ConsumerWidget {
  const ShiftManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftControllerProvider);
    final activeShift = shiftState.activeShift;
    final orders = ref.watch(ordersControllerProvider);
    final theme = Theme.of(context);

    // Filter completed orders that happened during this active shift
    final completedOrders = orders.where((o) {
      if (o.status != OrderStatus.completed) return false;
      if (activeShift == null) return false;
      return o.createdAt.isAfter(activeShift.openedAt);
    }).toList();

    final cashSales = completedOrders
        .where((o) => o.paymentMethod == PaymentMethod.cash)
        .fold<double>(0.0, (s, o) => s + o.totalAmount);
    final cardSales = completedOrders
        .where((o) => o.paymentMethod == PaymentMethod.card)
        .fold<double>(0.0, (s, o) => s + o.totalAmount);
    final walletSales = completedOrders
        .where((o) => o.paymentMethod == PaymentMethod.wallet)
        .fold<double>(0.0, (s, o) => s + o.totalAmount);
    final totalSales = cashSales + cardSales + walletSales;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الوردية والصندوق (Z-Report)'),
      ),
      body: ConstrainedContentView(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── Active Shift Section ─────────────────────────────────────
            if (activeShift == null)
              _NoActiveShiftCard(
                onOpenShift: () => _showOpenShiftDialog(context, ref),
              )
            else
              _ActiveShiftCard(
                shift: activeShift,
                completedOrdersCount: completedOrders.length,
                cashSales: cashSales,
                cardSales: cardSales,
                walletSales: walletSales,
                totalSales: totalSales,
                onCloseShift: () => _showCloseShiftDialog(
                  context,
                  ref,
                  activeShift,
                  cashSales,
                  cardSales,
                  walletSales,
                  completedOrders.length,
                ),
              ),

            const SizedBox(height: AppSpacing.xl),

            // ── Shift History Section ────────────────────────────────────
            Text(
              'سجل الورديات المقفلة السابقة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (shiftState.shiftHistory.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Text('لا توجد ورديات سابقة مقفلة حتى الآن'),
                  ),
                ),
              )
            else
              for (final pastShift in shiftState.shiftHistory)
                _PastShiftTile(shift: pastShift),
          ],
        ),
      ),
    );
  }

  void _showOpenShiftDialog(BuildContext context, WidgetRef ref) {
    final floatCtrl = TextEditingController(text: '500');
    final nameCtrl = TextEditingController(text: 'الكاشير الحالي');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بدء وردية جديدة (فتح الصندوق)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم الكاشير المسؤول',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: floatCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'المبلغ الافتتاحي بالدرج (ر.س)',
                prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final floatVal = double.tryParse(floatCtrl.text.trim()) ?? 0.0;
              final nameVal = nameCtrl.text.trim();
              ref.read(shiftControllerProvider.notifier).openShift(
                cashierId: 'usr-current',
                cashierName: nameVal.isEmpty ? 'الكاشير' : nameVal,
                openingFloat: floatVal,
              );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم فتح الوردية وتعيين العهدة النقدية بنجاح!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('فتح الوردية'),
          ),
        ],
      ),
    );
  }

  void _showCloseShiftDialog(
    BuildContext context,
    WidgetRef ref,
    ShiftEntity activeShift,
    double cashSales,
    double cardSales,
    double walletSales,
    int orderCount,
  ) {
    final countCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final expectedCash = activeShift.openingCashFloat + cashSales;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final enteredCash = double.tryParse(countCtrl.text.trim()) ?? 0.0;
          final diff = enteredCash - expectedCash;

          return AlertDialog(
            title: const Text('إقفال الوردية (Z-Report)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('العهدة الافتتاحية:'),
                            Text(Formatters.formatCurrency(activeShift.openingCashFloat)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('مبيعات النقد (Cash):'),
                            Text(Formatters.formatCurrency(cashSales)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'النقد المتوقع تسليمه:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              Formatters.formatCurrency(expectedCash),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: countCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'المبلغ النقدي الفعلي المسلم (ر.س)',
                      prefixIcon: Icon(Icons.point_of_sale),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (countCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      diff == 0
                          ? '✅ النقد مطابق تماماً للعمليات'
                          : (diff > 0
                              ? '⚠️ يوجد زيادة نقدية قدرها ${Formatters.formatCurrency(diff)}'
                              : '❌ يوجد عجز نقدي قدره ${Formatters.formatCurrency(diff.abs())}'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: diff == 0
                            ? Colors.green
                            : (diff > 0 ? Colors.orange : Colors.red),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات الإقفال (اختياري)',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton.icon(
                onPressed: () {
                  final actualVal = double.tryParse(countCtrl.text.trim()) ?? 0.0;
                  final closedShift = ref
                      .read(shiftControllerProvider.notifier)
                      .closeShift(
                        actualCashCount: actualVal,
                        cashSales: cashSales,
                        cardSales: cardSales,
                        walletSales: walletSales,
                        orderCount: orderCount,
                        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      );

                  Navigator.of(ctx).pop();

                  if (closedShift != null) {
                    _showZReportDialog(context, closedShift);
                  }
                },
                icon: const Icon(Icons.lock_clock),
                label: const Text('تأكيد الإقفال وسحب Z-Report'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showZReportDialog(BuildContext context, ShiftEntity shift) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.print_outlined),
            SizedBox(width: 8),
            Text('تقرير إقفال الوردية (Z-Report)'),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            shift.generateZReportText(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق وطباعة'),
          ),
        ],
      ),
    );
  }
}

class _NoActiveShiftCard extends StatelessWidget {
  const _NoActiveShiftCard({required this.onOpenShift});

  final VoidCallback onOpenShift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد وردية مفتوحة حالياً',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'يرجى فتح وردية جديدة وتحديد العهدة النقدية للبدء في البيع',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onOpenShift,
              icon: const Icon(Icons.add),
              label: const Text('فتح وردية جديدة الآن'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveShiftCard extends StatelessWidget {
  const _ActiveShiftCard({
    required this.shift,
    required this.completedOrdersCount,
    required this.cashSales,
    required this.cardSales,
    required this.walletSales,
    required this.totalSales,
    required this.onCloseShift,
  });

  final ShiftEntity shift;
  final int completedOrdersCount;
  final double cashSales;
  final double cardSales;
  final double walletSales;
  final double totalSales;
  final VoidCallback onCloseShift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Text(
                    '● وردية نشطة حالياً',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Text(
                  shift.id,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'المسؤول: ${shift.cashierName}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'بدأت في: ${Formatters.formatDateTime(shift.openedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _MiniKpi(
                    label: 'العهدة الافتتاحية',
                    value: Formatters.formatCurrency(shift.openingCashFloat),
                  ),
                ),
                Expanded(
                  child: _MiniKpi(
                    label: 'إجمالي المبيعات',
                    value: Formatters.formatCurrency(totalSales),
                    highlight: true,
                  ),
                ),
                Expanded(
                  child: _MiniKpi(
                    label: 'الطلبات المكتملة',
                    value: '$completedOrdersCount طلب',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _PaymentChip(
                    label: 'نقد (Cash)',
                    amount: cashSales,
                    icon: Icons.money,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PaymentChip(
                    label: 'شبكة (Card)',
                    amount: cardSales,
                    icon: Icons.credit_card,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PaymentChip(
                    label: 'محفظة (Wallet)',
                    amount: walletSales,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonalIcon(
              onPressed: onCloseShift,
              icon: const Icon(Icons.lock_clock),
              label: const Text('إقفال الوردية وجرد الصندوق (Z-Report)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: highlight ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.label,
    required this.amount,
    required this.icon,
  });

  final String label;
  final double amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            Formatters.formatCurrency(amount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PastShiftTile extends StatelessWidget {
  const _PastShiftTile({required this.shift});

  final ShiftEntity shift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = shift.cashDiscrepancy ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: const Icon(Icons.receipt_long),
        ),
        title: Text('${shift.id} — ${shift.cashierName}'),
        subtitle: Text(
          'أقفلت: ${Formatters.formatDateTime(shift.closedAt ?? shift.openedAt)} • مبيعات: ${Formatters.formatCurrency(shift.totalSales)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              diff == 0
                  ? 'مطابق'
                  : (diff > 0 ? '+${Formatters.formatCurrency(diff)}' : Formatters.formatCurrency(diff)),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: diff == 0 ? Colors.green : (diff > 0 ? Colors.orange : Colors.red),
              ),
            ),
            const Text('الفارق النقدي', style: TextStyle(fontSize: 10)),
          ],
        ),
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('تقرير الوردية ${shift.id}'),
              content: SingleChildScrollView(
                child: SelectableText(
                  shift.generateZReportText(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
