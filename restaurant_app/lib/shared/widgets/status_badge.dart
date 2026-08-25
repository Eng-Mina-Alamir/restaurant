import 'package:flutter/material.dart';

import '../../core/domain/enums.dart';
import '../../core/theme/status_colors.dart';
import '../../features/inventory/domain/entities/inventory_item_entity.dart';
import '../animations/animated_status_badge.dart';

/// Unified, brightness-aware status badge.
///
/// Thin wrapper around [AnimatedStatusBadge] that:
/// - resolves the status color from [StatusColors] using the current theme
///   brightness (no manual light/dark branching at call sites);
/// - wraps the badge in a live-region `Semantics` node so screen readers
///   announce status changes automatically;
/// - provides per-domain factories with sensible default icons.
class StatusBadge extends StatelessWidget {
  const StatusBadge._({
    required this.label,
    required this.colorResolver,
    this.icon,
  });

  final String label;
  final IconData? icon;

  /// Resolves the badge color for the active [Brightness].
  final Color Function(Brightness brightness) colorResolver;

  /// Badge for an [OrderStatus] (colors delegated to `KdsColors.statusColor`).
  factory StatusBadge.order(OrderStatus status, {IconData? icon}) =>
      StatusBadge._(
        label: status.labelAr,
        icon: icon ?? _orderIcons[status],
        colorResolver: (brightness) => StatusColors.order(status, brightness),
      );

  /// Badge for a [TableStatus].
  factory StatusBadge.table(TableStatus status, {IconData? icon}) =>
      StatusBadge._(
        label: status.labelAr,
        icon: icon ?? _tableIcons[status],
        colorResolver: (brightness) => StatusColors.table(status, brightness),
      );

  /// Badge for a [DeliveryStatus].
  factory StatusBadge.delivery(DeliveryStatus status, {IconData? icon}) =>
      StatusBadge._(
        label: status.labelAr,
        icon: icon ?? _deliveryIcons[status],
        colorResolver: (brightness) =>
            StatusColors.delivery(status, brightness),
      );

  /// Badge for an inventory [StockStatus].
  factory StatusBadge.stock(StockStatus status, {IconData? icon}) =>
      StatusBadge._(
        label: switch (status) {
          StockStatus.sufficient => 'كافٍ',
          StockStatus.low => 'منخفض',
          StockStatus.outOfStock => 'منتهي',
        },
        icon: icon ?? _stockIcons[status],
        colorResolver: (brightness) => StatusColors.stock(status, brightness),
      );

  /// Badge for a generic [SemanticTone] when no domain enum applies
  /// (e.g. KDS ticket-age urgency mapped onto success/warning/danger).
  factory StatusBadge.tone({
    required String label,
    required SemanticTone semanticTone,
    IconData? icon,
  }) =>
      StatusBadge._(
        label: label,
        icon: icon,
        colorResolver: (brightness) =>
            StatusColors.tone(semanticTone, brightness),
      );

  static const Map<OrderStatus, IconData> _orderIcons = {
    OrderStatus.pending: Icons.schedule,
    OrderStatus.confirmed: Icons.check_circle_outline,
    OrderStatus.preparing: Icons.local_fire_department_outlined,
    OrderStatus.ready: Icons.takeout_dining_outlined,
    OrderStatus.served: Icons.room_service_outlined,
    OrderStatus.completed: Icons.done_all_rounded,
    OrderStatus.cancelled: Icons.cancel_outlined,
  };

  static const Map<TableStatus, IconData> _tableIcons = {
    TableStatus.available: Icons.table_restaurant_outlined,
    TableStatus.occupied: Icons.event_seat,
    TableStatus.reserved: Icons.book_online_outlined,
    TableStatus.needsCleaning: Icons.cleaning_services_outlined,
  };

  static const Map<DeliveryStatus, IconData> _deliveryIcons = {
    DeliveryStatus.pending: Icons.schedule,
    DeliveryStatus.accepted: Icons.check_circle_outline,
    DeliveryStatus.pickedUp: Icons.shopping_bag_outlined,
    DeliveryStatus.inTransit: Icons.delivery_dining_outlined,
    DeliveryStatus.delivered: Icons.done_all_rounded,
    DeliveryStatus.failed: Icons.error_outline,
  };

  static const Map<StockStatus, IconData> _stockIcons = {
    StockStatus.sufficient: Icons.inventory_2_outlined,
    StockStatus.low: Icons.warning_amber_outlined,
    StockStatus.outOfStock: Icons.block,
  };

  @override
  Widget build(BuildContext context) {
    final color = colorResolver(Theme.of(context).brightness);

    return Semantics(
      label: label,
      liveRegion: true,
      excludeSemantics: true,
      child: AnimatedStatusBadge(label: label, color: color, icon: icon),
    );
  }
}
