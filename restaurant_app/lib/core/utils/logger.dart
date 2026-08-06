import 'package:intl/intl.dart';

/// Minimal timestamped logger.
///
/// Kept dependency-free (pure Dart + `intl`) so it can be used from any layer.
/// `print` is intentionally used (a dedicated logging package is not part of
/// the current dependencies); the `avoid_print` lint is disabled locally.
abstract final class AppLogger {
  AppLogger._();

  /// Whether log output is emitted. Disable in release to silence logging.
  static bool enabled = true;

  static void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _log('DEBUG', message, error: error, stackTrace: stackTrace);

  static void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _log('INFO', message, error: error, stackTrace: stackTrace);

  static void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _log('WARN', message, error: error, stackTrace: stackTrace);

  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log('ERROR', message, error: error, stackTrace: stackTrace);

  static void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!enabled) return;
    final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final buffer = StringBuffer('[$time] [$level] $message');
    if (error != null) {
      buffer.write('\n  └─ error: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n  └─ stack: $stackTrace');
    }
    _write(buffer.toString());
  }

  static void _write(String line) {
    // ignore: avoid_print
    print(line);
  }
}
