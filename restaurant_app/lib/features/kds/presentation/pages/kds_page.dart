import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
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
/// High-density, high-contrast operational screen designed for kitchen staff
/// with fast readability from distance, touch targets >= 56px, and quick navigation.
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

class _KdsPageState extends ConsumerState<KdsPage>
    with SingleTickerProviderStateMixin {
  static const _elapsedRefreshInterval = Duration(seconds: 30);

  late final TabController _tabController;
  Timer? _elapsedTimer;
  int _lastOrderCount = 0;
  KitchenStation _selectedStation = KitchenStation.all;

  // Search & Filter state
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  OrderType? _selectedOrderType;
  bool _sortOldestFirst = true;

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
              cat.contains('burger') ||
              cat.contains('chicken') ||
              cat.contains('لحوم') ||
              cat.contains('مشويات') ||
              name.contains('كباب') ||
              name.contains('كفتة') ||
              name.contains('لحم') ||
              name.contains('شيش') ||
              name.contains('برجر') ||
              name.contains('burger') ||
              name.contains('دجاج') ||
              name.contains('فراخ') ||
              name.contains('شاورما');
        case KitchenStation.bakery:
          return cat.contains('pizza') ||
              cat.contains('bakery') ||
              cat.contains('pastry') ||
              cat.contains('مخبوزات') ||
              cat.contains('بيتزا') ||
              cat.contains('فطائر') ||
              name.contains('بيتزا') ||
              name.contains('pizza') ||
              name.contains('عيش') ||
              name.contains('طاجن') ||
              name.contains('حواوشي');
        case KitchenStation.bar:
          return cat.contains('drink') ||
              cat.contains('beverage') ||
              cat.contains('coffee') ||
              cat.contains('tea') ||
              cat.contains('bar') ||
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
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _elapsedTimer = Timer.periodic(_elapsedRefreshInterval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
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
    final theme = Theme.of(context);
    final isMobile = AppBreakpoints.isMobile(context);

    // Current chef identity
    final currentUserId =
        ref.watch(authControllerProvider).user?.id ??
        ref.watch(supabaseCurrentUserProvider)?.id;

    final active = orders
        .where(
          (o) =>
              o.status == OrderStatus.pending ||
              o.status == OrderStatus.confirmed ||
              o.status == OrderStatus.preparing ||
              o.status == OrderStatus.ready,
        )
        .toList();

    // Multi-chef station visibility: Expo sees ALL, others see unclaimed + personal claims
    if (_selectedStation != KitchenStation.expo) {
      active.retainWhere(
        (o) =>
            o.assignedKitchenId == null || o.assignedKitchenId == currentUserId,
      );
    }

    // Filter by Kitchen Station
    final stationActive =
        active.where((o) => _orderMatchesStation(o, _selectedStation)).toList();

    // Alert when new pending orders arrive (confirmed counts as pending)
    final pendingCount = stationActive
        .where(
          (o) =>
              o.status == OrderStatus.pending ||
              o.status == OrderStatus.confirmed,
        )
        .length;
    if (pendingCount > _lastOrderCount) {
      ref.read(kdsAlertServiceProvider).alertNewOrder();
    }
    _lastOrderCount = pendingCount;

    // Apply Operational Filters (Search Query + OrderType)
    var operationalActive = stationActive;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      operationalActive = operationalActive.where((o) {
        final shortId = Formatters.formatOrderId(o.id).toLowerCase();
        final rawId = o.id.toLowerCase();
        final tableNum = o.tableId == null
            ? ''
            : (tableNumberById[o.tableId]?.toString() ?? '');
        return shortId.contains(q) || rawId.contains(q) || tableNum.contains(q);
      }).toList();
    }
    if (_selectedOrderType != null) {
      operationalActive = operationalActive
          .where((o) => o.orderType == _selectedOrderType)
          .toList();
    }

    // Late orders count across station (> 10 minutes)
    final lateCount = stationActive
        .where((o) => Formatters.elapsedMinutes(o.createdAt) >= 10)
        .length;

    // Partition into Pending, Preparing, and Ready lists
    final pendingList = operationalActive
        .where(
          (o) =>
              o.status == OrderStatus.pending ||
              o.status == OrderStatus.confirmed,
        )
        .toList();
    final preparingList = operationalActive
        .where((o) => o.status == OrderStatus.preparing)
        .toList();
    final readyList = operationalActive
        .where((o) => o.status == OrderStatus.ready)
        .toList();

    // Sorting
    if (_sortOldestFirst) {
      pendingList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      preparingList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      readyList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else {
      pendingList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      preparingList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      readyList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

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
    final isSoundMuted = ref.watch(kdsAlertServiceProvider).isMuted;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                strings.kdsTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isMobile && lateCount > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Tooltip(
                message: strings.kdsDelayedAlert,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: StatusColors.tone(
                      SemanticTone.danger,
                      theme.brightness,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: AppShadows.glow(
                      StatusColors.tone(SemanticTone.danger, theme.brightness),
                      opacity: 0.35,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        strings.kdsLateCountBadge(lateCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Search Toggle
          IconButton(
            icon: Icon(
              _isSearchExpanded
                  ? Icons.search_off_rounded
                  : Icons.search_rounded,
            ),
            tooltip: strings.kdsSearchHint,
            onPressed: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (!_isSearchExpanded) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          // Sound Mute Toggle (Always 1-tap accessible for kitchen staff)
          IconButton(
            icon: Icon(
              isSoundMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
            ),
            tooltip: strings.kdsSoundToggle,
            onPressed: () {
              setState(() {
                ref.read(kdsAlertServiceProvider).toggleMute();
              });
              HumanSnackBar.info(
                context,
                ref.read(kdsAlertServiceProvider).isMuted
                    ? strings.kdsSoundMuted
                    : strings.kdsSoundUnmuted,
              );
            },
          ),
          if (!isMobile) ...[
            // Sort Toggle
            IconButton(
              icon: Icon(
                _sortOldestFirst
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
              ),
              tooltip: _sortOldestFirst
                  ? strings.kdsSortOldestFirst
                  : strings.kdsSortNewestFirst,
              onPressed: () {
                AppHaptics.selectionTap();
                setState(() => _sortOldestFirst = !_sortOldestFirst);
              },
            ),
            // Incoming new orders badge
            if (badge > 0)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
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
                              theme.brightness,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Completed tickets history
            IconButton(
              icon: const Icon(Icons.history_rounded),
              tooltip: strings.recentCompletedOrdersTitle,
              onPressed: () => _showRecentCompletedOrdersSheet(context, ref),
            ),
            const LogoutActionButton(),
          ] else ...[
            // Mobile incoming new orders badge
            if (badge > 0)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
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
                              theme.brightness,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Mobile overflow menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: strings.isArabic ? 'المزيد' : 'More',
              onSelected: (value) async {
                AppHaptics.selectionTap();
                switch (value) {
                  case 'sort':
                    setState(() => _sortOldestFirst = !_sortOldestFirst);
                    HumanSnackBar.info(
                      context,
                      _sortOldestFirst
                          ? strings.kdsSortOldestFirst
                          : strings.kdsSortNewestFirst,
                    );
                    break;
                  case 'history':
                    _showRecentCompletedOrdersSheet(context, ref);
                    break;
                  case 'logout':
                    final messenger = ScaffoldMessenger.of(context);
                    await ref.read(authControllerProvider.notifier).logout();
                    messenger.showSnackBar(
                      const SnackBar(content: Text(AppConstants.logoutMessage)),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'sort',
                  child: Row(
                    children: [
                      Icon(
                        _sortOldestFirst
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _sortOldestFirst
                              ? strings.kdsSortOldestFirst
                              : strings.kdsSortNewestFirst,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          strings.recentCompletedOrdersTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          AppConstants.logout,
                          style: TextStyle(color: theme.colorScheme.error),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
        bottom: isMobile && operationalActive.isNotEmpty
            ? TabBar(
                controller: _tabController,
                indicatorColor: switch (_tabController.index) {
                  0 => pendingColor,
                  1 => preparingColor,
                  _ => readyColor,
                },
                indicatorWeight: 3.5,
                tabs: [
                  Tab(
                    text: '${strings.kdsPending} (${pendingList.length})',
                  ),
                  Tab(
                    text: '${strings.kdsPreparing} (${preparingList.length})',
                  ),
                  Tab(
                    text: '${strings.kdsReady} (${readyList.length})',
                  ),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // Offline Banner
          if (!ref.watch(isOnlineProvider))
            StaleDataBanner(
              lastUpdated: DateTime.now(),
              onRetry: () {
                ref.invalidate(ordersControllerProvider);
                ref.invalidate(tableControllerProvider);
              },
            ),

          // Search & Filter Expandable Row
          if (_isSearchExpanded)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: strings.kdsSearchHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text(strings.kdsFilterAll),
                          selected: _selectedOrderType == null,
                          onSelected: (_) =>
                              setState(() => _selectedOrderType = null),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        FilterChip(
                          label: Text(strings.kdsFilterDineIn),
                          selected: _selectedOrderType == OrderType.dineIn,
                          onSelected: (_) => setState(
                            () => _selectedOrderType = OrderType.dineIn,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        FilterChip(
                          label: Text(strings.kdsFilterTakeaway),
                          selected: _selectedOrderType == OrderType.takeaway,
                          onSelected: (_) => setState(
                            () => _selectedOrderType = OrderType.takeaway,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        FilterChip(
                          label: Text(strings.kdsFilterDelivery),
                          selected: _selectedOrderType == OrderType.delivery,
                          onSelected: (_) => setState(
                            () => _selectedOrderType = OrderType.delivery,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Station Selector Chips Strip (Always visible)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: KitchenStation.values.map((station) {
                  final isSelected = station == _selectedStation;
                  final count = active
                      .where((o) => _orderMatchesStation(o, station))
                      .length;

                  return Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.xs,
                    ),
                    child: ChoiceChip(
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: Icon(
                        station.icon,
                        size: 16,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            station.localizedTitle(strings.isArabic),
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 13,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary.withValues(
                                      alpha: 0.25,
                                    )
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      selectedColor: theme.colorScheme.primary,
                      onSelected: (selected) {
                        if (selected) {
                          AppHaptics.selectionTap();
                          setState(() => _selectedStation = station);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Expo Station Helper Banner
          if (_selectedStation == KitchenStation.expo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.4,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      strings.kdsExpoHelp,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // KDS Delayed Alert Strip (When lateCount > 0)
          if (lateCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              color: StatusColors.tone(SemanticTone.danger, theme.brightness)
                  .withValues(alpha: 0.12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: StatusColors.tone(
                      SemanticTone.danger,
                      theme.brightness,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${strings.kdsDelayedAlert}: ${strings.kdsLateCountBadge(lateCount)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: StatusColors.tone(
                        SemanticTone.danger,
                        theme.brightness,
                      ),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),

          // Mobile Wet-Hands Quick Navigation Buttons
          if (isMobile && operationalActive.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (btnContext) {
                      final isRtl =
                          Directionality.of(btnContext) == TextDirection.rtl;
                      final prevIcon = isRtl
                          ? Icons.arrow_forward_ios_rounded
                          : Icons.arrow_back_ios_rounded;
                      return FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        onPressed: _tabController.index > 0
                            ? () {
                                AppHaptics.selectionTap();
                                _tabController.animateTo(
                                  _tabController.index - 1,
                                );
                              }
                            : null,
                        icon: Icon(prevIcon, size: 14),
                        label: Text(strings.kdsPrevTab),
                      );
                    },
                  ),
                  Builder(
                    builder: (btnContext) {
                      final isRtl =
                          Directionality.of(btnContext) == TextDirection.rtl;
                      final nextIcon = isRtl
                          ? Icons.arrow_back_ios_rounded
                          : Icons.arrow_forward_ios_rounded;
                      return FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        onPressed: _tabController.index < 2
                            ? () {
                                AppHaptics.selectionTap();
                                _tabController.animateTo(
                                  _tabController.index + 1,
                                );
                              }
                            : null,
                        iconAlignment: IconAlignment.end,
                        icon: Icon(nextIcon, size: 14),
                        label: Text(strings.kdsNextTab),
                      );
                    },
                  ),
                ],
              ),
            ),

          // Main Board Columns / Tabs
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(ordersControllerProvider);
                ref.invalidate(tableControllerProvider);
              },
              child: active.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: KdsEmptyState(
                          title: HumanCopy.kitchenCalmTitle,
                          message: HumanCopy.kitchenCalmSubtitle,
                          primaryActionLabel: strings.kdsViewRecentCompleted,
                          onPrimaryAction: () =>
                              _showRecentCompletedOrdersSheet(context, ref),
                          secondaryActionLabel: strings.kdsRefreshBoard,
                          onSecondaryAction: () {
                            ref.invalidate(ordersControllerProvider);
                            ref.invalidate(tableControllerProvider);
                          },
                        ),
                      ),
                    )
                  : (_searchQuery.trim().isNotEmpty &&
                          operationalActive.isEmpty)
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: KdsEmptyState(
                              title: strings.isArabic
                                  ? 'لا توجد نتائج بحث'
                                  : 'No Search Results',
                              message: strings.isArabic
                                  ? 'لا توجد طلبات تطابق "$_searchQuery"'
                                  : 'No orders match "$_searchQuery"',
                              primaryActionLabel: strings.isArabic
                                  ? 'مسح البحث'
                                  : 'Clear Search',
                              onPrimaryAction: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            ),
                          ),
                        )
                      : (_selectedStation != KitchenStation.all &&
                              stationActive.isEmpty)
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 48),
                                child: KdsEmptyState(
                                  title: strings.isArabic
                                      ? 'المحطة هادئة حالياً'
                                      : 'Station is Calm',
                                  message: strings.isArabic
                                      ? 'لا توجد طلبات واردة لمحطة ${_selectedStation.localizedTitle(strings.isArabic)}'
                                      : 'No orders for ${_selectedStation.localizedTitle(false)}',
                                  primaryActionLabel: strings.isArabic
                                      ? 'عرض كل المحطات'
                                      : 'View All Stations',
                                  onPrimaryAction: () {
                                    setState(
                                      () => _selectedStation =
                                          KitchenStation.all,
                                    );
                                  },
                                ),
                              ),
                            )
                          : ResponsiveLayout(
                      mobile: TabBarView(
                        controller: _tabController,
                        children: [
                          _KdsColumn(
                            title: strings.kdsPending,
                            color: pendingColor,
                            icon: Icons.schedule,
                            orders: pendingList,
                            onAdvance: (order) =>
                                _advance(context, ref, order),
                            onClaim: (order) =>
                                _claim(order, currentUserId),
                            onRevert: (order, target) => _confirmAndRevert(
                              context,
                              order,
                              target,
                              currentUserId ?? '',
                            ),
                            tableNumberById: tableNumberById,
                            isExpanded: false,
                            emptyMessage: strings.kdsEmptyPending,
                          ),
                          _KdsColumn(
                            title: strings.kdsPreparing,
                            color: preparingColor,
                            icon: Icons.soup_kitchen_outlined,
                            orders: preparingList,
                            onAdvance: (order) =>
                                _advance(context, ref, order),
                            onClaim: (order) =>
                                _claim(order, currentUserId),
                            onRevert: (order, target) => _confirmAndRevert(
                              context,
                              order,
                              target,
                              currentUserId ?? '',
                            ),
                            tableNumberById: tableNumberById,
                            isExpanded: false,
                            emptyMessage: strings.kdsEmptyPreparing,
                          ),
                          _KdsColumn(
                            title: strings.kdsReady,
                            color: readyColor,
                            icon: Icons.check_circle_outline,
                            orders: readyList,
                            onAdvance: (order) =>
                                _advance(context, ref, order),
                            onClaim: (order) =>
                                _claim(order, currentUserId),
                            onRevert: (order, target) => _confirmAndRevert(
                              context,
                              order,
                              target,
                              currentUserId ?? '',
                            ),
                            tableNumberById: tableNumberById,
                            isExpanded: false,
                            emptyMessage: strings.kdsEmptyReady,
                          ),
                        ],
                      ),
                      tablet: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _KdsColumn(
                            title: strings.kdsPending,
                            color: pendingColor,
                            icon: Icons.schedule,
                            orders: pendingList,
                            onAdvance: (order) =>
                                _advance(context, ref, order),
                            onClaim: (order) =>
                                _claim(order, currentUserId),
                            onRevert: (order, target) => _confirmAndRevert(
                              context,
                              order,
                              target,
                              currentUserId ?? '',
                            ),
                            tableNumberById: tableNumberById,
                            isExpanded: true,
                            emptyMessage: strings.kdsEmptyPending,
                          ),
                          const VerticalDivider(width: 1),
                          _KdsColumn(
                            title: strings.kdsPreparing,
                            color: preparingColor,
                            icon: Icons.soup_kitchen_outlined,
                            orders: preparingList,
                            onAdvance: (order) =>
                                _advance(context, ref, order),
                            onClaim: (order) =>
                                _claim(order, currentUserId),
                            onRevert: (order, target) => _confirmAndRevert(
                              context,
                              order,
                              target,
                              currentUserId ?? '',
                            ),
                            tableNumberById: tableNumberById,
                            isExpanded: true,
                            emptyMessage: strings.kdsEmptyPreparing,
                          ),
                          const VerticalDivider(width: 1),
                          _KdsColumn(
                            title: strings.kdsReady,
                            color: readyColor,
                            icon: Icons.check_circle_outline,
                            orders: readyList,
                            onAdvance: (order) =>
                                _advance(context, ref, order),
                            onClaim: (order) =>
                                _claim(order, currentUserId),
                            onRevert: (order, target) => _confirmAndRevert(
                              context,
                              order,
                              target,
                              currentUserId ?? '',
                            ),
                            tableNumberById: tableNumberById,
                            isExpanded: true,
                            emptyMessage: strings.kdsEmptyReady,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
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

  /// Shows the guarded revert confirmation for [order], then applies the revert.
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

    // Delivery order constraints
    if (order.orderType == OrderType.delivery &&
        order.status == OrderStatus.ready) {
      if (order.driverId == null) {
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

    if (context.mounted &&
        (next == OrderStatus.served || next == OrderStatus.completed)) {
      final orderShortId = order.id.length > 6
          ? order.id.substring(order.id.length - 4)
          : order.id;
      ScaffoldMessenger.of(context).clearSnackBars();
      final successBg = StatusColors.tone(
        SemanticTone.success,
        Theme.of(context).brightness,
      );
      final canUndo = next.canRevertTo(prevStatus);
      final message = (order.orderType == OrderType.delivery &&
              next == OrderStatus.served)
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
                        .revertStatus(
                          order.id,
                          prevStatus,
                          actorId: authUser?.id ?? 'chef',
                        );
                    if (context.mounted) {
                      if (reverted != null) {
                        HumanSnackBar.info(
                          context,
                          'أعدنا الطلب إلى المطبخ — لا عليك',
                        );
                      } else {
                        HumanSnackBar.error(
                          context,
                          ref
                              .read(appStringsProvider)
                              .orderRevertFailed(orderShortId),
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
        .where(
          (o) =>
              o.status == OrderStatus.served ||
              o.status == OrderStatus.completed,
        )
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
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
                          strings.recentDeliveredWithCount(
                            completedOrders.length,
                          ),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (ctx, index) {
                            final order = completedOrders[index];
                            final orderIdShort = order.id.length > 6
                                ? order.id.substring(order.id.length - 4)
                                : order.id;

                            return Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                side: BorderSide(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF10B981)
                                      .withValues(alpha: 0.15),
                                  foregroundColor: const Color(0xFF10B981),
                                  child: const Icon(Icons.done_all_rounded),
                                ),
                                title: Text(
                                  strings.orderWithType(
                                    orderIdShort,
                                    order.orderType.localizedLabel(
                                      strings.isArabic,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  strings.itemsWithStatus(
                                    order.items.fold<int>(
                                      0,
                                      (s, i) => s + i.quantity,
                                    ),
                                    order.status.localizedLabel(
                                      strings.isArabic,
                                    ),
                                  ),
                                ),
                                trailing: Builder(
                                  builder: (_) {
                                    final canRevert = order.status.canRevertTo(
                                      OrderStatus.ready,
                                    );
                                    if (!canRevert) {
                                      return Tooltip(
                                        message: strings.orderFinalNoRevert,
                                        child: FilledButton.tonalIcon(
                                          icon: const Icon(
                                            Icons.lock_outline_rounded,
                                            size: 16,
                                          ),
                                          label: Text(
                                            strings.orderFinalNoRevert,
                                          ),
                                          onPressed: null,
                                        ),
                                      );
                                    }
                                    return FilledButton.tonalIcon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            colorScheme.primaryContainer,
                                        foregroundColor:
                                            colorScheme.onPrimaryContainer,
                                      ),
                                      icon: const Icon(
                                        Icons.undo_rounded,
                                        size: 16,
                                      ),
                                      label: Text(strings.backToKitchen),
                                      onPressed: () async {
                                        final authUser = ref
                                            .read(authControllerProvider)
                                            .user;
                                        final reverted = await ref
                                            .read(
                                              ordersControllerProvider.notifier,
                                            )
                                            .revertStatus(
                                              order.id,
                                              OrderStatus.ready,
                                              actorId: authUser?.id ?? 'chef',
                                            );
                                        if (!sheetContext.mounted) return;
                                        if (reverted != null) {
                                          Navigator.of(sheetContext).pop();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                strings.orderBackToReady(
                                                  orderIdShort,
                                                ),
                                              ),
                                              backgroundColor:
                                                  const Color(0xFF10B981),
                                            ),
                                          );
                                        } else {
                                          HumanSnackBar.error(
                                            sheetContext,
                                            strings.orderRevertFailed(
                                              orderIdShort,
                                            ),
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

  OrderStatus? _nextStatus(OrderStatus status, OrderType orderType) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
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
    required this.emptyMessage,
    this.isExpanded = true,
  });

  final String title;
  final Color color;
  final IconData icon;
  final List<OrderEntity> orders;
  final ValueChanged<OrderEntity> onAdvance;
  final ValueChanged<OrderEntity> onClaim;
  final void Function(OrderEntity order, OrderStatus target) onRevert;
  final Map<String, int> tableNumberById;
  final String emptyMessage;
  final bool isExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final content = Container(
      margin: isExpanded
          ? const EdgeInsets.all(AppSpacing.xs)
          : EdgeInsets.zero,
      padding: isExpanded
          ? const EdgeInsets.all(AppSpacing.sm)
          : const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
      decoration: isExpanded
          ? BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? color.withValues(alpha: 0.06)
                  : color.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 1.2,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // On tablet (isExpanded == true), render distinct column header.
          // On mobile (isExpanded == false), header is omitted to save ~90px!
          if (isExpanded) ...[
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
                  Icon(icon, size: 18, color: color),
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
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              size: 28,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            emptyMessage,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            HumanCopy.kitchenCalmSubtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _OrderCard(
                        key: ValueKey(order.id),
                        order: order,
                        onAdvance: onAdvance,
                        onClaim: onClaim,
                        onRevert: onRevert,
                        tableNumber: order.tableId == null
                            ? null
                            : tableNumberById[order.tableId],
                      );
                    },
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
    super.key,
    required this.order,
    required this.onAdvance,
    required this.onClaim,
    required this.onRevert,
    this.tableNumber,
  });

  final OrderEntity order;
  final ValueChanged<OrderEntity> onAdvance;
  final ValueChanged<OrderEntity> onClaim;
  final void Function(OrderEntity order, OrderStatus target) onRevert;
  final int? tableNumber;

  static const Duration _newThreshold = Duration(minutes: 2);
  bool get _isNew => DateTime.now().difference(order.createdAt) < _newThreshold;

  static SemanticTone _urgencyTone(int minutes) {
    if (minutes < 5) return SemanticTone.success;
    if (minutes < 10) return SemanticTone.warning;
    return SemanticTone.danger;
  }

  static IconData _urgencyIcon(SemanticTone tone) => switch (tone) {
    SemanticTone.success => Icons.check_circle_outline,
    SemanticTone.warning => Icons.warning_amber_rounded,
    _ => Icons.error_outline,
  };

  static String _urgencyLabel(
    AppStrings strings,
    int minutes,
    SemanticTone tone,
  ) =>
      switch (tone) {
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
          ? (order.driverId == null
              ? strings.assignDriverChip
              : strings.handoverToDriver)
          : strings.kdsCompleting,
      _ => strings.ok,
    };

    final actionKey = switch (order.status) {
      OrderStatus.pending => const ValueKey<String>('kds_action_preparing'),
      OrderStatus.ready => const ValueKey<String>('kds_action_resume'),
      _ => null,
    };

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

    // Filter items that have special notes for the prominent top banner
    final itemsWithNotes = order.items
        .where((i) => i.specialNotes?.trim().isNotEmpty ?? false)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: highlight,
          width: urgencyTone == SemanticTone.danger ? 2.5 : 1.8,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.kdsCard,
          color: theme.colorScheme.surface,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Identity Header ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    Formatters.formatOrderId(order.id),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppRadius.full,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          strings.kdsNewBadge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (displayTable != null)
                      Chip(
                        label: Text(
                          '${strings.orderTablePrefix} $displayTable',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    else if (order.orderType == OrderType.takeaway)
                      Chip(
                        label: Text(
                          strings.takeawayShort,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    else if (order.orderType == OrderType.delivery)
                      Chip(
                        label: Text(
                          order.orderType.localizedLabel(strings.isArabic),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ),

            // ── Prominent Notes & Allergies Banner FIRST ─────────────────────
            if (itemsWithNotes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              for (final noteItem in itemsWithNotes)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '${strings.specialNotesLabel}: ${noteItem.specialNotes}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: AppSpacing.xs),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.xs),

            // ── Items List ───────────────────────────────────────────────────
            for (final item in order.items) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        '${item.quantity}×',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.menuItem.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if (item.selectedModifiers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: AppSpacing.xs,
                                top: 1,
                              ),
                              child: Text(
                                item.selectedModifiers
                                    .map((m) => m.name)
                                    .join('، '),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xs),

            // ── Items count and total line ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    strings.itemCountLine(
                      order.items.fold<int>(0, (sum, i) => sum + i.quantity),
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  Formatters.formatCurrency(order.totalAmount),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),

            // ── Elapsed Time & Visual Urgency Progress Bar ───────────────────
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: (elapsed / 10.0).clamp(0.05, 1.0),
                minHeight: 5,
                backgroundColor: urgencyColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(urgencyColor),
              ),
            ),
            if (elapsed >= 1) ...[
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusBadge.tone(
                  label: _urgencyLabel(strings, elapsed, urgencyTone),
                  semanticTone: urgencyTone,
                  icon: _urgencyIcon(urgencyTone),
                ),
              ),
            ],

            // ── Delivery Driver Assignment Row (if Delivery order) ───────────
            if (order.orderType == OrderType.delivery) ...[
              const SizedBox(height: AppSpacing.xs),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: order.driverId != null
                        ? const Color(0xFF10B981)
                        : theme.colorScheme.primary,
                  ),
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onPressed: () =>
                    KdsDriverAssignmentSheet.show(context, order: order),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),

            // ── Action Buttons Row (Touch Target >= 56px Main CTA) ───────────
            Row(
              children: [
                // Print Ticket
                IconButton.outlined(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  tooltip: strings.printKitchenTicket,
                  icon: const Icon(Icons.print_outlined, size: 20),
                  onPressed: () => TicketPrintDialog.show(
                    context,
                    order: order,
                    tableDisplay: displayTable?.toString(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),

                // Claim Button (If unclaimed ticket)
                if (order.assignedKitchenId == null) ...[
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      onPressed: () => onClaim(order),
                      child: Text(
                        strings.kdsClaimOrder,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],

                // Advance Status CTA
                Expanded(
                  child: FilledButton(
                    key: actionKey,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    onPressed: () => onAdvance(order),
                    child: Text(
                      buttonLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Guarded Revert Button
                if (canUndo) ...[
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.outlined(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: strings.kdsRevertTooltip,
                    icon: const Icon(Icons.undo, size: 20),
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

  static OrderStatus? _revertTargetOf(OrderStatus status) => switch (status) {
    OrderStatus.ready => OrderStatus.preparing,
    OrderStatus.served => OrderStatus.ready,
    _ => null,
  };
}
