/// The brand: the mark, the wordmark and the lockup of the two.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// One tile of the mark, placed in a box.
@immutable
class MarkTile {
  const MarkTile({
    required this.family,
    required this.outer,
    required this.edge,
  });

  final TileFamily family;

  /// The whole tile, edge included.
  final Rect outer;

  /// How much of [outer]'s bottom is edge.
  final double edge;

  /// The face, above the edge.
  Rect get face =>
      Rect.fromLTRB(outer.left, outer.top, outer.right, outer.bottom - edge);
}

/// Where the mark's four tiles sit: shared by [ChorusMark] and the launch
/// reveal, which starts from it.
///
/// The same drawing as `docs/brand/mark.svg`, from which every app icon,
/// the splash and the web loader are rendered, so the mark does not change
/// shape between the system splash and the app's first frame.
abstract final class MarkGeometry {
  // In units of a tile's width (25 of the SVG's 64). The gaps are wide so
  // the mark still reads at 29 pt on a busy home screen.
  static const double _gap = 0.32;
  static const double _edge = 0.12;
  static const double _raise = 0.12;
  // The SVG's square, with its margin round the tiles.
  static const double _side = 2.56;

  /// The corner radius of a tile [tileWidth] wide.
  static double radiusFor(double tileWidth) => tileWidth * 0.24;

  /// The four tiles, in the largest square that fits in [box] and centred:
  /// action, person, describe and question, left to right and top to
  /// bottom. The top-left tile sits a little higher, as a card does before
  /// it is pressed onto the Velcro.
  static List<MarkTile> tilesIn(Rect box) {
    final unit = box.shortestSide / _side;
    final left = box.center.dx - unit * (2 + _gap) / 2;
    final top = box.center.dy - unit * (_raise + 2 + _gap) / 2;
    final rowTop = top + _raise * unit;
    final step = (1 + _gap) * unit;
    Rect at(int row, int col) =>
        Rect.fromLTWH(left + col * step, rowTop + row * step, unit, unit);
    return [
      MarkTile(
        family: TileFamily.action,
        outer: at(0, 0).translate(0, -_raise * unit),
        edge: _edge * unit,
      ),
      MarkTile(family: TileFamily.person, outer: at(0, 1), edge: _edge * unit),
      MarkTile(
        family: TileFamily.describe,
        outer: at(1, 0),
        edge: _edge * unit,
      ),
      MarkTile(
        family: TileFamily.question,
        outer: at(1, 1),
        edge: _edge * unit,
      ),
    ];
  }

  /// Paints one laminated tile: the edge, then the face over it.
  static void paintTile(
    Canvas canvas, {
    required Rect outer,
    required double edge,
    required double radius,
    required Color fill,
    required Color edgeColor,
  }) {
    final corner = Radius.circular(radius);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, corner),
      Paint()..color = edgeColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(outer.left, outer.top, outer.right, outer.bottom - edge),
        corner,
      ),
      Paint()..color = fill,
    );
  }
}

/// The mark: four laminated tiles in the colour key, drawn at any [size].
///
/// Decorative unless given a [semanticLabel].
class ChorusMark extends StatelessWidget {
  const ChorusMark({
    super.key,
    this.size = 48,
    this.brightness,
    this.semanticLabel,
  });

  final double size;

  /// Which tile colours to use. Null follows the theme.
  final Brightness? brightness;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(brightness ?? Theme.of(context).brightness),
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: mark);
    return Semantics(image: true, label: label, child: mark);
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.brightness);

  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    for (final tile in MarkGeometry.tilesIn(Offset.zero & size)) {
      final colors = tile.family.colorsFor(brightness);
      MarkGeometry.paintTile(
        canvas,
        outer: tile.outer,
        edge: tile.edge,
        radius: MarkGeometry.radiusFor(tile.outer.width),
        fill: colors.fill,
        edgeColor: colors.edge,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      oldDelegate.brightness != brightness;
}

/// "chorus", lowercase, in Fraunces at [size]. It grows with the reader's
/// text scale up to the display cap.
class ChorusWordmark extends StatelessWidget {
  const ChorusWordmark({super.key, this.size = 32, this.color});

  final double size;

  /// Null is ink.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'chorus',
      semanticsLabel: 'Chorus',
      maxLines: 1,
      softWrap: false,
      textScaler: ChorusType.displayScaler(context),
      style: ChorusType.wordmark(
        size,
      ).copyWith(color: color ?? ChorusColors.of(context).ink),
    );
  }
}

/// The mark to the left of the wordmark, read as one word: "Chorus".
class ChorusLockup extends StatelessWidget {
  const ChorusLockup({super.key, this.size = 32, this.color});

  /// The wordmark's size; the mark matches its height.
  final double size;

  /// The wordmark's colour. Null is ink.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scaled = ChorusType.displayScaler(context).scale(size);
    return Semantics(
      label: 'Chorus',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChorusMark(size: scaled * 1.1),
          SizedBox(width: scaled * 0.32),
          ChorusWordmark(size: size, color: color),
        ],
      ),
    );
  }
}
