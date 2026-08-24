import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';

class LanguageSwitcherButton extends ConsumerWidget {
  final bool compact;

  const LanguageSwitcherButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(currentLanguageProvider);

    if (compact) {
      return IconButton(
        icon: const Icon(Icons.language_rounded),
        tooltip: lang == AppLanguage.arabic
            ? 'Switch to English'
            : 'التحويل للعربية',
        onPressed: () {
          ref.read(localeControllerProvider.notifier).toggleLanguage();
        },
      );
    }

    return OutlinedButton.icon(
      icon: const Icon(Icons.language_rounded, size: 18),
      label: Text(
        lang == AppLanguage.arabic ? 'English 🇺🇸' : 'العربية 🇸🇦',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        ref.read(localeControllerProvider.notifier).toggleLanguage();
      },
    );
  }
}
