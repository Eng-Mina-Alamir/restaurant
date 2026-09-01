import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Snapshot-based language transition that captures the old screen as an image,
/// then cross-fades it out while the new locale's UI builds underneath.
///
/// This works even when [MaterialApp] fully rebuilds its widget tree on locale
/// change (RTL ↔ LTR), because the snapshot is a flat raster image that is
/// independent of the widget tree.
class RadialLanguageReveal extends StatefulWidget {
  const RadialLanguageReveal({
    super.key,
    required this.locale,
    required this.child,
    this.duration = const Duration(milliseconds: 420),
  });

  final Locale locale;
  final Widget child;
  final Duration duration;

  @override
  State<RadialLanguageReveal> createState() => _RadialLanguageRevealState();
}

class _RadialLanguageRevealState extends State<RadialLanguageReveal>
    with SingleTickerProviderStateMixin {
  final GlobalKey _repaintKey = GlobalKey();

  AnimationController? _controller;
  ui.Image? _snapshot;
  bool _isTransitioning = false;

  @override
  void didUpdateWidget(RadialLanguageReveal oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.locale.languageCode != widget.locale.languageCode) {
      _captureAndAnimate();
    }
  }

  /// Captures the current screen as a raster image, then starts the fade-out
  /// animation so the new locale UI is revealed smoothly underneath.
  Future<void> _captureAndAnimate() async {
    // Try to capture the current frame
    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;

    if (boundary != null && boundary.hasSize) {
      try {
        final image = await boundary.toImage(
          pixelRatio: MediaQuery.of(context).devicePixelRatio,
        );
        _snapshot = image;
      } catch (_) {
        // If capture fails, just let it rebuild without animation
        return;
      }
    } else {
      return;
    }

    // Dispose any previous controller
    _controller?.dispose();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    setState(() => _isTransitioning = true);

    _controller!.forward().then((_) {
      if (mounted) {
        setState(() {
          _isTransitioning = false;
          _snapshot?.dispose();
          _snapshot = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The live child (new locale UI) is always rendered underneath
          widget.child,

          // Overlay the old snapshot with a fade-out animation
          if (_isTransitioning && _snapshot != null && _controller != null)
            AnimatedBuilder(
              animation: _controller!,
              builder: (context, _) {
                return IgnorePointer(
                  child: Opacity(
                    opacity: 1.0 - CurvedAnimation(
                      parent: _controller!,
                      curve: Curves.easeInOutCubicEmphasized,
                    ).value,
                    child: RawImage(
                      image: _snapshot,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
