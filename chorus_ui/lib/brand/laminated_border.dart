/// The laminated edge for Material buttons, through the theme.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// A rounded shape whose bottom [edge] is drawn darker than its face, as a
/// laminated card's edge is. [sink] lowers the whole shape, face and edge,
/// from the top of its box.
///
/// A button's style uses [LaminatedBorder.new] at rest and
/// [LaminatedBorder.pressed] while pressed; the button's Material animates
/// between the two. The edge is [shade] laid over the face colour, so one
/// border suits a button of any colour.
@immutable
class LaminatedBorder extends OutlinedBorder {
  const LaminatedBorder({
    this.radius = ChorusSpace.buttonRadius,
    this.edge = ChorusSpace.edge,
    this.sink = 0,
    this.shade = laminatedEdgeShade,
    super.side,
  });

  /// Pressed: sunk onto a thinner edge.
  const LaminatedBorder.pressed({
    this.radius = ChorusSpace.buttonRadius,
    this.shade = laminatedEdgeShade,
    super.side,
  }) : edge = ChorusSpace.edgePressed,
       sink = ChorusSpace.pressSink;

  final double radius;
  final double edge;
  final double sink;
  final Color shade;

  RRect _outer(Rect rect) => RRect.fromLTRBR(
    rect.left,
    rect.top + sink,
    rect.right,
    rect.bottom,
    Radius.circular(radius),
  );

  RRect _face(Rect rect) => RRect.fromLTRBR(
    rect.left,
    rect.top + sink,
    rect.right,
    rect.bottom - edge,
    Radius.circular(radius),
  );

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(top: sink, bottom: edge);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_outer(rect));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_face(rect).deflate(side.strokeInset));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (edge > 0) {
      // The outer shape less the face: the band along the bottom.
      final band = Path()
        ..fillType = PathFillType.evenOdd
        ..addRRect(_outer(rect))
        ..addRRect(_face(rect));
      canvas.drawPath(band, Paint()..color = shade);
    }
    if (side.style == BorderStyle.none || side.width == 0) return;
    final outer = _outer(rect);
    canvas.drawDRRect(
      outer.inflate(side.strokeOutset),
      outer.deflate(side.strokeInset),
      Paint()..color = side.color,
    );
  }

  @override
  LaminatedBorder copyWith({
    BorderSide? side,
    double? radius,
    double? edge,
    double? sink,
    Color? shade,
  }) => LaminatedBorder(
    radius: radius ?? this.radius,
    edge: edge ?? this.edge,
    sink: sink ?? this.sink,
    shade: shade ?? this.shade,
    side: side ?? this.side,
  );

  @override
  ShapeBorder scale(double t) => LaminatedBorder(
    radius: radius * t,
    edge: edge * t,
    sink: sink * t,
    shade: shade,
    side: side.scale(t),
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is LaminatedBorder) return _lerp(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is LaminatedBorder) return _lerp(this, b, t);
    return super.lerpTo(b, t);
  }

  static LaminatedBorder _lerp(
    LaminatedBorder a,
    LaminatedBorder b,
    double t,
  ) => LaminatedBorder(
    radius: lerpDouble(a.radius, b.radius, t)!,
    edge: lerpDouble(a.edge, b.edge, t)!,
    sink: lerpDouble(a.sink, b.sink, t)!,
    shade: Color.lerp(a.shade, b.shade, t)!,
    side: BorderSide.lerp(a.side, b.side, t),
  );

  @override
  bool operator ==(Object other) =>
      other is LaminatedBorder &&
      other.radius == radius &&
      other.edge == edge &&
      other.sink == sink &&
      other.shade == shade &&
      other.side == side;

  @override
  int get hashCode => Object.hash(radius, edge, sink, shade, side);

  @override
  String toString() =>
      'LaminatedBorder(radius: $radius, edge: $edge, sink: $sink, $side)';
}
