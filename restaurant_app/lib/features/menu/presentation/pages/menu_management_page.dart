import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/entities/menu_item.dart';
import '../controllers/menu_controller.dart';

/// Full CRUD management interface for restaurant menu items and categories.
class MenuManagementPage extends ConsumerStatefulWidget {
  const MenuManagementPage({super.key});

  @override
  ConsumerState<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends ConsumerState<MenuManagementPage> {
  String _selectedCategory = kAllCategoriesFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة القائمة والأصناف'),
        actions: [
          IconButton(
            tooltip: 'إضافة قسم جديد',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _showAddCategoryDialog(context),
          ),
          IconButton(
            tooltip: 'إضافة صنف جديد',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showItemDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('إضافة صنف'),
      ),
      body: menuAsync.when(
        loading: () => const _MenuManagementSkeleton(),
        error: (error, _) => ErrorState(
          message: AppConstants.errorLoadingData,
          errorDetail: error,
          onRetry: () => ref.refresh(menuControllerProvider),
        ),
        data: (menu) {
          final items = filterMenu(
            menu,
            _selectedCategory,
            _searchQuery,
            MenuDietFilter.none,
          );

          return Column(
            children: [
              // Search & summary bar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'البحث في القائمة...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Categories Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('الكل (${menu.items.length})'),
                      selected: _selectedCategory == kAllCategoriesFilter,
                      onSelected: (_) => setState(
                        () => _selectedCategory = kAllCategoriesFilter,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    for (final category in menu.categories)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
                        child: ChoiceChip(
                          label: Text(
                            '$category (${menu.itemsIn(category).length})',
                          ),
                          selected: _selectedCategory == category,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = category),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Items List
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(
                        message: 'لا توجد أصناف مطابقة',
                        icon: Icons.restaurant_menu,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.xs,
                          AppSpacing.md,
                          80,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    item.name,
                                                    style: theme
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ),
                                                if (item.isVegetarian)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                          horizontal: 4,
                                                        ),
                                                    child: Icon(
                                                      Icons.eco,
                                                      size: 16,
                                                      color:
                                                          StatusColors.tone(
                                                        SemanticTone.success,
                                                        brightness,
                                                      ),
                                                    ),
                                                  ),
                                                if (item.isSpicy)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                          horizontal: 4,
                                                        ),
                                                    child: Icon(
                                                      Icons
                                                          .local_fire_department,
                                                      size: 16,
                                                      color:
                                                          StatusColors.tone(
                                                        SemanticTone.danger,
                                                        brightness,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.description,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        Formatters.formatCurrency(item.price),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: AppSpacing.md),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Switch.adaptive(
                                            value: item.isAvailable,
                                            onChanged: (val) {
                                              ref
                                                  .read(
                                                    menuControllerProvider
                                                        .notifier,
                                                  )
                                                  .toggleAvailability(
                                                    item.id,
                                                    val,
                                                  );
                                            },
                                          ),
                                          Text(
                                            item.isAvailable
                                                ? 'متوفر'
                                                : 'غير متوفر',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: StatusColors.tone(
                                                    item.isAvailable
                                                        ? SemanticTone.success
                                                        : SemanticTone.danger,
                                                    brightness,
                                                  ),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            tooltip: 'تعديل',
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 20,
                                            ),
                                            onPressed: () => _showItemDialog(
                                              context,
                                              existingItem: item,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: AppConstants.delete,
                                            icon: Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: StatusColors.tone(
                                                SemanticTone.danger,
                                                brightness,
                                              ),
                                            ),
                                            onPressed: () =>
                                                _confirmDelete(context, item),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة قسم جديد'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'اسم القسم (مثال: برجر، مشروبات، حلويات)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppConstants.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(menuControllerProvider.notifier).addCategory(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showItemDialog(BuildContext context, {MenuItem? existingItem}) {
    final menu = ref.read(menuControllerProvider).valueOrNull;
    final categories = menu?.categories ?? ['عام'];

    final nameCtrl = TextEditingController(text: existingItem?.name ?? '');
    final descCtrl = TextEditingController(
      text: existingItem?.description ?? '',
    );
    final priceCtrl = TextEditingController(
      text: existingItem != null ? existingItem.price.toString() : '',
    );
    final prepCtrl = TextEditingController(
      text: existingItem?.preparationTime != null
          ? existingItem!.preparationTime!.toStringAsFixed(0)
          : '15',
    );

    String category =
        existingItem?.categoryId ??
        (_selectedCategory != kAllCategoriesFilter
            ? _selectedCategory
            : (categories.isNotEmpty ? categories.first : 'عام'));
    bool isVeg = existingItem?.isVegetarian ?? false;
    bool isSpicy = existingItem?.isSpicy ?? false;
    bool isAvailable = existingItem?.isAvailable ?? true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      existingItem == null
                          ? 'إضافة صنف جديد'
                          : 'تعديل صنف: ${existingItem.name}',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      tooltip: 'إغلاق',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الوجبة / الصنف *',
                    prefixIcon: Icon(Icons.fastfood_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: categories.contains(category)
                      ? category
                      : categories.first,
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => category = val);
                  },
                  decoration: const InputDecoration(
                    labelText: 'القسم *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'الوصف ومكونات الصنف',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'السعر (ر.س) *',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: prepCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'مدة التحضير (دقيقة)',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  title: const Text('وجبة نباتية (Vegetarian)'),
                  value: isVeg,
                  onChanged: (val) => setSheetState(() => isVeg = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('صنف حار (Spicy)'),
                  value: isSpicy,
                  onChanged: (val) =>
                      setSheetState(() => isSpicy = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('متوفر للطلب حالياً'),
                  value: isAvailable,
                  onChanged: (val) =>
                      setSheetState(() => isAvailable = val ?? true),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text) ?? 0.0;
                    if (name.isEmpty || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('يرجى كتابة الاسم وتحديد سعر صالح'),
                        ),
                      );
                      return;
                    }

                    final prepTime = double.tryParse(prepCtrl.text) ?? 15.0;

                    if (existingItem == null) {
                      final newItem = MenuItem(
                        id: '0',
                        categoryId: category,
                        name: name,
                        description: descCtrl.text.trim(),
                        price: price,
                        isAvailable: isAvailable,
                        isVegetarian: isVeg,
                        isSpicy: isSpicy,
                        preparationTime: prepTime,
                        rating: 4.8,
                        orderCount: 0,
                      );
                      ref
                          .read(menuControllerProvider.notifier)
                          .addItem(newItem);
                    } else {
                      final updated = existingItem.copyWith(
                        categoryId: category,
                        name: name,
                        description: descCtrl.text.trim(),
                        price: price,
                        isAvailable: isAvailable,
                        isVegetarian: isVeg,
                        isSpicy: isSpicy,
                        preparationTime: prepTime,
                      );
                      ref
                          .read(menuControllerProvider.notifier)
                          .updateItem(updated);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    existingItem == null ? 'حفظ وإضافة الصنف' : 'حفظ التعديلات',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MenuItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الصنف'),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف "${item.name}" من القائمة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppConstants.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              ref.read(menuControllerProvider.notifier).deleteItem(item.id);
              Navigator.pop(ctx);
            },
            child: const Text(AppConstants.delete),
          ),
        ],
      ),
    );
  }
}

// ── Loading skeleton ─────────────────────────────────────────────────────────

/// Shimmer placeholder mirroring the management layout while the menu loads:
/// search field, category chip strip and item-card placeholders with
/// title/description lines beside the price plus availability footer controls.
class _MenuManagementSkeleton extends StatelessWidget {
  const _MenuManagementSkeleton();

  /// Varied widths echo category chip label lengths.
  static const List<double> _chipWidths = <double>[92, 76, 104, 68];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & summary bar.
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: SkeletonBox(
            width: double.infinity,
            height: 44,
            borderRadius: AppRadius.md,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Categories row.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              for (var i = 0; i < _chipWidths.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                SkeletonBox(
                  width: _chipWidths[i],
                  height: 32,
                  borderRadius: AppRadius.full,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Items list.
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              80,
            ),
            itemCount: 5,
            itemBuilder: (context, index) => const _MenuItemCardSkeleton(),
          ),
        ),
      ],
    );
  }
}

/// Shimmer stand-in for one menu item card: title/description lines beside the
/// price, then availability switch and edit/delete icon circles.
class _MenuItemCardSkeleton extends StatelessWidget {
  const _MenuItemCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        width: double.infinity,
                        height: 16,
                        borderRadius: AppRadius.sm,
                      ),
                      SizedBox(height: 2),
                      SkeletonBox(width: 200, height: 11, borderRadius: AppRadius.xs),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                SkeletonBox(width: 64, height: 16, borderRadius: AppRadius.sm),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SkeletonBox(
                      width: 34,
                      height: 20,
                      borderRadius: AppRadius.full,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    SkeletonBox(width: 52, height: 12, borderRadius: AppRadius.xs),
                  ],
                ),
                Row(
                  children: [
                    SkeletonCircle(size: 24),
                    SizedBox(width: AppSpacing.sm),
                    SkeletonCircle(size: 24),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
