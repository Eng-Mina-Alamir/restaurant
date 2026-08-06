import 'dart:async';

/// A lightweight, testable notification tracker for new orders.
///
/// Consumed by the KDS (and any role that needs a "new order" alert). It emits
/// a notification whenever [notifyNewOrder] is called and exposes how many
/// alerts have fired so the UI can show a badge. Real audio/OS notifications
/// are out of scope for the offline CLI build; this service is the seam where a
/// platform plugin would later be wired in.
class NewOrderNotifier {
  NewOrderNotifier();

  final StreamController<void> _stream = StreamController<void>.broadcast();
  int _alertCount = 0;

  /// A broadcast stream that closes each time a new order is announced.
  Stream<void> get stream => _stream.stream;

  /// Number of unacknowledged alerts ("new order") since the last [reset].
  int get alertCount => _alertCount;

  /// Announces a new order (e.g. waiter sent an order to the kitchen).
  void notifyNewOrder() {
    _alertCount++;
    if (!_stream.isClosed) {
      _stream.add(null);
    }
  }

  /// Clears the badge counter (e.g. KDS screen acknowledged the alerts).
  void reset() {
    _alertCount = 0;
  }

  /// Tears down the underlying stream controller.
  void dispose() {
    _stream.close();
  }
}
