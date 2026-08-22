import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/notifications/waiter_alert_service.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/animations/animated_counter.dart';
import '../../../../shared/animations/fade_slide_transition.dart';
import '../../../../shared/animations/staggered_fade_slide_list.dart';
import '../../../../shared/widgets/logout_action_button.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../controllers/table_controller.dart';
import 'waiter_table_card.dart';

/// Waiter / captain dashboard: a grid of restaurant tables with status-aware
/// actions (take order, release, clean, reserve) and smooth animations.
///
/// Also raises an audible/haptic alert and an AppBar badge whenever the
/// kitchen marks a dine-in order ready for pickup (Gap 11).
class WaiterDashboardPage extends ConsumerStatefulWidget {
  const WaiterDashboardPage({super.key});

  @override
  ConsumerState<WaiterDashboardPage> createState() =>
      _WaiterDashboardPageState();
}

class _WaiterDashboardPageState extends ConsumerState<WaiterDashboardPage> {
  int _lastReadyPickupCount = 0;

  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(tableControllerProvider);
    final orders = ref.watch(ordersControllerProvider);

    // Ready-for-pickup: kitchen finished a dine-in ticket and the waiter must
    // collect it. Alert on every INCREASE of this count, mirroring how the
    // KDS page alerts when new pending tickets arrive.
    final readyPickupCount = orders
        .where(
          (o) => o.status == OrderStatus.ready && o.orderType == OrderType.dineIn,
        )
        .length;
    if (readyPickupCount > _lastReadyPickupCount) {
      unawaited(ref.read(waiterAlertServiceProvider).notifyReadyForPickup());
    }
    _lastReadyPickupCount = readyPickupCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.tablesTitle),
        actions: [
          if (readyPickupCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Tooltip(
                  message: AppConstants.waiterReadyForPickupBadge,
                  child: Badge(
                    label: Text('$readyPickupCount'),
                    child: const Icon(Icons.room_service),
                  ),
                ),
              ),
            ),
          const LogoutActionButton(),
        ],
      ),
      body: tables.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: _OrdersSummary(orders: orders),
                ),
                Expanded(
                  child: ResponsiveBuilder(
                    builder: (context, screenType, constraints) {
                      final cols = AppBreakpoints.gridColumnsForWidth(
                        constraints.maxWidth,
                        minColumns: 2,
                        maxColumns: 5,
                      );
                      final ratio =
                          screenType == ScreenType.mobile ? 1.15 : 1.25;

                      return GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              childAspectRatio: ratio,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                            ),
                        itemCount: tables.length,
                        itemBuilder: (context, index) {
                          final table = tables[index];
                          return AnimatedListItem(
                            index: index,
                            staggerDuration: const Duration(milliseconds: 35),
                            duration: const Duration(milliseconds: 350),
                            child: WaiterTableCard(
                              table: table,
                              onTap: () {
                                context.push('/waiter/table/${table.id}');
                              },
                              onTakeOrder: () {
                                context.push('/waiter/order/${table.id}');
                              },
                              onRelease: () => ref
                                  .read(tableControllerProvider.notifier)
                                  .release(table.id),
                              onReserve: () => ref
                                  .read(tableControllerProvider.notifier)
                                  .setReserved(table.id, reserved: true),
                            ),
                          );
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

/// Compact live counters of active order statuses for the waiter.
class _OrdersSummary extends StatelessWidget {
  const _OrdersSummary({required this.orders});

  final List<OrderEntity> orders;

  @override
  Widget build(BuildContext context) {
    final pending = orders.where((o) => o.status == OrderStatus.pending).length;
    final preparing = orders
        .where((o) => o.status == OrderStatus.preparing)
        .length;
    final ready = orders.where((o) => o.status == OrderStatus.ready).length;
    final total = pending + preparing + ready;

    if (total == 0) return const SizedBox.shrink();

    return FadeSlideTransitionWidget(
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppConstants.waiterOrdersSummary,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _CountChip(
                      label: AppConstants.waiterPendingCount,
                      count: pending,
                      color: Colors.orange,
                    ),
                    _CountChip(
                      label: AppConstants.waiterPreparingCount,
                      count: preparing,
                      color: Colors.blue,
                    ),
                    _CountChip(
                      label: AppConstants.waiterReadyCount,
                      count: ready,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: AnimatedCounter(
        value: count,
        prefix: '$label: ',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// Helper to return appropriate color for each table status.
Color tableStatusColor(TableStatus status) {
  return switch (status) {
    TableStatus.available => Colors.green,
    TableStatus.occupied => Colors.red,
    TableStatus.reserved => Colors.orange,
    TableStatus.needsCleaning => Colors.blueGrey,
  };
}
