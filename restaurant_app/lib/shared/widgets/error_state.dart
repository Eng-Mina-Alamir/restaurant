import 'package:flutter/material.dart';

import '../../../config/constants.dart' show AppConstants;
import '../../../core/theme/spacing.dart';
import '../animations/fade_slide_transition.dart';
import '../animations/floating_illustration.dart';

/// Consistent error-state placeholder used across pages that fetch or render data.
///
/// Shows an error icon with subtle floating animation, a user-friendly [message],
/// an optional technical [errorDetail], and an optional [retryLabel] that
/// triggers [onRetry] (e.g. "إعادة المحاولة").
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message = AppConstants.errorGeneric,
    this.errorDetail,
    this.icon = Icons.error_outline_rounded,
    this.retryLabel = AppConstants.orderAuditTrailRetryAction,
    this.onRetry,
  });

  /// The primary Arabic error headline to show the user.
  final String message;

  /// Optional underlying error object/string for debug or detailed reporting.
  final Object? errorDetail;

  /// The icon representing the error state.
  final IconData icon;

  /// Label on the retry action button.
  final String retryLabel;

  /// Callback executed when the user taps the retry button.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Center(
      child: FadeSlideTransitionWidget(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingIllustration(
                distance: 6.0,
                duration: const Duration(milliseconds: 2400),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 44, color: errorColor),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (errorDetail != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    errorDetail.toString(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton.tonalIcon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(retryLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
