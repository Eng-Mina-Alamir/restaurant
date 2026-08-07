import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/logout_action_button.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../../table_management/presentation/controllers/table_controller.dart';

/// Kitchen Display System: live order columns (pending / preparing / ready).
///
/// Watches [ordersControllerProvider] so orders sent by a waiter appear
/// immediately, and the kitchen advances each order's status with a button.
class KdsPage extends ConsumerStatefulWidget {
  const KdsPage({super.key});

  @override
  ConsumerState<KdsPage> createState() => _KdsPageState();
}

class _KdsPageState extends ConsumerState<KdsPage> {
  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersControllerProvider);
    final badge = ref.watch(
      newOrderNotifierProvider.select((n) => n.alertCount),
    );
    final tables = ref.watch(tableControllerProvider);
    final tableNumberById = <String, int>{
      for (final t in tables) t.id: t.tableNumber,
    };

    final active = orders
        .where(
          (o) =>
              o.status != OrderStatus.completed &&
              o.status != OrderStatus.cancelled,
        )
        .toList();

    final pending = active.where((o) => o.status == OrderStatus.pending);
    final preparing = active.where((o) => o.status == OrderStatus.preparing);
    final ready = active.where((o) => o.status == OrderStatus.ready);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.kdsTitle),
        actions: [
          if (badge > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Badge(
                  label: Text('$badge'),
                  child: const Icon(Icons.notifications_active),
                ),
              ),
            ),
          const LogoutActionButton(),
        ],
      ),
      body: active.isEmpty
          ? const EmptyOrdersState()
          : Row(
              children: [
                _KdsColumn(
                  title: AppConstants.kdsPending,
                  color: Colors.orange,
                  orders: pending.toList(),
                  onAdvance: (order) => _advance(context, ref, order),
                  tableNumberById: tableNumberById,
                ),
                _KdsColumn(
                  title: AppConstants.kdsPreparing,
                  color: Colors.blue,
                  orders: preparing.toList(),
                  onAdvance: (order) => _advance(context, ref, order),
                  tableNumberById: tableNumberById,
                ),
                _KdsColumn(
                  title: AppConstants.kdsReady,
                  color: Colors.green,
                  orders: ready.toList(),
                  onAdvance: (order) => _advance(context, ref, order),
                  tableNumberById: tableNumberById,
                ),
              ],
            ),
    );
  }

  Future<void> _advance(
    BuildContext context,
    WidgetRef ref,
    OrderEntity order,
  ) async {
    ref.read(newOrderNotifierProvider).reset();
    final next = _nextStatus(order.status);
    if (next == null) return;
    await ref
        .read(ordersControllerProvider.notifier)
        .updateStatus(order.id, next);
  }

  /// Maps a status to the next KDS stage, or null when terminal.
  OrderStatus? _nextStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.served;
      case OrderStatus.served:
        return OrderStatus.completed;
      default:
        return null;
    }
  }
}

class _KdsColumn extends StatelessWidget {
  const _KdsColumn({
    required this.title,
    required this.color,
    required this.orders,
    required this.onAdvance,
    required this.tableNumberById,
  });

  final String title;
  final Color color;
  final List<OrderEntity> orders;
  final ValueChanged<OrderEntity> onAdvance;
  final Map<String, int> tableNumberById;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$title (${orders.length})',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: orders.isEmpty
                  ? Center(
                      child: Text(
                        AppConstants.kdsEmptyColumn,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final order in orders)
                          _OrderCard(
                            order: order,
                            onAdvance: onAdvance,
                            tableNumber: order.tableId == null
                                ? null
                                : tableNumberById[order.tableId],
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onAdvance,
    this.tableNumber,
  });

  final OrderEntity order;
  final ValueChanged<OrderEntity> onAdvance;
  final int? tableNumber;

  /// Orders younger than this threshold are considered "new".
  static const Duration _newThreshold = Duration(minutes: 2);

  bool get _isNew => DateTime.now().difference(order.createdAt) < _newThreshold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonLabel = switch (order.status) {
      OrderStatus.pending => AppConstants.kdsPreparing,
      OrderStatus.preparing => AppConstants.kdsReady,
      OrderStatus.ready => AppConstants.kdsCompleting,
      _ => AppConstants.ok,
    };

    final highlight = _isNew ? theme.colorScheme.primary : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: highlight != null
            ? BorderSide(color: highlight, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    Formatters.formatOrderId(order.id),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isNew)
                      Container(
                        margin: const EdgeInsetsDirectional.only(
                          end: AppSpacing.xs,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: highlight!.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          AppConstants.kdsNewBadge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: highlight,
                          ),
                        ),
                      ),
                    if (tableNumber != null)
                      Chip(
                        label: Text(
                          '${AppConstants.orderTablePrefix} $tableNumber',
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final item in order.items) ...[
              Text(
                '${item.quantity} × ${item.menuItem.name}',
                style: theme.textTheme.bodySmall,
              ),
              if (item.selectedModifiers.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.md,
                  ),
                  child: Text(
                    item.selectedModifiers.map((m) => m.name).join('، '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              if (item.specialNotes?.trim().isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.md,
                  ),
                  child: Text(
                    '${AppConstants.specialNotesLabel}: ${item.specialNotes}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${AppConstants.itemCountLabel}: ${order.items.fold<int>(0, (sum, i) => sum + i.quantity)}',
                    style: theme.textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  Formatters.formatCurrency(order.totalAmount),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (_elapsedMinutes(order.createdAt) >= 1)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '${AppConstants.sincePrefix} '
                  '${_elapsedMinutes(order.createdAt)} '
                  '${AppConstants.minutes}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              ),
              onPressed: () => onAdvance(order),
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }

  int _elapsedMinutes(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    final minutes = diff.inMinutes;
    return minutes < 0 ? 0 : minutes;
  }
}
