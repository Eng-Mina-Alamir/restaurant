import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'core/data/app_cache.dart';
import 'core/utils/logger.dart';

const String _sentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  // 1. Control logging: emit logs only in debug mode
  AppLogger.enabled = kDebugMode;

  Future<void> appRunner() async {
    await runZonedGuarded(
      () async {
        // Binding must be initialized inside the same zone as runApp().
        WidgetsFlutterBinding.ensureInitialized();

        // 2. Global Flutter framework error handling
        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          AppLogger.error(
            'Flutter framework error: ${details.exceptionAsString()}',
            error: details.exception,
            stackTrace: details.stack,
          );
          if (_sentryDsn.isNotEmpty) {
            Sentry.captureException(details.exception, stackTrace: details.stack);
          }
        };

        // 3. Global Platform Dispatcher error handling
        PlatformDispatcher.instance.onError = (error, stack) {
          AppLogger.error(
            'PlatformDispatcher error: $error',
            error: error,
            stackTrace: stack,
          );
          if (_sentryDsn.isNotEmpty) {
            Sentry.captureException(error, stackTrace: stack);
          }
          return true;
        };

        // Cache setup is independent of the backend, so start it now and
        // await it below; both initializations then run concurrently.
        final cacheFuture = initAppCache();

        // Initialize Supabase backend if configured via build environment
        if (SupabaseConfig.isConfigured) {
          try {
            await Supabase.initialize(
              url: SupabaseConfig.url,
              publishableKey: SupabaseConfig.anonKey,
            );
            AppLogger.info('Supabase initialized successfully');
          } catch (e, st) {
            AppLogger.error(
              'Failed to initialize Supabase: $e',
              error: e,
              stackTrace: st,
            );
          }
        } else {
          AppLogger.warning(
            'Supabase keys not injected in build environment. Running in offline/demo mode.',
          );
        }

        final cache = await cacheFuture;

        runApp(
          ProviderScope(
            overrides: [
              if (cache != null)
                localCacheServiceProvider.overrideWithValue(cache),
            ],
            child: const RestaurantApp(),
          ),
        );
      },
      (error, stack) {
        AppLogger.error(
          'Unhandled zone error: $error',
          error: error,
          stackTrace: stack,
        );
        if (_sentryDsn.isNotEmpty) {
          Sentry.captureException(error, stackTrace: stack);
        }
      },
    );
  }

  // 4. Initialize Sentry if DSN is configured
  if (_sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = _sentryDsn;
      options.tracesSampleRate = 1.0;
      options.environment = kReleaseMode ? 'production' : 'development';
    }, appRunner: appRunner);
  } else {
    await appRunner();
  }
}

