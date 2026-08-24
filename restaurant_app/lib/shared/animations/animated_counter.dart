import 'package:flutter/material.dart';

/// Smooth numeric counting animation for KPI metrics, order amounts, and quantities.
class AnimatedCounter extends ImplicitlyAnimatedWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimalPlaces = 0,
    this.formatter,
    super.duration = const Duration(milliseconds: 600),
    super.curve = Curves.easeOutCubic,
  });

  final num value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimalPlaces;
  final String Function(num value)? formatter;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _AnimatedCounterState();
}

class _AnimatedCounterState extends AnimatedWidgetBaseState<AnimatedCounter> {
  Tween<num>? _counterTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _counterTween =
        visitor(
              _counterTween,
              widget.value,
              (dynamic value) => Tween<num>(begin: value as num),
            )
            as Tween<num>?;
  }

  @override
  Widget build(BuildContext context) {
    final animatedValue = _counterTween?.evaluate(animation) ?? widget.value;

    final formattedText = widget.formatter != null
        ? widget.formatter!(animatedValue)
        : widget.decimalPlaces > 0
        ? animatedValue.toStringAsFixed(widget.decimalPlaces)
        : animatedValue.toInt().toString();

    return Text(
      '${widget.prefix}$formattedText${widget.suffix}',
      style: widget.style,
    );
  }
}

/// Specialized price ticker that counts up currency values smoothly.
class AnimatedPriceTicker extends StatelessWidget {
  const AnimatedPriceTicker({
    super.key,
    required this.amount,
    this.currency = 'ر.س',
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
  });

  final double amount;
  final String currency;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedCounter(
      value: amount,
      style: style,
      decimalPlaces: 2,
      suffix: ' $currency',
      duration: duration,
      curve: curve,
    );
  }
}
