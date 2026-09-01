import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_schemes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/presentation/controllers/menu_controller.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/entities/recipe_item_entity.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/recipe_controller.dart';

/// Recipe & Bill of Materials (BOM) Management Page
class RecipeManagementPage extends ConsumerStatefulWidget {
  const RecipeManagementPage({super.key});

  @override
  ConsumerState<RecipeManagementPage> createState() =>
      _RecipeManagementPageState();
}

class _RecipeManagementPageState extends ConsumerState<RecipeManagementPage> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final menuState = ref.watch(menuControllerProvider);
    final recipesState = ref.watch(recipeControllerProvider);
    final inventoryState = ref.watch(inventoryControllerProvider);

    final menuItems = menuState.valueOrNull?.items ?? [];
    final categories = menuState.valueOrNull?.categories ?? [];
    final recipes = recipesState.valueOrNull ?? [];
    final inventoryItems = inventoryState.valueOrNull ?? [];

    final filteredMenuItems =
        _selectedCategory == null
            ? menuItems
            : menuItems.where((i) => i.categoryId == _selectedCategory).toList();

    final avgFoodCost = ref
        .read(recipeControllerProvider.notifier)
        .averageFoodCostPercentage;

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
                Icons.menu_book_rounded,
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
                  'إدارة الوصفات وتكلفة الأطباق (BOM)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'ربط أطباق المنيو بالمخزون وحساب تكلفة الخامات (Food Cost)',
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
            // KPI Summary Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.brand.withValues(alpha: isDark ? 0.25 : 0.1),
                    const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.brand.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    label: 'متوسط تكلفة الطعام',
                    value: '${avgFoodCost.toStringAsFixed(1)}%',
                    sublabel: 'المستهدف: 28% - 35%',
                    color:
                        avgFoodCost <= 35
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                  ),
                  Container(
                    height: 45,
                    width: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  _buildSummaryItem(
                    label: 'الوصفات المكتملة',
                    value: '${recipes.length} / ${menuItems.length}',
                    sublabel: 'أطباق مربوطة بالمخزن',
                    color: AppColors.brand,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('الكل'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ...categories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected:
                            (_) => setState(() => _selectedCategory = cat),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Menu Items Recipe Cards
            if (filteredMenuItems.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: Text('لا توجد أصناف في هذا القسم')),
              )
            else
              ...filteredMenuItems.map((item) {
                final recipe = recipes.firstWhere(
                  (r) =>
                      r.menuItemId == item.id ||
                      r.menuItemName.trim().toLowerCase() ==
                          item.name.trim().toLowerCase(),
                  orElse:
                      () => MenuItemRecipeEntity(
                        menuItemId: item.id,
                        menuItemName: item.name,
                        menuItemPrice: item.price,
                        ingredients: const [],
                      ),
                );

                return _buildRecipeCard(item, recipe, inventoryItems);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required String sublabel,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          sublabel,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(
    MenuItem item,
    MenuItemRecipeEntity recipe,
    List<InventoryItemEntity> inventoryItems,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final hasIngredients = recipe.ingredients.isNotEmpty;
    final foodCost = recipe.totalFoodCost;
    final margin = recipe.grossMargin;
    final foodCostPct = recipe.foodCostPercentage;

    Color statusColor;
    if (foodCostPct <= 0) {
      statusColor = Colors.grey;
    } else if (foodCostPct <= 32) {
      statusColor = const Color(0xFF10B981);
    } else if (foodCostPct <= 38) {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFFEF4444);
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
                      'سعر البيع: ${Formatters.formatCurrency(item.price)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed:
                    () => _showEditRecipeDialog(item, recipe, inventoryItems),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: Text(hasIngredients ? 'تعديل المكونات' : 'إضافة وصفة'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Recipe Metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricBlock(
                label: 'تكلفة المكونات (COGS)',
                value:
                    hasIngredients
                        ? Formatters.formatCurrency(foodCost)
                        : 'غير محدد',
                valueColor: hasIngredients ? null : Colors.grey,
              ),
              _buildMetricBlock(
                label: 'نسبة تكلفة الطعام',
                value:
                    hasIngredients
                        ? '${foodCostPct.toStringAsFixed(1)}%'
                        : '--',
                valueColor: statusColor,
              ),
              _buildMetricBlock(
                label: 'هامش الربح',
                value:
                    hasIngredients
                        ? Formatters.formatCurrency(margin)
                        : '--',
                valueColor:
                    hasIngredients ? const Color(0xFF10B981) : Colors.grey,
              ),
            ],
          ),

          if (hasIngredients) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المكونات الخام المخصومة لكل وجبة (${recipe.ingredients.length}):',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children:
                        recipe.ingredients.map((ing) {
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                            label: Text(
                              '${ing.inventoryItemName} (${ing.quantity} ${ing.unit})',
                              style: const TextStyle(fontSize: 10.5),
                            ),
                            backgroundColor: colorScheme.surfaceContainerHigh,
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricBlock({
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

  void _showEditRecipeDialog(
    MenuItem item,
    MenuItemRecipeEntity currentRecipe,
    List<InventoryItemEntity> inventoryItems,
  ) {
    final List<RecipeIngredientEntity> ingredientsList =
        List.from(currentRecipe.ingredients);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setDialogState) {
            final theme = Theme.of(modalCtx);
            final colorScheme = theme.colorScheme;

            final totalCost = ingredientsList.fold<double>(
              0.0,
              (s, i) => s + i.lineCost,
            );
            final foodCostPct =
                item.price > 0 ? (totalCost / item.price) * 100.0 : 0.0;

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.blender_rounded, color: AppColors.brand),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'تركيب وصفة: ${item.name}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price & Cost Live Preview Box
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: AppColors.brand.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'سعر البيع: ${Formatters.formatCurrency(item.price)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                            Text(
                              'التكلفة: ${Formatters.formatCurrency(totalCost)} (${foodCostPct.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                                color:
                                    foodCostPct <= 35
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Text(
                        'المكونات الخام:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      if (ingredientsList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'لم يتم إضافة مكونات بعد',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...ingredientsList.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final ing = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${ing.inventoryItemName} (${ing.quantity} ${ing.unit})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  Formatters.formatCurrency(ing.lineCost),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setDialogState(() {
                                      ingredientsList.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),

                      const SizedBox(height: AppSpacing.sm),
                      // Add Ingredient Button
                      OutlinedButton.icon(
                        onPressed: () {
                          _showAddIngredientSubDialog(
                            modalCtx,
                            inventoryItems,
                            (newIngredient) {
                              setDialogState(() {
                                ingredientsList.add(newIngredient);
                              });
                            },
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('إضافة مكون خام من المخزن'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () async {
                    final newRecipe = MenuItemRecipeEntity(
                      menuItemId: item.id,
                      menuItemName: item.name,
                      menuItemPrice: item.price,
                      ingredients: ingredientsList,
                      lastUpdated: DateTime.now(),
                    );
                    await ref
                        .read(recipeControllerProvider.notifier)
                        .saveRecipe(newRecipe);
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  },
                  child: const Text('حفظ الوصفة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddIngredientSubDialog(
    BuildContext parentCtx,
    List<InventoryItemEntity> inventoryItems,
    ValueChanged<RecipeIngredientEntity> onAdded,
  ) {
    if (inventoryItems.isEmpty) {
      ScaffoldMessenger.of(parentCtx).showSnackBar(
        const SnackBar(content: Text('لا توجد عناصر بالمخزن. أضف عناصر أولاً.')),
      );
      return;
    }

    InventoryItemEntity selectedItem = inventoryItems.first;
    final qtyController = TextEditingController(text: '0.1');

    showDialog(
      context: parentCtx,
      builder: (subCtx) {
        return StatefulBuilder(
          builder: (ctx, setSubState) {
            return AlertDialog(
              title: const Text('اختر المكون والكمية'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<InventoryItemEntity>(
                    initialValue: selectedItem,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'عنصر المخزون',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        inventoryItems.map((inv) {
                          return DropdownMenuItem(
                            value: inv,
                            child: Text(
                              '${inv.name} (${Formatters.formatCurrency(inv.costPerUnit)} / ${inv.unit})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSubState(() => selectedItem = val);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: qtyController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'الكمية المستخدمة بالـ (${selectedItem.unit})',
                      border: const OutlineInputBorder(),
                      helperText: 'مثلاً 0.25 كغ للحم، أو 1 للرغيف',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(subCtx),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
                    final qty =
                        double.tryParse(qtyController.text.trim()) ?? 0.0;
                    if (qty <= 0) return;

                    final ing = RecipeIngredientEntity(
                      inventoryItemId: selectedItem.id,
                      inventoryItemName: selectedItem.name,
                      quantity: qty,
                      unit: selectedItem.unit,
                      costPerUnit: selectedItem.costPerUnit,
                    );
                    onAdded(ing);
                    Navigator.pop(subCtx);
                  },
                  child: const Text('إضافة'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
