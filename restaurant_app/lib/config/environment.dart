/// Deployment environments supported by the app.
///
/// See spec section 8.1 for base-URL resolution rules.
enum Environment { dev, staging, production }

/// Resolves environment-specific configuration, primarily API base URLs.
///
/// The active environment is chosen at compile time by toggling
/// [EnvironmentConfig.current]. This keeps the switch tree simple and avoids
/// any platform channel / runtime dependency so the class stays pure Dart.
abstract final class EnvironmentConfig {
  /// The currently active environment.
  ///
  /// Defaults to production for live Supabase deployment.
  static const Environment _current = Environment.production;

  /// The active environment.
  static Environment get current => _current;

  /// Whether the production backend is active.
  static bool get isProduction => _current == Environment.production;

  /// Whether the staging backend is active.
  static bool get isStaging => _current == Environment.staging;

  /// Base URL of the backend API for the active environment.
  static String get baseUrl {
    switch (_current) {
      case Environment.dev:
        return 'https://dev-api.restaurant.example.com';
      case Environment.staging:
        return 'https://staging-api.restaurant.example.com';
      case Environment.production:
        return 'https://iovxfvkaswdediephqep.supabase.co/rest/v1';
    }
  }

  /// WebSocket base URL for the active environment (real-time KDS/orders).
  static String get wsUrl {
    switch (_current) {
      case Environment.dev:
        return 'wss://dev-api.restaurant.example.com';
      case Environment.staging:
        return 'wss://staging-api.restaurant.example.com';
      case Environment.production:
        return 'wss://iovxfvkaswdediephqep.supabase.co/realtime/v1/websocket';
    }
  }
}
