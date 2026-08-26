import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/utils/haptics.dart';

void main() {
  tearDown(() {
    AppHaptics.override = null;
  });

  group('guard behavior (no binding initialized)', () {
    // NOTE: must run before any TestWidgetsFlutterBinding is created in this
    // isolate — binding initialization is irreversible. This exercises the
    // synchronous-throw guard (platform channel accessed too early).
    test('helpers never throw when the platform channel is unavailable', () {
      expect(AppHaptics.selectionTap, returnsNormally);
      expect(AppHaptics.actionSuccess, returnsNormally);
      expect(AppHaptics.milestoneSuccess, returnsNormally);
    });
  });

  group('with test binding (async MissingPluginException path)', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('helpers swallow MissingPluginException from the real channel',
        () async {
      AppHaptics.selectionTap();
      AppHaptics.actionSuccess();
      AppHaptics.milestoneSuccess();
      // Let async channel errors surface; catchError must have swallowed
      // them or the zone would report an unhandled error here.
      await Future<void>.delayed(Duration.zero);
    });

    test('override hook receives the semantic type per call', () async {
      final seen = <AppHapticsType>[];
      AppHaptics.override = (type) async => seen.add(type);

      AppHaptics.selectionTap();
      AppHaptics.actionSuccess();
      AppHaptics.milestoneSuccess();

      expect(seen, <AppHapticsType>[
        AppHapticsType.selectionTap,
        AppHapticsType.actionSuccess,
        AppHapticsType.milestoneSuccess,
      ]);
    });

    test('override bypasses the platform channel entirely', () async {
      var calls = 0;
      AppHaptics.override = (type) async => calls++;

      AppHaptics.milestoneSuccess();
      await Future<void>.delayed(Duration.zero);

      expect(calls, 1);
    });

    test('errors thrown by the override future are swallowed', () async {
      AppHaptics.override =
          (type) => Future<void>.error(StateError('stub failure'));

      expect(AppHaptics.actionSuccess, returnsNormally);
      await Future<void>.delayed(Duration.zero);
    });
  });

  group('AppHapticsType', () {
    test('exposes exactly the three semantic levels', () {
      expect(AppHapticsType.values, hasLength(3));
      expect(
        AppHapticsType.values.map((t) => t.name),
        ['selectionTap', 'actionSuccess', 'milestoneSuccess'],
      );
    });
  });
}
