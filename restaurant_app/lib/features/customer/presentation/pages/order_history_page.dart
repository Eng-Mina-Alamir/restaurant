import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../delivery/presentation/controllers/delivery_controller.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../../ratings/domain/entities/rating_entity.dart';
import '../../../ratings/presentation/widgets/rating_dialog.dart';

/// Customer order history: lists past orders and lets the user re-order (add
/// the full contents of a past order back to the cart).
class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  /// How many of the newest orders are currently rendered.
  ///
  /// Display-window rationale: [ordersControllerProvider] accumulates every
  /// order of the session — each realtime orderCreated appends to it, and
  /// terminal (completed/cancelled) orders are retained — so rendering the
  /// entire list would make this page progressively heavier the longer the
  /// app runs. The window is therefore bounded here: newest
  /// [AppConstants.orderHistoryInitialWindow] orders up front, extended by
  /// [AppConstants.orderHistoryPageSize] per "عرض المزيد" tap. This is purely
  /// presentational; the controller state below is never trimmed or mutated.
  int _visibleCount = AppConstants.orderHistoryInitialWindow;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersControllerProvider);

    // Newest-first so the bounded window always shows the most recent orders.
    final sortedNewestFirst = [...orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final visibleOrders = sortedNewestFirst
        .take(_visibleCount)
        .toList(growable: false);
    final hasMore = sortedNewestFirst.length > visibleOrders.length;

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.orderHistoryTitle)),
      body: orders.isEmpty
          ? EmptyOrdersState(onAction: () => context.go('/customer'))
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              // +1 reserves the trailing slot for "عرض المزيد" while orders
              // remain hidden behind the display window.
              itemCount: visibleOrders.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= visibleOrders.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Center(
                      child: FilledButton.tonalIcon(
                        onPressed: () => setState(() {
                          _visibleCount += AppConstants.orderHistoryPageSize;
                        }),
                        icon: const Icon(Icons.unfold_more),
                        label: const Text(AppConstants.orderHistoryLoadMore),
                      ),
                    ),
                  );
                }
                final order = visibleOrders[index];
                return _OrderHistoryCard(
                  order: order,
                  onReorder: () => _reorder(order, context),
                );
              },
            ),
    );
  }

  void _reorder(OrderEntity order, BuildContext context) {
    final cart = ref.read(cartControllerProvider.notifier);
    // Only currently-available items can be reordered.
    final availableItems = order.items.where((i) => i.menuItem.isAvailable);
    // A past order with no items (or whose items are all unavailable now)
    // means the whole re-order is a no-op.
    if (availableItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppConstants.reorderFailed)));
      return;
    }
    for (final item in availableItems) {
      cart.addItem(
        CartItem(
          menuItem: item.menuItem,
          quantity: item.quantity,
          selectedModifiers: item.selectedModifiers,
          specialNotes: item.specialNotes,
        ),
      );
    }
    final unavailableCount = order.items.length - availableItems.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          unavailableCount > 0
              ? '${AppConstants.reorderAction} — ${AppConstants.checkout} '
                    '(${AppConstants.reorderSkipped} $unavailableCount)'
              : '${AppConstants.reorderAction} — ${AppConstants.checkout}',
        ),
      ),
    );
    // Guide the user straight to the cart to review & pay.
    context.push('/customer/cart');
  }
}

class _OrderHistoryCard extends ConsumerWidget {
  const _OrderHistoryCard({required this.order, required this.onReorder});

  final OrderEntity order;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Delivery cards are enriched with driver data once an assignment exists;
    // the row stays hidden entirely while loading or not yet dispatched.
    // Dine-in/takeaway cards never query the delivery repository.
    final assignment = order.orderType == OrderType.delivery
        ? ref.watch(deliveryAssignmentForOrderProvider(order.id)).valueOrNull
        : null;

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
                  Formatters.formatOrderId(order.id),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  order.status.labelAr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (order.paymentMethod != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${AppConstants.paymentMethodDisplayLabel}: '
                '${order.paymentMethod!.labelAr}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (assignment != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      assignment.driverName ?? AppConstants.unknownDriverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (assignment.driverRating != null) ...[
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      assignment.driverRating!.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              order.items
                  .map((i) => '${i.quantity} × ${i.menuItem.name}')
                  .join('، '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatDate(order.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  Formatters.formatCurrency(order.totalAmount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Chat with the assigned driver (delivery orders only).
                if (assignment != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.sm,
                    ),
                    child: Semantics(
                      label: 'محادثة السائق',
                      button: true,
                      child: IconButton(
                        tooltip: 'محادثة السائق',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.chat_bubble_outline, size: 20),
                        onPressed: () => context.push('/chat/${order.id}'),
                      ),
                    ),
                  ),
                if (!order.status.isTerminal)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.sm,
                    ),
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          context.push('/customer/track/${order.id}'),
                      icon: const Icon(Icons.location_on, size: 16),
                      label: const Text('تتبع'),
                    ),
                  ),
                // Rate the driver once the delivery is complete.
                if (assignment != null &&
                    assignment.deliveryStatus == DeliveryStatus.delivered)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.sm,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () => RatingDialog.show(
                        context,
                        targetId: assignment.driverId,
                        targetType: RatingTargetType.driver,
                        title: AppConstants.rateDriverDialogTitle,
                        subtitle: AppConstants.rateDriverDialogSubtitle,
                      ),
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: const Text(AppConstants.rateDriverAction),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: onReorder,
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text(AppConstants.reorderAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
