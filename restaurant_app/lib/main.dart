import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const RestaurantApp());
}

/// Root application widget.
///
/// Placeholder entry point during scaffold stage; will be replaced by the
/// Riverpod + go_router setup in the auth/routing milestone.
class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const _HomePlaceholder(),
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConfig.appName)),
      body: const Center(child: Text('مطعمي - جاهز للتطوير')),
    );
  }
}
