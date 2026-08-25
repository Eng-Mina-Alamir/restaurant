import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../domain/entities/rating_entity.dart';
import '../controllers/rating_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Modal dialog for rating an item, driver, or restaurant experience.
class RatingDialog extends ConsumerStatefulWidget {
  const RatingDialog({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.title,
    this.subtitle,
  });

  final String targetId;
  final RatingTargetType targetType;
  final String title;
  final String? subtitle;

  static Future<bool?> show(
    BuildContext context, {
    required String targetId,
    required RatingTargetType targetType,
    required String title,
    String? subtitle,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => RatingDialog(
        targetId: targetId,
        targetType: targetType,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  ConsumerState<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends ConsumerState<RatingDialog> {
  double _score = 5.0;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.read(authControllerProvider).user;

    return AlertDialog(
      title: Text(widget.title, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.subtitle != null) ...[
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Star Rating Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  icon: Icon(
                    starValue <= _score ? Icons.star : Icons.star_border,
                    color: StatusColors.starRating(theme.brightness),
                    size: 36,
                  ),
                  onPressed: () =>
                      setState(() => _score = starValue.toDouble()),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _ratingLabel(_score),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Comment Box
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'شاركنا تجربتك وملاحظاتك (اختياري)...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('لاحقاً'),
        ),
        FilledButton(
          onPressed: _submitting
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final ok = await ref
                      .read(ratingSubmissionControllerProvider.notifier)
                      .submitRating(
                        targetId: widget.targetId,
                        targetType: widget.targetType,
                        userId: user?.id ?? 'guest',
                        userName: user?.name ?? 'عميل مميز',
                        score: _score,
                        comment: _commentController.text.trim().isEmpty
                            ? null
                            : _commentController.text.trim(),
                      );
                  if (!mounted) return;
                  setState(() => _submitting = false);
                  navigator.pop(ok);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('شكراً لمشاركتنا تقييمك القيّم!'),
                    ),
                  );
                },

          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إرسال التقييم'),
        ),
      ],
    );
  }

  String _ratingLabel(double score) {
    if (score >= 5) return 'ممتاز جداً';
    if (score >= 4) return 'جيد جداً';
    if (score >= 3) return 'جيد';
    if (score >= 2) return 'مقبول';
    return 'يحتاج إلى تحسين';
  }
}
