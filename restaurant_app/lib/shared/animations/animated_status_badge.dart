import 'package:flutter/material.dart';

/// Animated status badge that morphs colors, text, and performs a micro-bounce
/// whenever the underlying status changes.
class AnimatedStatusBadge extends StatefulWidget {
  const AnimatedStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.fontSize = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
    this.borderRadius = 12.0,
    this.duration = const Duration(milliseconds: 350),
  });

  final String label;
  final Color color;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Duration duration;

  @override
  State<AnimatedStatusBadge> createState() => _AnimatedStatusBadgeState();
}

class _AnimatedStatusBadgeState extends State<AnimatedStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 50,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(covariant AnimatedStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label || oldWidget.color != widget.color) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: widget.fontSize + 2, color: widget.color),
              const SizedBox(width: 4),
            ],
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ScaleTransition(
      scale: _bounceAnimation,
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeInOutCubic,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              AnimatedSwitcher(
                duration: widget.duration,
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  widget.icon,
                  key: ValueKey('${widget.icon}_${widget.color}'),
                  size: widget.fontSize + 2,
                  color: widget.color,
                ),
              ),
              const SizedBox(width: 4),
            ],
            AnimatedDefaultTextStyle(
              duration: widget.duration,
              curve: Curves.easeInOutCubic,
              style: TextStyle(
                color: widget.color,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w600,
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}
