import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../controllers/table_controller.dart';
import '../../domain/entities/restaurant_table.dart';

/// Modal dialog allowing waiters to transfer an active order or merge tables.
class TableTransferDialog extends ConsumerStatefulWidget {
  const TableTransferDialog({
    super.key,
    required this.currentTable,
    required this.activeOrderId,
  });

  final RestaurantTable currentTable;
  final String activeOrderId;

  static Future<bool?> show(
    BuildContext context, {
    required RestaurantTable currentTable,
    required String activeOrderId,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => TableTransferDialog(
            currentTable: currentTable,
            activeOrderId: activeOrderId,
          ),
    );
  }

  @override
  ConsumerState<TableTransferDialog> createState() =>
      _TableTransferDialogState();
}

class _TableTransferDialogState extends ConsumerState<TableTransferDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RestaurantTable? _selectedTargetTable;
  final Set<String> _selectedMergeTableIds = <String>{};
  String _transferReason = 'طلب الضيوف تغيير مكان الجلوس';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTables = ref.watch(tableControllerProvider);

    // Eligible destination tables for transfer (Available and not the current table)
    final eligibleTransferTables =
        allTables
            .where(
              (t) =>
                  t.id != widget.currentTable.id &&
                  t.status == TableStatus.available,
            )
            .toList();

    // Eligible tables for merge (Available tables that can be joined)
    final eligibleMergeTables =
        allTables.where((t) => t.id != widget.currentTable.id).toList();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.swap_horiz_rounded,
            color: Color(0xFF3B82F6),
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'إدارة موقع طاولة ${widget.currentTable.tableNumber}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        height: 380,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.drive_file_move_outline, size: 18),
                  text: 'نقل الطلب لطاولة أخرى',
                ),
                Tab(
                  icon: Icon(Icons.merge_type_rounded, size: 18),
                  text: 'دمج طاولات (عزومة/مجموعة)',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Transfer Order
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اختر الطاولة الشاغرة المراد نقل الطلب إليها:',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      if (eligibleTransferTables.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'لا توجد طاولات شاغرة متاحة حالياً للنقل',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: eligibleTransferTables.length,
                            itemBuilder: (ctx, index) {
                              final table = eligibleTransferTables[index];
                              final isSelected =
                                  _selectedTargetTable?.id == table.id;

                              return Card(
                                color:
                                    isSelected
                                        ? theme.colorScheme.primaryContainer
                                        : null,
                                margin: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        isSelected
                                            ? theme.colorScheme.primary
                                            : const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    child: Text('${table.tableNumber}'),
                                  ),
                                  title: Text(
                                    'طاولة رقم ${table.tableNumber} — ${table.location}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'السعة: ${table.capacity} مقاعد',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing:
                                      isSelected
                                          ? const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF3B82F6),
                                          )
                                          : null,
                                  onTap:
                                      () => setState(
                                        () => _selectedTargetTable = table,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 6),
                      // Quick reason selector
                      DropdownButtonFormField<String>(
                        initialValue: _transferReason,
                        decoration: const InputDecoration(
                          labelText: 'سبب النقل',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'طلب الضيوف تغيير مكان الجلوس',
                            child: Text(
                              'طلب الضيوف مكان أفضل / إطلالة',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'رغبة في طاولة أكبر سعة',
                            child: Text(
                              'حاجة لسعة أكبر',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'نقل من الداخل إلى التراس الخارجي',
                            child: Text(
                              'نقل للتراس الخارجي',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        onChanged:
                            (val) => setState(
                              () =>
                                  _transferReason =
                                      val ?? 'طلب الضيوف تغيير مكان الجلوس',
                            ),
                      ),
                    ],
                  ),

                  // Tab 2: Merge Tables
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حدد الطاولات الإضافية لضمها مع طاولة ${widget.currentTable.tableNumber}:',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: eligibleMergeTables.length,
                          itemBuilder: (ctx, index) {
                            final table = eligibleMergeTables[index];
                            final isChecked = _selectedMergeTableIds.contains(
                              table.id,
                            );

                            return CheckboxListTile(
                              value: isChecked,
                              dense: true,
                              title: Text(
                                'طاولة ${table.tableNumber} (${table.capacity} مقاعد) — ${table.status.labelAr}',
                                style: const TextStyle(fontSize: 12.5),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedMergeTableIds.add(table.id);
                                  } else {
                                    _selectedMergeTableIds.remove(table.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () async {
            if (_tabController.index == 0) {
              // Execute Transfer
              if (_selectedTargetTable == null) return;
              final targetNum = _selectedTargetTable!.tableNumber;
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final success = await ref
                  .read(tableControllerProvider.notifier)
                  .transferTable(
                    widget.currentTable.id,
                    _selectedTargetTable!.id,
                    reason: _transferReason,
                  );

              navigator.pop(success);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'تم نقل الطلب بنجاح إلى طاولة $targetNum ✅',
                  ),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            } else {
              // Execute Merge
              if (_selectedMergeTableIds.isEmpty) return;
              final count = _selectedMergeTableIds.length;
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final success = await ref
                  .read(tableControllerProvider.notifier)
                  .mergeTables(
                    widget.currentTable.id,
                    _selectedMergeTableIds.toList(),
                  );

              navigator.pop(success);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'تم دمج $count طاولات مع طاولة ${widget.currentTable.tableNumber} بنجاح ✅',
                  ),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            }
          },
          child: Text(
            _tabController.index == 0 ? 'تأكيد نقل الطلب' : 'تأكيد دمج الطاولات',
          ),
        ),
      ],
    );
  }
}
