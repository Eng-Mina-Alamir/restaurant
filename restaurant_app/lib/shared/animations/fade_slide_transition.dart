import 'dart:async';
import 'package:flutter/material.dart';

/// Smooth entry animation combining subtle slide and opacity fade.
class FadeSlideTransitionWidget extends StatefulWidget {
  const FadeSlideTransitionWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.offset = const Offset(0.0, 0.1),
    this.curve = Curves.easeOutCubic,
    this.onComplete,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset offset;
  final Curve curve;
  final VoidCallback? onComplete;

  @override
  State<FadeSlideTransitionWidget> createState() =>
      _FadeSlideTransitionWidgetState();
}

class _FadeSlideTransitionWidgetState extends State<FadeSlideTransitionWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward().then((_) {
        if (mounted) widget.onComplete?.call();
      });
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) {
          _controller.forward().then((_) {
            if (mounted) widget.onComplete?.call();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
