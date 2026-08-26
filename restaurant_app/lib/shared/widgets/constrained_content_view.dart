import 'package:flutter/material.dart';

import 'responsive_layout.dart';

/// Constrains wide list-style pages to a readable maximum width and centers
/// the content on tablets/desktops.
///
/// Card lists (staff, orders, invoices, inventory, ...) become hard to scan
/// when stretched edge-to-edge on wide screens. Wrap a page's body content in
/// this widget so it is capped at [maxWidth] (defaulting to
/// [AppBreakpoints.tabletMax]) and horizontally centered. On viewports
/// narrower than [maxWidth] the constraint never binds, so the child passes
/// through untouched at mobile sizes.
///
/// Note: text/legal pages intentionally use a narrower 720px reading measure;
/// this widget targets list pages whose cards need more room.
class ConstrainedContentView extends StatelessWidget {
  const ConstrainedContentView({
    super.key,
    this.maxWidth = AppBreakpoints.tabletMax,
    required this.child,
  });

  /// Maximum content width applied on wide screens.
  final double maxWidth;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
