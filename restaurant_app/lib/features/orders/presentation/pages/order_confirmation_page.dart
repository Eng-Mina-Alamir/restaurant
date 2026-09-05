import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/animations/animated_success_checkmark.dart';
import '../../../../shared/animations/fade_slide_transition.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/entities/order_entity.dart';

/// Confirmation screen shown after a customer places an order.
///
/// Summarizes the placed [order] with celebratory animations, reference number,
/// items, money figures and status.
class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCancelled = order.status == OrderStatus.cancelled;
    final totalQty = order.items.fold<int>(0, (s, i) => s + i.quantity);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(AppConstants.orderConfirmationTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: isCancelled
                ? Icon(
                    Icons.cancel_outlined,
                    size: 80,
                    color: theme.colorScheme.error,
                  )
                : const AnimatedSuccessCheckmark(
                    size: 80,
                    duration: Duration(milliseconds: 900),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeSlideTransitionWidget(
            delay: const Duration(milliseconds: 200),
            child: Column(
              children: [
                Text(
                  AppConstants.orderPlacedMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppConstants.orderNumberLabel,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formattedOrderNumber(order),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FadeSlideTransitionWidget(
            delay: const Duration(milliseconds: 300),
            child: _Card(
              title: AppConstants.orderItemsLabel,
              rows: [
                for (final item in order.items)
                  _Row(
                    label: '${item.quantity} × ${item.menuItem.name}',
                    value: Formatters.formatCurrency(item.itemTotal),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeSlideTransitionWidget(
            delay: const Duration(milliseconds: 400),
            child: _Card(
              title: AppConstants.orderSummaryLabel,
              rows: [
                _Row(
                  label: AppConstants.itemCountLabel,
                  value: '$totalQty',
                ),
                _Row(
                  label: AppConstants.subtotalLabel,
                  value: Formatters.formatCurrency(order.subtotal),
                ),
                if (order.discountAmount > 0)
                  _Row(
                    label: 'خصم الكوبون',
                    value: '- ${Formatters.formatCurrency(order.discountAmount)}',
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
                  label: 'نوع الطلب',
                  value: order.orderType.localizedLabel(
                    Localizations.localeOf(context).languageCode == 'ar',
                  ),
                ),
                if (order.orderType == OrderType.dineIn && order.tableId != null)
                  _Row(label: 'الطاولة', value: '${order.tableId}'),
                if (order.orderType == OrderType.delivery &&
                    order.deliveryAddress != null)
                  _Row(label: 'عنوان التوصيل', value: order.deliveryAddress!),
                _Row(
                  label: AppConstants.estimatedTimeLabel,
                  value: order.estimatedMinutes != null && order.estimatedMinutes! > 0
                      ? '${order.estimatedMinutes} ${AppConstants.minutes}'
                      : '—',
                ),
                if (order.paymentMethod != null)
                  _Row(
                    label: AppConstants.paymentMethodDisplayLabel,
                    value: order.paymentMethod!.labelAr,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeSlideTransitionWidget(
            delay: const Duration(milliseconds: 500),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppConstants.statusLabel,
                        style: theme.textTheme.bodyMedium,
                      ),
                      StatusBadge.order(order.status),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () =>
                        context.push('/customer/track/${order.id}'),
                    icon: const Icon(Icons.location_on),
                    label: const Text(
                      'تتبع الطلب مباشرة',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => context.go('/customer'),
                    icon: const Icon(Icons.restaurant),
                    label: const Text(AppConstants.backToMenu),
                  ),
                ),
              ],
            ),
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
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(value, style: style),
        ],
      ),
    );
  }
}
