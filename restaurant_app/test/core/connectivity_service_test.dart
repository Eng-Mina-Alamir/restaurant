import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/network/connectivity_service.dart';

void main() {
  group('ConnectivityService', () {
    test('defaults to online and notifies status transitions', () async {
      final service = ConnectivityService();
      addTearDown(service.dispose);

      expect(service.isOnline, isTrue);
      expect(service.isOffline, isFalse);

      ConnectivityStatus? captured;
      final sub = service.onStatusChanged.listen((s) => captured = s);
      addTearDown(sub.cancel);

      service.goOffline();
      expect(service.isOffline, isTrue);
      expect(service.isOnline, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(captured, ConnectivityStatus.offline);

      service.goOnline();
      expect(service.isOnline, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(captured, ConnectivityStatus.online);
    });
  });
}
