/// One label size for a whole board.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The smallest size a board's labels are set in. A label too long for its
/// tile even at this size is scaled down on its own tile.
const double minTileLabelSize = 14;

/// The largest size a board's labels are set in.
const double maxTileLabelSize = 32;

/// Weight of every tile label.
const FontWeight tileLabelWeight = FontWeight.w700;

/// Space a tile keeps between its edge and its label, on each side.
const double tileLabelPadding = 6;

/// Kept clear inside the padding for the tile's border, on each side.
const double _borderSlack = 2;

/// Works out the one font size shared by every tile of a board: the largest
/// at which the board's widest label still fits a tile on one line, between
/// [minTileLabelSize] and [maxTileLabelSize].
///
/// Keep one per grid. It measures text only when the labels, the text style
/// or the text scale change, and redoes the fit only when those or the tile
/// size change; every other build gets the remembered answer.
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
  /// [style] is the text style the labels inherit; its size and weight are
  /// replaced here.
  double sizeFor({
    required Iterable<String> labels,
    required Size tile,
    required TextStyle style,
    required TextScaler scaler,
    required TextDirection direction,
  }) {
    final list = labels.toList()..sort();
    final labelsKey = (
      list.join('\u0000'),
      style.fontFamily,
      style.letterSpacing,
      scaler,
      direction,
    );
    if (labelsKey != _labelsKey) {
      _labelsKey = labelsKey;
      _fitKey = null;
      _widest = '';
      _widestAtReference = Size.zero;
      for (final label in list.toSet()) {
        final size = _measure(label, _reference, style, scaler, direction);
        if (size.width > _widestAtReference.width) {
          _widest = label;
          _widestAtReference = size;
        }
      }
    }
    final fitKey = (tile.width, tile.height);
    if (fitKey == _fitKey) return _size;
    _fitKey = fitKey;

    if (_widestAtReference.width <= 0 || _widestAtReference.height <= 0) {
      return _size = maxTileLabelSize;
    }
    final inset = 2 * (tileLabelPadding + _borderSlack);
    final width = math.max(0, tile.width - inset);
    final height = math.max(0, tile.height - inset);
    final ideal = math.min(
      width * _reference / _widestAtReference.width,
      height * _reference / _widestAtReference.height,
    );
    var size = (ideal / _step).floorToDouble() * _step;
    size = size.clamp(minTileLabelSize, maxTileLabelSize);
    // Letter spacing and a non-linear text scale do not grow with the font
    // size, so check the real thing and step down until it fits.
    while (size > minTileLabelSize) {
      final real = _measure(_widest, size, style, scaler, direction);
      if (real.width <= width && real.height <= height) break;
      size = math.max(minTileLabelSize, size - _step);
    }
    return _size = size;
  }

  Size _measure(
    String label,
    double fontSize,
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    measurements++;
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: style.copyWith(fontSize: fontSize, fontWeight: tileLabelWeight),
      ),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final size = painter.size;
    painter.dispose();
    return size;
  }
}
