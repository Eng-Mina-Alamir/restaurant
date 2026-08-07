import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/logout_action_button.dart';
import '../../domain/entities/delivery_assignment.dart';
import '../controllers/delivery_controller.dart';

/// Delivery driver home: live list of assignments with lifecycle actions and a
/// status filter.
class DriverHomePage extends ConsumerStatefulWidget {
  const DriverHomePage({super.key});

  @override
  ConsumerState<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends ConsumerState<DriverHomePage> {
  DeliveryStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(deliveryControllerProvider);
    final visible = _filter == null
        ? assignments
        : assignments.where((a) => a.deliveryStatus == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.driverTitle),
        actions: const [LogoutActionButton()],
      ),
      body: Column(
        children: [
          _StatusFilterBar(
            selected: _filter,
            onChanged: (s) => setState(() => _filter = s),
          ),
          Expanded(
            child: visible.isEmpty
                ? EmptyState(
                    message: _filter == null
                        ? AppConstants.noDeliveryJobs
                        : '${deliveryStatusShortLabel(_filter!)} — '
                              '${AppConstants.noDeliveryJobs}',
                    icon: Icons.local_shipping_outlined,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final assignment = visible[index];
                      return _DeliveryCard(
                        assignment: assignment,
                        onAction: () => _handleAction(ref, assignment),
                      );
                    },
                  ),
          ),
        ],
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

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onChanged});

  final DeliveryStatus? selected;
  final ValueChanged<DeliveryStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: ChoiceChip(
              label: const Text(AppConstants.driverFilterAll),
              selected: selected == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          for (final status in DeliveryStatus.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(_statusShortLabel(status)),
                selected: selected == status,
                onSelected: (_) => onChanged(status),
              ),
            ),
        ],
      ),
    );
  }

  String _statusShortLabel(DeliveryStatus status) => switch (status) {
    DeliveryStatus.pending => AppConstants.deliveryPending,
    DeliveryStatus.accepted => AppConstants.deliveryAccepted,
    DeliveryStatus.pickedUp => AppConstants.deliveryPickedUp,
    DeliveryStatus.inTransit => AppConstants.deliveryInTransit,
    DeliveryStatus.delivered => AppConstants.deliveryDelivered,
    DeliveryStatus.failed => AppConstants.deliveryFailed,
  };
}

/// Short Arabic label for a delivery status used in the filter chips.
String deliveryStatusShortLabel(DeliveryStatus status) => switch (status) {
  DeliveryStatus.pending => AppConstants.deliveryPending,
  DeliveryStatus.accepted => AppConstants.deliveryAccepted,
  DeliveryStatus.pickedUp => AppConstants.deliveryPickedUp,
  DeliveryStatus.inTransit => AppConstants.deliveryInTransit,
  DeliveryStatus.delivered => AppConstants.deliveryDelivered,
  DeliveryStatus.failed => AppConstants.deliveryFailed,
};

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
            if (assignment.customerPhone != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${AppConstants.customerPhoneLabel}: '
                    '${assignment.customerPhone}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (assignment.routeDistanceMeters != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.route_outlined, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${AppConstants.distanceLabel}: '
                    '${_formatDistance(assignment.routeDistanceMeters!)}',
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
                '${AppConstants.deliveryFeeLabel}: '
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
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} ${AppConstants.unitKm}';
    }
    return '${meters.round()} ${AppConstants.unitMeter}';
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
