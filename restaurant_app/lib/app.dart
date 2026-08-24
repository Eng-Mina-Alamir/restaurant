import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'config/app_config.dart';
import 'core/l10n/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

/// Root application widget.
///
/// Wraps the app with [ProviderScope], configures the [GoRouter] with
/// role-based redirects, and triggers the auth bootstrap (session restore) once
/// on first frame.
class RestaurantApp extends ConsumerStatefulWidget {
  const RestaurantApp({super.key});

  @override
  ConsumerState<RestaurantApp> createState() => _RestaurantAppState();
}

class _RestaurantAppState extends ConsumerState<RestaurantApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(ref: ref);
    // Resolve the initial session on the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force the router to re-evaluate its redirects when the auth state changes.
    ref.listen(authControllerProvider, (_, _) => _router.refresh());

    final activeLocale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
      locale: activeLocale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
