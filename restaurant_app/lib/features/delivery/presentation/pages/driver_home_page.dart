import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/notifications/driver_alert_service.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/logout_action_button.dart';
import '../../domain/entities/delivery_assignment.dart';
import '../controllers/delivery_controller.dart';
import '../widgets/live_tracking_map.dart';

/// Delivery driver home: live list of assignments with lifecycle actions,
/// live map tracking and status filter.
class DriverHomePage extends ConsumerStatefulWidget {
  const DriverHomePage({super.key});

  @override
  ConsumerState<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends ConsumerState<DriverHomePage> {
  DeliveryStatus? _filter;

  /// Assignment ids already announced through the "new assignment" cue so
  /// repeated rebuilds / duplicate events never re-fire it.
  final Set<String> _announcedIds = <String>{};

  /// The first non-empty snapshot is adopted as a baseline so assignments
  /// that were already loaded when the page opened don't trigger the cue.
  bool _baselineInitialized = false;

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(deliveryControllerProvider);

    ref.listen<List<DeliveryAssignment>>(
      deliveryControllerProvider,
      (_, next) => _announceNewAssignments(next),
    );

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
                        : '${_filter!.labelAr} — '
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
                        onOpenMap: () => _showTrackingMap(context, ref, assignment),
                        onOpenChat: () =>
                            context.push('/chat/${assignment.orderId}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Raises the in-app "new assignment" cue (snackbar + chime/haptic) for
  /// assignments appended to state that haven't been announced yet.
  void _announceNewAssignments(List<DeliveryAssignment> current) {
    if (!_baselineInitialized) {
      if (current.isEmpty) return;
      _baselineInitialized = true;
      _announcedIds.addAll(current.map((a) => a.id));
      return;
    }
    final fresh =
        current.where((a) => !_announcedIds.contains(a.id)).toList();
    if (fresh.isEmpty) return;
    for (final a in fresh) {
      _announcedIds.add(a.id);
    }
    unawaited(ref.read(driverAlertServiceProvider).notifyNewAssignment());
    if (!mounted) return;
    final latest = fresh.last;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${AppConstants.driverNewAssignmentAlert} — '
          '${AppConstants.driverNewAssignmentOrderPrefix} '
          '${Formatters.formatOrderId(latest.orderId)}',
        ),
      ),
    );
  }

  void _showTrackingMap(
    BuildContext context,
    WidgetRef ref,
    DeliveryAssignment assignment,
  ) {
    const pickup = LatLng(24.7136, 46.6753);
    final delivery = LatLng(
      assignment.latitude != 0 ? assignment.latitude : 24.7220,
      assignment.longitude != 0 ? assignment.longitude : 46.6850,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.90,
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.navigation_rounded, color: Colors.blue),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'ملاحة وتتبع الطلب ${Formatters.formatOrderId(assignment.orderId)}',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: LiveTrackingMap(
                  pickupLatLng: pickup,
                  deliveryLatLng: delivery,
                  pickupLabel: 'مطعم الأصالة',
                  deliveryLabel: assignment.deliveryLocation,
                  showControls: true,
                  showNavigationHud: true,
                  showDeliveryRadius: true,
                  deliveryRadiusMeters: 10000,
                  onLocationUpdate: (pos) {
                    ref.read(deliveryControllerProvider.notifier).updateLocation(
                          latitude: pos.latitude,
                          longitude: pos.longitude,
                        );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.location_pin, color: Colors.red, size: 20),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      assignment.deliveryLocation,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (assignment.customerPhone != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(assignment.customerPhone!),
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.phone, size: 14),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
                label: Text(status.labelAr),
                selected: selected == status,
                onSelected: (_) => onChanged(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.assignment,
    required this.onAction,
    required this.onOpenMap,
    required this.onOpenChat,
  });

  final DeliveryAssignment assignment;
  final VoidCallback onAction;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenChat;

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
                  Formatters.formatOrderId(assignment.orderId),
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
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('الخريطة والتتبع'),
                  onPressed: onOpenMap,
                ),
                IconButton(
                  tooltip: 'محادثة العميل',
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  onPressed: onOpenChat,
                ),
                if (actionLabel != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: onAction,
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ],
            ),
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
    final label = status.labelAr;
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
