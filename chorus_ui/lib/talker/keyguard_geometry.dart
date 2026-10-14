/// Where the child's grid sits in keyguard mode, worked out from the screen
/// alone, and the same grid in real millimetres for making a keyguard.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../brand/tokens.dart';
import 'talker_tabs.dart';

/// The arrangements the child's screen has (see `TalkerLayout`), as the
/// keyguard reads them.
enum KeyguardLayout { roomy, narrow, short }

/// Round the whole talker screen, inside the safe area.
const double keyguardEdge = 6;

/// Width of the board tabs' column beside the grid, on a phone on its side.
const double keyguardSideTabs = 92;

/// The grid of a board in keyguard mode: one fixed place on the screen and
/// one fixed size for every cell, whatever the board is showing.
///
/// Everything above the grid has a fixed height in keyguard mode (the strip
/// and its buttons, the status row, and a row kept for board tabs whether
/// or not there are any), and nothing is ever drawn between them and the
/// grid, so the grid starts at the same place every time.
class KeyguardGeometry {
  const KeyguardGeometry({
    required this.grid,
    required this.rows,
    required this.cols,
    required this.gap,
  });

  /// Works out the grid for a talker [body] (the screen inside its safe
  /// area) arranged as [layout].
  factory KeyguardGeometry.of({
    required Size body,
    required KeyguardLayout layout,
    required int rows,
    required int cols,
  }) {
    const rowGap = ChorusSpace.targetGap;
    const tabs = TalkerBoardTabs.height;
    final double top;
    var left = keyguardEdge;
    switch (layout) {
      case KeyguardLayout.roomy:
        // Strip, status, tabs, each followed by a gap.
        top = keyguardEdge + 72 + rowGap + 52 + rowGap + tabs + rowGap;
      case KeyguardLayout.narrow:
        // Strip, buttons, status, tabs.
        top =
            keyguardEdge +
            64 +
            rowGap +
            52 +
            rowGap +
            ChorusSpace.minTarget +
            rowGap +
            tabs +
            rowGap;
      case KeyguardLayout.short:
        top = keyguardEdge + 52 + 4;
        left = keyguardEdge + keyguardSideTabs + 4;
    }
    final width = math.max(0.0, body.width - keyguardEdge - left);
    final height = math.max(0.0, body.height - keyguardEdge - top);
    return KeyguardGeometry(
      grid: Rect.fromLTWH(left, top, width, height),
      rows: rows,
      cols: cols,
      gap: layout == KeyguardLayout.short ? 3 : 4,
    );
  }

  /// The grid's area, cells and the gaps round them included.
  final Rect grid;
  final int rows;
  final int cols;

  /// Space round each cell.
  final double gap;

  /// The tile at [row], [col]: its cell less the gap round it.
  Rect cell(int row, int col) {
    final w = grid.width / cols;
    final h = grid.height / rows;
    return Rect.fromLTWH(
      grid.left + col * w + gap,
      grid.top + row * h + gap,
      math.max(0, w - 2 * gap),
      math.max(0, h - 2 * gap),
    );
  }

  /// Every tile, row by row.
  List<Rect> get cells => [
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++) cell(row, col),
  ];

  /// The same grid moved by [offset] (from the body to the whole screen).
  KeyguardGeometry shift(Offset offset) => KeyguardGeometry(
    grid: grid.shift(offset),
    rows: rows,
    cols: cols,
    gap: gap,
  );
}

/// Millimetres per logical pixel on a screen of [screen] logical pixels
/// whose diagonal is [diagonalInches]. Null when either is not usable.
double? millimetresPerPixel(Size screen, double diagonalInches) {
  final pixels = math.sqrt(
    screen.width * screen.width + screen.height * screen.height,
  );
  if (pixels <= 0 || !diagonalInches.isFinite || diagonalInches <= 0) {
    return null;
  }
  return diagonalInches * 25.4 / pixels;
}

/// An SVG of the screen's outline and each tile's hole, in real
/// millimetres, for cutting or ordering a keyguard. [geometry] is in the
/// whole screen's logical pixels.
String keyguardSvg({
  required Size screen,
  required KeyguardGeometry geometry,
  required double mmPerPixel,
}) {
  String mm(double value) => (value * mmPerPixel).toStringAsFixed(2);
  final out = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'width="${mm(screen.width)}mm" height="${mm(screen.height)}mm" '
      'viewBox="0 0 ${mm(screen.width)} ${mm(screen.height)}">',
    )
    ..writeln(
      '<title>Chorus keyguard: ${geometry.rows} rows by ${geometry.cols} '
      'columns</title>',
    )
    ..writeln(
      '<rect x="0" y="0" width="${mm(screen.width)}" '
      'height="${mm(screen.height)}" fill="none" stroke="#000" '
      'stroke-width="0.2"/>',
    );
  final radius = ChorusSpace.tileRadius;
  for (final rect in geometry.cells) {
    out.writeln(
      '<rect x="${mm(rect.left)}" y="${mm(rect.top)}" '
      'width="${mm(rect.width)}" height="${mm(rect.height)}" '
      'rx="${mm(radius)}" fill="none" stroke="#000" stroke-width="0.2"/>',
    );
  }
  out.writeln('</svg>');
  return out.toString();
}
