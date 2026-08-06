import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';

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
        ],
      ),
      body: active.isEmpty
          ? const Center(child: Text(AppConstants.emptyOrders))
          : Row(
              children: [
                _KdsColumn(
                  title: AppConstants.kdsPending,
                  color: Colors.orange,
                  orders: pending.toList(),
                  onAdvance: (order) => _advance(context, ref, order),
                ),
                _KdsColumn(
                  title: AppConstants.kdsPreparing,
                  color: Colors.blue,
                  orders: preparing.toList(),
                  onAdvance: (order) => _advance(context, ref, order),
                ),
                _KdsColumn(
                  title: AppConstants.kdsReady,
                  color: Colors.green,
                  orders: ready.toList(),
                  onAdvance: (order) => _advance(context, ref, order),
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
  });

  final String title;
  final Color color;
  final List<OrderEntity> orders;
  final ValueChanged<OrderEntity> onAdvance;

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
                        '—',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final order in orders)
                          _OrderCard(order: order, onAdvance: onAdvance),
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
  const _OrderCard({required this.order, required this.onAdvance});

  final OrderEntity order;
  final ValueChanged<OrderEntity> onAdvance;

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
                Text(
                  _orderNumber(order),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    if (order.tableId != null)
                      Chip(
                        label: Text('${AppConstants.seats} ${order.tableId}'),
                        visualDensity: VisualDensity.compact,
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
            if (_elapsedMinutes(order.createdAt) >= 1)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'منذ ${_elapsedMinutes(order.createdAt)} دقيقة',
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

  String _orderNumber(OrderEntity order) {
    final digits = order.id.replaceAll(RegExp(r'[^0-9]'), '');
    return '#$digits';
  }

  int _elapsedMinutes(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    final minutes = diff.inMinutes;
    return minutes < 0 ? 0 : minutes;
  }
}
