import 'package:intl/intl.dart';

/// Minimal timestamped logger.
///
/// Kept dependency-free (pure Dart + `intl`) so it can be used from any layer.
/// `print` is intentionally used (a dedicated logging package is not part of
/// the current dependencies); the `avoid_print` lint is disabled locally.
///
/// Each entry is prefixed with the caller's `file:line` (derived from
/// [StackTrace.current]) so logs are greppable back to the source.
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
    final location = _callerLocation();
    final buffer = StringBuffer('[$time] [$level] $location $message');
    if (error != null) {
      buffer.write('\n  └─ error: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n  └─ stack: $stackTrace');
    }
    _write(buffer.toString());
  }

  /// Returns the `file:line` of the first frame that is *not* this logger,
  /// i.e. the original call site. Falls back to `(unknown)` when parsing
  /// fails (some runtimes emit non-standard frame formats).
  static String _callerLocation() {
    for (final frame in StackTrace.current.toString().split('\n')) {
      final trimmed = frame.trimLeft();
      if (!trimmed.contains('logger.dart')) {
        final match = RegExp(r'(\S+\.dart):(\d+)').firstMatch(trimmed);
        if (match != null) {
          final file = match.group(1)!.split('/').last;
          return '$file:${match.group(2)}';
        }
      }
    }
    return '(unknown)';
  }

  static void _write(String line) {
    // ignore: avoid_print
    print(line);
  }
}
