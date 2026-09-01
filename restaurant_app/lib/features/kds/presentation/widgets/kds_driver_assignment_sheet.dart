import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/animations/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../delivery/domain/entities/driver_info.dart';
import '../../../delivery/domain/services/delivery_fee_calculator.dart';
import '../../../delivery/domain/services/driver_assignment_service.dart';
import '../../../delivery/presentation/controllers/delivery_controller.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';

/// Modal bottom sheet for kitchen staff (KDS) to manually pick a delivery driver
/// or trigger smart auto-dispatch when a delivery order is ready for handover.
class KdsDriverAssignmentSheet extends ConsumerStatefulWidget {
  const KdsDriverAssignmentSheet({
    super.key,
    required this.order,
  });

  final OrderEntity order;

  /// Convenience launcher
  static Future<bool?> show(
    BuildContext context, {
    required OrderEntity order,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => KdsDriverAssignmentSheet(order: order),
    );
  }

  @override
  ConsumerState<KdsDriverAssignmentSheet> createState() =>
      _KdsDriverAssignmentSheetState();
}

class _KdsDriverAssignmentSheetState
    extends ConsumerState<KdsDriverAssignmentSheet> {
  bool _assigning = false;

  Future<void> _handleAssignDriver(DriverInfo driver, {String method = 'manual'}) async {
    if (_assigning) return;
    setState(() => _assigning = true);

    try {
      final deliveryRepo = ref.read(deliveryRepositoryProvider);
      final ok = await ref.read(ordersControllerProvider.notifier).assignDriver(
            orderId: widget.order.id,
            driverId: driver.id,
            driverName: driver.name,
            driverPhone: driver.phone,
            deliveryRepo: deliveryRepo,
            assignmentMethod: method,
          );

      if (!mounted) return;
      if (ok) {
        AppHaptics.milestoneSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسليم الطلب للمندوب: ${driver.name} بنجاح ✅'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        AppHaptics.selectionTap();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تعذر تعيين المندوب، يرجى المحاولة مرة أخرى'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  Future<void> _handleSmartAutoAssign(List<DriverInfo> drivers) async {
    if (drivers.isEmpty) return;
    final decision = const DriverAssignmentService().assign(
      candidates: drivers,
      restaurantLat: DeliveryFeeCalculator.restaurantLat,
      restaurantLng: DeliveryFeeCalculator.restaurantLng,
    );

    switch (decision) {
      case Assigned(:final driverId):
        final selectedDriver = drivers.firstWhere(
          (d) => d.id == driverId,
          orElse: () => drivers.first,
        );
        await _handleAssignDriver(selectedDriver, method: 'auto');
      case Waiting(:final reason):
        if (!mounted) return;
        AppHaptics.selectionTap();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('التعيين التلقائي غير متاح حالياً: $reason'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final driversAsync = ref.watch(availableDriversProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delivery_dining_rounded,
                      color: theme.colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اختيار مندوب التوصيل',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${Formatters.formatOrderId(widget.order.id)} • ${Formatters.formatCurrency(widget.order.totalAmount)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Destination address chip
            if (widget.order.deliveryAddress != null &&
                widget.order.deliveryAddress!.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        widget.order.deliveryAddress!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 1),

            // Driver list body
            Expanded(
              child: driversAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: SkeletonBox(
                    height: 80,
                    width: double.infinity,
                    borderRadius: 12,
                  ),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: EmptyState(
                    icon: Icons.error_outline_rounded,
                    message: 'تعذر جلب قائمة المناديب: $err',
                    actionLabel: 'إعادة المحاولة',
                    onAction: () => ref.invalidate(availableDriversProvider),
                  ),
                ),
                data: (drivers) {
                  if (drivers.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: EmptyState(
                        icon: Icons.two_wheeler_outlined,
                        message: 'لا يوجد مناديب توصيل متاحين حالياً في النظام',
                        actionLabel: 'تحديث القائمة',
                        onAction: () => ref.invalidate(availableDriversProvider),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Smart Auto-Dispatch Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: _assigning
                              ? null
                              : () => _handleSmartAutoAssign(drivers),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '⚡ تعيين تلقائي ذكي',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Text(
                                        'اختيار المندوب الأقرب والأقل انشغالاً فوراً',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xs,
                        ),
                        child: Text(
                          'أو اختر المندوب بالاسم من القائمة:',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // List of Available Drivers
                      for (final driver in drivers)
                        _DriverCard(
                          driver: driver,
                          disabled: _assigning,
                          onSelect: () => _handleAssignDriver(driver),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.onSelect,
    this.disabled = false,
  });

  final DriverInfo driver;
  final VoidCallback onSelect;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFree = driver.activeAssignments == 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            _getVehicleIcon(driver.vehicleInfo),
            color: theme.colorScheme.primary,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                driver.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 2),
                Text(
                  driver.rating.toStringAsFixed(1),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Row(
          children: [
            if (driver.phone != null && driver.phone!.isNotEmpty) ...[
              Icon(
                Icons.phone_outlined,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 2),
              Text(
                driver.phone!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (driver.vehicleInfo != null && driver.vehicleInfo!.isNotEmpty)
              Text(
                driver.vehicleInfo!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: isFree
                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                : Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            isFree ? 'متاح الآن' : '${driver.activeAssignments} طلب نشط',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isFree ? const Color(0xFF10B981) : Colors.orange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: disabled ? null : onSelect,
      ),
    );
  }

  IconData _getVehicleIcon(String? info) {
    if (info == null) return Icons.two_wheeler;
    final lower = info.toLowerCase();
    if (lower.contains('سيارة') || lower.contains('car')) {
      return Icons.directions_car;
    }
    if (lower.contains('دراجة') || lower.contains('bike') || lower.contains('عجلة')) {
      return Icons.pedal_bike;
    }
    return Icons.two_wheeler;
  }
}
