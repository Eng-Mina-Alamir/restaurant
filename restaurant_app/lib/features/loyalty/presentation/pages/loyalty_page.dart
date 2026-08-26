import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/animations/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../domain/entities/loyalty_entity.dart';
import '../controllers/loyalty_controller.dart';

class LoyaltyPage extends ConsumerWidget {
  const LoyaltyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(loyaltyControllerProvider);
    final rewardsAsync = ref.watch(availableRewardsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('برنامج الولاء والمكافآت'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(loyaltyControllerProvider.notifier).loadAccount(),
          ),
        ],
      ),
      body: accountAsync.when(
        loading: () => const _LoyaltySkeleton(),
        error: (err, _) => ErrorState(
          message: AppConstants.errorLoadingData,
          errorDetail: err,
          onRetry: () =>
              ref.read(loyaltyControllerProvider.notifier).loadAccount(),
        ),
        data: (account) {
          final nextTier = account.tier.nextTier;
          final nextTierPoints = nextTier?.minPoints ?? account.lifetimePoints;
          final currentTierPoints = account.tier.minPoints;
          final progress = nextTier == null
              ? 1.0
              : ((account.lifetimePoints - currentTierPoints) /
                        (nextTierPoints - currentTierPoints))
                    .clamp(0.0, 1.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Tier Card ───────────────────────────────────────────────
                _TierBanner(
                  account: account,
                  progress: progress,
                  nextTier: nextTier,
                  nextTierPoints: nextTierPoints,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Rewards Catalog ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المكافآت المتاحة للاستبدال',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: StatusColors.starRating(theme.brightness),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${account.currentPoints} نقطة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                rewardsAsync.when(
                  loading: () => const Column(
                    children: [
                      _RewardCardSkeleton(),
                      _RewardCardSkeleton(),
                    ],
                  ),
                  error: (err, _) => ErrorState(
                    message: AppConstants.errorLoadingData,
                    errorDetail: err,
                    onRetry: () => ref.invalidate(availableRewardsProvider),
                  ),
                  data: (rewards) => Column(
                    children: [
                      for (final reward in rewards)
                        _RewardCard(
                          reward: reward,
                          userPoints: account.currentPoints,
                          onRedeem: () => _confirmRedeem(context, ref, reward),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Points History ──────────────────────────────────────────
                Text(
                  'سجل النقاط والمعاملات',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (account.transactions.isEmpty)
                  const EmptyState(
                    message: 'لا توجد معاملات نقاط سابقة',
                    icon: Icons.history,
                  )
                else
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: account.transactions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tx = account.transactions[index];
                        final isPositive = tx.points > 0;
                        final txColor = StatusColors.tone(
                          isPositive
                              ? SemanticTone.success
                              : SemanticTone.danger,
                          theme.brightness,
                        );

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: txColor.withValues(alpha: 0.15),
                            child: Icon(
                              isPositive
                                  ? Icons.add_circle_outline
                                  : Icons.remove_circle_outline,
                              color: txColor,
                            ),
                          ),
                          title: Text(tx.description),
                          subtitle: Text(
                            Formatters.formatDateTime(tx.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Text(
                            '${isPositive ? '+' : ''}${tx.points} نقطة',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: txColor,
                              fontWeight: FontWeight.bold,
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

  void _confirmRedeem(
    BuildContext context,
    WidgetRef ref,
    LoyaltyReward reward,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('استبدال: ${reward.title}'),
        content: Text(
          'هل تريد استبدال ${reward.pointsCost} نقطة للحصول على "${reward.description}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppConstants.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(loyaltyControllerProvider.notifier)
                  .redeemReward(reward);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'تم استبدال المكافأة بنجاح وتمت إضافة القسيمة لحسابك!'
                          : 'عفواً، رصيد نقاطك غير كافٍ',
                    ),
                  ),
                );
              }
            },
            child: const Text('تأكيد الاستبدال'),
          ),
        ],
      ),
    );
  }
}

class _TierBanner extends StatelessWidget {
  final LoyaltyAccount account;
  final double progress;
  final LoyaltyTier? nextTier;
  final int nextTierPoints;

  const _TierBanner({
    required this.account,
    required this.progress,
    required this.nextTier,
    required this.nextTierPoints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tier = account.tier;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tier.color.withValues(alpha: 0.85),
            tier.color.withValues(alpha: 0.4),
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: tier.color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      // Scrim veil keeps the tier pill legible over any of the
                      // bright metallic tier gradients (bronze → platinum).
                      color: colorScheme.scrim.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: colorScheme.onPrimary,
                          size: 16,
                        ),

                        const SizedBox(width: 4),
                        Text(
                          'المستوى ${tier.labelAr}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${account.currentPoints}',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'نقطة ولاء صالحة للاستخدام',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.onPrimary.withValues(alpha: 0.4),
                ),
                child: Center(
                  child: Text(
                    '${tier.multiplier}x',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (nextTier != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المستوى القادم: ${nextTier!.labelAr}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${nextTierPoints - account.lifetimePoints} نقطة متبقية',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ] else
            Text(
              'وصلت لأعلى مستوى في برنامج الولاء (VIP النخبة)!',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final LoyaltyReward reward;
  final int userPoints;
  final VoidCallback onRedeem;

  const _RewardCard({
    required this.reward,
    required this.userPoints,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canAfford = userPoints >= reward.pointsCost;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: canAfford
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                color: canAfford
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reward.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        size: 16,
                        color: StatusColors.starRating(theme.brightness),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reward.pointsCost} نقطة',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: canAfford
                              ? colorScheme.primary
                              : colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.tonal(
              onPressed: canAfford ? onRedeem : null,
              child: const Text('استبدال'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading skeleton ─────────────────────────────────────────────────────────

/// Shimmer placeholder mirroring the loyalty layout while the account loads:
/// tier banner with multiplier badge, next-tier progress bar and points
/// history rows.
class _LoyaltySkeleton extends StatelessWidget {
  const _LoyaltySkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Tier banner ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(
                            width: 96,
                            height: 20,
                            borderRadius: AppRadius.full,
                          ),
                          SizedBox(height: AppSpacing.xs),
                          SkeletonBox(width: 150, height: 32),
                          SizedBox(height: AppSpacing.xs),
                          SkeletonBox(width: 130, height: 12, borderRadius: AppRadius.xs),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    SkeletonCircle(size: 64),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 110, height: 10, borderRadius: AppRadius.full),
                    SkeletonBox(width: 80, height: 10, borderRadius: AppRadius.full),
                  ],
                ),
                SizedBox(height: 6),
                // Progress bar.
                SkeletonBox(
                  width: double.infinity,
                  height: 8,
                  borderRadius: AppRadius.full,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Points history ──
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: SkeletonBox(width: 180, height: 18, borderRadius: AppRadius.sm),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  const _HistoryRowSkeleton(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer stand-in for one points-history list tile: avatar circle,
/// description/date lines and a trailing points pill.
class _HistoryRowSkeleton extends StatelessWidget {
  const _HistoryRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SkeletonCircle(size: 40),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: double.infinity, height: 14),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 120, height: 10, borderRadius: AppRadius.xs),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          SkeletonBox(width: 56, height: 12, borderRadius: AppRadius.xs),
        ],
      ),
    );
  }
}

/// Shimmer stand-in for one reward catalog card: icon circle, title/description
/// lines and a redeem button block.
class _RewardCardSkeleton extends StatelessWidget {
  const _RewardCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            SkeletonCircle(size: 44),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 14, borderRadius: AppRadius.xs),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonBox(
                    width: double.infinity,
                    height: 11,
                    borderRadius: AppRadius.xs,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonBox(width: 80, height: 11, borderRadius: AppRadius.xs),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            SkeletonBox(width: 76, height: 40, borderRadius: AppRadius.full),
          ],
        ),
      ),
    );
  }
}
