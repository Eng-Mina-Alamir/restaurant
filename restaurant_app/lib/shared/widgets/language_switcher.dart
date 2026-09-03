import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/spacing.dart';
import '../animations/animated_press_card.dart';

/// Modern tactile language switcher button toggling between Arabic (RTL) and English (LTR)
/// with micro-rotations, animated text flips, and haptic feedback.
class LanguageSwitcherButton extends ConsumerWidget {
  final bool compact;

  const LanguageSwitcherButton({super.key, this.compact = false});

  void _onToggle(BuildContext context, WidgetRef ref, bool isArabic) {
    HapticFeedback.lightImpact();

    // Capture global position of this switcher button for the radial wave reveal
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final center = renderBox.localToGlobal(
        renderBox.size.center(Offset.zero),
      );
      ref.read(languageTransitionOriginProvider.notifier).state = center;
    }

    final strings = ref.read(appStringsProvider);
    final switchedMessage = isArabic ? strings.switchedToEnglish : strings.switchedToArabic;
    ref.read(localeControllerProvider.notifier).toggleLanguage();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        duration: const Duration(milliseconds: 1400),
        backgroundColor: const Color(0xFF1E293B),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              switchedMessage,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final lang = ref.watch(currentLanguageProvider);
    final isArabic = lang == AppLanguage.arabic;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (compact) {
      return AnimatedPressCard(
        borderRadius: AppRadius.full,
        onTap: () => _onToggle(context, ref, isArabic),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 3,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                turns: isArabic ? 0.0 : 0.5,
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutBack,
                child: Icon(
                  Icons.language_rounded,
                  size: 15,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Text(
                  isArabic ? strings.languageToggleToEnglish : strings.languageToggleToArabic,
                  key: ValueKey<String>(isArabic ? 'EN' : 'عربي'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedPressCard(
      borderRadius: AppRadius.full,
      onTap: () => _onToggle(context, ref, isArabic),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedRotation(
              turns: isArabic ? 0.0 : 0.5,
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutBack,
              child: Icon(
                Icons.language_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
                child: Text(
                  isArabic ? strings.languageToggleLongToEnglish : strings.languageToggleLongToArabic,
                  key: ValueKey<String>(isArabic ? 'English (EN)' : 'العربية (AR)'),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
