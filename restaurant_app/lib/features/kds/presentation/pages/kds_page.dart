import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/notifications/kds_alert_service.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/logout_action_button.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../../table_management/presentation/controllers/table_controller.dart';
import '../widgets/kds_driver_assignment_sheet.dart';
import '../widgets/ticket_print_dialog.dart';

/// Kitchen Display System: live order columns (pending / preparing / ready).
///
/// Watches [ordersControllerProvider] so orders sent by a waiter appear
/// immediately, and the kitchen advances each order's status with a button.
class KdsPage extends ConsumerStatefulWidget {
  const KdsPage({super.key});

  @override
  ConsumerState<KdsPage> createState() => _KdsPageState();
}

enum KitchenStation {
  all('الكل', Icons.apps_rounded),
  grill('الشواية واللحوم', Icons.local_fire_department_rounded),
  bakery('الفرن والمخبوزات', Icons.local_pizza_rounded),
  bar('المشروبات والبار', Icons.local_cafe_rounded),
  expo('شاشة التجميع (Expo)', Icons.inventory_2_rounded);

  final String titleAr;
  final IconData icon;
  const KitchenStation(this.titleAr, this.icon);
}

class _KdsPageState extends ConsumerState<KdsPage> {
  static const _elapsedRefreshInterval = Duration(minutes: 1);

  Timer? _elapsedTimer;
  int _lastOrderCount = 0;
  KitchenStation _selectedStation = KitchenStation.all;

  bool _orderMatchesStation(OrderEntity order, KitchenStation station) {
    if (station == KitchenStation.all || station == KitchenStation.expo) {
      return true;
    }
    return order.items.any((item) {
      final cat = item.menuItem.categoryId.toLowerCase();
      final name = item.menuItem.name.toLowerCase();
      switch (station) {
        case KitchenStation.grill:
          return cat.contains('grill') ||
              cat.contains('meat') ||
              cat.contains('لحوم') ||
              cat.contains('مشويات') ||
              name.contains('كباب') ||
              name.contains('كفتة') ||
              name.contains('لحم') ||
              name.contains('شيش') ||
              name.contains('برجر') ||
              name.contains('دجاج') ||
              name.contains('فراخ') ||
              name.contains('شاورما');
        case KitchenStation.bakery:
          return cat.contains('pizza') ||
              cat.contains('bakery') ||
              cat.contains('مخبوزات') ||
              cat.contains('بيتزا') ||
              cat.contains('فطائر') ||
              name.contains('بيتزا') ||
              name.contains('عيش') ||
              name.contains('طاجن') ||
              name.contains('حواوشي');
        case KitchenStation.bar:
          return cat.contains('drink') ||
              cat.contains('beverage') ||
              cat.contains('مشروبات') ||
              cat.contains('عصائر') ||
              name.contains('عصير') ||
              name.contains('شاي') ||
              name.contains('قهوة') ||
              name.contains('مياه') ||
              name.contains('بيبسي') ||
              name.contains('مانجو');
        default:
          return true;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Keep the "منذ N دقيقة" counters fresh even when no order changes occur.
    _elapsedTimer = Timer.periodic(_elapsedRefreshInterval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

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

    // Current chef identity (auth state first, Supabase session fallback) —
    // same convention as the loyalty/ratings features.
    final currentUserId =
        ref.watch(authControllerProvider).user?.id ??
        ref.watch(supabaseCurrentUserProvider)?.id;

    final active = orders.where((o) => !o.status.isTerminal).toList();

    // KDS multi-chef: each chef only sees unclaimed tickets plus the ones
    // they personally claimed (استلام الطلب).
    active.retainWhere(
      (o) =>
          o.assignedKitchenId == null || o.assignedKitchenId == currentUserId,
    );

    // Filter by Kitchen Station
    final filteredActive =
        active.where((o) => _orderMatchesStation(o, _selectedStation)).toList();

    // Alert when new pending orders arrive
    final pendingCount = filteredActive
        .where((o) => o.status == OrderStatus.pending)
        .length;
    if (pendingCount > _lastOrderCount) {
      ref.read(kdsAlertServiceProvider).alertNewOrder();
    }
    _lastOrderCount = pendingCount;

    final pendingList =
        filteredActive.where((o) => o.status == OrderStatus.pending).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final preparingList =
        filteredActive.where((o) => o.status == OrderStatus.preparing).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final readyList =
        filteredActive.where((o) => o.status == OrderStatus.ready).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text(AppConstants.kdsTitle),
              const SizedBox(width: AppSpacing.sm),
              // Station Selector Menu
              PopupMenuButton<KitchenStation>(
                initialValue: _selectedStation,
                tooltip: 'اختيار محطة المطبخ',
                onSelected: (st) => setState(() => _selectedStation = st),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedStation.icon,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedStation.titleAr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, size: 16),
                    ],
                  ),
                ),
                itemBuilder:
                    (ctx) =>
                        KitchenStation.values
                            .map(
                              (s) => PopupMenuItem(
                                value: s,
                                child: Row(
                                  children: [
                                    Icon(s.icon, size: 18),
                                    const SizedBox(width: 8),
                                    Text(s.titleAr),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
              ),
            ],
          ),
          actions: [
            if (badge > 0)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                child: Center(
                  child: Tooltip(
                    message: '$badge طلبات جديدة واردة للمطبخ',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      onTap: () {
                        ref.read(newOrderNotifierProvider).reset();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم تأكيد مراجعة $badge تنبيهات للطلبات الجديدة 🛎️'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Badge(
                          label: Text('$badge'),
                          child: const Icon(Icons.notifications_active, color: Color(0xFFF59E0B)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const LogoutActionButton(),
          ],
          bottom: AppBreakpoints.isMobile(context) && filteredActive.isNotEmpty
              ? TabBar(
                  tabs: [
                    Tab(
                      text:
                          '${AppConstants.kdsPending} (${pendingList.length})',
                    ),
                    Tab(
                      text:
                          '${AppConstants.kdsPreparing} (${preparingList.length})',
                    ),
                    Tab(text: '${AppConstants.kdsReady} (${readyList.length})'),
                  ],
                )
              : null,
        ),
        body: active.isEmpty
            ? const EmptyOrdersState()
            : Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  final pendingColor = KdsColors.statusColor(
                    OrderStatus.pending,
                    theme.brightness,
                  );
                  final preparingColor = KdsColors.statusColor(
                    OrderStatus.preparing,
                    theme.brightness,
                  );
                  final readyColor = KdsColors.statusColor(
                    OrderStatus.ready,
                    theme.brightness,
                  );

                  return ResponsiveLayout(
                    mobile: TabBarView(
                      children: [
                        _KdsColumn(
                          title: AppConstants.kdsPending,
                          color: pendingColor,
                          icon: Icons.schedule,
                          orders: pendingList,
                          onAdvance: (order) => _advance(context, ref, order),
                          onClaim: (order) => _claim(order, currentUserId),
                          onRevert: (order, target) => _confirmAndRevert(
                            context,
                            order,
                            target,
                            currentUserId ?? '',
                          ),
                          tableNumberById: tableNumberById,
                          isExpanded: false,
                        ),
                        _KdsColumn(
                          title: AppConstants.kdsPreparing,
                          color: preparingColor,
                          icon: Icons.soup_kitchen_outlined,
                          orders: preparingList,
                          onAdvance: (order) => _advance(context, ref, order),
                          onClaim: (order) => _claim(order, currentUserId),
                          onRevert: (order, target) => _confirmAndRevert(
                            context,
                            order,
                            target,
                            currentUserId ?? '',
                          ),
                          tableNumberById: tableNumberById,
                          isExpanded: false,
                        ),
                        _KdsColumn(
                          title: AppConstants.kdsReady,
                          color: readyColor,
                          icon: Icons.check_circle_outline,
                          orders: readyList,
                          onAdvance: (order) => _advance(context, ref, order),
                          onClaim: (order) => _claim(order, currentUserId),
                          onRevert: (order, target) => _confirmAndRevert(
                            context,
                            order,
                            target,
                            currentUserId ?? '',
                          ),
                          tableNumberById: tableNumberById,
                          isExpanded: false,
                        ),
                      ],
                    ),
                    tablet: Row(
                      children: [
                        _KdsColumn(
                          title: AppConstants.kdsPending,
                          color: pendingColor,
                          icon: Icons.schedule,
                          orders: pendingList,
                          onAdvance: (order) => _advance(context, ref, order),
                          onClaim: (order) => _claim(order, currentUserId),
                          onRevert: (order, target) => _confirmAndRevert(
                            context,
                            order,
                            target,
                            currentUserId ?? '',
                          ),
                          tableNumberById: tableNumberById,
                        ),
                        _KdsColumn(
                          title: AppConstants.kdsPreparing,
                          color: preparingColor,
                          icon: Icons.soup_kitchen_outlined,
                          orders: preparingList,
                          onAdvance: (order) => _advance(context, ref, order),
                          onClaim: (order) => _claim(order, currentUserId),
                          onRevert: (order, target) => _confirmAndRevert(
                            context,
                            order,
                            target,
                            currentUserId ?? '',
                          ),
                          tableNumberById: tableNumberById,
                        ),
                        _KdsColumn(
                          title: AppConstants.kdsReady,
                          color: readyColor,
                          icon: Icons.check_circle_outline,
                          orders: readyList,
                          onAdvance: (order) => _advance(context, ref, order),
                          onClaim: (order) => _claim(order, currentUserId),
                          onRevert: (order, target) => _confirmAndRevert(
                            context,
                            order,
                            target,
                            currentUserId ?? '',
                          ),
                          tableNumberById: tableNumberById,
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  /// Claims [order] for [currentUserId], resetting any new-order badge.
  Future<void> _claim(OrderEntity order, String? currentUserId) async {
    ref.read(newOrderNotifierProvider).reset();
    await ref
        .read(ordersControllerProvider.notifier)
        .claim(order.id, kitchenUserId: currentUserId);
  }

  /// Shows the guarded revert confirmation for [order], then applies the
  /// revert attributed to the current chef.
  Future<void> _confirmAndRevert(
    BuildContext context,
    OrderEntity order,
    OrderStatus target,
    String actorId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('تراجع إلى ${target.labelAr}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppConstants.ok),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppConstants.kdsRevertConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await ref
        .read(ordersControllerProvider.notifier)
        .revertStatus(order.id, target, actorId: actorId);
  }

  Future<void> _advance(
    BuildContext context,
    WidgetRef ref,
    OrderEntity order,
  ) async {
    ref.read(newOrderNotifierProvider).reset();

    // When advancing a delivery order to ready or when ready without a driver,
    // prompt the chef to select the delivery driver directly.
    if (order.orderType == OrderType.delivery && order.driverId == null) {
      final assigned = await KdsDriverAssignmentSheet.show(context, order: order);
      if (assigned == true) return;
    }

    final next = _nextStatus(order.status);
    if (next == null) return;
    ref.read(kdsAlertServiceProvider).alertOrderReady();
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
    required this.icon,
    required this.orders,
    required this.onAdvance,
    required this.onClaim,
    required this.onRevert,
    required this.tableNumberById,
    this.isExpanded = true,
  });

  final String title;
  final Color color;
  final IconData icon;
  final List<OrderEntity> orders;
  final ValueChanged<OrderEntity> onAdvance;

  /// Claims an unclaimed ticket for the current chef (استلام الطلب).
  final ValueChanged<OrderEntity> onClaim;

  /// Requests a guarded revert of [OrderEntity] to [OrderStatus].
  final void Function(OrderEntity order, OrderStatus target) onRevert;
  final Map<String, int> tableNumberById;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Container(
      margin: const EdgeInsets.all(AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    '$title (${orders.length})',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
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
                          onClaim: onClaim,
                          onRevert: onRevert,
                          tableNumber: order.tableId == null
                              ? null
                              : tableNumberById[order.tableId],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );

    if (isExpanded) {
      return Expanded(child: content);
    }
    return content;
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onAdvance,
    required this.onClaim,
    required this.onRevert,
    this.tableNumber,
  });

  final OrderEntity order;
  final ValueChanged<OrderEntity> onAdvance;

  /// Claims this unclaimed ticket for the current chef (استلام الطلب).
  final ValueChanged<OrderEntity> onClaim;

  /// Requests a guarded revert of [order] to the mapped target status.
  final void Function(OrderEntity order, OrderStatus target) onRevert;
  final int? tableNumber;

  /// Orders younger than this threshold are considered "new".
  static const Duration _newThreshold = Duration(minutes: 2);

  bool get _isNew => DateTime.now().difference(order.createdAt) < _newThreshold;

  /// Elapsed-time urgency mapped onto the audited semantic tones
  /// (< 5 min on time, < 10 min warning, otherwise late).
  static SemanticTone _urgencyTone(int minutes) {
    if (minutes < 5) return SemanticTone.success;
    if (minutes < 10) return SemanticTone.warning;
    return SemanticTone.danger;
  }

  /// Icon shown next to the urgency label on the ticket card.
  static IconData _urgencyIcon(SemanticTone tone) => switch (tone) {
    SemanticTone.success => Icons.check_circle_outline,
    SemanticTone.warning => Icons.warning_amber_rounded,
    _ => Icons.error_outline,
  };

  /// Arabic urgency label for the badge (emoji-free).
  static String _urgencyLabel(int minutes, SemanticTone tone) => switch (tone) {
    SemanticTone.success => 'في الوقت ($minutes د)',
    SemanticTone.warning => 'تنبيه ($minutes د)',
    _ => 'متأخر! ($minutes د)',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonLabel = switch (order.status) {
      OrderStatus.pending => AppConstants.kdsPreparing,
      OrderStatus.preparing => AppConstants.kdsReady,
      OrderStatus.ready => order.orderType == OrderType.delivery
          ? (order.driverId == null ? 'تسليم للمندوب' : 'تم التسليم للمندوب')
          : AppConstants.kdsCompleting,
      _ => AppConstants.ok,
    };

    // Semantic keys so tests can target the advance action without fragile
    // Arabic text lookups (the labels also appear as column titles).
    final actionKey = switch (order.status) {
      OrderStatus.pending => const ValueKey<String>('kds_action_preparing'),
      OrderStatus.ready => const ValueKey<String>('kds_action_resume'),
      _ => null,
    };

    // Guarded undo: only legal single-step backward moves offer a revert
    // (ready→preparing, served→ready); terminal statuses never do.
    final revertTarget = _revertTargetOf(order.status);
    final canUndo =
        revertTarget != null && order.status.canRevertTo(revertTarget);

    final elapsed = _elapsedMinutes(order.createdAt);
    final urgencyTone = _urgencyTone(elapsed);
    final urgencyColor = StatusColors.tone(urgencyTone, theme.brightness);
    final highlight = _isNew ? theme.colorScheme.primary : urgencyColor;

    final displayTable =
        tableNumber ??
        (order.tableId != null
            ? int.tryParse(order.tableId!.replaceAll(RegExp(r'[^0-9]'), ''))
            : null);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: highlight, width: 1.8),
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
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          AppConstants.kdsNewBadge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (displayTable != null)
                      Chip(
                        label: Text(
                          '${AppConstants.orderTablePrefix} $displayTable',
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    else if (order.orderType == OrderType.takeaway)
                      const Chip(
                        label: Text('سفري'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    else if (order.orderType == OrderType.delivery)
                      ActionChip(
                        avatar: Icon(
                          order.driverId != null
                              ? Icons.two_wheeler_rounded
                              : Icons.person_add_alt_1_rounded,
                          size: 16,
                          color: order.driverId != null
                              ? const Color(0xFF10B981)
                              : theme.colorScheme.primary,
                        ),
                        label: Text(
                          order.driverId != null
                              ? 'المندوب معيّن 🛵'
                              : 'تعيين مندوب',
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onPressed: () =>
                            KdsDriverAssignmentSheet.show(context, order: order),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final item in order.items) ...[
              Text(
                '${item.quantity} × ${item.menuItem.name}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.selectedModifiers.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.md,
                  ),
                  child: Text(
                    item.selectedModifiers.map((m) => m.name).join('، '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
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
            if (elapsed >= 1)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: StatusBadge.tone(
                    label: _urgencyLabel(elapsed, urgencyTone),
                    semanticTone: urgencyTone,
                    icon: _urgencyIcon(urgencyTone),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                IconButton.outlined(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  tooltip: 'طباعة تذكرة المطبخ',
                  icon: const Icon(Icons.print_outlined, size: 18),
                  onPressed: () => TicketPrintDialog.show(
                    context,
                    order: order,
                    tableDisplay: displayTable?.toString(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                if (order.assignedKitchenId == null) ...[
                  Expanded(
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                      ),
                      onPressed: () => onClaim(order),
                      child: Text(
                        AppConstants.kdsClaimOrder,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: FilledButton.tonal(
                    key: actionKey,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                    ),
                    onPressed: () => onAdvance(order),
                    child: Text(
                      buttonLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (canUndo) ...[
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: AppConstants.kdsRevertTooltip,
                    icon: const Icon(Icons.undo, size: 18),
                    onPressed: () => onRevert(order, revertTarget),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _elapsedMinutes(DateTime createdAt) =>
      Formatters.elapsedMinutes(createdAt);

  /// Maps a status to its revert target, or null when no backward move is
  /// defined (pending/preparing/completed/cancelled never offer undo).
  static OrderStatus? _revertTargetOf(OrderStatus status) => switch (status) {
    OrderStatus.ready => OrderStatus.preparing,
    OrderStatus.served => OrderStatus.ready,
    _ => null,
  };
}
