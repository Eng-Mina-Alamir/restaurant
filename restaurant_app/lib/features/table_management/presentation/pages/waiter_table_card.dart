import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/animated_press_card.dart';
import '../../../../shared/animations/animated_status_badge.dart';
import '../../../../shared/animations/scale_button.dart';
import '../../domain/entities/restaurant_table.dart';
import '../../domain/entities/table_service_request.dart';
import 'waiter_dashboard_page.dart';

/// A modern, elevated table card for the waiter dashboard grid with status-aware styling and actions.
class WaiterTableCard extends StatelessWidget {
  const WaiterTableCard({
    super.key,
    required this.table,
    required this.onTap,
    required this.onTakeOrder,
    required this.onRelease,
    required this.onReserve,
    this.activeServiceRequest,
    this.onAcknowledgeService,
  });

  final RestaurantTable table;
  final VoidCallback onTap;
  final VoidCallback onTakeOrder;
  final VoidCallback onRelease;
  final VoidCallback onReserve;
  final TableServiceRequest? activeServiceRequest;
  final VoidCallback? onAcknowledgeService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = tableStatusColor(table.status, theme.brightness);
    final statusLabel = table.status.labelAr;

    return AnimatedPressCard(
      onTap: onTap,
      borderRadius: AppRadius.lg,
      border: Border.all(
        color: accent.withValues(alpha: isDark ? 0.45 : 0.35),
        width: 1.5,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.8),
              accent.withValues(alpha: isDark ? 0.08 : 0.04),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Header: Table Number & Status Pill ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${table.tableNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                AnimatedStatusBadge(
                  label: statusLabel,
                  color: accent,
                  icon: tableStatusIcon(table.status),
                  fontSize: 11,
                  borderRadius: AppRadius.full,
                ),
              ],
            ),

            const Spacer(),

            // ── Capacity and Location Badges ──
            Row(
              children: [
                // Capacity Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chair_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${table.capacity} ${AppConstants.seats}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),

                // Location Zone Pill
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            table.location,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Active Order Indicator ──
            if (table.currentOrderId != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  Formatters.formatOrderId(table.currentOrderId!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // ── Active Waiter Service Call Banner ──
            if (activeServiceRequest != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: Colors.amber.shade700, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activeServiceRequest!.type.labelAr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onAcknowledgeService != null)
                      InkWell(
                        onTap: onAcknowledgeService,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(Icons.check_circle, size: 16, color: Colors.green),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xs),

            // ── Action Buttons Row ──
            Row(
              children: [
                Expanded(
                  child: ScaleButton(
                    onTap: onTakeOrder,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: onTakeOrder,
                      child: const Text(
                        AppConstants.tableActionTakeOrder,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                ScaleButton(
                  onTap: onReserve,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: AppConstants.tableActionReserve,
                      icon: const Icon(Icons.event_available, size: 18),
                      onPressed: onReserve,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                ScaleButton(
                  onTap: onRelease,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: AppConstants.tableActionRelease,
                      icon: const Icon(Icons.fullscreen_exit, size: 18),
                      onPressed: onRelease,
                    ),
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
