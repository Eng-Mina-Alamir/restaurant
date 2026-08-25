import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Helper builders for creating premium, smooth page transitions in GoRouter.
class AppPageTransitions {
  const AppPageTransitions._();

  /// Smooth fade and slide page transition.
  static CustomTransitionPage<T> fadeSlide<T>({
    required LocalKey key,
    required Widget child,
    Offset beginOffset = const Offset(0.05, 0.0),
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Respect the OS reduce-motion setting: show the page immediately at
        // full opacity with no slide offset.
        if (MediaQuery.disableAnimationsOf(context)) {
          return FadeTransition(
            opacity: const AlwaysStoppedAnimation<double>(1.0),
            child: child,
          );
        }

        final fadeAnim = CurvedAnimation(parent: animation, curve: curve);
        final slideAnim = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        return FadeTransition(
          opacity: fadeAnim,
          child: SlideTransition(position: slideAnim, child: child),
        );
      },
    );
  }

  /// Modern scale and fade page transition for dialogs or full modals.
  static CustomTransitionPage<T> scaleFade<T>({
    required LocalKey key,
    required Widget child,
    double beginScale = 0.94,
    Duration duration = const Duration(milliseconds: 280),
    Curve curve = Curves.easeOutCubic,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Respect the OS reduce-motion setting: show the page immediately at
        // full opacity with no scaling.
        if (MediaQuery.disableAnimationsOf(context)) {
          return FadeTransition(
            opacity: const AlwaysStoppedAnimation<double>(1.0),
            child: child,
          );
        }

        final fadeAnim = CurvedAnimation(parent: animation, curve: curve);
        final scaleAnim = Tween<double>(
          begin: beginScale,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        return FadeTransition(
          opacity: fadeAnim,
          child: ScaleTransition(scale: scaleAnim, child: child),
        );
      },
    );
  }

  /// Shared axis transition for tab-like and drill-down navigation.
  static CustomTransitionPage<T> sharedAxis<T>({
    required LocalKey key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 320),
    Curve curve = Curves.easeInOutCubic,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final inSlide = Tween<Offset>(
          begin: const Offset(0.1, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        final inFade = CurvedAnimation(parent: animation, curve: curve);

        return SlideTransition(
          position: inSlide,
          child: FadeTransition(opacity: inFade, child: child),
        );
      },
    );
  }
}
