import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurant_app/core/theme/app_theme.dart';
import 'package:restaurant_app/core/theme/spacing.dart';

/// Builds both brightnesses through the public [AppTheme] entry points.
///
/// AppTextStyles resolves Cairo via google_fonts, whose loader rethrows fetch
/// failures into the zone; tests never bundle/download fonts, so construction
/// runs inside a guarded zone that swallows those loader errors only.
Map<Brightness, ThemeData> _buildThemes() {
  final themes = <Brightness, ThemeData>{};
  runZonedGuarded(
    () {
      themes[Brightness.light] = AppTheme.light;
      themes[Brightness.dark] = AppTheme.dark;
    },
    (error, stackTrace) {},
  );
  return themes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Never hit the network from tests.
  GoogleFonts.config.allowRuntimeFetching = false;

  final themes = _buildThemes();

  RoundedRectangleBorder roundedOf(Object? shape) => shape! as RoundedRectangleBorder;

  group('BadgeTheme', () {
    test('Aligns with AnimatedStatusBadge padding and brand colors', () {
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final badge = entry.value.badgeTheme;

        expect(
          badge.backgroundColor,
          scheme.primary,
          reason: '${entry.key}: badge background must follow primary',
        );
        expect(badge.textColor, scheme.onPrimary);
        expect(
          badge.padding,
          const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
          reason: '${entry.key}: must mirror AnimatedStatusBadge defaults',
        );
        expect(badge.textStyle, isNotNull);
        // Non-default placement (M3 defaults are topEnd + Offset(3, -3)).
        expect(badge.alignment, AlignmentDirectional.topStart);
        expect(badge.offset, const Offset(-AppSpacing.xs, AppSpacing.xs));
        expect(badge.offset, isNot(const Offset(3, -3)));
      }
    });
  });

  group('SegmentedButtonTheme', () {
    test('Resolves 48dp height, md corners and selected container styling',
        () {
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final style = entry.value.segmentedButtonTheme.style;

        expect(style, isNotNull);

        final minimumSize = style!.minimumSize!.resolve({});
        expect(minimumSize, isNotNull);
        expect(
          minimumSize!.height,
          48,
          reason: '${entry.key}: segments must be 48dp tall',
        );

        expect(
          roundedOf(style.shape!.resolve({})).borderRadius,
          BorderRadius.circular(AppRadius.md),
          reason: '${entry.key}: md corners',
        );

        expect(
          style.backgroundColor!.resolve({WidgetState.selected}),
          scheme.primaryContainer,
          reason: '${entry.key}: selected segment background',
        );
        expect(
          style.foregroundColor!.resolve({WidgetState.selected}),
          scheme.onPrimaryContainer,
          reason: '${entry.key}: selected segment foreground',
        );
        expect(style.side!.resolve({})?.color, scheme.outline);
        expect(style.textStyle!.resolve({}), isNotNull);
      }
    });
  });

  group('DatePickerTheme', () {
    test('Uses high surface, lg corners and themed header', () {
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final picker = entry.value.datePickerTheme;

        expect(picker.backgroundColor, scheme.surfaceContainerHigh);
        expect(picker.elevation, AppElevation.lg);
        expect(
          roundedOf(picker.shape).borderRadius,
          BorderRadius.circular(AppRadius.lg),
          reason: '${entry.key}: dialog corners',
        );
        expect(picker.headerBackgroundColor, scheme.primaryContainer);
        expect(picker.headerForegroundColor, scheme.onPrimaryContainer);
        expect(picker.headerHeadlineStyle, isNotNull);
        expect(picker.headerHelpStyle, isNotNull);
        expect(picker.weekdayStyle, isNotNull);
        expect(picker.dayStyle, isNotNull);
      }
    });
  });

  group('TimePickerTheme', () {
    test('Uses high surface, lg corners and brand dial', () {
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final picker = entry.value.timePickerTheme;

        expect(picker.backgroundColor, scheme.surfaceContainerHigh);
        expect(picker.elevation, AppElevation.lg);
        expect(
          roundedOf(picker.shape).borderRadius,
          BorderRadius.circular(AppRadius.lg),
          reason: '${entry.key}: dialog corners',
        );
        expect(picker.dialHandColor, scheme.primary);
        expect(picker.dialBackgroundColor, scheme.surfaceContainerHighest);
        // Plain colors are wrapped into a state-dependent resolver.
        final periodColor = picker.dayPeriodColor! as WidgetStateColor;
        expect(
          periodColor.resolve({WidgetState.selected}),
          scheme.primaryContainer,
        );
        expect(
          roundedOf(picker.hourMinuteShape).borderRadius,
          BorderRadius.circular(AppRadius.md),
        );
        expect(picker.hourMinuteTextStyle, isNotNull);
        expect(picker.helpTextStyle, isNotNull);
      }
    });
  });

  group('NavigationBarTheme', () {
    test('Indicates selection with secondaryContainer and themed labels', () {
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final bar = entry.value.navigationBarTheme;

        expect(
          bar.indicatorColor,
          scheme.secondaryContainer,
          reason: '${entry.key}: nav bar indicator',
        );
        expect(
          bar.labelTextStyle!.resolve({WidgetState.selected})?.color,
          scheme.onSecondaryContainer,
        );
        expect(bar.labelTextStyle!.resolve({})?.color, scheme.onSurfaceVariant);
        expect(
          bar.iconTheme!.resolve({WidgetState.selected})?.color,
          scheme.onSecondaryContainer,
        );
        expect(
          bar.labelBehavior,
          NavigationDestinationLabelBehavior.alwaysShow,
        );
      }
    });
  });

  group('NavigationRailTheme', () {
    test('Indicates selection with primaryContainer and themed labels', () {
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final rail = entry.value.navigationRailTheme;

        expect(
          rail.indicatorColor,
          scheme.primaryContainer,
          reason: '${entry.key}: nav rail indicator',
        );
        expect(rail.useIndicator, isTrue);
        expect(rail.selectedLabelTextStyle!.color, scheme.onPrimaryContainer);
        expect(rail.unselectedLabelTextStyle!.color, scheme.onSurfaceVariant);
        expect(rail.selectedIconTheme!.color, scheme.onPrimaryContainer);
        expect(rail.unselectedIconTheme!.color, scheme.onSurfaceVariant);
      }
    });
  });

  group('TooltipTheme', () {
    test('Decorates with sm corners on a high surface using bodyMedium text',
        () {
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final tooltip = entry.value.tooltipTheme;

        final decoration = tooltip.decoration! as BoxDecoration;
        expect(decoration.color, scheme.surfaceContainerHigh);
        expect(
          decoration.borderRadius,
          BorderRadius.circular(AppRadius.sm),
          reason: '${entry.key}: tooltip corners',
        );

        expect(tooltip.textStyle!.fontSize, 14, reason: 'bodyMedium size');
        expect(tooltip.textStyle!.color, scheme.onSurface);
      }
    });
  });

  group('PopupMenuTheme', () {
    test('Renders menus on high surfaces with md corners and md elevation',
        () {
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final popup = entry.value.popupMenuTheme;

        expect(popup.color, scheme.surfaceContainerHigh);
        expect(popup.elevation, AppElevation.md);
        expect(
          roundedOf(popup.shape).borderRadius,
          BorderRadius.circular(AppRadius.md),
          reason: '${entry.key}: menu corners',
        );
        expect(popup.textStyle, isNotNull);
      }
    });
  });

  group('DropdownMenuTheme', () {
    test('Styles the menu overlay like popup menus', () {
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final menuStyle = entry.value.dropdownMenuTheme.menuStyle!;

        expect(menuStyle.backgroundColor!.resolve({}),
            scheme.surfaceContainerHigh);
        expect(menuStyle.elevation!.resolve({}), AppElevation.md);
        expect(
          roundedOf(menuStyle.shape!.resolve({})).borderRadius,
          BorderRadius.circular(AppRadius.md),
          reason: '${entry.key}: menu corners',
        );
      }
    });
  });
}
