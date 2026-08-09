import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';

/// Stock level status for an inventory item.
enum StockStatus {
  sufficient,  // كافٍ
  low,         // منخفض
  outOfStock,  // منتهي
}

/// Represents a tracked inventory item.
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.unit,
    required this.minThreshold,
    required this.costPerUnit,
  });

  final String id;
  final String name;
  final String category;
  final double currentStock;
  final String unit;
  final double minThreshold;
  final double costPerUnit;

  StockStatus get status {
    if (currentStock <= 0) return StockStatus.outOfStock;
    if (currentStock <= minThreshold) return StockStatus.low;
    return StockStatus.sufficient;
  }

  String get statusLabel {
    switch (status) {
      case StockStatus.sufficient:
        return 'كافٍ';
      case StockStatus.low:
        return 'منخفض';
      case StockStatus.outOfStock:
        return 'منتهي';
    }
  }

  Color statusColor(ColorScheme cs) {
    switch (status) {
      case StockStatus.sufficient:
        return Colors.green;
      case StockStatus.low:
        return Colors.orange;
      case StockStatus.outOfStock:
        return cs.error;
    }
  }

  double get totalValue => currentStock * costPerUnit;
}

// ── Mock data ──────────────────────────────────────────────────────────────────

final _mockInventory = [
  const InventoryItem(
    id: 'inv-1',
    name: 'لحم بقري مفروم',
    category: 'لحوم',
    currentStock: 12,
    unit: 'كغ',
    minThreshold: 5,
    costPerUnit: 55,
  ),
  const InventoryItem(
    id: 'inv-2',
    name: 'خبز برجر',
    category: 'مخبوزات',
    currentStock: 3,
    unit: 'كرتون',
    minThreshold: 5,
    costPerUnit: 25,
  ),
  const InventoryItem(
    id: 'inv-3',
    name: 'زيت نباتي',
    category: 'مواد غذائية',
    currentStock: 0,
    unit: 'لتر',
    minThreshold: 10,
    costPerUnit: 12,
  ),
  const InventoryItem(
    id: 'inv-4',
    name: 'طماطم طازجة',
    category: 'خضروات',
    currentStock: 20,
    unit: 'كغ',
    minThreshold: 8,
    costPerUnit: 6,
  ),
  const InventoryItem(
    id: 'inv-5',
    name: 'جبن شيدر',
    category: 'ألبان',
    currentStock: 4,
    unit: 'كغ',
    minThreshold: 5,
    costPerUnit: 45,
  ),
  const InventoryItem(
    id: 'inv-6',
    name: 'دجاج مبرد',
    category: 'لحوم',
    currentStock: 25,
    unit: 'كغ',
    minThreshold: 10,
    costPerUnit: 30,
  ),
];

// ── Provider ──────────────────────────────────────────────────────────────────

final inventoryProvider =
    StateProvider<List<InventoryItem>>((ref) => _mockInventory);

// ── Page ──────────────────────────────────────────────────────────────────────

/// Manager inventory management page showing stock levels and alerts.
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
    final allItems = ref.watch(inventoryProvider);

    final filtered = allItems.where((item) {
      final matchesSearch = item.name.contains(_searchQuery) ||
          item.category.contains(_searchQuery);
      final matchesStatus =
          _filterStatus == null || item.status == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    final outOfStock = allItems.where((i) => i.status == StockStatus.outOfStock).length;
    final low = allItems.where((i) => i.status == StockStatus.low).length;
    final totalValue = allItems.fold<double>(0, (sum, i) => sum + i.totalValue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المخزون'),
        actions: [
          PopupMenuButton<StockStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'تصفية حسب الحالة',
            onSelected: (val) => setState(() => _filterStatus = val),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('الكل')),
              const PopupMenuItem(
                value: StockStatus.outOfStock,
                child: Text('منتهي'),
              ),
              const PopupMenuItem(
                value: StockStatus.low,
                child: Text('منخفض'),
              ),
              const PopupMenuItem(
                value: StockStatus.sufficient,
                child: Text('كافٍ'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
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
                    () => _filterStatus =
                        low > 0 ? StockStatus.low : null,
                  ),
                ),
                const Spacer(),
                Text(
                  'القيمة: ${Formatters.formatCurrency(totalValue)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'بحث في المخزون...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Items list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) =>
                  _InventoryCard(item: filtered[i], allItems: allItems),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItem(context),
        icon: const Icon(Icons.add),
        label: const Text('صنف جديد'),
      ),
    );
  }

  void _showAddItem(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة هذه الميزة في الإصدار القادم'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Inventory card ─────────────────────────────────────────────────────────────

class _InventoryCard extends ConsumerWidget {
  const _InventoryCard({required this.item, required this.allItems});
  final InventoryItem item;
  final List<InventoryItem> allItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
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
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  '${item.currentStock} ${item.unit}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Text(
                  'الحد الأدنى: ${item.minThreshold} ${item.unit}',
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
                backgroundColor:
                    colorScheme.surfaceContainerHighest,
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
                  style: theme.textTheme.bodySmall,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('إعادة التخزين'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    // Placeholder for restock action
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('إعادة تخزين: ${item.name}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
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
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
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
