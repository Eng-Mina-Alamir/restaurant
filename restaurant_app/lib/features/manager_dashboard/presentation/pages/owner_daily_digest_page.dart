import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/animated_press_card.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../../inventory/presentation/controllers/recipe_controller.dart';
import '../../../inventory/presentation/controllers/waste_controller.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../controllers/shift_controller.dart';

/// Executive Daily Summary & AI Digest Page for Restaurant Owner
class OwnerDailyDigestPage extends ConsumerWidget {
  const OwnerDailyDigestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final orders = ref.watch(ordersControllerProvider);
    final shiftState = ref.watch(shiftControllerProvider);
    final recipesState = ref.watch(recipeControllerProvider);

    final completedOrders =
        orders.where((o) => o.status == OrderStatus.completed).toList();

    // 1. Financial totals
    final double cashSales = completedOrders
        .where((o) => o.paymentMethod == PaymentMethod.cash)
        .fold<double>(0.0, (s, o) => s + o.totalAmount);
    final double cardSales = completedOrders
        .where((o) => o.paymentMethod == PaymentMethod.card)
        .fold<double>(0.0, (s, o) => s + o.totalAmount);
    final double walletSales = completedOrders
        .where((o) => o.paymentMethod == PaymentMethod.wallet)
        .fold<double>(0.0, (s, o) => s + o.totalAmount);
    final double totalSales = cashSales + cardSales + walletSales;

    final double avgTicket =
        completedOrders.isNotEmpty ? totalSales / completedOrders.length : 0.0;

    // 2. Food Cost & Margins
    final recipes = recipesState.valueOrNull ?? [];
    double totalEstimatedFoodCost = 0.0;

    for (final order in completedOrders) {
      for (final item in order.items) {
        final recipeMatch = recipes.where(
          (r) =>
              r.menuItemId == item.menuItem.id ||
              r.menuItemName.trim().toLowerCase() ==
                  item.menuItem.name.trim().toLowerCase(),
        );
        final costPerPlate =
            recipeMatch.isNotEmpty
                ? recipeMatch.first.totalFoodCost
                : (item.unitTotal * 0.32);
        totalEstimatedFoodCost += costPerPlate * item.quantity;
      }
    }

    final double grossProfit = (totalSales - totalEstimatedFoodCost).clamp(
      0.0,
      999999.0,
    );
    final double foodCostPct =
        totalSales > 0 ? (totalEstimatedFoodCost / totalSales) * 100.0 : 0.0;

    // 3. Waste & Spoilage
    final double totalWasteCost =
        ref.read(wasteControllerProvider.notifier).totalWasteCost;

    // 4. Shifts & Cash Discrepancy
    final activeShift = shiftState.activeShift;
    final double? activeDiscrepancy = activeShift?.cashDiscrepancy;

    // 5. Top Dish
    final Map<String, int> dishCounts = {};
    for (final o in completedOrders) {
      for (final item in o.items) {
        dishCounts[item.menuItem.name] =
            (dishCounts[item.menuItem.name] ?? 0) + item.quantity;
      }
    }
    final sortedDishes =
        dishCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final String topDishName =
        sortedDishes.isNotEmpty ? sortedDishes.first.key : 'لا توجد مبيعات بعد';
    final int topDishCount =
        sortedDishes.isNotEmpty ? sortedDishes.first.value : 0;

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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: AppShadows.glow(
                  const Color(0xFF8B5CF6),
                  opacity: 0.3,
                ),
              ),
              child: const Icon(
                Icons.query_stats_rounded,
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
                  'الملخص التنفيذي للمالك (Owner Digest)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'مؤشرات الأداء اللحظية، الأرباح، والرقابة على الشيفتات',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ConstrainedContentView(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Top Highlights Banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'إجمالي صافي مبيعات اليوم',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFF10B981),
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'مباشر',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.formatCurrency(totalSales),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWhiteStat(
                        'عدد الطلبات',
                        '${completedOrders.length} طلب',
                      ),
                      _buildWhiteStat(
                        'متوسط الفاتورة',
                        Formatters.formatCurrency(avgTicket),
                      ),
                      _buildWhiteStat(
                        'مجمل الربح التقديري',
                        Formatters.formatCurrency(grossProfit),
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Share to WhatsApp / Telegram Action Card
            AnimatedPressCard(
              onTap:
                  () => _shareExecutiveReport(
                    context,
                    totalSales: totalSales,
                    ordersCount: completedOrders.length,
                    avgTicket: avgTicket,
                    grossProfit: grossProfit,
                    foodCostPct: foodCostPct,
                    wasteCost: totalWasteCost,
                    cashSales: cashSales,
                    cardSales: cardSales,
                    topDish: '$topDishName ($topDishCount طلب)',
                  ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadows.subtle,
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مشاركة التقرير اليومي للمالك (WhatsApp / SMS)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'توليد رسالة ملخصة ومنسقة بضغطة زر للإرسال الفوري',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2-Column Breakdown Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'تكلفة الطعام (Food Cost)',
                    value: '${foodCostPct.toStringAsFixed(1)}%',
                    subtitle:
                        'التكلفة: ${Formatters.formatCurrency(totalEstimatedFoodCost)}',
                    icon: Icons.pie_chart_rounded,
                    color:
                        foodCostPct <= 35
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'الهالك والتالف (Waste)',
                    value: Formatters.formatCurrency(totalWasteCost),
                    subtitle: 'خسائر مسجلة اليوم',
                    icon: Icons.delete_sweep_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'الأكثر مبيعاً اليوم 🌟',
                    value: topDishName,
                    subtitle: '$topDishCount طلب مباع',
                    icon: Icons.star_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    title: 'حالة درج الكاش (Shift)',
                    value:
                        activeShift != null
                            ? (activeDiscrepancy == null
                                ? 'شيفت مفتوح'
                                : (activeDiscrepancy == 0
                                    ? 'مطابق تماماً'
                                    : (activeDiscrepancy < 0
                                        ? 'عجز ${Formatters.formatCurrency(activeDiscrepancy.abs())}'
                                        : 'زيادة ${Formatters.formatCurrency(activeDiscrepancy)}')))
                            : 'لا يوجد شيفت نشط',
                    subtitle:
                        activeShift != null
                            ? 'الكاشير: ${activeShift.cashierName}'
                            : 'جميع الشيفتات مغلقة',
                    icon: Icons.point_of_sale_rounded,
                    color:
                        activeDiscrepancy == null || activeDiscrepancy >= 0
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Payment Methods Breakdown Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color:
                    isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'توزيع قنوات الدفع النقدية والإلكترونية',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildPaymentRow(
                    '💵 نقدًا (Cash):',
                    cashSales,
                    totalSales,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 6),
                  _buildPaymentRow(
                    '💳 بطاقات وفيزا (Card):',
                    cardSales,
                    totalSales,
                    const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 6),
                  _buildPaymentRow(
                    '📱 محافظ إلكترونية (Wallet):',
                    walletSales,
                    totalSales,
                    const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
    String label,
    double amount,
    double total,
    Color color,
  ) {
    final pct = total > 0 ? (amount / total) * 100.0 : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? (amount / total) : 0,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              color: color,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${Formatters.formatCurrency(amount)} (${pct.toStringAsFixed(0)}%)',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _shareExecutiveReport(
    BuildContext context, {
    required double totalSales,
    required int ordersCount,
    required double avgTicket,
    required double grossProfit,
    required double foodCostPct,
    required double wasteCost,
    required double cashSales,
    required double cardSales,
    required String topDish,
  }) {
    final nowStr = Formatters.formatDateTime(DateTime.now());
    final reportText = '''
🍽️ *تقرير الأداء اليومي لمطعم ليالي المحروسة*
📅 التاريخ: $nowStr
━━━━━━━━━━━━━━━━━━━━
💰 *إجمالي المبيعات:* ${Formatters.formatCurrency(totalSales)}
🧾 *عدد الطلبات:* $ordersCount طلب
🎯 *متوسط الفاتورة:* ${Formatters.formatCurrency(avgTicket)}
━━━━━━━━━━━━━━━━━━━━
💵 *الكاش المورد:* ${Formatters.formatCurrency(cashSales)}
💳 *المدفوعات الإلكترونية:* ${Formatters.formatCurrency(cardSales)}
━━━━━━━━━━━━━━━━━━━━
📊 *تكلفة الطعام (Food Cost):* ${foodCostPct.toStringAsFixed(1)}%
✨ *مجمل الربح التقديري:* ${Formatters.formatCurrency(grossProfit)}
⚠️ *إجمالي الهالك والتالف:* ${Formatters.formatCurrency(wasteCost)}
🌟 *الطبق الأكثر طلباً:* $topDish
━━━━━━━━━━━━━━━━━━━━
🚀 *تم التوليد آلياً عبر نظام إدارة المطاعم الذكي*
''';

    Clipboard.setData(ClipboardData(text: reportText));

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text('تم نسخ التقرير للمالك'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تم نسخ نص التقرير التنفيذي للحافظة، ويمكنك لصقه وإرساله الآن على الواتساب أو التيليجرام:',
                  style: TextStyle(fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reportText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('تم'),
              ),
            ],
          ),
    );
  }
}
