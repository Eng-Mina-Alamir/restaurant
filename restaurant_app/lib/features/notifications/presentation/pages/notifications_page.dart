import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/push_notification_service.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  NotificationCategory? _filterCategory;

  @override
  Widget build(BuildContext context) {
    final notificationService = ref.watch(pushNotificationServiceProvider);
    final history = notificationService.history;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filtered = history.where((n) {
      if (_filterCategory == null) return true;
      return n.category == _filterCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز الإشعارات والتنبيهات'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              tooltip: 'مسح الكل',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () {
                setState(() {
                  notificationService.clearAll();
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('الكل (${history.length})'),
                  selected: _filterCategory == null,
                  onSelected: (_) => setState(() => _filterCategory = null),
                ),
                const SizedBox(width: AppSpacing.xs),
                for (final cat in NotificationCategory.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(_categoryLabel(cat)),
                      selected: _filterCategory == cat,
                      onSelected: (_) => setState(() => _filterCategory = cat),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    message: 'لا توجد إشعارات حالياً',
                    icon: Icons.notifications_off_outlined,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isUnread = !item.isRead;

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        color: isUnread
                            ? colorScheme.primaryContainer.withValues(
                                alpha: 0.35,
                              )
                            : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _categoryColor(
                              item.category,
                            ).withValues(alpha: 0.15),
                            child: Icon(
                              _categoryIcon(item.category),
                              color: _categoryColor(item.category),
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(item.body),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.formatDateTime(item.timestamp),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          trailing: isUnread
                              ? IconButton(
                                  icon: const Icon(Icons.check, size: 18),
                                  tooltip: 'تحديد كمقروء',
                                  onPressed: () {
                                    setState(() {
                                      notificationService.markAsRead(item.id);
                                    });
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.orderStatus:
        return 'حالة الطلب';
      case NotificationCategory.newOrder:
        return 'طلبات جديدة';
      case NotificationCategory.tableAlert:
        return 'تنبيهات الطاولات';
      case NotificationCategory.deliveryJob:
        return 'التوصيل';
      case NotificationCategory.system:
        return 'النظام والولاء';
    }
  }

  Color _categoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.orderStatus:
        return Colors.blue;
      case NotificationCategory.newOrder:
        return Colors.green;
      case NotificationCategory.tableAlert:
        return Colors.orange;
      case NotificationCategory.deliveryJob:
        return Colors.teal;
      case NotificationCategory.system:
        return Colors.purple;
    }
  }

  IconData _categoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.orderStatus:
        return Icons.receipt_long_outlined;
      case NotificationCategory.newOrder:
        return Icons.add_shopping_cart;
      case NotificationCategory.tableAlert:
        return Icons.table_restaurant;
      case NotificationCategory.deliveryJob:
        return Icons.delivery_dining;
      case NotificationCategory.system:
        return Icons.stars_rounded;
    }
  }
}
