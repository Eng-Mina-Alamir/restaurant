import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Celebratory animated success checkmark with expanding particle ring and progressive path drawing.
class AnimatedSuccessCheckmark extends StatefulWidget {
  const AnimatedSuccessCheckmark({
    super.key,
    this.size = 80.0,
    this.color,
    this.duration = const Duration(milliseconds: 900),
    this.onComplete,
  });

  final double size;
  final Color? color;
  final Duration duration;
  final VoidCallback? onComplete;

  @override
  State<AnimatedSuccessCheckmark> createState() =>
      _AnimatedSuccessCheckmarkState();
}

class _AnimatedSuccessCheckmarkState extends State<AnimatedSuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleAnimation;
  late final Animation<double> _checkAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // 0.0 -> 0.4: Circle outline draws
    _circleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );

    // 0.4 -> 0.8: Checkmark stroke draws
    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.85, curve: Curves.easeOutBack),
    );

    // 0.0 -> 0.5: Scale bounce
    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0.0,
              end: 1.15,
            ).chain(CurveTween(curve: Curves.easeOutQuad)),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.15,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeInQuad)),
            weight: 40,
          ),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)),
        );

    // 0.3 -> 0.9: Ripple expansion
    _rippleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
    );

    _controller.forward().then((_) {
      if (mounted) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.primary;

    if (MediaQuery.disableAnimationsOf(context)) {
      return Icon(
        Icons.check_circle_rounded,
        size: widget.size,
        color: effectiveColor,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Celebratory outer ripple ring
            if (_rippleAnimation.value > 0.0 && _rippleAnimation.value < 1.0)
              Transform.scale(
                scale: 1.0 + (_rippleAnimation.value * 0.4),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: effectiveColor.withValues(
                        alpha: (1.0 - _rippleAnimation.value) * 0.4,
                      ),
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            // Scaled checkmark canvas
            Transform.scale(
              scale: _scaleAnimation.value,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CheckmarkPainter(
                  circleProgress: _circleAnimation.value,
                  checkProgress: _checkAnimation.value,
                  color: effectiveColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  const _CheckmarkPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.color,
  });

  final double circleProgress;
  final double checkProgress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4.0;

    // Fill subtle circle background
    if (circleProgress > 0) {
      final bgPaint = Paint()
        ..color = color.withValues(alpha: 0.12 * circleProgress)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, bgPaint);
    }

    // Draw circle stroke
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.0, size.width * 0.05)
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * circleProgress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      circlePaint,
    );

    // Draw checkmark stroke
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(3.5, size.width * 0.065)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final p1 = Offset(size.width * 0.28, size.height * 0.52);
      final p2 = Offset(size.width * 0.44, size.height * 0.68);
      final p3 = Offset(size.width * 0.72, size.height * 0.36);

      final path = Path();
      path.moveTo(p1.dx, p1.dy);

      if (checkProgress <= 0.45) {
        final t = checkProgress / 0.45;
        path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
      } else {
        path.lineTo(p2.dx, p2.dy);
        final t = (checkProgress - 0.45) / 0.55;
        path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.circleProgress != circleProgress ||
        oldDelegate.checkProgress != checkProgress ||
        oldDelegate.color != color;
  }
}
