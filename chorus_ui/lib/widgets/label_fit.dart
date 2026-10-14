/// One label size for a whole board, and where a tile puts its label and
/// its picture.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../brand/tokens.dart';

/// The smallest size a board's labels are set in. A label too long for its
/// tile even at this size is scaled down on its own tile.
const double minTileLabelSize = 14;

/// The largest size a board's labels are set in.
const double maxTileLabelSize = 32;

/// Weight of every tile label: [ChorusType.tileLabel]'s.
const FontWeight tileLabelWeight = FontWeight.w700;

/// Between a picture and its label.
const double tilePictureGap = 2;

/// Of a tile's content height, the most a label under a picture may take
/// at the usual text size: the picture keeps the rest.
const double pictureLabelShare = 0.4;

/// The share of a tile's content height a label under a picture may take
/// for a reader whose text is [scaler] larger: up to 0.6 at twice the
/// size, so large text makes labels larger and pictures smaller rather than
/// leaving the labels as they were.
double pictureLabelShareFor(TextScaler scaler) =>
    (pictureLabelShare * scaler.scale(minTileLabelSize) / minTileLabelSize)
        .clamp(pictureLabelShare, 0.6)
        .toDouble();

/// Kept clear beside a label, on each side, so rounding never makes it
/// touch the face's edge.
const double _slack = 1;

/// Space between a tile's face and what is on it, on each side: a little
/// more on a large tile than on a phone's.
double tilePaddingFor(Size tile) =>
    (tile.shortestSide * 0.07).clamp(3.0, 8.0).toDouble();

/// How a tile with a picture arranges it: above the label on an upright or
/// square tile, beside it on a wide one (a phone on its side, a desktop).
enum TilePictureLayout { above, beside }

/// Where everything on one tile goes. A tile of outer size [tile] has its
/// laminated edge along the bottom, then [padding] round its content.
///
/// `TileLabelSizer` sizes labels with it, and `TileView` lays out with it,
/// so a label is drawn in the box it was measured for.
@immutable
class TileLayout {
  factory TileLayout(
    Size tile, {
    required bool picture,
    double labelShare = pictureLabelShare,
  }) {
    final padding = tilePaddingFor(tile);
    final content = Size(
      math.max(0, tile.width - 2 * padding),
      math.max(0, tile.height - ChorusSpace.edge - 2 * padding),
    );
    // Too small to show a picture usefully: the label alone.
    final roomForPicture = content.shortestSide >= 20;
    return TileLayout._(
      padding,
      content,
      labelShare,
      picture && roomForPicture
          ? (content.width >= 1.6 * content.height
                ? TilePictureLayout.beside
                : TilePictureLayout.above)
          : null,
    );
  }

  const TileLayout._(
    this.padding,
    this.content,
    this.labelShare,
    this.pictureLayout,
  );

  /// Round the content, on each side.
  final double padding;

  /// Inside the padding, above the edge.
  final Size content;

  /// Of the content height, the most a label under a picture may take.
  final double labelShare;

  /// How the picture sits, or null when the tile shows its label alone.
  final TilePictureLayout? pictureLayout;

  /// The side of the square the picture is drawn in, on a [beside] tile.
  double get besideSide => math.min(content.height, content.width * 0.5);

  /// The box the label must fit in.
  Size get labelBox => switch (pictureLayout) {
    null => Size(math.max(0, content.width - 2 * _slack), content.height),
    TilePictureLayout.above => Size(
      math.max(0, content.width - 2 * _slack),
      math.max(0, (content.height - tilePictureGap) * labelShare),
    ),
    TilePictureLayout.beside => Size(
      math.max(0, content.width - besideSide - tilePictureGap - 2 * _slack),
      content.height,
    ),
  };
}

/// Works out the one font size shared by every tile of a board: the largest
/// at which the board's widest label still fits a tile on one line, between
/// [minTileLabelSize] and [maxTileLabelSize].
///
/// Labels are measured in [ChorusType.tileLabel], the style `TileView`
/// paints them in. On a board where any tile has a picture ([pictures]),
/// every label is sized for the room beside or under a picture, so a word
/// with a picture and a word without one are the same size.
///
/// Keep one per grid. It measures text only when the labels or the text
/// scale change, and redoes the fit only when those, the tile size or
/// [pictures] change; every other build gets the remembered answer.
class TileLabelSizer {
  static const double _reference = 100;
  static const double _step = 0.5;

  Object? _labelsKey;
  String _widest = '';
  Size _widestAtReference = Size.zero;

  Object? _fitKey;
  double _size = maxTileLabelSize;

  /// How many times labels have been measured; for tests.
  @visibleForTesting
  int measurements = 0;

  /// The size for tiles of outer size [tile] carrying [labels].
  ///
  /// [style] is no longer read: labels are measured in
  /// [ChorusType.tileLabel], whatever the style around the grid. It stays so
  /// callers written before need no change.
  double sizeFor({
    required Iterable<String> labels,
    required Size tile,
    TextStyle? style,
    required TextScaler scaler,
    required TextDirection direction,
    bool pictures = false,
  }) {
    final list = labels.toList()..sort();
    final labelsKey = (list.join('\u0000'), scaler, direction);
    if (labelsKey != _labelsKey) {
      _labelsKey = labelsKey;
      _fitKey = null;
      _widest = '';
      _widestAtReference = Size.zero;
      for (final label in list.toSet()) {
        final size = _measure(label, _reference, scaler, direction);
        if (size.width > _widestAtReference.width) {
          _widest = label;
          _widestAtReference = size;
        }
      }
    }
    final fitKey = (tile.width, tile.height, pictures);
    if (fitKey == _fitKey) return _size;
    _fitKey = fitKey;

    if (_widestAtReference.width <= 0 || _widestAtReference.height <= 0) {
      return _size = maxTileLabelSize;
    }
    final box = TileLayout(
      tile,
      picture: pictures,
      labelShare: pictureLabelShareFor(scaler),
    ).labelBox;
    final ideal = math.min(
      box.width * _reference / _widestAtReference.width,
      box.height * _reference / _widestAtReference.height,
    );
    var size = (ideal / _step).floorToDouble() * _step;
    size = size.clamp(minTileLabelSize, maxTileLabelSize);
    // Letter spacing and a non-linear text scale do not grow with the font
    // size, so check the real thing and step down until it fits.
    while (size > minTileLabelSize) {
      final real = _measure(_widest, size, scaler, direction);
      if (real.width <= box.width && real.height <= box.height) break;
      size = math.max(minTileLabelSize, size - _step);
    }
    return _size = size;
  }

  Size _measure(
    String label,
    double fontSize,
    TextScaler scaler,
    TextDirection direction,
  ) {
    measurements++;
    final painter = TextPainter(
      text: TextSpan(text: label, style: ChorusType.tileLabel(fontSize)),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final size = painter.size;
    painter.dispose();
    return size;
  }
}
