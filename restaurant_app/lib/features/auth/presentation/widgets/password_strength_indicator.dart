import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/validators.dart';

/// Qualitative password strength buckets shown by the meter.
///
/// `strong` means every [Validators] password criterion passes, so the meter
/// and the form validator can never disagree about what is acceptable.
enum PasswordStrength { weak, good, strong }

/// Compact three-segment password strength meter with an Arabic label.
///
/// Design constraints:
/// * Fully stateless — no layout or implicit animations, so it respects the
///   platform reduce-motion preference by construction (only colors change).
/// * Renders nothing ([SizedBox.shrink]) while [password] is empty.
/// * Colors stay inside the audited semantic palette (`colorScheme.error`,
///   warning and success tones) in both brightness modes.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});

  /// Live password text driving both visibility and level.
  final String password;

  static const int _segmentCount = 3;
  static const double _segmentHeight = 4;

  /// Maps [password] onto a [PasswordStrength] bucket via the shared
  /// [Validators.passwordStrengthScore] helper (single source of truth with
  /// the form validators).
  ///
  /// Scoring: 0–1 criteria met → weak, 2 → good, all 3 → strong.
  static PasswordStrength evaluate(String? password) {
    return switch (Validators.passwordStrengthScore(password)) {
      3 => PasswordStrength.strong,
      2 => PasswordStrength.good,
      _ => PasswordStrength.weak,
    };
  }

  /// Resolves the accent color for [strength] against the current theme.
  static Color toneOf(ThemeData theme, PasswordStrength strength) {
    return switch (strength) {
      PasswordStrength.weak => theme.colorScheme.error,
      PasswordStrength.good => StatusColors.tone(
        SemanticTone.warning,
        theme.brightness,
      ),
      PasswordStrength.strong => StatusColors.tone(
        SemanticTone.success,
        theme.brightness,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Hide entirely until the user types something.
    if (password.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final strength = evaluate(password);
    final activeColor = toneOf(theme, strength);
    final filledCount = strength.index + 1;

    return Row(
      children: [
        for (var i = 0; i < _segmentCount; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              height: _segmentHeight,
              decoration: BoxDecoration(
                color: i < filledCount
                    ? activeColor
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.sm),
        Text(
          strength.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: activeColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

extension _PasswordStrengthLabel on PasswordStrength {
  String get label => switch (this) {
    PasswordStrength.weak => 'ضعيفة',
    PasswordStrength.good => 'متوسطة',
    PasswordStrength.strong => 'قوية',
  };
}
