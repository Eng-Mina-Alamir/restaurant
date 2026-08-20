import 'package:flutter/material.dart';

/// Smooth expandable accordion card with rotated chevron and animated size transition.
class AnimatedExpandableCard extends StatefulWidget {
  const AnimatedExpandableCard({
    super.key,
    required this.header,
    required this.expandedContent,
    this.initiallyExpanded = false,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = 16.0,
    this.color,
    this.border,
    this.onExpansionChanged,
  });

  final Widget header;
  final Widget expandedContent;
  final bool initiallyExpanded;
  final Duration duration;
  final Curve curve;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? color;
  final BoxBorder? border;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<AnimatedExpandableCard> createState() => _AnimatedExpandableCardState();
}

class _AnimatedExpandableCardState extends State<AnimatedExpandableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _chevronAnimation;
  late final Animation<double> _expandAnimation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: _isExpanded ? 1.0 : 0.0,
    );

    _chevronAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: widget.color ?? theme.cardTheme.color,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.border ??
            Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _toggleExpand,
            child: Padding(
              padding: widget.padding,
              child: Row(
                children: [
                  Expanded(child: widget.header),
                  RotationTransition(
                    turns: _chevronAnimation,
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Padding(
                padding: widget.padding,
                child: widget.expandedContent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
