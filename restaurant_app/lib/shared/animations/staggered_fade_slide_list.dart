import 'dart:async';
import 'package:flutter/material.dart';

/// Wraps individual children to animate them into view with a cascading/staggered delay.
class AnimatedListItem extends StatefulWidget {
  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.initialDelay = Duration.zero,
    this.staggerDuration = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.offset = const Offset(0.0, 0.15),
    this.curve = Curves.easeOutCubic,
  });

  final int index;
  final Widget child;
  final Duration initialDelay;
  final Duration staggerDuration;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
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

    final totalDelay =
        widget.initialDelay + (widget.staggerDuration * widget.index);

    if (totalDelay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(totalDelay, () {
        if (mounted) _controller.forward();
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

/// A convenience builder for staggered lists of items.
class StaggeredFadeSlideList extends StatelessWidget {
  const StaggeredFadeSlideList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.shrinkWrap = false,
    this.physics,
    this.initialDelay = Duration.zero,
    this.staggerDuration = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 400),
    this.offset = const Offset(0.0, 0.15),
    this.curve = Curves.easeOutCubic,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Duration initialDelay;
  final Duration staggerDuration;
  final Duration animationDuration;
  final Offset offset;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      scrollDirection: scrollDirection,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          initialDelay: initialDelay,
          staggerDuration: staggerDuration,
          duration: animationDuration,
          offset: offset,
          curve: curve,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}
