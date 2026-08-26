import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/errors/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/shimmer_loading.dart';
import '../../../orders/domain/entities/order_status_log_entry.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';

/// Loads the audit trail of an order (oldest-first) through the shared
/// [OrderRepository].
///
/// The repository result is kept as an [Either] so failures surface as a
/// retryable error row instead of an unhandled provider exception.
final orderAuditTrailProvider = FutureProvider.autoDispose
    .family<Either<Failure, List<OrderStatusLogEntry>>, String>((ref, orderId) {
      final repository = ref.watch(orderRepositoryProvider);
      return repository.getAuditTrail(orderId);
    });

/// Bottom sheet showing the status-change timeline of a single order.
///
/// Each row renders the from→to transition chips, the acting staff id, an
/// optional justification line and — for guarded backward moves — a distinct
/// 'تراجع' badge.
class OrderAuditTrailSheet extends ConsumerWidget {
  const OrderAuditTrailSheet({super.key, required this.orderId});

  final String orderId;

  /// Opens the audit trail sheet for [orderId] above the current navigator.
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    String orderId,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => OrderAuditTrailSheet(orderId: orderId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trailAsync = ref.watch(orderAuditTrailProvider(orderId));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.history, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppConstants.orderAuditTrailTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: trailAsync.when(
                loading: () => const _AuditTrailSkeleton(),
                error: (_, _) => _ErrorRow(
                  onRetry: () =>
                      ref.invalidate(orderAuditTrailProvider(orderId)),
                ),
                data: (result) => result.when(
                  onLeft: (failure) => _ErrorRow(
                    onRetry: () =>
                        ref.invalidate(orderAuditTrailProvider(orderId)),
                  ),
                  onRight: (entries) => entries.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            AppConstants.orderAuditTrailEmpty,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          itemCount: entries.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, index) =>
                              _AuditTrailTile(entry: entries[index]),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single chronological audit entry rendered as from→to chips with actor,
/// optional reason and revert badge.
class _AuditTrailTile extends StatelessWidget {
  const _AuditTrailTile({required this.entry});

  final OrderStatusLogEntry entry;

  /// Trims long backend user ids to a short display form.
  static String _shortActor(String actorId) =>
      actorId.length <= 12 ? actorId : '${actorId.substring(0, 12)}…';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final reason = entry.reason;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusChip(label: entry.fromStatus.labelAr),
              Icon(
                rtl ? Icons.arrow_back : Icons.arrow_forward,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              _StatusChip(label: entry.toStatus.labelAr),
              const Spacer(),
              if (entry.isRevert) const _RevertBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${AppConstants.orderAuditTrailActorPrefix} '
            '${_shortActor(entry.actorId)}',
            style: theme.textTheme.bodySmall,
          ),
          if (reason != null && reason.isNotEmpty)
            Text(
              '${AppConstants.orderAuditTrailReasonPrefix} $reason',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          Text(
            Formatters.formatDateTime(entry.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tonal chip rendering one side of a transition (from/to label).
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Warning-tonal badge marking a guarded backward move (تراجع).
class _RevertBadge extends StatelessWidget {
  const _RevertBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = StatusColors.tone(SemanticTone.warning, theme.brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        AppConstants.orderAuditTrailRevertBadge,
        style: theme.textTheme.bodySmall?.copyWith(
          color: warning,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Shimmer placeholder shown while the audit trail fetches: four rows
/// echoing the timeline tiles below.
class _AuditTrailSkeleton extends StatelessWidget {
  const _AuditTrailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            const SkeletonBox(
              width: double.infinity,
              height: 48,
              borderRadius: AppRadius.sm,
            ),
          ],
        ],
      ),
    );
  }
}

/// Failure placeholder with a retry action re-running the fetch.
class _ErrorRow extends ConsumerWidget {
  const _ErrorRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            AppConstants.orderAuditTrailLoadFailed,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text(AppConstants.orderAuditTrailRetryAction),
          ),
        ],
      ),
    );
  }
}
