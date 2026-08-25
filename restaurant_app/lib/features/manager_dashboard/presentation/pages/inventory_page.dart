import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/shimmer_loading.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../inventory/domain/entities/inventory_item_entity.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../data/services/report_export_service.dart';

/// Full-featured Manager Inventory Management Page.
class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  String _searchQuery = '';
  StockStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inventoryAsync = ref.watch(inventoryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المخزون والتوريد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'تصدير تقرير المخزون CSV',
            onPressed: () {
              final items = inventoryAsync.valueOrNull ?? [];
              if (items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لا توجد عناصر في المخزون لتصديرها'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              final exportService = ref.read(reportExportServiceProvider);
              final _ = exportService.generateInventoryCsv(items);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم تصدير تقرير ${items.length} صنف بنجاح!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          PopupMenuButton<StockStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'تصفية حسب الحالة',
            onSelected: (val) => setState(() => _filterStatus = val),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('الكل')),
              PopupMenuItem(
                value: StockStatus.outOfStock,
                child: StatusBadge.stock(StockStatus.outOfStock),
              ),
              PopupMenuItem(
                value: StockStatus.low,
                child: StatusBadge.stock(StockStatus.low),
              ),
              PopupMenuItem(
                value: StockStatus.sufficient,
                child: StatusBadge.stock(StockStatus.sufficient),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(inventoryControllerProvider.notifier).load(),
        child: inventoryAsync.when(
          loading: () => const _InventorySkeletonList(),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: ErrorState(
                  message: AppConstants.errorLoadingData,
                  errorDetail: err,
                  onRetry: () =>
                      ref.read(inventoryControllerProvider.notifier).load(),
                ),
              ),
            ],
          ),
          data: (allItems) {
            final filtered = allItems.where((item) {
              final matchesSearch =
                  item.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  item.category.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
              final matchesStatus =
                  _filterStatus == null || item.status == _filterStatus;
              return matchesSearch && matchesStatus;
            }).toList();

            final outOfStock = allItems
                .where((i) => i.status == StockStatus.outOfStock)
                .length;
            final low = allItems
                .where((i) => i.status == StockStatus.low)
                .length;
            final totalValue = allItems.fold<double>(
              0,
              (sum, i) => sum + i.totalValue,
            );

            return Column(
              children: [
                // Summary cards
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      _SummaryChip(
                        label: 'منتهية',
                        count: '$outOfStock',
                        color: colorScheme.error,
                        onTap: () => setState(
                          () => _filterStatus = outOfStock > 0
                              ? StockStatus.outOfStock
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _SummaryChip(
                        label: 'منخفضة',
                        count: '$low',
                        color: Colors.orange,
                        onTap: () => setState(
                          () =>
                              _filterStatus = low > 0 ? StockStatus.low : null,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'إجمالي القيمة: ${Formatters.formatCurrency(totalValue)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'بحث في أصناف المخزون والفئات...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (q) => setState(() => _searchQuery = q),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Items list
                Expanded(
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 56,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'لا توجد أصناف مطابقة للبحث أو التصفية',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.xl * 2,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) => _InventoryCard(
                            item: filtered[i],
                            onRestock: () =>
                                _showRestockDialog(context, filtered[i]),
                            onEdit: () => _showEditDialog(context, filtered[i]),
                            onDelete: () =>
                                _showDeleteDialog(context, filtered[i]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('إضافة صنف جديد'),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'كغ');
    final thresholdCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_box_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('إضافة صنف مخزون جديد'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم الصنف *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(
                  labelText: 'الفئة (لحوم، خضروات، ...) *',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stockCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'الكمية الحالية *',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: unitCtrl,
                      decoration: const InputDecoration(
                        labelText: 'الوحدة (كغ، لتر، كرتون)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: thresholdCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'حد التنبيه الأدنى *',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: costCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'التكلفة للوحدة (ر.س) *',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppConstants.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final cat = catCtrl.text.trim();
              final stock = double.tryParse(stockCtrl.text.trim()) ?? 0.0;
              final unit = unitCtrl.text.trim().isEmpty
                  ? 'كغ'
                  : unitCtrl.text.trim();
              final threshold =
                  double.tryParse(thresholdCtrl.text.trim()) ?? 0.0;
              final cost = double.tryParse(costCtrl.text.trim()) ?? 0.0;

              if (name.isEmpty || cat.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('يرجى ملء جميع الحقول المطلوبة'),
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              final ok = await ref
                  .read(inventoryControllerProvider.notifier)
                  .addItem(
                    name: name,
                    category: cat,
                    currentStock: stock,
                    unit: unit,
                    minThreshold: threshold,
                    costPerUnit: cost,
                  );

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'تمت إضافة الصنف "$name" بنجاح' : 'تعذر إضافة الصنف',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showRestockDialog(BuildContext context, InventoryItemEntity item) {
    final messenger = ScaffoldMessenger.of(context);
    final amountCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إعادة تخزين: ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الكمية الحالية: ${item.currentStock} ${item.unit}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'الكمية المضافة (${item.unit})',
                hintText: 'مثال: 10',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppConstants.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (amount <= 0) return;
              Navigator.pop(ctx);
              await ref
                  .read(inventoryControllerProvider.notifier)
                  .restock(item.id, amount);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'تمت إضافة $amount ${item.unit} إلى ${item.name}',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('تأكيد الإضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, InventoryItemEntity item) {
    final messenger = ScaffoldMessenger.of(context);
    final stockCtrl = TextEditingController(text: '${item.currentStock}');
    final thresholdCtrl = TextEditingController(text: '${item.minThreshold}');
    final costCtrl = TextEditingController(text: '${item.costPerUnit}');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل: ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'الكمية الحالية (${item.unit})',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: thresholdCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'حد التنبيه الأدنى (${item.unit})',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: costCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'تكلفة الوحدة (ر.س)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppConstants.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final stock =
                  double.tryParse(stockCtrl.text.trim()) ?? item.currentStock;
              final threshold =
                  double.tryParse(thresholdCtrl.text.trim()) ??
                  item.minThreshold;
              final cost =
                  double.tryParse(costCtrl.text.trim()) ?? item.costPerUnit;

              Navigator.pop(ctx);
              await ref
                  .read(inventoryControllerProvider.notifier)
                  .updateItem(
                    item.copyWith(
                      currentStock: stock,
                      minThreshold: threshold,
                      costPerUnit: cost,
                    ),
                  );
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('تم تحديث بيانات الصنف بنجاح'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, InventoryItemEntity item) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الصنف من المخزون'),
        content: Text('هل أنت متأكد من رغبتك في حذف "${item.name}" نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppConstants.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(inventoryControllerProvider.notifier)
                  .deleteItem(item.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('تم حذف "${item.name}"'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(AppConstants.delete),
          ),
        ],
      ),
    );
  }
}

// ── Inventory card ─────────────────────────────────────────────────────────────

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.item,
    required this.onRestock,
    required this.onEdit,
    required this.onDelete,
  });

  final InventoryItemEntity item;
  final VoidCallback onRestock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = item.statusColor(colorScheme);
    final progress = item.minThreshold > 0
        ? (item.currentStock / (item.minThreshold * 2)).clamp(0.0, 1.0)
        : 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    item.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('تعديل الصنف'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            AppConstants.delete,
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  '${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Text(
                  'الحد الأدنى: ${item.minThreshold.toStringAsFixed(1)} ${item.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'القيمة: ${Formatters.formatCurrency(item.totalValue)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('إعادة التخزين'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onRestock,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary chip ──────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '$count $label',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventorySkeletonList extends StatelessWidget {
  const _InventorySkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl * 2,
      ),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 140, height: 18),
                  SkeletonBox(
                    width: 65,
                    height: 22,
                    borderRadius: AppRadius.full,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              SkeletonBox(width: 80, height: 12),
              SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 100, height: 14),
                  SkeletonBox(width: 90, height: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
