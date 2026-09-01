import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_schemes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/constrained_content_view.dart';
import '../../domain/entities/guest_feedback_entity.dart';
import '../controllers/guest_feedback_controller.dart';

/// Guest Feedback, Rating CSAT Metrics, and Complaint Resolution Hub for Managers.
class GuestFeedbackHubPage extends ConsumerWidget {
  const GuestFeedbackHubPage({super.key});

  void _showResolveDialog(BuildContext context, WidgetRef ref, GuestFeedback feedback) {
    final notesCtrl = TextEditingController(text: 'تم الاتصال بالعميل والاعتذار عن التأخير وإرسال كود خصم 20%');
    final couponCtrl = TextEditingController(text: 'APOLOGY20');

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.handshake_rounded, color: Color(0xFF10B981), size: 24),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('معالجة شكوى العميل: ${feedback.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(feedback.customerPhone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),

                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'إجراءات المعالجة والتواصل مع العميل *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                TextField(
                  controller: couponCtrl,
                  decoration: InputDecoration(
                    labelText: 'كوبون تعويض أو خصم اعتذار للعميل',
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        onPressed: () {
                          ref.read(guestFeedbackControllerProvider.notifier).resolveComplaint(
                                feedbackId: feedback.id,
                                resolutionNotes: notesCtrl.text.trim(),
                                compensationCouponCode: couponCtrl.text.trim().isEmpty ? null : couponCtrl.text.trim(),
                              );

                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم توثيق حل الشكوى وإرسال التعويض للعميل بنجاح ✅'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('حفظ وتسوية الشكوى'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final feedbackState = ref.watch(guestFeedbackControllerProvider);
    final metrics = feedbackState.metrics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز تقييمات وشكاوى العملاء (Guest CSAT)'),
      ),
      body: ConstrainedContentView(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── 1. Top CSAT Banner ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppGradients.emerald,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'مؤشر رضا العملاء العام (CSAT Score)',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.stars_rounded, color: Colors.white70),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${metrics.csatPercentage}%',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('التقييم العام: ⭐ ${metrics.averageOverallRating} / 5.0', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('إجمالي التقييمات: ${metrics.totalReviewsCount} تقييم', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      _RatingDetail(title: 'جودة الطعام:', value: '${metrics.averageFoodQuality} ⭐'),
                      _RatingDetail(title: 'سرعة الخدمة:', value: '${metrics.averageServiceSpeed} ⭐'),
                      _RatingDetail(title: 'نظافة الصالة:', value: '${metrics.averageCleanliness} ⭐'),
                      _RatingDetail(title: 'شكاوى معلقة:', value: '${metrics.unresolvedComplaintsCount} شكوى'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 2. Feedback Feed ─────────────────────────────────────────────
            Text(
              'أحدث تقييمات وآراء العملاء (${feedbackState.feedbacks.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: feedbackState.feedbacks.length,
              separatorBuilder: (ctx, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final f = feedbackState.feedbacks[index];

                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: f.isNegative
                          ? (f.isResolved ? Colors.green.withValues(alpha: 0.4) : Colors.red.withValues(alpha: 0.4))
                          : Colors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(f.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 6),
                              Text('(${f.customerPhone})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (starIdx) => Icon(
                                starIdx < f.overallRating ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 18,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(f.comment, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'طعام: ${f.foodQualityRating}⭐ • سرعة: ${f.serviceSpeedRating}⭐ • نظافة: ${f.cleanlinessRating}⭐ • ${Formatters.formatTime(f.createdAt)}',
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                          ),
                          if (f.isNegative && !f.isResolved)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              onPressed: () => _showResolveDialog(context, ref, f),
                              icon: const Icon(Icons.support_agent_rounded, size: 16),
                              label: const Text('تسوية الشكوى والتعويض', style: TextStyle(fontSize: 11)),
                            )
                          else if (f.isResolved)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: const Text('تمت التسوية بنجاح ✅', style: TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingDetail extends StatelessWidget {
  const _RatingDetail({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
