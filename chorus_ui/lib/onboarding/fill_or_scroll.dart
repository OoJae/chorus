/// A column that fills the screen when it fits and scrolls when it does not.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays [children] out top to bottom, at least as tall as the room it is
/// given, so an `Expanded` or a `Spacer` among them can push what follows
/// into the thumb zone. When they need more room than there is (a short
/// phone, a large text size) the column scrolls instead of clipping.
///
/// Every child must be able to say how tall it wants to be: wrap one that
/// cannot, such as a widget built by a `LayoutBuilder`, in an
/// [IntrinsicFloor].
class FillOrScroll extends StatelessWidget {
  const FillOrScroll({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;

  /// Space round the column, inside the scrolling area.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final room = box.maxHeight.isFinite
            ? math.max(0.0, box.maxHeight - padding.vertical)
            : 0.0;
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: room),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Tells a [FillOrScroll] that [child] needs at least [minHeight] and will
/// take whatever it is given above that, without asking the child, which
/// may not be able to answer (a `LayoutBuilder` cannot).
class IntrinsicFloor extends SingleChildRenderObjectWidget {
  const IntrinsicFloor({super.key, required this.minHeight, super.child});

  final double minHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderIntrinsicFloor(minHeight);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderIntrinsicFloor).minHeight = minHeight;
  }
}

class _RenderIntrinsicFloor extends RenderProxyBox {
  _RenderIntrinsicFloor(this._minHeight);

  double _minHeight;

  set minHeight(double value) {
    if (value == _minHeight) return;
    _minHeight = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicHeight(double width) => _minHeight;

  @override
  double computeMaxIntrinsicHeight(double width) => _minHeight;

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    Size(constraints.hasBoundedWidth ? constraints.maxWidth : 0, _minHeight),
  );
}
