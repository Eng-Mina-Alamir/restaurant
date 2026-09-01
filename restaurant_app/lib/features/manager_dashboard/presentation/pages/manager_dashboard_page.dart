import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/animated_press_card.dart';
import '../../../../shared/animations/pulse_badge.dart';
import '../../../../shared/animations/shimmer_loading.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../../../../shared/widgets/logout_action_button.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';
import '../../../restaurant/domain/entities/branch_entity.dart';
import '../../../restaurant/presentation/controllers/branch_controller.dart';
import '../controllers/alerts_controller.dart';
import '../controllers/dispatch_controller.dart';
import '../controllers/metrics_controller.dart';
import '../widgets/add_branch_dialog.dart';
import '../widgets/branches_overview_section.dart';
import '../widgets/peak_hours_chart.dart';
import '../widgets/sales_line_chart.dart';
import '../widgets/top_items_bar_chart.dart';

/// Modern Multi-Branch Manager & Super Admin dashboard.
class ManagerDashboardPage extends ConsumerWidget {
  const ManagerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final metrics = ref.watch(metricsControllerProvider);
    final unreadAlerts = ref.watch(unreadAlertsCountProvider);
    final authUser = ref.watch(authControllerProvider).user;
    final isAdmin = authUser?.role == UserRole.admin;
    final selectedBranchId = ref.watch(selectedBranchIdProvider);
    final activeBranch = ref.watch(activeBranchProvider);
    final branches = ref.watch(branchesControllerProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: isAdmin ? AppGradients.purple : AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: AppShadows.glow(
                  isAdmin ? const Color(0xFF7C3AED) : AppColors.brand,
                  opacity: 0.3,
                ),
              ),
              child: Icon(
                isAdmin ? Icons.admin_panel_settings_rounded : Icons.dashboard_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAdmin ? strings.adminTitle : strings.managerTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isAdmin
                        ? (selectedBranchId == null
                            ? (strings.isArabic ? 'إدارة كل الفروع (${branches.length})' : 'All Branches (${branches.length})')
                            : (strings.isArabic ? 'متابعة ${activeBranch?.name ?? "الفرع"}' : 'Managing ${activeBranch?.name ?? "Branch"}'))
                        : (activeBranch?.name ?? strings.managerSubtitle),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher (AR / EN)
          const LanguageSwitcherButton(compact: true),
          const SizedBox(width: AppSpacing.xs),

          // Quick Switcher Menu for Admin
          if (isAdmin)
            PopupMenuButton<String>(
              tooltip: strings.isArabic ? 'التبديل بين شاشات النظام' : 'Switch System Apps',
              icon: Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.swap_horiz_rounded, size: 20),
              ),
              onSelected: (route) => context.push(route),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: '/kds',
                  child: Row(
                    children: [
                      Icon(Icons.kitchen_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('شاشة المطبخ (KDS)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: '/waiter',
                  child: Row(
                    children: [
                      Icon(Icons.table_restaurant_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('شاشة الويتر / الصالة (POS)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: '/driver',
                  child: Row(
                    children: [
                      Icon(Icons.delivery_dining_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('شاشة السائق والتوصيل'),
                    ],
                  ),
                ),
              ],
            ),

          IconButton(
            tooltip: 'مركز التنبيهات',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHigh
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_outlined, size: 20),
                ),
                if (unreadAlerts > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: PulseBadge(
                      color: colorScheme.error,
                      size: 16,
                      child: Center(
                        child: Text(
                          '$unreadAlerts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.push('/manager/alerts'),
          ),

          IconButton(
            tooltip: AppConstants.allOrdersTitle,
            icon: Container(
              padding: const EdgeInsets.all(AppSpacing.xs + 2),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHigh
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 20),
            ),
            onPressed: () => context.push('/manager/orders'),
          ),

          const LogoutActionButton(),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: metrics.when(
        loading: () => const _DashboardSkeleton(),
        error: (e, _) => ErrorState(
          message: AppConstants.errorLoadingData,
          errorDetail: e,
          onRetry: () => ref.refresh(metricsControllerProvider),
        ),
        data: (data) => ResponsiveBuilder(
          builder: (context, screenType, constraints) {
            final isWide = screenType != ScreenType.mobile;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  children: [
                    // ── 1. Admin Multi-Branch Tabs Navigation Bar ───────────
                    if (isAdmin) ...[
                      _BranchTabsBar(
                        branches: branches,
                        selectedBranchId: selectedBranchId,
                        onSelectBranch: (id) {
                          ref.read(selectedBranchIdProvider.notifier).state = id;
                        },
                        onAddBranch: () => AddBranchDialog.show(context),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // ── 2. Hero Greeting Banner ──────────────────────────────
                    _HeroGreetingBanner(
                      isAdmin: isAdmin,
                      activeBranch: activeBranch,
                      activeOrdersCount: _activeOrdersCount(ref),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── 3. Content depending on Tab (All Branches vs Single Branch) ──
                    if (isAdmin && selectedBranchId == null) ...[
                      // 🌐 All Branches Overview for Super Admin
                      const BranchesOverviewSection(),
                    ] else ...[
                      // 📍 Single Branch Dashboard View
                      _SingleBranchDashboardContent(
                        data: data,
                        isWide: isWide,
                        ref: ref,
                        activeBranch: activeBranch,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int _activeOrdersCount(WidgetRef ref) {
    final orders = ref.watch(ordersControllerProvider);
    return orders.where((o) => !o.status.isTerminal).length;
  }
}

// ── Multi-Branch Tabs Bar ──────────────────────────────────────────────────────

class _BranchTabsBar extends StatelessWidget {
  const _BranchTabsBar({
    required this.branches,
    required this.selectedBranchId,
    required this.onSelectBranch,
    required this.onAddBranch,
  });

  final List<BranchEntity> branches;
  final String? selectedBranchId;
  final ValueChanged<String?> onSelectBranch;
  final VoidCallback onAddBranch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All Branches Tab (السلسلة بالكامل)
          _BranchTabPill(
            label: '🌐 كل الفروع (السلسلة)',
            isSelected: selectedBranchId == null,
            badgeCount: branches.length,
            onTap: () => onSelectBranch(null),
          ),
          const SizedBox(width: AppSpacing.xs + 2),

          // Individual Branch Tabs
          for (final branch in branches) ...[
            _BranchTabPill(
              label: branch.name,
              isSelected: selectedBranchId == branch.id,
              isOpen: branch.isOpen,
              badgeCount: branch.activeOrdersCount > 0 ? branch.activeOrdersCount : null,
              accentColor: branch.color,
              onTap: () => onSelectBranch(branch.id),
            ),
            const SizedBox(width: AppSpacing.xs + 2),
          ],

          // Add New Branch Button
          IconButton(
            tooltip: 'إضافة فرع جديد',
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? colorScheme.surfaceContainerHigh
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            onPressed: onAddBranch,
          ),
        ],
      ),
    );
  }
}

class _BranchTabPill extends StatelessWidget {
  const _BranchTabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isOpen,
    this.badgeCount,
    this.accentColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool? isOpen;
  final int? badgeCount;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = accentColor ?? colorScheme.primary;

    return AnimatedPressCard(
      borderRadius: AppRadius.full,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 3,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primary
              : (isDark ? colorScheme.surfaceContainerLow : Colors.white),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? primary
                : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? AppShadows.glow(primary, opacity: 0.3)
              : AppShadows.subtle,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOpen != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOpen!
                      ? (isSelected ? Colors.white : const Color(0xFF10B981))
                      : (isSelected ? Colors.white70 : colorScheme.error),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : colorScheme.onSurface,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Hero Greeting Banner ───────────────────────────────────────────────────────

class _HeroGreetingBanner extends ConsumerWidget {
  const _HeroGreetingBanner({
    required this.isAdmin,
    required this.activeOrdersCount,
    this.activeBranch,
  });

  final bool isAdmin;
  final int activeOrdersCount;
  final BranchEntity? activeBranch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
          width: 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isAdmin ? AppGradients.purple : AppGradients.primary,
              shape: BoxShape.circle,
              boxShadow: AppShadows.glow(
                isAdmin ? const Color(0xFF7C3AED) : AppColors.brand,
                opacity: 0.35,
              ),
            ),
            child: Center(
              child: Text(
                isAdmin ? '👑' : '👨‍🍳',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isAdmin
                            ? strings.welcomeAdmin
                            : '${strings.welcomeManager} ${activeBranch?.name ?? (strings.isArabic ? "الفرع" : "Branch")}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Text('👋', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isAdmin && activeBranch == null
                      ? strings.centralView
                      : (activeOrdersCount > 0
                          ? (strings.isArabic
                              ? 'لديك $activeOrdersCount طلبات جارية الآن في هذا الفرع'
                              : 'You have $activeOrdersCount active orders in this branch')
                          : strings.readyAndReceiving),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PulseBadge(
                  color: Color(0xFF10B981),
                  size: 8,
                ),
                const SizedBox(width: 6),
                Text(
                  activeBranch != null
                      ? (activeBranch!.isOpen ? strings.open : strings.closed)
                      : strings.live,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF047857),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single Branch Dashboard Content ───────────────────────────────────────────

class _SingleBranchDashboardContent extends ConsumerWidget {
  const _SingleBranchDashboardContent({
    required this.data,
    required this.isWide,
    required this.ref,
    this.activeBranch,
  });

  final dynamic data;
  final bool isWide;
  final WidgetRef ref;
  final BranchEntity? activeBranch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final salesValue = activeBranch?.todaySales ?? data.totalSales;
    final ordersCount = activeBranch?.totalOrdersToday ?? data.totalOrders;
    final activeOrdersCount = activeBranch?.activeOrdersCount ?? _activeOrders(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. KPI Metrics Overview ──────────────────────────────────────────
        _SectionHeader(
          title: activeBranch != null
              ? '${strings.generalOverview} • ${activeBranch!.name}'
              : strings.generalOverview,
          icon: Icons.auto_graph_rounded,
          badgeText: strings.live,
          badgeColor: colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isWide)
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: strings.metricsSalesTitle,
                  value: Formatters.formatCurrency(salesValue),
                  subtitle: strings.todaySalesBranch,
                  icon: Icons.payments_rounded,
                  gradient: AppGradients.emerald,
                  accentColor: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  title: strings.metricsOrdersTitle,
                  value: '$ordersCount',
                  subtitle: strings.totalOrdersBranch,
                  icon: Icons.receipt_long_rounded,
                  gradient: AppGradients.info,
                  accentColor: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  title: strings.metricsAvgOrderTitle,
                  value: Formatters.formatCurrency(
                    ordersCount > 0 ? (salesValue / ordersCount) : 0.0,
                  ),
                  subtitle: strings.avgCart,
                  icon: Icons.pie_chart_rounded,
                  gradient: AppGradients.warning,
                  accentColor: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  title: strings.metricsActiveTitle,
                  value: '$activeOrdersCount',
                  subtitle: strings.inProgressBranch,
                  icon: Icons.pending_actions_rounded,
                  gradient: AppGradients.purple,
                  accentColor: const Color(0xFF8B5CF6),
                  isLive: int.tryParse('$activeOrdersCount') != null &&
                      int.parse('$activeOrdersCount') > 0,
                ),
              ),
            ],
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: strings.metricsSalesTitle,
                  value: Formatters.formatCurrency(salesValue),
                  subtitle: strings.todaySalesBranch,
                  icon: Icons.payments_rounded,
                  gradient: AppGradients.emerald,
                  accentColor: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  title: strings.metricsOrdersTitle,
                  value: '$ordersCount',
                  subtitle: strings.totalOrdersBranch,
                  icon: Icons.receipt_long_rounded,
                  gradient: AppGradients.info,
                  accentColor: const Color(0xFF0284C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: strings.metricsAvgOrderTitle,
                  value: Formatters.formatCurrency(
                    ordersCount > 0 ? (salesValue / ordersCount) : 0.0,
                  ),
                  subtitle: strings.avgCart,
                  icon: Icons.pie_chart_rounded,
                  gradient: AppGradients.warning,
                  accentColor: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  title: strings.metricsActiveTitle,
                  value: '$activeOrdersCount',
                  subtitle: strings.inProgressBranch,
                  icon: Icons.pending_actions_rounded,
                  gradient: AppGradients.purple,
                  accentColor: const Color(0xFF8B5CF6),
                  isLive: int.tryParse('$activeOrdersCount') != null &&
                      int.parse('$activeOrdersCount') > 0,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),

        // ── 2. Dispatch & Fleet Health Strip ─────────────────────────────────
        const _DispatchHealthCard(),
        const SizedBox(height: AppSpacing.lg),

        // ── 3. Live Order Pipeline / Status Breakdown ────────────────────────
        _SectionHeader(
          title: strings.ordersByStatus,
          icon: Icons.route_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        _StatusBreakdown(
          orders: ref.watch(ordersControllerProvider),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── 4. Quick Actions Bento Grid ──────────────────────────────────────
        _SectionHeader(
          title: strings.quickActions,
          icon: Icons.apps_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        _QuickActionsGrid(isWide: isWide),
        const SizedBox(height: AppSpacing.lg),

        // ── 5. Analytics Charts ──────────────────────────────────────────────
        _SectionHeader(
          title: strings.analyticsTitle,
          icon: Icons.show_chart_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        SalesLineChart(
          salesData: {
            strings.isArabic ? 'السبت' : 'Sat': salesValue * 0.12,
            strings.isArabic ? 'الأحد' : 'Sun': salesValue * 0.14,
            strings.isArabic ? 'الإثنين' : 'Mon': salesValue * 0.10,
            strings.isArabic ? 'الثلاثاء' : 'Tue': salesValue * 0.15,
            strings.isArabic ? 'الأربعاء' : 'Wed': salesValue * 0.18,
            strings.isArabic ? 'الخميس' : 'Thu': salesValue * 0.22,
            strings.isArabic ? 'الجمعة' : 'Fri': salesValue * 0.25,
          },
        ),
        const SizedBox(height: AppSpacing.md),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TopItemsBarChart(itemsSold: data.itemsSold),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PeakHoursChart(
                  hourlyDistribution: const {
                    12: 12,
                    13: 18,
                    14: 25,
                    15: 14,
                    16: 8,
                    17: 10,
                    18: 22,
                    19: 34,
                    20: 45,
                    21: 38,
                    22: 28,
                    23: 15,
                  },
                  peakHour: data.peakHour,
                ),
              ),
            ],
          )
        else ...[
          TopItemsBarChart(itemsSold: data.itemsSold),
          const SizedBox(height: AppSpacing.md),
          PeakHoursChart(
            hourlyDistribution: const {
              12: 12,
              13: 18,
              14: 25,
              15: 14,
              16: 8,
              17: 10,
              18: 22,
              19: 34,
              20: 45,
              21: 38,
              22: 28,
              23: 15,
            },
            peakHour: data.peakHour,
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        _BreakdownSection(
          title: AppConstants.metricsItemsSold,
          icon: Icons.shopping_bag_rounded,
          data: data.itemsSold,
          tone: SemanticTone.success,
          formatValue: (value) => '$value ${strings.isArabic ? "صنف" : "items"}',
        ),
        const SizedBox(height: AppSpacing.md),
        _BreakdownSection(
          title: AppConstants.metricsByCategory,
          icon: Icons.category_rounded,
          data: data.categoryRevenue,
          tone: SemanticTone.info,
          formatValue: (value) => Formatters.formatCurrency(value.toDouble()),
        ),
        const SizedBox(height: AppSpacing.md),
        _BreakdownSection(
          title: AppConstants.metricsByPayment,
          icon: Icons.credit_card_rounded,
          data: data.paymentMethodRevenue,
          tone: SemanticTone.neutral,
          formatValue: (value) => Formatters.formatCurrency(value.toDouble()),
        ),
      ],
    );
  }

  String _activeOrders(WidgetRef ref) {
    final orders = ref.watch(ordersControllerProvider);
    return '${orders.where((o) => !o.status.isTerminal).length}';
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.badgeText,
    this.badgeColor,
  });

  final String title;
  final IconData icon;
  final String? badgeText;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        if (badgeText != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs + 2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: (badgeColor ?? colorScheme.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              badgeText!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: badgeColor ?? colorScheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Modern Bento KPI Card ──────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    this.isLive = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedPressCard(
      borderRadius: AppRadius.lg,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
            width: 1.0,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: AppShadows.glow(accentColor, opacity: 0.3),
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      if (isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs + 2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PulseBadge(color: accentColor, size: 6),
                              const SizedBox(width: 4),
                              Text(
                                'نشط',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dispatch Fleet Health Card ─────────────────────────────────────────────────

class _DispatchHealthCard extends ConsumerWidget {
  const _DispatchHealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final board = ref.watch(dispatchControllerProvider);

    return AnimatedPressCard(
      key: const ValueKey('dispatch_health_card'),
      borderRadius: AppRadius.lg,
      onTap: () => context.push('/manager/dispatch'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
            width: 1,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs + 2),
                      decoration: BoxDecoration(
                        gradient: AppGradients.info,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      strings.dispatchFleetTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.dispatchBoard,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            board.when(
              loading: () => const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(AppConstants.dispatchHealthLoading),
                ],
              ),
              error: (_, _) => Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(AppConstants.dispatchHealthUnavailable),
                  ),
                ],
              ),
              data: (state) => Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _DispatchHealthStat(
                        label: strings.availableDrivers,
                        value: '${state.availableDrivers.length}',
                        color: const Color(0xFF10B981),
                        hasPulse: state.availableDrivers.isNotEmpty,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    Expanded(
                      child: _DispatchHealthStat(
                        label: strings.failedAssignments,
                        value: '${state.failedAssignments.length}',
                        color: state.failedAssignments.isNotEmpty
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    Expanded(
                      child: _DispatchHealthStat(
                        label: strings.pendingDrivers,
                        value: '${state.undispatchedOrders.length}',
                        color: state.undispatchedOrders.isNotEmpty
                            ? const Color(0xFFD97706)
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DispatchHealthStat extends StatelessWidget {
  const _DispatchHealthStat({
    required this.label,
    required this.value,
    required this.color,
    this.hasPulse = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool hasPulse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasPulse) ...[
              PulseBadge(color: color, size: 7),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Live Order Pipeline / Status Breakdown ─────────────────────────────────────

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({required this.orders});

  final List<OrderEntity> orders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
            width: 1,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_rounded,
                color: colorScheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'لا توجد طلبات جارية الآن',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'ستظهر جميع مراحل وإحصائيات الطلبات فور تسجيلها في النظام',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final counts = <OrderStatus, int>{};
    for (final order in orders) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
          width: 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final status in OrderStatus.values)
            if ((counts[status] ?? 0) > 0)
              _StatusPill(
                status: status,
                count: counts[status] ?? 0,
              ),
        ],
      ),
    );
  }
}

class _StatusPill extends ConsumerWidget {
  const _StatusPill({
    required this.status,
    required this.count,
  });

  final OrderStatus status;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = KdsColors.statusColor(status, theme.brightness);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.localizedLabel(ref.watch(isRtlProvider)),
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions Grid ─────────────────────────────────────────────────────────

class _QuickActionsGrid extends ConsumerWidget {
  const _QuickActionsGrid({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    final actions = [
      _ActionData(
        icon: Icons.restaurant_menu_rounded,
        label: strings.menu,
        gradient: AppGradients.primary,
        route: '/manager/menu',
      ),
      _ActionData(
        icon: Icons.table_restaurant_rounded,
        label: strings.tables,
        gradient: AppGradients.info,
        route: '/manager/tables',
      ),
      _ActionData(
        icon: Icons.event_seat_rounded,
        label: strings.reservations,
        gradient: AppGradients.purple,
        route: '/manager/reservations',
      ),
      _ActionData(
        icon: Icons.local_offer_rounded,
        label: strings.discounts,
        gradient: AppGradients.warning,
        route: '/manager/discounts',
      ),
      _ActionData(
        icon: Icons.confirmation_number_rounded,
        label: strings.coupons,
        gradient: AppGradients.warning,
        route: '/manager/coupons',
      ),
      _ActionData(
        icon: Icons.inventory_2_rounded,
        label: strings.inventory,
        gradient: AppGradients.emerald,
        route: '/manager/inventory',
      ),
      _ActionData(
        icon: Icons.people_alt_rounded,
        label: strings.staff,
        gradient: AppGradients.primary,
        route: '/manager/staff',
      ),
      _ActionData(
        icon: Icons.manage_accounts_rounded,
        label: strings.users,
        gradient: AppGradients.purple,
        route: '/manager/users',
      ),
      _ActionData(
        icon: Icons.local_shipping_rounded,
        label: strings.delivery,
        gradient: AppGradients.info,
        route: '/manager/dispatch',
      ),
      _ActionData(
        icon: Icons.receipt_long_rounded,
        label: strings.invoices,
        gradient: AppGradients.emerald,
        route: '/manager/invoices',
      ),
      _ActionData(
        icon: Icons.analytics_rounded,
        label: strings.financialReports,
        gradient: AppGradients.emerald,
        route: '/manager/financial-reports',
      ),
      _ActionData(
        icon: Icons.lock_clock_rounded,
        label: strings.shifts,
        gradient: AppGradients.primary,
        route: '/manager/shifts',
      ),
      _ActionData(
        icon: Icons.query_stats_rounded,
        label: strings.isArabic ? 'تقرير المالك 🌟' : 'Owner Digest 🌟',
        gradient: AppGradients.purple,
        route: '/manager/owner-digest',
      ),
      _ActionData(
        icon: Icons.analytics_outlined,
        label: strings.isArabic ? 'هندسة المنيو' : 'Menu Matrix',
        gradient: AppGradients.emerald,
        route: '/manager/menu-engineering',
      ),
      _ActionData(
        icon: Icons.menu_book_rounded,
        label: strings.isArabic ? 'الوصفات والتكلفة' : 'Recipes & BOM',
        gradient: AppGradients.primary,
        route: '/manager/recipes',
      ),
      _ActionData(
        icon: Icons.delete_sweep_rounded,
        label: strings.isArabic ? 'سجل الهالك' : 'Waste Logs',
        gradient: AppGradients.warning,
        route: '/manager/waste-logs',
      ),
      _ActionData(
        icon: Icons.qr_code_2_rounded,
        label: strings.qrCodes,
        gradient: AppGradients.purple,
        route: '/manager/qr-codes',
      ),
      _ActionData(
        icon: Icons.receipt_rounded,
        label: strings.orders,
        gradient: AppGradients.info,
        route: '/manager/orders',
      ),
      _ActionData(
        icon: Icons.timer_outlined,
        label: strings.isArabic ? 'ساعات الموظفين والأجور' : 'Staff Timesheet',
        gradient: AppGradients.primary,
        route: '/manager/timesheet',
      ),
      _ActionData(
        icon: Icons.local_shipping_outlined,
        label: strings.isArabic ? 'أوامر الشراء والموردين' : 'Purchase Orders',
        gradient: AppGradients.info,
        route: '/manager/purchase-orders',
      ),
      _ActionData(
        icon: Icons.security_rounded,
        label: strings.isArabic ? 'سجل التدقيق الأمني' : 'Security Audit',
        gradient: AppGradients.warning,
        route: '/manager/security-audit',
      ),
      _ActionData(
        icon: Icons.stars_rounded,
        label: strings.isArabic ? 'تقييمات وشكاوى العملاء' : 'Guest Feedback',
        gradient: AppGradients.emerald,
        route: '/manager/guest-feedback',
      ),
      _ActionData(
        icon: Icons.speed_rounded,
        label: strings.isArabic ? 'تارجت المبيعات والسرعة' : 'Sales Target',
        gradient: AppGradients.purple,
        route: '/manager/sales-target',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 7 : 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: isWide ? 1.05 : 0.95,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        return _QuickActionTile(data: item);
      },
    );
  }
}

class _ActionData {
  const _ActionData({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.route,
  });

  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final String route;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.data});

  final _ActionData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedPressCard(
      onTap: () => context.push(data.route),
      borderRadius: AppRadius.md,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
            width: 1,
          ),
          boxShadow: AppShadows.subtle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: data.gradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(
                  data.gradient.colors.first,
                  opacity: 0.25,
                ),
              ),
              child: Icon(data.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              data.label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Metric Breakdown Section ───────────────────────────────────────────────────

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    required this.title,
    required this.icon,
    required this.data,
    required this.tone,
    required this.formatValue,
  });

  final String title;
  final IconData icon;
  final Map<String, num> data;
  final SemanticTone tone;
  final String Function(num value) formatValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = StatusColors.tone(tone, theme.brightness);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
          width: 1,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(
                child: Text(
                  AppConstants.metricsNoData,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                for (final entry in data.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surfaceContainerHigh
                                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            formatValue(entry.value),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Dashboard Skeleton Loading ─────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 600;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const SkeletonBox(
              width: double.infinity,
              height: 48,
              borderRadius: AppRadius.full,
            ),
            const SizedBox(height: AppSpacing.md),
            const SkeletonBox(
              width: double.infinity,
              height: 70,
              borderRadius: AppRadius.lg,
            ),
            const SizedBox(height: AppSpacing.md),
            if (isWide)
              Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    const Expanded(child: _SkeletonCard()),
                  ],
                ],
              )
            else ...[
              const Row(
                children: [
                  Expanded(child: _SkeletonCard()),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: _SkeletonCard()),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Row(
                children: [
                  Expanded(child: _SkeletonCard()),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: _SkeletonCard()),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const _SkeletonCard(height: 80),
            const SizedBox(height: AppSpacing.md),
            const SkeletonBox(
              width: double.infinity,
              height: 240,
              borderRadius: AppRadius.lg,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({this.height = 130});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: double.infinity,
      height: height,
      borderRadius: AppRadius.lg,
    );
  }
}
