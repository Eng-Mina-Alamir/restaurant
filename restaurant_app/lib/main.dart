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
    AppLogger.error('PlatformDispatcher error: $error', error: error, stackTrace: stack);
    if (_sentryDsn.isNotEmpty) {
      Sentry.captureException(error, stackTrace: stack);
    }
    return true;
  };

  Future<void> appRunner() async {
    await runZonedGuarded(() async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Supabase backend
      try {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          publishableKey: SupabaseConfig.anonKey,
        );
        AppLogger.info('Supabase initialized successfully');
      } catch (e, st) {
        AppLogger.error('Failed to initialize Supabase: $e', error: e, stackTrace: st);
      }

      final cache = await initAppCache();

      runApp(
        ProviderScope(
          overrides: [
            if (cache != null) localCacheServiceProvider.overrideWithValue(cache),
          ],
          child: const RestaurantApp(),
        ),
      );
    }, (error, stack) {
      AppLogger.error('Unhandled zone error: $error', error: error, stackTrace: stack);
      if (_sentryDsn.isNotEmpty) {
        Sentry.captureException(error, stackTrace: stack);
      }
    });
  }

  // 4. Initialize Sentry if DSN is configured
  if (_sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
        options.tracesSampleRate = 1.0;
        options.environment = kReleaseMode ? 'production' : 'development';
      },
      appRunner: appRunner,
    );
  } else {
    await appRunner();
  }
}
