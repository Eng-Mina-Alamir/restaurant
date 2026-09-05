import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/notifications/kds_alert_service.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/humanized_feedback.dart';
import '../../../../shared/widgets/logout_action_button.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../shared/widgets/stale_data_banner.dart';
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
  all('الكل', 'All', Icons.apps_rounded),
  grill('الشواية واللحوم', 'Grill & Meats', Icons.local_fire_department_rounded),
  bakery('الفرن والمخبوزات', 'Oven & Bakery', Icons.local_pizza_rounded),
  bar('المشروبات والبار', 'Drinks & Bar', Icons.local_cafe_rounded),
  expo('شاشة التجميع (Expo)', 'Expo Screen', Icons.inventory_2_rounded);

  final String titleAr;
  final String titleEn;
  final IconData icon;
  const KitchenStation(this.titleAr, this.titleEn, this.icon);

  String localizedTitle(bool isArabic) => isArabic ? titleAr : titleEn;
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
    final strings = ref.watch(appStringsProvider);
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
    // they personally claimed (استلام الطلب). Expo station sees ALL tickets for assembly.
    if (_selectedStation != KitchenStation.expo) {
      active.retainWhere(
        (o) =>
            o.assignedKitchenId == null || o.assignedKitchenId == currentUserId,
      );
    }

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
          title: AppBreakpoints.isMobile(context)
              ? Text(strings.kdsTitle)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(strings.kdsTitle),
                    const SizedBox(width: AppSpacing.sm),
                    // Station Selector Menu
                    PopupMenuButton<KitchenStation>(
                      initialValue: _selectedStation,
                      tooltip: strings.selectKitchenStation,
                      onSelected: (st) => setState(() => _selectedStation = st),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        constraints: const BoxConstraints(minHeight: 48),
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
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _selectedStation.localizedTitle(strings.isArabic),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, size: 20),
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
                                          Text(s.localizedTitle(strings.isArabic)),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                    ),
                  ],
                ),
          actions: [
            if (AppBreakpoints.isMobile(context))
              PopupMenuButton<KitchenStation>(
                initialValue: _selectedStation,
                tooltip: strings.stationTooltip(
                  _selectedStation.localizedTitle(strings.isArabic),
                ),
                onSelected: (st) => setState(() => _selectedStation = st),
                icon: Icon(_selectedStation.icon),
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
                                    Text(s.localizedTitle(strings.isArabic)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
              ),
            if (badge > 0)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                child: Center(
                  child: Tooltip(
                    message: '$badge طلبات جديدة واردة للمطبخ',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      onTap: () {
                        AppHaptics.selectionTap();
                        ref.read(newOrderNotifierProvider).reset();
                        HumanSnackBar.success(
                          context,
                          HumanCopy.alertsReviewed,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Badge(
                          label: Text('$badge'),
                          child: Icon(
                            Icons.notifications_active_outlined,
                            color: StatusColors.tone(
                              SemanticTone.warning,
                              Theme.of(context).brightness,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.history_rounded),
              tooltip: strings.recentCompletedOrdersTitle,
              onPressed: () => _showRecentCompletedOrdersSheet(context, ref),
            ),
            const LogoutActionButton(),
          ],
          bottom: AppBreakpoints.isMobile(context) && filteredActive.isNotEmpty
              ? TabBar(
                  tabs: [
                    Tab(
                      text:
                          '${strings.kdsPending} (${pendingList.length})',
                    ),
                    Tab(
                      text:
                          '${strings.kdsPreparing} (${preparingList.length})',
                    ),
                    Tab(text: '${strings.kdsReady} (${readyList.length})'),
                  ],
                )
              : null,
        ),
        body: Column(
          children: [
            if (!ref.watch(isOnlineProvider))
              StaleDataBanner(
                lastUpdated: DateTime.now(),
                onRetry: () {
                  ref.invalidate(ordersControllerProvider);
                  ref.invalidate(tableControllerProvider);
                },
              ),
            Expanded(
              child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ordersControllerProvider);
            ref.invalidate(tableControllerProvider);
          },
          child: active.isEmpty
              ? const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 500,
                    child: EmptyState(
                      message: HumanCopy.kitchenCalmSubtitle,
                      title: HumanCopy.kitchenCalmTitle,
                      icon: Icons.sentiment_satisfied_alt_outlined,
                    ),
                  ),
                )
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
                          title: strings.kdsPending,
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
                          title: strings.kdsPreparing,
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
                          title: strings.kdsReady,
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
                          title: strings.kdsPending,
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
                          title: strings.kdsPreparing,
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
                          title: strings.kdsReady,
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
          ),
        ],
      ),
    ),
    );
  }

  /// Claims [order] for [currentUserId], resetting any new-order badge.
  Future<void> _claim(OrderEntity order, String? currentUserId) async {
    ref.read(newOrderNotifierProvider).reset();
    AppHaptics.actionSuccess();
    await ref
        .read(ordersControllerProvider.notifier)
        .claim(order.id, kitchenUserId: currentUserId);
    if (mounted) {
      HumanSnackBar.success(context, HumanCopy.claimedWarm);
    }
  }

  /// Shows the guarded revert confirmation for [order], then applies the
  /// revert attributed to the current chef.
  Future<void> _confirmAndRevert(
    BuildContext context,
    OrderEntity order,
    OrderStatus target,
    String actorId,
  ) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          strings.kdsRevertPrompt(target.localizedLabel(strings.isArabic)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.kdsRevertConfirmAction),
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
    final prevStatus = order.status;
    final next = _nextStatus(order.status, order.orderType);
    if (next == null) return;

    // When dealing with delivery orders:
    // 1. If moving preparing -> ready, advance to ready and offer driver assignment sheet.
    // 2. If already ready, advancing means handing over to the driver. Only allow if a driver is assigned!
    if (order.orderType == OrderType.delivery && order.status == OrderStatus.ready) {
      if (order.driverId == null) {
        // Must assign a driver before handing over
        await KdsDriverAssignmentSheet.show(context, order: order);
        return;
      }
    } else if (order.orderType == OrderType.delivery &&
        next == OrderStatus.ready &&
        order.driverId == null) {
      ref.read(kdsAlertServiceProvider).alertOrderReady();
      AppHaptics.actionSuccess();
      await ref
          .read(ordersControllerProvider.notifier)
          .updateStatus(order.id, OrderStatus.ready);
      if (context.mounted) {
        await KdsDriverAssignmentSheet.show(context, order: order);
      }
      return;
    }

    ref.read(kdsAlertServiceProvider).alertOrderReady();
    AppHaptics.actionSuccess();
    await ref
        .read(ordersControllerProvider.notifier)
        .updateStatus(order.id, next);

    if (context.mounted && (next == OrderStatus.served || next == OrderStatus.completed)) {
      final orderShortId = order.id.length > 6 ? order.id.substring(order.id.length - 4) : order.id;
      ScaffoldMessenger.of(context).clearSnackBars();
      final successBg = StatusColors.tone(
        SemanticTone.success,
        Theme.of(context).brightness,
      );
      // Terminal orders are immutable: served→completed has no legal undo,
      // so only offer "تراجع" when the backward move is allowed
      // (e.g. ready→served can go back to ready).
      final canUndo = next.canRevertTo(prevStatus);
      final message = (order.orderType == OrderType.delivery && next == OrderStatus.served)
          ? 'تم تسليم الطلب #$orderShortId للمندوب بنجاح 🛵'
          : 'أحسنت يا شيف! الطلب #$orderShortId أصبح جاهزاً للتقديم';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: successBg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          action: canUndo
              ? SnackBarAction(
                  label: 'تراجع',
                  textColor: Colors.white,
                  onPressed: () async {
                    final authUser = ref.read(authControllerProvider).user;
                    final reverted = await ref
                        .read(ordersControllerProvider.notifier)
                        .revertStatus(order.id, prevStatus, actorId: authUser?.id ?? 'chef');
                    if (context.mounted) {
                      if (reverted != null) {
                        HumanSnackBar.info(context, 'أعدنا الطلب إلى المطبخ — لا عليك');
                      } else {
                        HumanSnackBar.error(
                          context,
                          ref.read(appStringsProvider).orderRevertFailed(orderShortId),
                        );
                      }
                    }
                  },
                )
              : null,
        ),
      );
    } else if (context.mounted) {
      HumanSnackBar.success(context, HumanCopy.advancedWarm);
    }
  }

  void _showRecentCompletedOrdersSheet(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);
    final allOrders = ref.read(ordersControllerProvider);
    final completedOrders = allOrders
        .where((o) => o.status == OrderStatus.served || o.status == OrderStatus.completed)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) {
          final theme = Theme.of(ctx);
          final colorScheme = theme.colorScheme;

          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history_rounded, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          strings.recentDeliveredWithCount(completedOrders.length),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  strings.revertHint,
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: completedOrders.isEmpty
                      ? Center(
                          child: Text(
                            strings.noRecentDelivered,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: completedOrders.length,
                          separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (ctx, index) {
                            final order = completedOrders[index];
                            final orderIdShort = order.id.length > 6
                                ? order.id.substring(order.id.length - 4)
                                : order.id;

                            return Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                side: BorderSide(color: colorScheme.outlineVariant),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  foregroundColor: const Color(0xFF10B981),
                                  child: const Icon(Icons.done_all_rounded),
                                ),
                                title: Text(
                                  strings.orderWithType(
                                    orderIdShort,
                                    order.orderType.localizedLabel(strings.isArabic),
                                  ),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  strings.itemsWithStatus(
                                    order.items.fold<int>(0, (s, i) => s + i.quantity),
                                    order.status.localizedLabel(strings.isArabic),
                                  ),
                                ),
                                trailing: Builder(
                                  builder: (_) {
                                    // Only served→ready is a legal revert. Terminal
                                    // orders (completed/cancelled) are immutable,
                                    // so they get a disabled badge instead of an
                                    // action that would silently fail.
                                    final canRevert = order.status.canRevertTo(OrderStatus.ready);
                                    if (!canRevert) {
                                      return Tooltip(
                                        message: strings.orderFinalNoRevert,
                                        child: FilledButton.tonalIcon(
                                          icon: const Icon(Icons.lock_outline_rounded, size: 16),
                                          label: Text(strings.orderFinalNoRevert),
                                          onPressed: null,
                                        ),
                                      );
                                    }
                                    return FilledButton.tonalIcon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: colorScheme.primaryContainer,
                                        foregroundColor: colorScheme.onPrimaryContainer,
                                      ),
                                      icon: const Icon(Icons.undo_rounded, size: 16),
                                      label: Text(strings.backToKitchen),
                                      onPressed: () async {
                                        final authUser = ref.read(authControllerProvider).user;
                                        final reverted = await ref
                                            .read(ordersControllerProvider.notifier)
                                            .revertStatus(order.id, OrderStatus.ready, actorId: authUser?.id ?? 'chef');
                                        if (!sheetContext.mounted) return;
                                        if (reverted != null) {
                                          Navigator.of(sheetContext).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(strings.orderBackToReady(orderIdShort)),
                                              backgroundColor: const Color(0xFF10B981),
                                            ),
                                          );
                                        } else {
                                          HumanSnackBar.error(
                                            sheetContext,
                                            strings.orderRevertFailed(orderIdShort),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Maps a status to the next KDS stage based on order type, or null when terminal.
  OrderStatus? _nextStatus(OrderStatus status, OrderType orderType) {
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

class _KdsColumn extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
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
                      strings.kdsEmptyColumn,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
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

class _OrderCard extends ConsumerWidget {
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

  /// Bilingual urgency label for the badge (emoji-free).
  static String _urgencyLabel(AppStrings strings, int minutes, SemanticTone tone) => switch (tone) {
    SemanticTone.success => strings.onTimeMinutes(minutes),
    SemanticTone.warning => strings.warningMinutes(minutes),
    _ => strings.lateMinutes(minutes),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final buttonLabel = switch (order.status) {
      OrderStatus.pending => strings.kdsPreparing,
      OrderStatus.preparing => strings.kdsReady,
      OrderStatus.ready => order.orderType == OrderType.delivery
          ? (order.driverId == null ? strings.assignDriverChip : strings.handoverToDriver)
          : strings.kdsCompleting,
      _ => strings.ok,
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
                          strings.kdsNewBadge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (displayTable != null)
                      Chip(
                        label: Text(
                          '${strings.orderTablePrefix} $displayTable',
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    else if (order.orderType == OrderType.takeaway)
                      Chip(
                        label: Text(strings.takeawayShort),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    else if (order.orderType == OrderType.delivery)
                      if (order.status == OrderStatus.ready || order.driverId != null)
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
                                ? strings.driverAssignedChip
                                : strings.assignDriverChip,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onPressed: () =>
                              KdsDriverAssignmentSheet.show(context, order: order),
                        )
                      else
                        Chip(
                          avatar: const Icon(
                            Icons.two_wheeler_outlined,
                            size: 16,
                          ),
                          label: Text(
                            order.orderType.localizedLabel(strings.isArabic),
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
                    '${strings.specialNotesLabel}: ${item.specialNotes}',
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
                    strings.itemCountLine(order.items.fold<int>(0, (sum, i) => sum + i.quantity)),
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
                    label: _urgencyLabel(strings, elapsed, urgencyTone),
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
                  tooltip: strings.printKitchenTicket,
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
                        strings.kdsClaimOrder,
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
                    tooltip: strings.kdsRevertTooltip,
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
