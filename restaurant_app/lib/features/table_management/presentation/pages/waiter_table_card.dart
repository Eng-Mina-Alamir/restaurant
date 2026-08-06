import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/restaurant_table.dart';
import 'waiter_dashboard_page.dart';

/// A single table tile shown in the waiter dashboard grid.
class WaiterTableCard extends StatelessWidget {
  const WaiterTableCard({
    super.key,
    required this.table,
    required this.onTap,
    required this.onTakeOrder,
    required this.onRelease,
    required this.onReserve,
  });

  final RestaurantTable table;
  final VoidCallback onTap;
  final VoidCallback onTakeOrder;
  final VoidCallback onRelease;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tableStatusColor(table.status);
    final statusLabel = tableStatusLabel(table.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: accent, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Text(
                      '${table.tableNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      statusLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.chair_outlined, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Text('${table.capacity} ${AppConstants.seats}'),
                ],
              ),
              if (table.currentOrderId != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '#${table.currentOrderId}',
                  style: theme.textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                      ),
                      onPressed: onTakeOrder,
                      child: const Text(AppConstants.tableActionTakeOrder),
                    ),
                  ),
                  IconButton(
                    tooltip: AppConstants.tableActionReserve,
                    icon: const Icon(Icons.event_available),
                    onPressed: onReserve,
                  ),
                  IconButton(
                    tooltip: AppConstants.tableActionRelease,
                    icon: const Icon(Icons.fullscreen_exit),
                    onPressed: onRelease,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
