import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_controller.dart';

/// Reusable AppBar action button to toggle between Light and Dark theme modes.
class ThemeModeSwitchButton extends ConsumerWidget {
  const ThemeModeSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final brightness = Theme.of(context).brightness;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && brightness == Brightness.dark);

    return IconButton(
      tooltip: isDark ? 'التبديل إلى الوضع الفاتح' : 'التبديل إلى الوضع الداكن',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: anim,
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          key: ValueKey(isDark),
        ),
      ),
      onPressed: () {
        ref.read(themeModeControllerProvider.notifier).toggleTheme(brightness);
      },
    );
  }
}
