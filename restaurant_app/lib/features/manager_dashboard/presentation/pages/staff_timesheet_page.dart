import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../controllers/staff_timesheet_controller.dart';

/// Comprehensive Staff Timesheet & Labor Cost Analysis page for Restaurant Managers.
class StaffTimesheetPage extends ConsumerWidget {
  const StaffTimesheetPage({super.key});

  void _showClockInDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final wageCtrl = TextEditingController(text: '35');
    UserRole selectedRole = UserRole.waiter;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          Icons.more_time_rounded,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'تسجيل حضور موظف (Clock-In)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),

                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'اسم الموظف *',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'المسمى الوظيفي',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    items: const [
                      DropdownMenuItem(value: UserRole.waiter, child: Text('ويتر / كابتن صالة')),
                      DropdownMenuItem(value: UserRole.cashier, child: Text('كاشير / POS')),
                      DropdownMenuItem(value: UserRole.kitchen, child: Text('شيف مطبخ')),
                      DropdownMenuItem(value: UserRole.driver, child: Text('سائق دليفري')),
                    ],
                    onChanged: (v) => setState(() => selectedRole = v ?? UserRole.waiter),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  TextField(
                    controller: wageCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'الأجر في الساعة (ج.م/ساعة)',
                      suffixText: 'ج.م',
                      prefixIcon: const Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
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
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                          onPressed: () {
                            final name = nameCtrl.text.trim();
                            final wage = double.tryParse(wageCtrl.text.trim()) ?? 35.0;
                            if (name.isEmpty) return;

                            ref.read(staffTimesheetControllerProvider.notifier).clockIn(
                                  staffId: 'user-${DateTime.now().millisecondsSinceEpoch}',
                                  staffName: name,
                                  role: selectedRole,
                                  hourlyWage: wage,
                                );

                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم تسجيل حضور $name بنجاح ✅'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('تأكيد الحضور'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final timesheetState = ref.watch(staffTimesheetControllerProvider);
    final orders = ref.watch(ordersControllerProvider);

    // Calculate total completed revenue today
    final totalSales = orders
        .where((o) => o.status == OrderStatus.completed)
        .fold<double>(0.0, (acc, o) => acc + o.totalAmount);

    final metrics = timesheetState.calculateMetrics(totalSales > 0 ? totalSales : 4850.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حضور وانصراف وتكلفة العمالة (Timesheet)'),
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => _showClockInDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('تسجيل حضور موظف'),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: ConstrainedContentView(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── 1. Top Labor Cost KPI Meter ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'مؤشر تكلفة العمالة بالنسبة للمبيعات (Labor Cost %)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.query_stats_rounded, color: Colors.white70),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${metrics.laborCostPercentage}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${metrics.healthStatusAr})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      _StatMini(label: 'إجمالي أجور اليوم:', value: Formatters.formatCurrency(metrics.totalWagesCost)),
                      _StatMini(label: 'مبيعات اليوم:', value: Formatters.formatCurrency(metrics.totalSalesRevenue)),
                      _StatMini(label: 'الموظفون بالخدمة:', value: '${metrics.activeStaffCount} موظفين'),
                      _StatMini(label: 'إجمالي ساعات العمل:', value: '${metrics.totalHoursWorked} ساعة'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 2. Active Staff On Duty ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الموظفون على رأس العمل الآن (${timesheetState.activeStaffOnDuty.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            if (timesheetState.activeStaffOnDuty.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('لا يوجد موظفون مسجلون بالخدمة حالياً'),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 380,
                  mainAxisExtent: 130,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: timesheetState.activeStaffOnDuty.length,
                itemBuilder: (ctx, index) {
                  final record = timesheetState.activeStaffOnDuty[index];

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFDCFCE7),
                          child: Icon(
                            record.role == UserRole.kitchen
                                ? Icons.soup_kitchen_rounded
                                : record.role == UserRole.cashier
                                    ? Icons.point_of_sale_rounded
                                    : Icons.person_rounded,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                record.staffName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '${record.role.labelAr} • دخل: ${Formatters.formatTime(record.clockInAt)}',
                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                              ),
                              Text(
                                'مدة العمل: ${record.durationHours.toStringAsFixed(1)} ساعة (${Formatters.formatCurrency(record.calculatedShiftWage)})',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () {
                            ref.read(staffTimesheetControllerProvider.notifier).clockOut(record.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم تسجيل انصراف ${record.staffName} بنجاح ✅'),
                              ),
                            );
                          },
                          child: const Text('انصراف'),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: AppSpacing.xl),

            // ── 3. All Timesheet Records Table ───────────────────────────────
            Text(
              'سجل الحضور والانصراف الكامل',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timesheetState.records.length,
              separatorBuilder: (ctx, index) => const SizedBox(height: 6),
              itemBuilder: (ctx, index) {
                final r = timesheetState.records[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        r.isActiveOnDuty ? Icons.check_circle : Icons.history_toggle_off,
                        color: r.isActiveOnDuty ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${r.staffName} (${r.role.labelAr})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      Text(
                        'من ${Formatters.formatTime(r.clockInAt)} ${r.clockOutAt != null ? "إلى ${Formatters.formatTime(r.clockOutAt!)}" : "(نشط)"}',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        Formatters.formatCurrency(r.calculatedShiftWage),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
