import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/order_entity.dart';

/// Confirmation screen shown after a customer places an order.
///
/// Summarizes the placed [order]: reference number, items, money figures and
/// status, with actions to return to the menu.
class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(AppConstants.orderConfirmationTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Icon(Icons.check_circle, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              AppConstants.orderPlacedMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              AppConstants.orderNumberLabel,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              formattedOrderNumber(order),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Card(
            title: AppConstants.orderItemsLabel,
            rows: [
              for (final item in order.items)
                _Row(
                  label: '${item.quantity} × ${item.menuItem.name}',
                  value: Formatters.formatCurrency(item.itemTotal),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Card(
            title: AppConstants.orderSummaryLabel,
            rows: [
              _Row(
                label: AppConstants.itemCountLabel,
                value: '${order.items.length}',
              ),
              _Row(
                label: AppConstants.subtotalLabel,
                value: Formatters.formatCurrency(order.subtotal),
              ),
              _Row(
                label: AppConstants.taxLabel,
                value: Formatters.formatCurrency(order.taxAmount),
              ),
              _Row(
                label: AppConstants.orderTotalLabel,
                value: Formatters.formatCurrency(order.totalAmount),
                emphasized: true,
              ),
              _Row(
                label: AppConstants.estimatedTimeLabel,
                value: '${order.estimatedMinutes ?? 0} ${AppConstants.minutes}',
              ),
              if (order.paymentMethod != null)
                _Row(
                  label: AppConstants.paymentMethodDisplayLabel,
                  value: order.paymentMethod!.labelAr,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Row(label: AppConstants.statusLabel, value: order.status.labelAr),
          FilledButton.icon(
            onPressed: () {
              context.push('/customer/track/${order.id}');
            },
            icon: const Icon(Icons.location_on),
            label: const Text('تتبع الطلب مباشرة'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {
              context.go('/customer');
            },
            icon: const Icon(Icons.restaurant),
            label: const Text(AppConstants.backToMenu),
          ),
        ],
      ),
    );
  }


  static String formattedOrderNumber(OrderEntity order) =>
      Formatters.formatOrderId(order.id);
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value, style: style),
        ],
      ),
    );
  }
}
