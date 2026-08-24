import 'package:flutter/material.dart';

/// Premium interactive card that gently scales down on press with spring physics,
/// providing tactile and responsive touch feedback while maintaining Material [Card] compatibility.
class AnimatedPressCard extends StatefulWidget {
  const AnimatedPressCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.97,
    this.duration = const Duration(milliseconds: 120),
    this.borderRadius = 16.0,
    this.elevation = 0.0,
    this.pressedElevation = 2.0,
    this.color,
    this.border,
    this.clipBehavior = Clip.antiAlias,
    this.padding,
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final Duration duration;
  final double borderRadius;
  final double elevation;
  final double pressedElevation;
  final Color? color;
  final BoxBorder? border;
  final Clip clipBehavior;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  State<AnimatedPressCard> createState() => _AnimatedPressCardState();
}

class _AnimatedPressCardState extends State<AnimatedPressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      _controller.reverse().then((_) {
        if (mounted) setState(() => _isPressed = false);
      });
      widget.onTap!();
    } else {
      _resetPress();
    }
  }

  void _handleTapCancel() {
    _resetPress();
  }

  void _resetPress() {
    if (_isPressed) {
      _controller.reverse().then((_) {
        if (mounted) setState(() => _isPressed = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderSide = widget.border is Border
        ? (widget.border as Border).top
        : BorderSide.none;

    final cardWidget = Card(
      margin: widget.margin ?? EdgeInsets.zero,
      clipBehavior: widget.clipBehavior,
      color: widget.color,
      elevation: _isPressed ? widget.pressedElevation : widget.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        side: borderSide,
      ),
      child: Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: widget.child,
      ),
    );

    if (MediaQuery.disableAnimationsOf(context)) {
      return InkWell(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: cardWidget,
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: cardWidget,
      ),
    );
  }
}
