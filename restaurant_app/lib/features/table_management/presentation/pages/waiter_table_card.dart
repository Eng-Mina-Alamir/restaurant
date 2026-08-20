import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/animated_press_card.dart';
import '../../../../shared/animations/animated_status_badge.dart';
import '../../../../shared/animations/scale_button.dart';
import '../../domain/entities/restaurant_table.dart';
import 'waiter_dashboard_page.dart';

/// A single table tile shown in the waiter dashboard grid with smooth animations.
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
    final statusLabel = table.status.labelAr;

    return AnimatedPressCard(
      onTap: onTap,
      borderRadius: AppRadius.md,
      border: Border.all(color: accent, width: 2),
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
                AnimatedStatusBadge(
                  label: statusLabel,
                  color: accent,
                  fontSize: 11,
                  borderRadius: AppRadius.full,
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.chair_outlined, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text('${table.capacity} ${AppConstants.seats}'),
                const SizedBox(width: AppSpacing.md),
                const Icon(Icons.place_outlined, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    table.location,
                    style: theme.textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (table.currentOrderId != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                Formatters.formatOrderId(table.currentOrderId!),
                style: theme.textTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ScaleButton(
                    onTap: onTakeOrder,
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
                ),
                ScaleButton(
                  onTap: onReserve,
                  child: IconButton(
                    tooltip: AppConstants.tableActionReserve,
                    icon: const Icon(Icons.event_available),
                    onPressed: onReserve,
                  ),
                ),
                ScaleButton(
                  onTap: onRelease,
                  child: IconButton(
                    tooltip: AppConstants.tableActionRelease,
                    icon: const Icon(Icons.fullscreen_exit),
                    onPressed: onRelease,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
