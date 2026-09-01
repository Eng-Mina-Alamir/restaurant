import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_schemes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/animated_press_card.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../../inventory/presentation/controllers/recipe_controller.dart';
import '../../../menu/presentation/controllers/menu_controller.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../domain/entities/menu_engineering_item.dart';

/// Interactive F&B Menu Engineering Matrix (Stars, Plowhorses, Puzzles, Dogs)
class MenuEngineeringPage extends ConsumerStatefulWidget {
  const MenuEngineeringPage({super.key});

  @override
  ConsumerState<MenuEngineeringPage> createState() =>
      _MenuEngineeringPageState();
}

class _MenuEngineeringPageState extends ConsumerState<MenuEngineeringPage> {
  MenuEngineeringCategory? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final menuState = ref.watch(menuControllerProvider);
    final recipesState = ref.watch(recipeControllerProvider);
    final orders = ref.watch(ordersControllerProvider);

    final menuItems = menuState.valueOrNull?.items ?? [];
    final recipes = recipesState.valueOrNull ?? [];

    // 1. Calculate sales count per menu item from completed orders
    final Map<String, int> salesCountMap = {};
    for (final order in orders) {
      for (final item in order.items) {
        final id = item.menuItem.id;
        salesCountMap[id] = (salesCountMap[id] ?? 0) + item.quantity;
      }
    }

    // 2. Build analysis items
    final List<MenuEngineeringItem> analysisItems = [];
    double totalMarginSum = 0.0;
    int totalSalesCountSum = 0;

    for (final item in menuItems) {
      final recipeMatch = recipes.where(
        (r) =>
            r.menuItemId == item.id ||
            r.menuItemName.trim().toLowerCase() ==
                item.name.trim().toLowerCase(),
      );

      final double foodCost =
          recipeMatch.isNotEmpty
              ? recipeMatch.first.totalFoodCost
              : (item.price * 0.33); // realistic 33% fallback if no recipe configured

      final int salesCount =
          salesCountMap[item.id] ?? (item.orderCount ?? 0);
      final grossMargin = (item.price - foodCost).clamp(0.0, 999999.0);
      final foodCostPct =
          item.price > 0 ? (foodCost / item.price) * 100.0 : 0.0;

      totalMarginSum += grossMargin;
      totalSalesCountSum += salesCount;

      analysisItems.add(
        MenuEngineeringItem(
          menuItemId: item.id,
          name: item.name,
          category: item.categoryId,
          sellingPrice: item.price,
          foodCost: foodCost,
          salesCount: salesCount,
          grossMargin: grossMargin,
          foodCostPercentage: foodCostPct,
          classification: MenuEngineeringCategory.star, // temporary placeholder
        ),
      );
    }

    // 3. Benchmarks (Averages)
    final double avgMargin =
        analysisItems.isNotEmpty ? totalMarginSum / analysisItems.length : 0.0;
    final double avgSalesCount =
        analysisItems.isNotEmpty
            ? totalSalesCountSum / analysisItems.length
            : 0.0;

    // 4. Classify each item against benchmarks
    final List<MenuEngineeringItem> classifiedItems =
        analysisItems.map((item) {
          final isHighProfit = item.grossMargin >= avgMargin;
          final isHighVolume = item.salesCount >= avgSalesCount;

          MenuEngineeringCategory category;
          if (isHighProfit && isHighVolume) {
            category = MenuEngineeringCategory.star;
          } else if (!isHighProfit && isHighVolume) {
            category = MenuEngineeringCategory.plowhorse;
          } else if (isHighProfit && !isHighVolume) {
            category = MenuEngineeringCategory.puzzle;
          } else {
            category = MenuEngineeringCategory.dog;
          }

          return MenuEngineeringItem(
            menuItemId: item.menuItemId,
            name: item.name,
            category: item.category,
            sellingPrice: item.sellingPrice,
            foodCost: item.foodCost,
            salesCount: item.salesCount,
            grossMargin: item.grossMargin,
            foodCostPercentage: item.foodCostPercentage,
            classification: category,
          );
        }).toList();

    // 5. Filter list
    final filteredItems =
        _selectedFilter == null
            ? classifiedItems
            : classifiedItems
                .where((i) => i.classification == _selectedFilter)
                .toList();

    // Counts
    final starCount =
        classifiedItems
            .where((i) => i.classification == MenuEngineeringCategory.star)
            .length;
    final plowhorseCount =
        classifiedItems
            .where((i) => i.classification == MenuEngineeringCategory.plowhorse)
            .length;
    final puzzleCount =
        classifiedItems
            .where((i) => i.classification == MenuEngineeringCategory.puzzle)
            .length;
    final dogCount =
        classifiedItems
            .where((i) => i.classification == MenuEngineeringCategory.dog)
            .length;

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
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: AppShadows.glow(AppColors.brand, opacity: 0.3),
              ),
              child: const Icon(
                Icons.analytics_rounded,
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
                  'مصفوفة هندسة المنيو (F&B)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'تحليل ربحية وشعبية أطباق المطعم لاتخاذ قرارات التسعير',
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
            // Overview Info Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.brand.withValues(alpha: isDark ? 0.2 : 0.08),
                    const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.05),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.brand.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFFF59E0B),
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'كيف تقرأ مصفوفة المنيو؟',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'السيستم يقارن هامش ربح كل وجبة ومعدل مبيعاتها بمتوسط المطعم (متوسط الربح: ${Formatters.formatCurrency(avgMargin)} - متوسط المبيعات: ${avgSalesCount.toStringAsFixed(1)} طلب).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 4 Quadrants Grid / Filter Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.4,
              children: [
                _buildQuadrantCard(
                  category: MenuEngineeringCategory.star,
                  count: starCount,
                  color: const Color(0xFF10B981),
                  icon: Icons.star_rounded,
                  isSelected: _selectedFilter == MenuEngineeringCategory.star,
                  onTap: () => _toggleFilter(MenuEngineeringCategory.star),
                ),
                _buildQuadrantCard(
                  category: MenuEngineeringCategory.plowhorse,
                  count: plowhorseCount,
                  color: const Color(0xFF3B82F6),
                  icon: Icons.trending_up_rounded,
                  isSelected:
                      _selectedFilter == MenuEngineeringCategory.plowhorse,
                  onTap: () => _toggleFilter(MenuEngineeringCategory.plowhorse),
                ),
                _buildQuadrantCard(
                  category: MenuEngineeringCategory.puzzle,
                  count: puzzleCount,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.extension_rounded,
                  isSelected: _selectedFilter == MenuEngineeringCategory.puzzle,
                  onTap: () => _toggleFilter(MenuEngineeringCategory.puzzle),
                ),
                _buildQuadrantCard(
                  category: MenuEngineeringCategory.dog,
                  count: dogCount,
                  color: const Color(0xFFEF4444),
                  icon: Icons.warning_amber_rounded,
                  isSelected: _selectedFilter == MenuEngineeringCategory.dog,
                  onTap: () => _toggleFilter(MenuEngineeringCategory.dog),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedFilter == null
                      ? 'جميع أطباق المنيو (${classifiedItems.length})'
                      : '${_selectedFilter!.titleAr} (${filteredItems.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_selectedFilter != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedFilter = null),
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    label: const Text('عرض الكل'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Items List
            if (filteredItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Text(
                    'لا توجد أطباق في هذا التصنيف حالياً',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...filteredItems.map((item) => _buildDishAnalysisTile(item)),
          ],
        ),
      ),
    );
  }

  void _toggleFilter(MenuEngineeringCategory category) {
    setState(() {
      if (_selectedFilter == category) {
        _selectedFilter = null;
      } else {
        _selectedFilter = category;
      }
    });
  }

  Widget _buildQuadrantCard({
    required MenuEngineeringCategory category,
    required int count,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedPressCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? color.withValues(alpha: isDark ? 0.25 : 0.15)
                  : (isDark ? colorScheme.surfaceContainerHighest : Colors.white),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? color : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadows.subtle : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Text(
                  '$count',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.titleAr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isSelected ? color : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  category.descriptionAr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDishAnalysisTile(MenuEngineeringItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Color badgeColor;
    switch (item.classification) {
      case MenuEngineeringCategory.star:
        badgeColor = const Color(0xFF10B981);
        break;
      case MenuEngineeringCategory.plowhorse:
        badgeColor = const Color(0xFF3B82F6);
        break;
      case MenuEngineeringCategory.puzzle:
        badgeColor = const Color(0xFFF59E0B);
        break;
      case MenuEngineeringCategory.dog:
        badgeColor = const Color(0xFFEF4444);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'المبيعات: ${item.salesCount} طلب | الإيراد: ${Formatters.formatCurrency(item.totalRevenue)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  item.classification.titleAr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric(
                label: 'سعر البيع',
                value: Formatters.formatCurrency(item.sellingPrice),
              ),
              _buildMetric(
                label: 'تكلفة الطبق (Food Cost)',
                value:
                    '${Formatters.formatCurrency(item.foodCost)} (${item.foodCostPercentage.toStringAsFixed(1)}%)',
                valueColor:
                    item.foodCostPercentage > 38 ? const Color(0xFFEF4444) : null,
              ),
              _buildMetric(
                label: 'هامش الربح للطبق',
                value: Formatters.formatCurrency(item.grossMargin),
                valueColor: const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates_outlined, size: 14, color: badgeColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'الاستراتيجية المقترحة: ${item.classification.strategyAr}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : colorScheme.onSurface,
                      fontSize: 10.5,
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

  Widget _buildMetric({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
