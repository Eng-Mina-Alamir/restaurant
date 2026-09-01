import 'package:flutter/material.dart';

/// A smooth, high-performance directional transition widget for language and RTL/LTR flips.
///
/// When the [locale] changes, it gracefully fades and slides the newly-rendered layout
/// from the direction matching the target language:
/// - Switching to Arabic (RTL): gentle glide from the right + fade-in.
/// - Switching to English (LTR): gentle glide from the left + fade-in.
///
/// Crucially, this uses an [AnimationController] on the existing child subtree without
/// unmounting or duplicating the router's [Navigator], preventing any black screen flashes.
class DirectionalLanguageTransition extends StatefulWidget {
  const DirectionalLanguageTransition({
    super.key,
    required this.locale,
    required this.child,
    this.duration = const Duration(milliseconds: 260),
  });

  final Locale locale;
  final Widget child;
  final Duration duration;

  @override
  State<DirectionalLanguageTransition> createState() =>
      _DirectionalLanguageTransitionState();
}

class _DirectionalLanguageTransitionState
    extends State<DirectionalLanguageTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_controller);
  }

  @override
  void didUpdateWidget(DirectionalLanguageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale.languageCode != widget.locale.languageCode) {
      final isArabic = widget.locale.languageCode == 'ar';
      final startOffset =
          isArabic ? const Offset(0.025, 0.0) : const Offset(-0.025, 0.0);

      _slideAnimation = Tween<Offset>(
        begin: startOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _fadeAnimation = Tween<double>(
        begin: 0.35,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
