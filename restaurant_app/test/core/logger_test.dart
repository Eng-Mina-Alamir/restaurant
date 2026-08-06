import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_app/core/utils/logger.dart';

void main() {
  test('logger prefixes output with caller file:line', () {
    final lines = <String>[];
    final originalWrite = AppLogger.enabled;
    AppLogger.enabled = true;

    // Capture print output by overriding Zone print.
    runZoned(
      () {
        AppLogger.info('hello from test');
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => lines.add(line),
      ),
    );

    AppLogger.enabled = originalWrite;
    expect(lines, isNotEmpty);
    expect(lines.first, contains('logger_test.dart:'));
    expect(lines.first, contains('[INFO]'));
    expect(lines.first, contains('hello from test'));
  });

  test('logger disabled emits nothing', () {
    final lines = <String>[];
    final originalEnabled = AppLogger.enabled;
    AppLogger.enabled = false;

    runZoned(
      () {
        AppLogger.info('should be silent');
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => lines.add(line),
      ),
    );

    AppLogger.enabled = originalEnabled;
    expect(lines, isEmpty);
  });
}
