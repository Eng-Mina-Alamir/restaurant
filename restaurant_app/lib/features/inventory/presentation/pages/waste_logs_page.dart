import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_schemes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/entities/waste_log_entity.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/waste_controller.dart';

/// Waste & Spoilage Logs Management Page (إدارة الهالك والتالف وتكلفة الخسائر)
class WasteLogsPage extends ConsumerStatefulWidget {
  const WasteLogsPage({super.key});

  @override
  ConsumerState<WasteLogsPage> createState() => _WasteLogsPageState();
}

class _WasteLogsPageState extends ConsumerState<WasteLogsPage> {
  WasteReason? _filterReason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final wasteState = ref.watch(wasteControllerProvider);
    final inventoryState = ref.watch(inventoryControllerProvider);

    final wasteLogs = wasteState.valueOrNull ?? [];
    final inventoryItems = inventoryState.valueOrNull ?? [];

    final filteredLogs =
        _filterReason == null
            ? wasteLogs
            : wasteLogs.where((w) => w.reason == _filterReason).toList();

    final totalLoss = ref.read(wasteControllerProvider.notifier).totalWasteCost;

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
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: AppShadows.glow(const Color(0xFFEF4444), opacity: 0.3),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
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
                  'سجل الهالك والتوالف (Waste Log)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'متابعة الخامات التالفة والمنتهية الصلاحية وحساب تكلفة الهدر',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton.filled(
            onPressed: () => _showAddWasteDialog(inventoryItems),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'تسجيل هالك جديد',
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: ConstrainedContentView(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Total Loss Summary Banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEF4444).withValues(alpha: isDark ? 0.25 : 0.1),
                    const Color(0xFFF97316).withValues(alpha: isDark ? 0.15 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trending_down_rounded,
                      color: Color(0xFFEF4444),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إجمالي تكلفة الهالك والتالف المسجل',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(totalLoss),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddWasteDialog(inventoryItems),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('تسجيل تالف'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Reason Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('الكل'),
                    selected: _filterReason == null,
                    onSelected: (_) => setState(() => _filterReason = null),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ...WasteReason.values.map(
                    (reason) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(reason.labelAr),
                        selected: _filterReason == reason,
                        onSelected:
                            (_) => setState(() => _filterReason = reason),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Waste Logs List
            if (filteredLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 48,
                        color: Colors.green.shade400,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'لا توجد سجلات هالك مسجلة في هذا القسم',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredLogs.map((log) => _buildWasteTile(log)),
          ],
        ),
      ),
    );
  }

  Widget _buildWasteTile(WasteLogEntity log) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
                child: Text(
                  log.inventoryItemName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                Formatters.formatCurrency(log.totalCost),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الكمية التالفة: ${log.quantity} ${log.unit} (سعر الوحدة: ${Formatters.formatCurrency(log.unitCost)})',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  log.reason.labelAr,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          if (log.notes != null && log.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'ملاحظات: ${log.notes}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المسؤول: ${log.loggedByName}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                Formatters.formatDateTime(log.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddWasteDialog(List<InventoryItemEntity> inventoryItems) {
    if (inventoryItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد عناصر بالمخزن.')),
      );
      return;
    }

    InventoryItemEntity selectedItem = inventoryItems.first;
    WasteReason selectedReason = WasteReason.expired;
    final qtyController = TextEditingController(text: '1');
    final notesController = TextEditingController();
    final user = ref.read(authControllerProvider).user;
    final userName = user?.name ?? 'المدير المسؤول';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final qty = double.tryParse(qtyController.text.trim()) ?? 0.0;
            final estimatedCost = qty * selectedItem.costPerUnit;

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444)),
                  SizedBox(width: 8),
                  Text('تسجيل هالك / تالف من المخزن'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<InventoryItemEntity>(
                      initialValue: selectedItem,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'العنصر التالف بالمخزن',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          inventoryItems.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(
                                '${item.name} (المتاح: ${item.currentStock} ${item.unit})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedItem = val);
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
                        labelText: 'الكمية التالفة بالـ (${selectedItem.unit})',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<WasteReason>(
                      initialValue: selectedReason,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'سبب التلف / الهدر',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          WasteReason.values.map((r) {
                            return DropdownMenuItem(
                              value: r,
                              child: Text(r.labelAr),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedReason = val);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات تفصيلية (اختياري)',
                        border: OutlineInputBorder(),
                        hintText: 'مثلاً: عطل في التبريد أو كسر أثناء النقل',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('إجمالي قيمة الخسارة:'),
                          Text(
                            Formatters.formatCurrency(estimatedCost),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () async {
                    final qty =
                        double.tryParse(qtyController.text.trim()) ?? 0.0;
                    if (qty <= 0) return;

                    await ref
                        .read(wasteControllerProvider.notifier)
                        .logWaste(
                          inventoryItemId: selectedItem.id,
                          inventoryItemName: selectedItem.name,
                          quantity: qty,
                          unit: selectedItem.unit,
                          unitCost: selectedItem.costPerUnit,
                          reason: selectedReason,
                          loggedByName: userName,
                          notes: notesController.text.trim(),
                        );

                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  },
                  child: const Text('تأكيد وتسجيل الهالك'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
