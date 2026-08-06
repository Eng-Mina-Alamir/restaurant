import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/data/app_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cache = await initAppCache();

  runApp(
    ProviderScope(
      overrides: [
        if (cache != null) localCacheServiceProvider.overrideWithValue(cache),
      ],
      child: const RestaurantApp(),
    ),
  );
}
