import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/color_schemes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/animated_press_card.dart';
import '../../../../shared/animations/pulse_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../restaurant/domain/entities/branch_entity.dart';
import '../../../restaurant/presentation/controllers/branch_controller.dart';
import 'add_branch_dialog.dart';

/// Section displayed on the Super Admin dashboard when "All Branches" tab is selected.
class BranchesOverviewSection extends ConsumerWidget {
  const BranchesOverviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = ref.watch(authControllerProvider).user;
    final isAdmin = currentUser?.role == UserRole.admin;
    final branches = ref.watch(branchesControllerProvider);
    final totalSales = ref.watch(totalChainSalesProvider);
    final totalOrders = ref.watch(totalChainOrdersProvider);
    final totalActive = ref.watch(totalChainActiveOrdersProvider);
    final openCount = branches.where((b) => b.isOpen).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Chain-Wide KPI Bento Cards ───────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _ChainKpiCard(
                title: 'إجمالي مبيعات السلسلة',
                value: Formatters.formatCurrency(totalSales),
                subtitle: 'اليوم عبر $openCount فروع مفتوحة',
                icon: Icons.account_balance_rounded,
                gradient: AppGradients.emerald,
                accentColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ChainKpiCard(
                title: 'إجمالي طلبات السلسلة',
                value: '$totalOrders',
                subtitle: 'طلب مسجل اليوم',
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
              child: _ChainKpiCard(
                title: 'الطلبات النشطة بالسلسلة',
                value: '$totalActive',
                subtitle: 'قيد التحضير والتوصيل',
                icon: Icons.delivery_dining_rounded,
                gradient: AppGradients.purple,
                accentColor: const Color(0xFF8B5CF6),
                isLive: totalActive > 0,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ChainKpiCard(
                title: 'الفروع النشطة',
                value: '$openCount / ${branches.length}',
                subtitle: 'فروع تستقبل الطلبات',
                icon: Icons.storefront_rounded,
                gradient: AppGradients.primary,
                accentColor: AppColors.brand,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Branches Header ──────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.apartment_rounded, color: colorScheme.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'أداء وحالة فروع السلسلة',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (isAdmin)
              FilledButton.tonalIcon(
                onPressed: () => AddBranchDialog.show(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('فرع جديد'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 4,
                    vertical: AppSpacing.xs,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Individual Branch Cards List ─────────────────────────────────────
        for (final branch in branches) ...[
          _BranchCard(branch: branch),
          const SizedBox(height: AppSpacing.sm),
        ],

        const SizedBox(height: AppSpacing.md),

        // ── Branch Performance Comparison Bar ────────────────────────────────
        _BranchPerformanceLeaderboard(branches: branches),
      ],
    );
  }
}

class _ChainKpiCard extends StatelessWidget {
  const _ChainKpiCard({
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadows.glow(accentColor, opacity: 0.3),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
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
                        'مباشر',
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
          const SizedBox(height: AppSpacing.sm),
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
    );
  }
}

class _BranchCard extends ConsumerWidget {
  const _BranchCard({required this.branch});

  final BranchEntity branch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedPressCard(
      borderRadius: AppRadius.lg,
      onTap: () {
        ref.read(selectedBranchIdProvider.notifier).state = branch.id;
      },
      child: Container(
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
            // Top Accent line with branch color
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: branch.color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: branch.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          Icons.store_rounded,
                          color: branch.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  branch.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(
                                    branch.city,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              branch.address,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(branchesControllerProvider.notifier)
                              .toggleBranchStatus(branch.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: branch.isOpen
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : colorScheme.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: branch.isOpen
                                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                  : colorScheme.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (branch.isOpen)
                                const PulseBadge(color: Color(0xFF10B981), size: 7)
                              else
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              const SizedBox(width: 4),
                              Text(
                                branch.isOpen ? 'مفتوح' : 'مغلق',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: branch.isOpen
                                      ? const Color(0xFF047857)
                                      : colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHigh
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BranchStatItem(
                          label: 'مبيعات اليوم',
                          value: Formatters.formatCurrency(branch.todaySales),
                          color: const Color(0xFF10B981),
                        ),
                        _divider(colorScheme),
                        _BranchStatItem(
                          label: 'الطلبات',
                          value: '${branch.totalOrdersToday}',
                          color: const Color(0xFF0284C7),
                        ),
                        _divider(colorScheme),
                        _BranchStatItem(
                          label: 'طلبات جارية',
                          value: '${branch.activeOrdersCount}',
                          color: branch.activeOrdersCount > 0
                              ? const Color(0xFFD97706)
                              : colorScheme.onSurfaceVariant,
                        ),
                        _divider(colorScheme),
                        _BranchStatItem(
                          label: 'الطاولات',
                          value: '${branch.totalTables}',
                          color: colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'المدير: ${branch.managerName ?? "غير محدد"}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'فتح لوحة الفرع',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 24,
      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

class _BranchStatItem extends StatelessWidget {
  const _BranchStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _BranchPerformanceLeaderboard extends StatelessWidget {
  const _BranchPerformanceLeaderboard({required this.branches});

  final List<BranchEntity> branches;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final sorted = List<BranchEntity>.from(branches)
      ..sort((a, b) => b.todaySales.compareTo(a.todaySales));

    final maxSales = sorted.isNotEmpty && sorted.first.todaySales > 0
        ? sorted.first.todaySales
        : 1.0;

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
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.leaderboard_rounded, color: colorScheme.primary, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'ترتيب الفروع حسب حجم المبيعات اليوم',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < sorted.length; i++) ...[
            _LeaderboardRow(
              rank: i + 1,
              branch: sorted[i],
              maxSales: maxSales,
            ),
            if (i < sorted.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.branch,
    required this.maxSales,
  });

  final int rank;
  final BranchEntity branch;
  final double maxSales;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (branch.todaySales / maxSales).clamp(0.05, 1.0);

    String medal = '';
    if (rank == 1) medal = '🥇';
    if (rank == 2) medal = '🥈';
    if (rank == 3) medal = '🥉';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (medal.isNotEmpty)
                  Text(medal, style: const TextStyle(fontSize: 14))
                else
                  Text(
                    '#$rank',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  branch.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(
              Formatters.formatCurrency(branch.todaySales),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(branch.color),
          ),
        ),
      ],
    );
  }
}
