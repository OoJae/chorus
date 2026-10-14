/// Picture scenes: a family photo with spots that speak when tapped.
///
/// Every position is a fraction of the photo (0 at its left or top edge, 1
/// at its right or bottom edge), so a spot stays on the same part of the
/// picture whatever size the screen draws it. The app, the server and the
/// tests share these rules.
library;

import 'tile_text.dart';

/// Longest scene name, in characters.
const int maxSceneNameLength = 30;

/// Most spots one scene may have.
const int maxSpotsPerScene = 24;

/// Smallest side of a spot, as a fraction of the photo's side: about a
/// fingertip on a phone held on its side.
const double minSpotSide = 0.05;

/// What is wrong with [name] as a scene name, in words for the adult, or
/// null when it can be used. Judged on [tidyText].
String? sceneNameProblem(String name) {
  final tidy = tidyText(name);
  if (tidy.isEmpty) return 'Give the scene a name.';
  if (tidy.runes.length > maxSceneNameLength) {
    return 'Keep the name to $maxSceneNameLength characters or fewer.';
  }
  return null;
}

/// A rectangle on a photo, in fractions of its width and height.
class SpotRect {
  const SpotRect(this.x, this.y, this.width, this.height);

  /// Left edge.
  final double x;

  /// Top edge.
  final double y;
  final double width;
  final double height;

  double get right => x + width;
  double get bottom => y + height;
  double get area => width * height;

  /// True when the point ([px], [py]) is inside, edges included (with a
  /// rounding slack).
  bool contains(double px, double py) {
    const slack = 1e-9;
    return px >= x - slack &&
        px <= right + slack &&
        py >= y - slack &&
        py <= bottom + slack;
  }

  /// True when every edge is on the photo and each side is at least
  /// [minSpotSide]. A small rounding slack is allowed at the edges.
  bool get isValid {
    const slack = 1e-6;
    final finite = [x, y, width, height].every((v) => v.isFinite);
    return finite &&
        x >= -slack &&
        y >= -slack &&
        right <= 1 + slack &&
        bottom <= 1 + slack &&
        width >= minSpotSide - slack &&
        height >= minSpotSide - slack;
  }

  /// The rectangle a drag from ([x0], [y0]) to ([x1], [y1]) draws, in either
  /// direction, kept on the photo and at least [minSpotSide] on each side.
  /// Where the drag was too short the spot grows away from the start,
  /// towards where the finger went, and turns back at the photo's edge.
  static SpotRect fromDrag(double x0, double y0, double x1, double y1) {
    final (left, w) = _span(_unit(x0), _unit(x1));
    final (top, h) = _span(_unit(y0), _unit(y1));
    return SpotRect(left, top, w, h);
  }

  /// This rectangle moved by ([dx], [dy]), stopped at the photo's edges.
  /// Its size never changes.
  SpotRect moved(double dx, double dy) => SpotRect(
    (x + dx).clamp(0.0, 1.0 - width),
    (y + dy).clamp(0.0, 1.0 - height),
    width,
    height,
  );

  /// This rectangle with its bottom-right corner dragged by ([dx], [dy]):
  /// the top-left corner stays, the photo's edges and [minSpotSide] stop
  /// it.
  SpotRect resized(double dx, double dy) => SpotRect(
    x,
    y,
    (width + dx).clamp(minSpotSide, 1.0 - x),
    (height + dy).clamp(minSpotSide, 1.0 - y),
  );

  /// The nearest rectangle that [isValid]: shrunk to the photo, grown to
  /// [minSpotSide], then moved back onto the photo.
  SpotRect clamped() {
    double fix(double v) => v.isFinite ? v : 0;
    final w = fix(width).clamp(minSpotSide, 1.0);
    final h = fix(height).clamp(minSpotSide, 1.0);
    return SpotRect(
      fix(x).clamp(0.0, 1.0 - w),
      fix(y).clamp(0.0, 1.0 - h),
      w,
      h,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SpotRect &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() =>
      'SpotRect(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}, '
      '${width.toStringAsFixed(3)} x ${height.toStringAsFixed(3)})';
}

double _unit(double v) => v.isFinite ? v.clamp(0.0, 1.0) : 0.0;

/// The start and length of a span from [a] to [b] on 0..1, at least
/// [minSpotSide] long.
(double, double) _span(double a, double b) {
  final low = a < b ? a : b;
  final length = (a - b).abs();
  if (length >= minSpotSide) return (low, length);
  // Too short: grow from the start towards the finger (forwards by
  // default), turning back at the far edge.
  final forwards = b >= a;
  var start = forwards ? a : a - minSpotSide;
  if (start < 0) start = 0;
  if (start + minSpotSide > 1) start = 1 - minSpotSide;
  return (start, minSpotSide);
}

/// The index in [spots] of the spot under the point ([px], [py]), or null
/// when there is none. Where spots overlap, the smallest wins, so a face
/// drawn inside a whole person can still be tapped; among equal sizes the
/// one drawn last (on top) wins.
int? spotAt(List<SpotRect> spots, double px, double py) {
  int? best;
  for (var i = 0; i < spots.length; i++) {
    final spot = spots[i];
    if (!spot.contains(px, py)) continue;
    if (best == null || spot.area <= spots[best].area) best = i;
  }
  return best;
}

/// Where a photo of [imageWidth] x [imageHeight] is drawn when it is fitted
/// whole and centred in a box of [boxWidth] x [boxHeight]: its left, top,
/// width and height in the box's units.
({double left, double top, double width, double height}) fitPhoto({
  required double boxWidth,
  required double boxHeight,
  required double imageWidth,
  required double imageHeight,
}) {
  if (boxWidth <= 0 || boxHeight <= 0 || imageWidth <= 0 || imageHeight <= 0) {
    return (left: 0, top: 0, width: 0, height: 0);
  }
  final scale = (boxWidth / imageWidth) < (boxHeight / imageHeight)
      ? boxWidth / imageWidth
      : boxHeight / imageHeight;
  final width = imageWidth * scale;
  final height = imageHeight * scale;
  return (
    left: (boxWidth - width) / 2,
    top: (boxHeight - height) / 2,
    width: width,
    height: height,
  );
}

/// What is wrong with a spot's [label] and [speech], in words for the
/// adult, or null when they can be used. Judged on [tidyText].
String? spotWordProblem(String label, {String? speech}) {
  final tidy = tidyText(label);
  if (tidy.isEmpty) return 'Type the word this spot says.';
  if (tidy.runes.length > maxTileLabelLength) {
    return 'Keep the word to $maxTileLabelLength characters or fewer.';
  }
  if (speech != null && tidyText(speech).runes.length > maxTileSpeechLength) {
    return 'Keep what it says to $maxTileSpeechLength characters or fewer.';
  }
  return null;
}
