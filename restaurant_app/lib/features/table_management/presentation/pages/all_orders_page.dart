import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../widgets/order_audit_trail_sheet.dart';

/// A shared staff-facing view of all orders with status filtering and the
/// ability to advance an order's state (used by the manager and KDS).
class AllOrdersPage extends ConsumerStatefulWidget {
  const AllOrdersPage({super.key});

  @override
  ConsumerState<AllOrdersPage> createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends ConsumerState<AllOrdersPage> {
  OrderStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersControllerProvider);
    final filtered = _filter == null
        ? orders
        : orders.where((o) => o.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.allOrdersTitle)),
      body: ConstrainedContentView(
        child: Column(
        children: [
          _StatusFilterBar(
            selected: _filter,
            onChanged: (s) => setState(() => _filter = s),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(ordersControllerProvider),
              child: filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: const EmptyOrdersState(),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _OrderStatusCard(order: filtered[index]),
                    ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onChanged});

  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final statuses = [...OrderStatus.values];
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            child: ChoiceChip(
              label: const Text(AppConstants.filterAll),
              selected: selected == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          for (final status in statuses)
            Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
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

class _OrderStatusCard extends ConsumerWidget {
  const _OrderStatusCard({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final next = _nextStatus(order.status);
    final isTerminal = order.status.isTerminal;
    final statusColor = StatusColors.order(order.status, theme.brightness);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatOrderId(order.id),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: AppConstants.orderAuditTrailTitle,
                      icon: const Icon(Icons.history),
                      onPressed: () =>
                          OrderAuditTrailSheet.show(context, ref, order.id),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        order.status.labelAr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${order.items.length} ${AppConstants.orderItemsCount} • '
              '${Formatters.formatCurrency(order.totalAmount)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              Formatters.formatDateTime(order.createdAt),
              style: theme.textTheme.bodySmall,
            ),
            if (order.orderType == OrderType.dineIn && order.tableId != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${AppConstants.orderTablePrefix} ${order.tableId}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (!isTerminal && next != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  // Semantic key for the pending -> 'مؤكد' confirmation
                  // action, so tests avoid the ambiguous Arabic text lookup.
                  key: next == OrderStatus.confirmed
                      ? const ValueKey<String>('orders_confirm_action')
                      : null,
                  onPressed: () async {
                    await ref
                        .read(ordersControllerProvider.notifier)
                        .updateStatus(order.id, next);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(AppConstants.orderCompletedToaster),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.fast_forward),
                  label: Text('${AppConstants.orderMoveTo} ${next.labelAr}'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  OrderStatus? _nextStatus(OrderStatus current) {
    const flow = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.served,
      OrderStatus.completed,
    ];
    final index = flow.indexOf(current);
    if (index == -1 || index == flow.length - 1) return null;
    return flow[index + 1];
  }
}
