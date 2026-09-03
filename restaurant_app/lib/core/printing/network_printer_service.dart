import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';

/// Service responsible for communicating directly with thermal receipt & KDS
/// printers across the local area network (Raw TCP Socket on Port 9100).
class NetworkPrinterService {
  const NetworkPrinterService();

  /// Default port for raw thermal ESC/POS printing across all major manufacturers.
  static const int defaultPort = 9100;
  static const Duration defaultTimeout = Duration(seconds: 4);

  /// Sends raw ESC/POS byte sequence directly to a network printer at [ipAddress].
  ///
  /// Returns `true` if bytes were successfully written and flushed to the printer socket.
  Future<bool> sendRawBytes({
    required String ipAddress,
    required List<int> bytes,
    int port = defaultPort,
    Duration timeout = defaultTimeout,
  }) async {
    if (kIsWeb) {
      AppLogger.info('NetworkPrinter: Raw TCP printing is not supported on web browser, skipped.');
      return false;
    }
    Socket? socket;
    try {
      AppLogger.info('NetworkPrinter: Connecting to printer at $ipAddress:$port...');
      socket = await Socket.connect(ipAddress, port, timeout: timeout);
      socket.add(Uint8List.fromList(bytes));
      await socket.flush();
      AppLogger.info('NetworkPrinter: Successfully sent ${bytes.length} bytes to $ipAddress:$port');
      return true;
    } catch (e, st) {
      AppLogger.warning(
        'NetworkPrinter: Failed to send print job to $ipAddress:$port - $e',
        error: e,
        stackTrace: st,
      );
      return false;
    } finally {
      try {
        await socket?.close();
        socket?.destroy();
      } catch (_) {}
    }
  }

  /// Pings a printer IP to verify network connectivity.
  Future<bool> testPrinterConnection(
    String ipAddress, {
    int port = defaultPort,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (kIsWeb) return false;
    try {
      final socket = await Socket.connect(ipAddress, port, timeout: timeout);
      await socket.close();
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final networkPrinterServiceProvider = Provider<NetworkPrinterService>((ref) {
  return const NetworkPrinterService();
});
