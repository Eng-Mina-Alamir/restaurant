import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/printing/ticket_printer_service.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/animations/animated_press_card.dart';
import '../../../../shared/animations/pulse_badge.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../../../../shared/widgets/logout_action_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../manager_dashboard/domain/entities/shift_entity.dart';
import '../../../manager_dashboard/presentation/controllers/shift_controller.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../../restaurant/presentation/controllers/branch_controller.dart';
import '../../../table_management/presentation/controllers/table_controller.dart';
import '../controllers/cash_drawer_controller.dart';
import '../controllers/held_orders_controller.dart';
import '../widgets/cash_drawer_in_out_dialog.dart';
import '../widgets/held_orders_modal.dart';
import '../widgets/order_refund_dialog.dart';

/// Professional, standalone Cashier POS Hub & Drawer Management Dashboard.
class CashierDashboardPage extends ConsumerWidget {
  const CashierDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final isArabic = strings.isArabic;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final authUser = ref.watch(authControllerProvider).user;
    final activeBranch = ref.watch(activeBranchProvider);
    final shiftState = ref.watch(shiftControllerProvider);
    final activeShift = shiftState.activeShift;
    final orders = ref.watch(ordersControllerProvider);
    final tables = ref.watch(tableControllerProvider);

    // Filter completed orders during current active shift
    final completedOrders = orders.where((o) {
      if (o.status != OrderStatus.completed) return false;
      if (activeShift == null) return false;
      return o.createdAt.isAfter(activeShift.openedAt);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
    final drawerState = ref.watch(cashDrawerControllerProvider);
    final heldOrders = ref.watch(heldOrdersControllerProvider);
    final totalCashInDrawer = (activeShift?.openingCashFloat ?? 0.0) +
        cashSales +
        drawerState.totalPayIns -
        drawerState.totalPayOuts -
        drawerState.totalRefunds;

    final occupiedTablesCount =
        tables.where((t) => t.status == TableStatus.occupied).length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.3),
              ),
              child: const Icon(
                Icons.point_of_sale_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        isArabic ? 'نقطة البيع والكاشير' : 'Cashier POS Hub',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: activeShift != null
                              ? const Color(0xFFDCFCE7)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          activeShift != null
                              ? (isArabic ? 'وردية نشطة' : 'Shift Active')
                              : (isArabic ? 'الوردية مقفلة' : 'Shift Closed'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: activeShift != null
                                ? const Color(0xFF15803D)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${authUser?.name ?? (isArabic ? "كاشير الصالة" : "Cashier")} • ${activeBranch?.name ?? (isArabic ? "الفرع الرئيسي" : "Main Branch")}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [
          LanguageSwitcherButton(compact: true),
          SizedBox(width: AppSpacing.xs),
          LogoutActionButton(),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ConstrainedContentView(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          children: [
            // ── 1. Active Shift & Cash Drawer Card ──────────────────────────
            if (activeShift == null)
              _CashierNoActiveShiftCard(
                isArabic: isArabic,
                onOpenShift: () => _showOpenShiftDialog(context, ref, authUser?.name),
              )
            else
              _CashierActiveShiftCard(
                isArabic: isArabic,
                shift: activeShift,
                cashierName: authUser?.name,
                completedOrdersCount: completedOrders.length,
                totalCashInDrawer: totalCashInDrawer,
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
                  isArabic,
                ),
              ),

            const SizedBox(height: AppSpacing.lg),

            // ── 2. Fast POS & Quick Actions Hub ──────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isArabic ? 'العمليات السريعة ونقطة البيع' : 'POS Quick Operations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Quick Operations Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final crossAxisCount = isWide ? 3 : 2;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: isWide ? 1.45 : 1.15,
                  children: [
                    _POSHubActionCard(
                      icon: Icons.point_of_sale_rounded,
                      gradient: AppGradients.emerald,
                      title: isArabic ? 'نقطة البيع السريعة' : 'Fast POS Counter',
                      subtitle: isArabic
                          ? 'محاسبة التيك أواي وحاسبة الباقي'
                          : 'Quick Takeaway & Tender',
                      onTap: () {
                        AppHaptics.selectionTap();
                        context.push('/cashier/pos');
                      },
                    ),
                    _POSHubActionCard(
                      icon: Icons.account_balance_wallet_rounded,
                      gradient: AppGradients.primary,
                      title: isArabic ? 'حركات الدرج والمصروفات' : 'Petty Cash & In/Out',
                      subtitle: isArabic
                          ? 'تسجيل سحب أو إيداع نقدية'
                          : 'Record Pay-In / Pay-Out',
                      badge: drawerState.transactions.isNotEmpty
                          ? '${drawerState.transactions.length}'
                          : null,
                      onTap: () {
                        AppHaptics.selectionTap();
                        CashDrawerInOutDialog.show(
                          context,
                          shiftId: activeShift?.id ?? 'SHIFT-0',
                        );
                      },
                    ),
                    _POSHubActionCard(
                      icon: Icons.pause_circle_filled_rounded,
                      gradient: AppGradients.warning,
                      title: isArabic ? 'الطلبات المعلقة' : 'Held / Parked Orders',
                      subtitle: isArabic
                          ? '${heldOrders.length} طلبات معلقة بالانتظار'
                          : '${heldOrders.length} Parked Orders',
                      badge: heldOrders.isNotEmpty ? '${heldOrders.length}' : null,
                      onTap: () {
                        AppHaptics.selectionTap();
                        HeldOrdersModal.show(context);
                      },
                    ),
                    _POSHubActionCard(
                      icon: Icons.table_restaurant_rounded,
                      gradient: AppGradients.info,
                      title: isArabic ? 'طاولات الصالة و POS' : 'Dine-In Tables',
                      subtitle: isArabic
                          ? '$occupiedTablesCount طاولة مشغولة'
                          : '$occupiedTablesCount Occupied',
                      badge: '${tables.length}',
                      onTap: () {
                        AppHaptics.selectionTap();
                        context.push('/waiter');
                      },
                    ),
                    _POSHubActionCard(
                      icon: Icons.receipt_long_rounded,
                      gradient: AppGradients.purple,
                      title: isArabic ? 'الفواتير والتحصيل' : 'Invoices & Billing',
                      subtitle: isArabic
                          ? '${completedOrders.length} فاتورة مسجلة'
                          : '${completedOrders.length} Invoices',
                      onTap: () {
                        AppHaptics.selectionTap();
                        context.push('/manager/invoices');
                      },
                    ),
                    _POSHubActionCard(
                      icon: Icons.history_edu_rounded,
                      gradient: AppGradients.primary,
                      title: isArabic ? 'سجل الورديات و Z-Report' : 'Shifts & Z-Reports',
                      subtitle: isArabic
                          ? '${shiftState.shiftHistory.length} وردية مقفلة'
                          : '${shiftState.shiftHistory.length} Past Shifts',
                      onTap: () {
                        AppHaptics.selectionTap();
                        context.push('/manager/shifts');
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── 3. Recent Shift Transactions & Quick Receipt ─────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs + 2),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.receipt_rounded,
                        color: colorScheme.secondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isArabic ? 'آخر فواتير الوردية المحصلة' : 'Recent Shift Receipts',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (completedOrders.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => context.push('/manager/invoices'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(
                      isArabic ? 'عرض الكل' : 'View All',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            if (completedOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: colorScheme.outlineVariant
                        .withValues(alpha: isDark ? 0.3 : 0.6),
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
                      isArabic
                          ? 'لا توجد فواتير محصلة في هذه الوردية بعد'
                          : 'No completed orders in this shift yet',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'عند إتمام وتحصيل أي طلب سيظهر هنا مع إمكانية طباعة الإيصال فوراً'
                          : 'Receipts will appear here as soon as orders are paid',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: completedOrders.take(5).length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, idx) {
                  final order = completedOrders[idx];
                  return _CashierOrderTile(
                    order: order,
                    isArabic: isArabic,
                    onPrint: () => _printOrderTicket(context, ref, order),
                    onRefund: () => OrderRefundDialog.show(context, order: order),
                  );
                },
              ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _printOrderTicket(BuildContext context, WidgetRef ref, OrderEntity order) {
    AppHaptics.selectionTap();
    final printer = ref.read(ticketPrinterServiceProvider);
    unawaited(printer.printCustomerInvoice(order));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال إيصال الطلب #${Formatters.formatOrderId(order.id)} للطابعة'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showOpenShiftDialog(BuildContext context, WidgetRef ref, String? defaultCashierName) {
    final floatCtrl = TextEditingController(text: '500');
    final nameCtrl = TextEditingController(text: defaultCashierName ?? 'حسام علي (كاشير)');

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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'فتح وردية واستلام الدرج',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'تسجيل عهدة بداية اليوم وتفعيل نقطة البيع',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'المسؤول عن الوردية',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'العهدة الافتتاحية (ج.م) النقد في الدرج',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: floatCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.payments_outlined),
                    suffixText: 'ج.م',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand,
                        ),
                        onPressed: () {
                          final floatVal = double.tryParse(floatCtrl.text.trim()) ?? 0.0;
                          final nameVal = nameCtrl.text.trim();
                          ref.read(shiftControllerProvider.notifier).openShift(
                                cashierId: 'usr-cashier',
                                cashierName: nameVal.isEmpty ? 'الكاشير' : nameVal,
                                openingFloat: floatVal,
                              );
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم فتح الوردية وتفعيل الصندوق بنجاح'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('تأكيد وبدء الوردية'),
                      ),
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
    ShiftEntity shift,
    double cashSales,
    double cardSales,
    double walletSales,
    int ordersCount,
    bool isArabic,
  ) {
    final expectedTotalCash = shift.openingCashFloat + cashSales;
    final actualCashCtrl = TextEditingController(
      text: expectedTotalCash.toStringAsFixed(2),
    );
    final notesCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final enteredActual =
              double.tryParse(actualCashCtrl.text.trim()) ?? expectedTotalCash;
          final diff = enteredActual - expectedTotalCash;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SingleChildScrollView(
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
                              Icons.lock_clock_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إقفال الوردية وجرد الصندوق',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Z-Report • تقفيل الحسابات ومطابقة النقدية',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.xs),

                      // Expected Breakdown Summary
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          children: [
                            _ReceiptRow('العهدة الافتتاحية:', Formatters.formatCurrency(shift.openingCashFloat)),
                            _ReceiptRow('المبيعات النقدية (كاش):', Formatters.formatCurrency(cashSales)),
                            _ReceiptRow('مبيعات مدى / بطاقات:', Formatters.formatCurrency(cardSales)),
                            _ReceiptRow('مبيعات المحافظ الإلكترونية:', Formatters.formatCurrency(walletSales)),
                            const Divider(height: 12),
                            _ReceiptRow(
                              'إجمالي النقد المتوقع في الدرج:',
                              Formatters.formatCurrency(expectedTotalCash),
                              isBold: true,
                              color: AppColors.brand,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      const Text(
                        'النقد الفعلي الموجود في الدرج (جرد الكاشير):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: actualCashCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setStateDialog(() {}),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.calculate_outlined),
                          suffixText: 'ج.م',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Difference indicator
                      if (diff.abs() < 0.01)
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'المبلغ مطابق تماماً للعهدة والمبيعات (لا يوجد عجز أو زيادة)',
                              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      else if (diff > 0)
                        Row(
                          children: [
                            const Icon(Icons.arrow_upward, color: Colors.blue, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'يوجد فائض بالدرج بمقدار: +${Formatters.formatCurrency(diff)}',
                              style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'يوجد عجز بالدرج بمقدار: ${Formatters.formatCurrency(diff)}',
                              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'ملاحظات إضافية (اختياري):',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'أي ملاحظات خاصة بالوردية أو المصروفات النثرية...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('إلغاء'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFEA580C),
                              ),
                              onPressed: () {
                                final actualVal =
                                    double.tryParse(actualCashCtrl.text.trim()) ??
                                        expectedTotalCash;
                                final closedShift = ref
                                    .read(shiftControllerProvider.notifier)
                                    .closeShift(
                                      actualCashCount: actualVal,
                                      cashSales: cashSales,
                                      cardSales: cardSales,
                                      walletSales: walletSales,
                                      orderCount: ordersCount,
                                      notes: notesCtrl.text.trim().isEmpty
                                          ? null
                                          : notesCtrl.text.trim(),
                                    );
                                Navigator.of(ctx).pop();

                                if (closedShift != null) {
                                  _showZReportSuccessModal(
                                    context,
                                    closedShift,
                                    ref,
                                  );
                                }
                              },
                              icon: const Icon(Icons.lock_outline),
                              label: const Text('إقفال وطباعة Z-Report'),
                            ),
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

  void _showZReportSuccessModal(
    BuildContext context,
    ShiftEntity shift,
    WidgetRef ref,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 56),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'تم إقفال الوردية وحفظ تقرير Z-Report بنجاح',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'رقم الوردية: #${shift.id} • مسؤول الكاشير: ${shift.cashierName}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إرسال تقرير الـ Z-Report للطابعة الحرارية'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.print_rounded),
              label: const Text('طباعة التقرير المالي للوردية (Z-Report)'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting Components ───────────────────────────────────────────────────

class _CashierActiveShiftCard extends StatelessWidget {
  const _CashierActiveShiftCard({
    required this.isArabic,
    required this.shift,
    this.cashierName,
    required this.completedOrdersCount,
    required this.totalCashInDrawer,
    required this.cashSales,
    required this.cardSales,
    required this.walletSales,
    required this.totalSales,
    required this.onCloseShift,
  });

  final bool isArabic;
  final ShiftEntity shift;
  final String? cashierName;
  final int completedOrdersCount;
  final double totalCashInDrawer;
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
    const emeraldColor = Color(0xFF10B981);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: emeraldColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: emeraldColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  emeraldColor.withValues(alpha: 0.15),
                  colorScheme.surface,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg - 1.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PulseBadge(color: emeraldColor, size: 8),
                      const SizedBox(width: 6),
                      Text(
                        isArabic ? 'وردية نشطة حالياً' : 'Active Shift',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '#${shift.id}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cashier info line
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                      child: Icon(Icons.person, color: colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isArabic ? "المسؤول" : "Cashier"}: ${cashierName ?? shift.cashierName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${isArabic ? "بدأت في" : "Started"}: ${Formatters.formatDate(shift.openedAt)} ${Formatters.formatTime(shift.openedAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 4-Stat Financial Tiles
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        title: isArabic ? 'العهدة الافتتاحية' : 'Opening Float',
                        value: Formatters.formatCurrency(shift.openingCashFloat),
                        color: Colors.blueGrey,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _MetricTile(
                        title: isArabic ? 'النقد بالدرج' : 'Cash in Drawer',
                        value: Formatters.formatCurrency(totalCashInDrawer),
                        color: emeraldColor,
                        icon: Icons.payments_rounded,
                        isHighlighted: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        title: isArabic ? 'إجمالي المبيعات' : 'Total Sales',
                        value: Formatters.formatCurrency(totalSales),
                        color: AppColors.brand,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _MetricTile(
                        title: isArabic ? 'الطلبات المكتملة' : 'Paid Orders',
                        value: '$completedOrdersCount ${isArabic ? "طلب" : "Orders"}',
                        color: Colors.indigo,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Payment breakdown pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MiniPaymentStat(
                        label: isArabic ? 'كاش' : 'Cash',
                        amount: cashSales,
                        color: emeraldColor,
                        icon: Icons.money_rounded,
                      ),
                      _MiniPaymentStat(
                        label: isArabic ? 'بطاقة' : 'Card',
                        amount: cardSales,
                        color: Colors.blue,
                        icon: Icons.credit_card_rounded,
                      ),
                      _MiniPaymentStat(
                        label: isArabic ? 'محفظة' : 'Wallet',
                        amount: walletSales,
                        color: Colors.purple,
                        icon: Icons.account_balance_wallet_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Close Shift Z-Report Action
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: onCloseShift,
                    icon: const Icon(Icons.lock_clock_rounded, size: 20),
                    label: Text(
                      isArabic
                          ? 'إقفال الوردية وجرد الصندوق (Z-Report)'
                          : 'Close Shift & Cash Audit (Z-Report)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

class _CashierNoActiveShiftCard extends StatelessWidget {
  const _CashierNoActiveShiftCard({
    required this.isArabic,
    required this.onOpenShift,
  });

  final bool isArabic;
  final VoidCallback onOpenShift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const amberColor = Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: amberColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: amberColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: amberColor,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isArabic
                ? 'لا توجد وردية مفتوحة حالياً للكاشير'
                : 'No Active Cashier Shift',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'يرجى تسجيل العهدة الافتتاحية وبدء الوردية لتفعيل نقطة البيع وتسجيل المدفوعات'
                : 'Please open a shift and enter the opening float to start accepting payments',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onPressed: onOpenShift,
            icon: const Icon(Icons.lock_open_rounded),
            label: Text(
              isArabic
                  ? 'بدء وردية جديدة واستلام العهدة'
                  : 'Start New Cashier Shift',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.isHighlighted = false,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? color.withValues(alpha: isDark ? 0.15 : 0.08)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: color.withValues(alpha: isHighlighted ? 0.4 : 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MiniPaymentStat extends StatelessWidget {
  const _MiniPaymentStat({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ${Formatters.formatCurrency(amount)}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _POSHubActionCard extends StatelessWidget {
  const _POSHubActionCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedPressCard(
      onTap: onTap,
      borderRadius: AppRadius.lg,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadows.glow(gradient.colors.first, opacity: 0.3),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: gradient.colors.first.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: gradient.colors.first,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CashierOrderTile extends StatelessWidget {
  const _CashierOrderTile({
    required this.order,
    required this.isArabic,
    required this.onPrint,
    this.onRefund,
  });

  final OrderEntity order;
  final bool isArabic;
  final VoidCallback onPrint;
  final VoidCallback? onRefund;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: AppColors.brand,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerId != null
                      ? 'طلب #${Formatters.formatOrderId(order.id)}'
                      : (isArabic ? 'طلب صالة #${Formatters.formatOrderId(order.id)}' : 'Order #${Formatters.formatOrderId(order.id)}'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${Formatters.formatTime(order.createdAt)} • ${order.paymentMethod?.labelAr ?? (isArabic ? "نقدي" : "Cash")}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.formatCurrency(order.totalAmount),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (onRefund != null)
            IconButton(
              onPressed: onRefund,
              tooltip: isArabic ? 'استرجاع الفاتورة' : 'Refund Invoice',
              icon: const Icon(Icons.assignment_return_outlined, size: 20, color: Colors.orange),
              style: IconButton.styleFrom(
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
              ),
            ),
          IconButton(
            onPressed: onPrint,
            tooltip: isArabic ? 'طباعة الفاتورة' : 'Print Receipt',
            icon: const Icon(Icons.print_outlined, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(
    this.label,
    this.value, {
    this.isBold = false,
    this.color,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
