import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/alert_entity.dart';
import '../controllers/alerts_controller.dart';

/// Manager page for viewing and managing system alerts and notifications.
class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allAlerts = ref.watch(alertsControllerProvider);
    final selectedCategory = ref.watch(selectedAlertCategoryProvider);

    final filteredAlerts = selectedCategory == AlertCategory.all
        ? allAlerts
        : allAlerts.where((a) => a.category == selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز التنبيهات'),
        actions: [
          if (allAlerts.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'read_all') {
                  ref.read(alertsControllerProvider.notifier).markAllAsRead();
                } else if (value == 'clear_all') {
                  ref.read(alertsControllerProvider.notifier).clearAll();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'read_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 18),
                      SizedBox(width: 8),
                      Text('تحديد الكل كمقروء'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('مسح كل التنبيهات', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Category Filters ──────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: AlertCategory.values.map((cat) {
                final isSelected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(cat.displayName),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(selectedAlertCategoryProvider.notifier).state = cat;
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Alerts List ───────────────────────────────────────────────
          Expanded(
            child: filteredAlerts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'لا توجد تنبيهات حالياً',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filteredAlerts.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final alert = filteredAlerts[i];
                      return _AlertCard(
                        alert: alert,
                        onTap: () {
                          ref
                              .read(alertsControllerProvider.notifier)
                              .markAsRead(alert.id);
                        },
                        onDismiss: () {
                          ref
                              .read(alertsControllerProvider.notifier)
                              .dismissAlert(alert.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onTap,
    required this.onDismiss,
  });

  final AlertEntity alert;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (color, icon) = switch (alert.severity) {
      AlertSeverity.critical => (Colors.red, Icons.error_outline),
      AlertSeverity.warning => (Colors.orange, Icons.warning_amber_rounded),
      AlertSeverity.info => (Colors.blue, Icons.info_outline),
    };

    return Card(
      elevation: 0,
      color: alert.isRead
          ? colorScheme.surfaceContainerLow
          : color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: alert.isRead
              ? colorScheme.outlineVariant.withValues(alpha: 0.5)
              : color.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: alert.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          Formatters.formatTime(alert.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'تجاهل',
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
