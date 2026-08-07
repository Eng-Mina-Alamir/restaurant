import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/delivery_assignment.dart';
import '../controllers/delivery_controller.dart';

/// Delivery driver home: live list of assignments with lifecycle actions.
class DriverHomePage extends ConsumerWidget {
  const DriverHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(deliveryControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.driverTitle)),
      body: assignments.isEmpty
          ? const EmptyState(
              message: AppConstants.noDeliveryJobs,
              icon: Icons.local_shipping_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                return _DeliveryCard(
                  assignment: assignment,
                  onAction: () => _handleAction(ref, assignment),
                );
              },
            ),
    );
  }

  Future<void> _handleAction(
    WidgetRef ref,
    DeliveryAssignment assignment,
  ) async {
    final controller = ref.read(deliveryControllerProvider.notifier);
    switch (assignment.deliveryStatus) {
      case DeliveryStatus.pending:
        await controller.accept(assignment.id);
      case DeliveryStatus.accepted:
        await controller.start(assignment.id);
      case DeliveryStatus.inTransit:
        await controller.complete(assignment.id);
      default:
        break;
    }
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.assignment, required this.onAction});

  final DeliveryAssignment assignment;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = assignment.deliveryStatus;
    final actionLabel = switch (status) {
      DeliveryStatus.pending => AppConstants.actionAccept,
      DeliveryStatus.accepted => AppConstants.actionStartDelivery,
      DeliveryStatus.inTransit => AppConstants.actionCompleteDelivery,
      _ => null,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${assignment.orderId}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${AppConstants.deliveryLocationLabel}: '
                    '${assignment.deliveryLocation}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (assignment.routeDistanceMeters != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.route_outlined, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'المسافة: ${_formatDistance(assignment.routeDistanceMeters!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${AppConstants.pickupTimeLabel}: '
                  '${Formatters.formatTime(assignment.pickupTime)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (assignment.routeDistanceMeters != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${AppConstants.deliveryEtaLabel}: '
                    '${Formatters.estimateDeliveryMinutes(assignment.routeDistanceMeters!)} '
                    '${AppConstants.minutes}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (assignment.deliveryFee != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${AppConstants.orderTotalLabel}: '
                '${Formatters.formatCurrency(assignment.deliveryFee!)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} كم';
    return '${meters.round()} م';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(status);
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }

  String _statusLabel(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return AppConstants.deliveryPending;
      case DeliveryStatus.accepted:
        return AppConstants.deliveryAccepted;
      case DeliveryStatus.pickedUp:
        return AppConstants.deliveryPickedUp;
      case DeliveryStatus.inTransit:
        return AppConstants.deliveryInTransit;
      case DeliveryStatus.delivered:
        return AppConstants.deliveryDelivered;
      case DeliveryStatus.failed:
        return AppConstants.deliveryFailed;
    }
  }

  Color _statusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.accepted:
        return Colors.blue;
      case DeliveryStatus.pickedUp:
        return Colors.teal;
      case DeliveryStatus.inTransit:
        return Colors.purple;
      case DeliveryStatus.delivered:
        return Colors.green;
      case DeliveryStatus.failed:
        return Colors.red;
    }
  }
}
