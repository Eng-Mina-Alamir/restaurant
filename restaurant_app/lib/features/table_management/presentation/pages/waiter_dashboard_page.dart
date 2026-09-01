import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/notifications/waiter_alert_service.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/animations/animated_counter.dart';
import '../../../../shared/animations/fade_slide_transition.dart';
import '../../../../shared/animations/shimmer_loading.dart';
import '../../../../shared/animations/staggered_fade_slide_list.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/logout_action_button.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../controllers/table_controller.dart';
import '../controllers/table_service_controller.dart';
import '../../domain/entities/restaurant_table.dart';
import '../../domain/entities/table_service_request.dart';
import 'waiter_table_card.dart';

/// Waiter / captain dashboard: a modern, interactive grid of restaurant tables with status-aware
/// filtering, live statistics counters, and instant actions.
class WaiterDashboardPage extends ConsumerStatefulWidget {
  const WaiterDashboardPage({super.key});

  @override
  ConsumerState<WaiterDashboardPage> createState() =>
      _WaiterDashboardPageState();
}

class _WaiterDashboardPageState extends ConsumerState<WaiterDashboardPage> {
  int _lastReadyPickupCount = 0;
  TableStatus? _selectedStatusFilter;
  String _selectedZoneFilter = 'الكل';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(tableControllerProvider);
    final orders = ref.watch(ordersControllerProvider);
    final serviceRequests = ref.watch(tableServiceControllerProvider);
    final activeServiceRequests =
        serviceRequests.where((r) => !r.isHandled).toList();

    final readyPickupCount = orders
        .where(
          (o) =>
              o.status == OrderStatus.ready && o.orderType == OrderType.dineIn,
        )
        .length;
    if (readyPickupCount > _lastReadyPickupCount) {
      unawaited(ref.read(waiterAlertServiceProvider).notifyReadyForPickup());
    }
    _lastReadyPickupCount = readyPickupCount;

    // Filter tables by status, zone, and search query
    final filteredTables = tables.where((t) {
      if (_selectedStatusFilter != null && t.status != _selectedStatusFilter) {
        return false;
      }
      if (_selectedZoneFilter != 'الكل' && t.location != _selectedZoneFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchNum = t.tableNumber.toString().contains(q);
        final matchLoc = t.location.toLowerCase().contains(q);
        if (!matchNum && !matchLoc) return false;
      }
      return true;
    }).toList();

    // Extract unique zones from tables
    final zones = <String>['الكل', ...{for (final t in tables) t.location}];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.tablesTitle),
        actions: [
          if (activeServiceRequests.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: Center(
                child: Tooltip(
                  message: 'نداءات مساعدة من الطاولات (${activeServiceRequests.length})',
                  child: Badge(
                    backgroundColor: Colors.amber.shade800,
                    label: Text('${activeServiceRequests.length}'),
                    child: const Icon(Icons.notifications_active, color: Colors.amber),
                  ),
                ),
              ),
            ),
          if (readyPickupCount > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
              child: Center(
                child: Tooltip(
                  message: AppConstants.waiterReadyForPickupBadge,
                  child: Badge(
                    label: Text('$readyPickupCount'),
                    child: const Icon(Icons.room_service),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'تقرير إكراميات وأداء الوردية',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => context.push('/waiter/tips'),
          ),
          const LogoutActionButton(),
        ],
      ),
      body: tables.isEmpty
          ? const _TablesSkeleton()
          : Column(
              children: [
                // ── Active Service Requests Alert Banner ──
                if (activeServiceRequests.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'طاولة ${activeServiceRequests.first.tableNumber} تطلب: ${activeServiceRequests.first.type.labelAr}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(tableServiceControllerProvider.notifier)
                                .acknowledgeService(activeServiceRequests.first.id);
                          },
                          child: const Text('تمت التلبية'),
                        ),
                      ],
                    ),
                  ),

                // ── Orders Summary Counter ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    0,
                  ),
                  child: _OrdersSummary(orders: orders),
                ),

                // ── Interactive Status Statistics Filter Bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: _TableStatusStatsBar(
                    tables: tables,
                    selectedStatus: _selectedStatusFilter,
                    onStatusSelected: (status) {
                      AppHaptics.selectionTap();
                      setState(() {
                        _selectedStatusFilter = status;
                      });
                    },
                  ),
                ),

                // ── Zone Tabs & Quick Search ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
                  child: Row(
                    children: [
                      // Zone chips
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: zones.map((zone) {
                              final isSelected = zone == _selectedZoneFilter;
                              return Padding(
                                padding: const EdgeInsetsDirectional.only(end: 6),
                                child: ChoiceChip(
                                  label: Text(
                                    zone,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    AppHaptics.selectionTap();
                                    setState(() {
                                      _selectedZoneFilter = zone;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      if (zones.length > 2) ...[
                        const SizedBox(width: AppSpacing.xs),
                        // Quick Search Icon / Dialog
                        IconButton(
                          icon: Icon(
                            _searchQuery.isEmpty ? Icons.search : Icons.search_off,
                            size: 20,
                          ),
                          tooltip: 'بحث برقم الطاولة',
                          onPressed: () {
                            if (_searchQuery.isNotEmpty) {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            } else {
                              _showSearchDialog(context);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Grid of Tables ──
                Expanded(
                  child: filteredTables.isEmpty
                      ? const Center(
                          child: EmptyState(
                            message: 'لا توجد طاولات مطابقة للفلتر المختار',
                            icon: Icons.table_restaurant_outlined,
                          ),
                        )
                      : ResponsiveBuilder(
                          builder: (context, screenType, constraints) {
                            final cols = AppBreakpoints.gridColumnsForWidth(
                              constraints.maxWidth,
                              minColumns: 2,
                              maxColumns: 5,
                            );
                            final ratio = screenType == ScreenType.mobile
                                ? 1.05
                                : 1.2;

                            return GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                childAspectRatio: ratio,
                                crossAxisSpacing: AppSpacing.md,
                                mainAxisSpacing: AppSpacing.md,
                              ),
                              itemCount: filteredTables.length,
                              itemBuilder: (context, index) {
                                final table = filteredTables[index];
                                final activeReq = activeServiceRequests
                                    .cast<TableServiceRequest?>()
                                    .firstWhere(
                                      (r) => r?.tableId == table.id,
                                      orElse: () => null,
                                    );

                                return AnimatedListItem(
                                  index: index,
                                  staggerDuration: const Duration(milliseconds: 30),
                                  duration: const Duration(milliseconds: 320),
                                  child: WaiterTableCard(
                                    table: table,
                                    activeServiceRequest: activeReq,
                                    onAcknowledgeService: activeReq == null
                                        ? null
                                        : () {
                                            ref
                                                .read(
                                                  tableServiceControllerProvider
                                                      .notifier,
                                                )
                                                .acknowledgeService(activeReq.id);
                                          },
                                    onTap: () {
                                      context.push('/waiter/table/${table.id}');
                                    },
                                    onTakeOrder: () {
                                      context.push('/waiter/order/${table.id}');
                                    },
                                    onRelease: () => ref
                                        .read(tableControllerProvider.notifier)
                                        .release(table.id),
                                    onReserve: () => ref
                                        .read(tableControllerProvider.notifier)
                                        .setReserved(table.id, reserved: true),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بحث برقم الطاولة أو المكان'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'مثال: 1 أو تراس',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (val) {
            setState(() {
              _searchQuery = val;
            });
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('بحث'),
          ),
        ],
      ),
    );
  }
}

/// Interactive Status Statistics filter strip (All, Available, Occupied, Reserved, Needs Cleaning).
class _TableStatusStatsBar extends StatelessWidget {
  const _TableStatusStatsBar({
    required this.tables,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  final List<RestaurantTable> tables;
  final TableStatus? selectedStatus;
  final ValueChanged<TableStatus?> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    final total = tables.length;
    final available = tables.where((t) => t.status == TableStatus.available).length;
    final occupied = tables.where((t) => t.status == TableStatus.occupied).length;
    final reserved = tables.where((t) => t.status == TableStatus.reserved).length;
    final needsCleaning = tables.where((t) => t.status == TableStatus.needsCleaning).length;

    final chips = <_StatusFilterItem>[
      _StatusFilterItem(
        status: null,
        label: 'الكل',
        count: total,
        color: theme.colorScheme.primary,
      ),
      _StatusFilterItem(
        status: TableStatus.available,
        label: TableStatus.available.labelAr,
        count: available,
        color: tableStatusColor(TableStatus.available, brightness),
      ),
      _StatusFilterItem(
        status: TableStatus.occupied,
        label: TableStatus.occupied.labelAr,
        count: occupied,
        color: tableStatusColor(TableStatus.occupied, brightness),
      ),
      _StatusFilterItem(
        status: TableStatus.reserved,
        label: TableStatus.reserved.labelAr,
        count: reserved,
        color: tableStatusColor(TableStatus.reserved, brightness),
      ),
      _StatusFilterItem(
        status: TableStatus.needsCleaning,
        label: TableStatus.needsCleaning.labelAr,
        count: needsCleaning,
        color: tableStatusColor(TableStatus.needsCleaning, brightness),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: chips.map((item) {
          final isSelected = selectedStatus == item.status;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: InkWell(
              onTap: () => onStatusSelected(isSelected && item.status != null ? null : item.status),
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? item.color.withValues(alpha: 0.18)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: isSelected
                        ? item.color
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? item.color : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? item.color
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '(${item.count})',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatusFilterItem {
  const _StatusFilterItem({
    required this.status,
    required this.label,
    required this.count,
    required this.color,
  });

  final TableStatus? status;
  final String label;
  final int count;
  final Color color;
}

/// Compact live counters of active order statuses for the waiter.
class _OrdersSummary extends StatelessWidget {
  const _OrdersSummary({required this.orders});

  final List<OrderEntity> orders;

  @override
  Widget build(BuildContext context) {
    final pending = orders.where((o) => o.status == OrderStatus.pending).length;
    final preparing = orders
        .where((o) => o.status == OrderStatus.preparing)
        .length;
    final ready = orders.where((o) => o.status == OrderStatus.ready).length;
    final total = pending + preparing + ready;

    if (total == 0) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;
    return FadeSlideTransitionWidget(
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppConstants.waiterOrdersSummary,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: 4,
                  children: [
                    _CountChip(
                      label: OrderStatus.pending.labelAr,
                      count: pending,
                      color: StatusColors.tone(
                        SemanticTone.warning,
                        brightness,
                      ),
                    ),
                    _CountChip(
                      label: OrderStatus.preparing.labelAr,
                      count: preparing,
                      color: StatusColors.tone(
                        SemanticTone.neutral,
                        brightness,
                      ),
                    ),
                    _CountChip(
                      label: OrderStatus.ready.labelAr,
                      count: ready,
                      color: StatusColors.tone(
                        SemanticTone.success,
                        brightness,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: AnimatedCounter(
        value: count,
        prefix: '$label: ',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// Helper to return appropriate color for each table status.
Color tableStatusColor(
  TableStatus status, [
  Brightness brightness = Brightness.light,
]) => StatusColors.table(status, brightness);

/// Helper to return appropriate icon for each table status.
IconData tableStatusIcon(TableStatus status) {
  return switch (status) {
    TableStatus.available => Icons.check_circle_outline,
    TableStatus.occupied => Icons.people_outline,
    TableStatus.reserved => Icons.bookmark_outline,
    TableStatus.needsCleaning => Icons.cleaning_services_outlined,
  };
}

/// Shimmer placeholder mirroring the table-card grid while tables load.
class _TablesSkeleton extends StatelessWidget {
  const _TablesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, constraints) {
        final cols = AppBreakpoints.gridColumnsForWidth(
          constraints.maxWidth,
          minColumns: 2,
          maxColumns: 5,
        );
        final ratio = screenType == ScreenType.mobile ? 1.05 : 1.2;

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: ratio,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: cols * 3,
          itemBuilder: (context, index) => const SkeletonBox(
            width: double.infinity,
            height: double.infinity,
            borderRadius: AppRadius.md,
          ),
        );
      },
    );
  }
}
