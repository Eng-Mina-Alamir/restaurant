import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../controllers/table_controller.dart';
import '../../domain/entities/restaurant_table.dart';

/// Full CRUD management interface for restaurant tables and floor setup.
class TableManagementCrudPage extends ConsumerStatefulWidget {
  const TableManagementCrudPage({super.key});

  @override
  ConsumerState<TableManagementCrudPage> createState() =>
      _TableManagementCrudPageState();
}

class _TableManagementCrudPageState
    extends ConsumerState<TableManagementCrudPage> {
  TableStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(tableControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredTables = _filterStatus == null
        ? tables
        : tables.where((t) => t.status == _filterStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطاولات والصالة'),
        actions: [
          IconButton(
            tooltip: 'إضافة طاولة',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddTableDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTableDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('إضافة طاولة'),
      ),
      body: Column(
        children: [
          // Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('الكل (${tables.length})'),
                  selected: _filterStatus == null,
                  onSelected: (_) => setState(() => _filterStatus = null),
                ),
                const SizedBox(width: AppSpacing.xs),
                for (final status in TableStatus.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(
                        '${status.labelAr} (${tables.where((t) => t.status == status).length})',
                      ),
                      selected: _filterStatus == status,
                      onSelected: (_) => setState(() => _filterStatus = status),
                    ),
                  ),
              ],
            ),
          ),

          // Grid View of Tables
          Expanded(
            child: filteredTables.isEmpty
                ? const EmptyState(
                    message: 'لا توجد طاولات بهذه الحالة',
                    icon: Icons.table_restaurant_outlined,
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      80,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: filteredTables.length,
                    itemBuilder: (context, index) {
                      final table = filteredTables[index];
                      final statusColor = StatusColors.table(
                        table.status,
                        theme.brightness,
                      );

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: BorderSide(
                            color: statusColor.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: statusColor.withValues(
                                      alpha: 0.15,
                                    ),
                                    foregroundColor: statusColor,
                                    child: Text(
                                      '${table.tableNumber}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        _showEditTableDialog(context, table);
                                      } else if (val == 'delete') {
                                        _confirmDeleteTable(context, table);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18),
                                            SizedBox(width: 8),
                                            Text('تعديل البيانات'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: colorScheme.error,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'حذف الطاولة',
                                              style: TextStyle(
                                                color: colorScheme.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.people_outline,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'السعة: ${table.capacity} أفراد',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    table.assignedWaiterId != null
                                        ? 'النادل: ${table.assignedWaiterId}'
                                        : 'غير مخصصة لنادل',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              // Status Dropdown
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<TableStatus>(
                                    value: table.status,
                                    isDense: true,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      size: 18,
                                    ),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    onChanged: (newStatus) {
                                      if (newStatus != null) {
                                        ref
                                            .read(
                                              tableControllerProvider.notifier,
                                            )
                                            .editTable(
                                              table.id,
                                              status: newStatus,
                                            );
                                      }
                                    },
                                    items: TableStatus.values
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s.labelAr),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddTableDialog(BuildContext context) {
    final numberCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '4');
    final waiterCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة طاولة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'رقم الطاولة *',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: capacityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'سعة الأفراد (عدد الكراسي) *',
                prefixIcon: Icon(Icons.chair_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: waiterCtrl,
              decoration: const InputDecoration(
                labelText: 'النادل المسؤول (اختياري)',
                prefixIcon: Icon(Icons.badge_outlined),
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
            onPressed: () {
              final number = int.tryParse(numberCtrl.text.trim());
              final cap = int.tryParse(capacityCtrl.text.trim()) ?? 4;
              if (number == null || number <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال رقم طاولة صحيح')),
                );
                return;
              }

              ref
                  .read(tableControllerProvider.notifier)
                  .addTable(
                    tableNumber: number,
                    capacity: cap,
                    assignedWaiterId: waiterCtrl.text.trim().isEmpty
                        ? null
                        : waiterCtrl.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditTableDialog(BuildContext context, RestaurantTable table) {
    final numberCtrl = TextEditingController(
      text: table.tableNumber.toString(),
    );
    final capacityCtrl = TextEditingController(text: table.capacity.toString());
    final waiterCtrl = TextEditingController(
      text: table.assignedWaiterId ?? '',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل طاولة ${table.tableNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'رقم الطاولة *',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: capacityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'سعة الأفراد *',
                prefixIcon: Icon(Icons.chair_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: waiterCtrl,
              decoration: const InputDecoration(
                labelText: 'النادل المسؤول',
                prefixIcon: Icon(Icons.badge_outlined),
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
            onPressed: () {
              final number = int.tryParse(numberCtrl.text.trim());
              final cap = int.tryParse(capacityCtrl.text.trim()) ?? 4;
              if (number == null || number <= 0) return;

              ref
                  .read(tableControllerProvider.notifier)
                  .editTable(
                    table.id,
                    tableNumber: number,
                    capacity: cap,
                    assignedWaiterId: waiterCtrl.text.trim().isEmpty
                        ? null
                        : waiterCtrl.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTable(BuildContext context, RestaurantTable table) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الطاولة'),
        content: Text('هل أنت متأكد من حذف طاولة رقم ${table.tableNumber}؟'),
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
              ref.read(tableControllerProvider.notifier).deleteTable(table.id);
              Navigator.pop(ctx);
            },
            child: const Text(AppConstants.delete),
          ),
        ],
      ),
    );
  }
}
