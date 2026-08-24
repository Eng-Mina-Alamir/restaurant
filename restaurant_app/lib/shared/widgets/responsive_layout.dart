import 'package:flutter/material.dart';

/// Screen type categorization for responsive UI.
enum ScreenType { mobile, tablet, desktop }

/// Breakpoints standard used across the restaurant application.
abstract final class AppBreakpoints {
  AppBreakpoints._();

  static const double mobileMax = 600.0;
  static const double tabletMax = 1024.0;

  static ScreenType of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileMax) return ScreenType.mobile;
    if (width <= tabletMax) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      of(context) == ScreenType.mobile;

  static bool isTablet(BuildContext context) =>
      of(context) == ScreenType.tablet;

  static bool isDesktop(BuildContext context) =>
      of(context) == ScreenType.desktop;

  static bool isTabletOrDesktop(BuildContext context) =>
      of(context) != ScreenType.mobile;

  /// Optimal column count for grid views based on screen width.
  static int gridColumnsForWidth(
    double width, {
    int minColumns = 2,
    int maxColumns = 6,
  }) {
    if (width < 600) return minColumns;
    if (width < 900) return (minColumns + 1).clamp(minColumns, maxColumns);
    if (width < 1200) return (minColumns + 2).clamp(minColumns, maxColumns);
    return (minColumns + 3).clamp(minColumns, maxColumns);
  }
}

/// A widget that switches between [mobile], [tablet], and [desktop] layouts.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width > AppBreakpoints.tabletMax && desktop != null) {
          return desktop!;
        }
        if (width >= AppBreakpoints.mobileMax && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}

/// A builder providing the current [ScreenType] and [BoxConstraints].
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    ScreenType screenType,
    BoxConstraints constraints,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = constraints.maxWidth > AppBreakpoints.tabletMax
            ? ScreenType.desktop
            : constraints.maxWidth >= AppBreakpoints.mobileMax
            ? ScreenType.tablet
            : ScreenType.mobile;
        return builder(context, screenType, constraints);
      },
    );
  }
}
