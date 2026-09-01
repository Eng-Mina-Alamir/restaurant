import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../domain/entities/security_audit_log_entity.dart';
import '../controllers/security_audit_controller.dart';

/// Comprehensive Restaurant Security Audit Trail & Loss Prevention Page for Managers.
class SecurityAuditLogsPage extends ConsumerWidget {
  const SecurityAuditLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final auditState = ref.watch(securityAuditControllerProvider);
    final logs = auditState.filteredLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التدقيق الأمني ومكافحة التلاعب (Audit Trail)'),
      ),
      body: ConstrainedContentView(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── 1. Loss Prevention KPI Cards ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('إجمالي الإلغاءات والضيافات:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatCurrency(auditState.totalSensitiveAmounts),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('فتح الدرج بدون بيع (No-Sale):', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '${auditState.noSaleDrawerOpenCount} مرات',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── 2. Severity Filter Chips ─────────────────────────────────────
            Row(
              children: [
                FilterChip(
                  label: const Text('الكل'),
                  selected: auditState.selectedSeverityFilter == null,
                  onSelected: (_) => ref.read(securityAuditControllerProvider.notifier).setSeverityFilter(null),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('خطير / تدقيق 🚨'),
                  selected: auditState.selectedSeverityFilter == AuditSeverity.critical,
                  onSelected: (_) => ref
                      .read(securityAuditControllerProvider.notifier)
                      .setSeverityFilter(AuditSeverity.critical),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('تنبيهات ⚠️'),
                  selected: auditState.selectedSeverityFilter == AuditSeverity.warning,
                  onSelected: (_) => ref
                      .read(securityAuditControllerProvider.notifier)
                      .setSeverityFilter(AuditSeverity.warning),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── 3. Security Event Timeline ───────────────────────────────────
            Text(
              'العمليات والأنشطة المسجلة (${logs.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (logs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Text('لا توجد سجلات أمنية مطابقة للفلتر المحدد'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (ctx, index) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final entry = logs[index];
                  final isCritical = entry.severity == AuditSeverity.critical;

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isCritical
                            ? Colors.red
                            : entry.severity == AuditSeverity.warning
                                ? Colors.orange
                                : colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: isCritical ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCritical
                                ? Colors.red.withValues(alpha: 0.15)
                                : Colors.orange.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCritical ? Icons.gpp_bad_rounded : Icons.security_rounded,
                            color: isCritical ? Colors.red : Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.type.labelAr,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    Formatters.formatTime(entry.timestamp),
                                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.actionDescription,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'المسؤول: ${entry.staffName} (${entry.staffRole})',
                                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                  ),
                                  if (entry.managerPinUsed != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('PIN معتمد ✅', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
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
