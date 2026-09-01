import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/animated_press_card.dart';
import '../../../../shared/animations/pulse_badge.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../domain/entities/shift_entity.dart';
import '../controllers/shift_controller.dart';

/// Full-featured Cashier Shift & Cash Drawer Management Page (Z-Report & X-Report).
class ShiftManagementPage extends ConsumerWidget {
  const ShiftManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final shiftState = ref.watch(shiftControllerProvider);
    final activeShift = shiftState.activeShift;
    final orders = ref.watch(ordersControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.3),
              ),
              child: const Icon(
                Icons.point_of_sale_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.shiftManagementTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  strings.shiftSubtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: const [
          LanguageSwitcherButton(compact: true),
          SizedBox(width: AppSpacing.md),
        ],
      ),
      body: ConstrainedContentView(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          children: [
            // ── 1. Active Shift Section ──────────────────────────────────
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

            // ── 2. Shift History Section ─────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'سجل الورديات المقفلة السابقة',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            if (shiftState.shiftHistory.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
                    width: 1,
                  ),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'لا توجد ورديات سابقة مقفلة حتى الآن',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ستظهر تقارير الـ Z-Report والأرشيف المالي فور إقفال أي وردية',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              for (final pastShift in shiftState.shiftHistory) ...[
                _PastShiftTile(shift: pastShift),
                const SizedBox(height: AppSpacing.sm),
              ],

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _showOpenShiftDialog(BuildContext context, WidgetRef ref) {
    final authUser = ref.read(authControllerProvider).user;
    final floatCtrl = TextEditingController(text: '500');
    final nameCtrl = TextEditingController(
      text: authUser?.name ?? 'الكاشير',
    );

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.lock_open_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'بدء وردية جديدة (فتح الصندوق)',
                            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'تسجيل العهدة النقدية ومسؤول الكاشير',
                            style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الكاشير المسؤول *',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: floatCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'المبلغ الافتتاحي بالدرج (العهدة)',
                    hintText: '500.00',
                    prefixIcon: Icon(Icons.payments_rounded),
                    suffixText: 'ج.م',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
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
                            content: Text('تم فتح الوردية وتعيين العهدة النقدية بنجاح! 🟢'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('فتح الوردية الآن'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final enteredCash = double.tryParse(countCtrl.text.trim()) ?? 0.0;
          final diff = countCtrl.text.isEmpty ? null : (enteredCash - expectedCash);

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            backgroundColor: isDark ? colorScheme.surfaceContainerLow : Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(
                              Icons.lock_clock_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إقفال الوردية وجرد الصندوق',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'إصدار التقرير النهائي Z-Report',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colorScheme.surfaceContainerHigh
                              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            _ReceiptRow(
                              label: 'العهدة الافتتاحية:',
                              value: Formatters.formatCurrency(activeShift.openingCashFloat),
                            ),
                            const SizedBox(height: 6),
                            _ReceiptRow(
                              label: 'مبيعات الكاش النقدية:',
                              value: Formatters.formatCurrency(cashSales),
                              valueColor: const Color(0xFF10B981),
                            ),
                            const SizedBox(height: 6),
                            _ReceiptRow(
                              label: 'مبيعات البطاقة / الشبكة:',
                              value: Formatters.formatCurrency(cardSales),
                              valueColor: const Color(0xFF0284C7),
                            ),
                            const SizedBox(height: 6),
                            _ReceiptRow(
                              label: 'مبيعات المحفظة الإلكترونية:',
                              value: Formatters.formatCurrency(walletSales),
                              valueColor: const Color(0xFF8B5CF6),
                            ),
                            const Divider(height: 20),
                            _ReceiptRow(
                              label: 'النقد المتوقع تسليمه بالدرج:',
                              value: Formatters.formatCurrency(expectedCash),
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: countCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'المبلغ النقدي الفعلي المسلم *',
                          hintText: 'أدخل المبلغ الموجود بالدرج بعد العد',
                          prefixIcon: Icon(Icons.point_of_sale_rounded),
                          suffixText: 'ج.م',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (diff != null) ...[
                        const SizedBox(height: AppSpacing.xs + 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: diff == 0
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : (diff > 0
                                    ? const Color(0xFFD97706).withValues(alpha: 0.12)
                                    : colorScheme.error.withValues(alpha: 0.12)),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: diff == 0
                                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                  : (diff > 0
                                      ? const Color(0xFFD97706).withValues(alpha: 0.3)
                                      : colorScheme.error.withValues(alpha: 0.3)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                diff == 0
                                    ? Icons.check_circle_rounded
                                    : (diff > 0
                                        ? Icons.info_rounded
                                        : Icons.warning_rounded),
                                size: 18,
                                color: diff == 0
                                    ? const Color(0xFF047857)
                                    : (diff > 0
                                        ? const Color(0xFFB45309)
                                        : colorScheme.error),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  diff == 0
                                      ? 'النقد مطابق تماماً للعمليات المسجلة'
                                      : (diff > 0
                                          ? 'يوجد زيادة نقدية قدرها ${Formatters.formatCurrency(diff)}'
                                          : 'يوجد عجز نقدي قدره ${Formatters.formatCurrency(diff.abs())}'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: diff == 0
                                        ? const Color(0xFF047857)
                                        : (diff > 0
                                            ? const Color(0xFFB45309)
                                            : colorScheme.error),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات الإقفال (اختياري)',
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('إلغاء'),
                          ),
                          const SizedBox(width: AppSpacing.sm),
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
                                    notes: notesCtrl.text.trim().isEmpty
                                        ? null
                                        : notesCtrl.text.trim(),
                                  );

                              Navigator.of(ctx).pop();

                              if (closedShift != null) {
                                _showZReportDialog(context, closedShift);
                              }
                            },
                            icon: const Icon(Icons.lock_clock_rounded, size: 18),
                            label: const Text('تأكيد الإقفال وسحب Z-Report'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showZReportDialog(BuildContext context, ShiftEntity shift) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.receipt_rounded,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تقرير إقفال الوردية (Z-Report)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'المعرف: ${shift.id}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      shift.generateZReportText(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('إغلاق'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم إرسال تقرير Z-Report إلى الطابعة الحرارية 🖨️'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('طباعة الإيصال'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── No Active Shift Card ───────────────────────────────────────────────────────

class _NoActiveShiftCard extends StatelessWidget {
  const _NoActiveShiftCard({required this.onOpenShift});

  final VoidCallback onOpenShift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
          width: 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
              boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.35),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'لا توجد وردية مفتوحة حالياً',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'يرجى فتح وردية جديدة وتحديد العهدة النقدية في الدرج للبدء في البيع واستقبال المدفوعات',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedPressCard(
            borderRadius: AppRadius.full,
            onTap: onOpenShift,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm + 4,
              ),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.3),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'بدء وردية جديدة الآن',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active Shift Card (Hero Bento Component) ───────────────────────────────────

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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
          width: 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Glowing Accent Strip
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: AppGradients.emerald,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Shift Status & ID Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PulseBadge(color: Color(0xFF10B981), size: 7),
                          const SizedBox(width: 6),
                          Text(
                            'وردية نشطة حالياً',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF047857),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '#${shift.id}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Cashier Info Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المسؤول: ${shift.cashierName}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'بدأت في: ${Formatters.formatDateTime(shift.openedAt)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. 3-Stat KPI Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHigh
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _BentoStatBox(
                          label: 'العهدة الافتتاحية',
                          value: Formatters.formatCurrency(shift.openingCashFloat),
                          icon: Icons.account_balance_wallet_rounded,
                          color: const Color(0xFF0F766E),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                      Expanded(
                        child: _BentoStatBox(
                          label: 'إجمالي المبيعات',
                          value: Formatters.formatCurrency(totalSales),
                          icon: Icons.payments_rounded,
                          color: const Color(0xFF10B981),
                          isProminent: true,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                      Expanded(
                        child: _BentoStatBox(
                          label: 'الطلبات المكتملة',
                          value: '$completedOrdersCount طلب',
                          icon: Icons.receipt_long_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Payment Method Micro-Chips (Zero Overflow Guaranteed!)
                Text(
                  'تفصيل المقبوضات حسب وسيلة الدفع:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: _PaymentChip(
                        label: 'كاش نقد',
                        amount: cashSales,
                        icon: Icons.payments_outlined,
                        accentColor: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Expanded(
                      child: _PaymentChip(
                        label: 'بطاقة / مدى',
                        amount: cardSales,
                        icon: Icons.credit_card_rounded,
                        accentColor: const Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Expanded(
                      child: _PaymentChip(
                        label: 'محفظة إلكترونية',
                        amount: walletSales,
                        icon: Icons.account_balance_wallet_outlined,
                        accentColor: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 5. Close Shift Action Button
                AnimatedPressCard(
                  borderRadius: AppRadius.lg,
                  onTap: onCloseShift,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_clock_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'إقفال الوردية وجرد الصندوق (Z-Report)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bento Stat Box ─────────────────────────────────────────────────────────────

class _BentoStatBox extends StatelessWidget {
  const _BentoStatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isProminent = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isProminent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isProminent ? FontWeight.w900 : FontWeight.bold,
                fontSize: 13,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment Micro Chip (Responsive & Zero Overflow) ────────────────────────────

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.label,
    required this.amount,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: AppSpacing.xs + 3,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.formatCurrency(amount),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Past Shift Tile Component ──────────────────────────────────────────────────

class _PastShiftTile extends StatelessWidget {
  const _PastShiftTile({required this.shift});

  final ShiftEntity shift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final diff = shift.cashDiscrepancy ?? 0.0;

    return AnimatedPressCard(
      borderRadius: AppRadius.lg,
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تقرير الوردية #${shift.id}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'المسؤول: ${shift.cashierName}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          shift.generateZReportText(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('إغلاق'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تمت إعادة طباعة الإيصال بنجاح 🖨️'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          },
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: const Text('طباعة'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
            width: 1,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${shift.id} — ${shift.cashierName}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'أقفلت: ${Formatters.formatDateTime(shift.closedAt ?? shift.openedAt)} • مبيعات: ${Formatters.formatCurrency(shift.totalSales)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: diff == 0
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : (diff > 0
                            ? const Color(0xFFD97706).withValues(alpha: 0.12)
                            : colorScheme.error.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    diff == 0
                        ? 'مطابق'
                        : (diff > 0
                            ? '+${Formatters.formatCurrency(diff)}'
                            : Formatters.formatCurrency(diff)),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: diff == 0
                          ? const Color(0xFF047857)
                          : (diff > 0
                              ? const Color(0xFFB45309)
                              : colorScheme.error),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'الفارق النقدي',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 9,
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

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: valueColor ?? (isBold ? theme.colorScheme.primary : null),
            fontSize: isBold ? 14 : 12,
          ),
        ),
      ],
    );
  }
}
