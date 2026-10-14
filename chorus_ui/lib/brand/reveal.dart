/// The chorus reveal: the launch moment.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'mark.dart';
import 'motion.dart';
import 'tokens.dart';

/// The mark's four tiles multiply column by column, like voices joining,
/// into the starter board's 6 x 6 grid in its colour key, and settle on the
/// [ChorusMotion.chorus] spring. It lasts [duration] and then calls
/// [onDone].
///
/// It plays once for the life of this widget. Under reduced motion it shows
/// its last frame at once and calls [onDone] after that frame.
class ChorusReveal extends StatefulWidget {
  const ChorusReveal({super.key, this.onDone, this.size = 240});

  final VoidCallback? onDone;

  /// The side of the square it draws in.
  final double size;

  static const Duration duration = Duration(milliseconds: 900);

  /// The drawing, for tests that look at its frame.
  @visibleForTesting
  static const Key paintKey = ValueKey('ChorusReveal.paint');

  @override
  State<ChorusReveal> createState() => _ChorusRevealState();
}

class _ChorusRevealState extends State<ChorusReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _time = AnimationController(
    vsync: this,
    duration: ChorusReveal.duration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (ChorusMotion.reduced(context)) {
      _time.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDone?.call();
      });
    } else {
      _time.forward().whenCompleteOrCancel(() {
        if (mounted && _time.isCompleted) widget.onDone?.call();
      });
    }
  }

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Chorus',
      child: RepaintBoundary(
        child: CustomPaint(
          key: ChorusReveal.paintKey,
          size: Size.square(widget.size),
          painter: RevealPainter(_time, Theme.of(context).brightness),
        ),
      ),
    );
  }
}

/// Draws the reveal at [progress] (0 is the mark, 1 the settled board).
@visibleForTesting
class RevealPainter extends CustomPainter {
  RevealPainter(this.progress, this.brightness) : super(repaint: progress);

  final Animation<double> progress;
  final Brightness brightness;

  // Each column starts this much after the one to its left.
  static const double _stagger = 0.07;
  static const int _rows = starterRows;
  static const int _cols = starterCols;
  static final SpringSimulation _spring = SpringSimulation(
    ChorusMotion.chorus,
    0,
    1,
    0,
  );

  // The starter board's colour key, by cell.
  static final Map<(int, int), TileFamily> _families = {
    for (final word in universalCore36)
      (word.row, word.col): TileFamily.forKey(word.colorKey),
  };

  /// How far column [col] has travelled at [progress], past 1 while it
  /// bounces; exactly 1 at the end.
  static double travel(int col, double progress) {
    if (progress >= 1) return 1;
    final seconds =
        progress * ChorusReveal.duration.inMicroseconds / 1e6 - col * _stagger;
    return seconds <= 0 ? 0 : _spring.x(seconds);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final box = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side,
      height: side,
    );
    final mark = MarkGeometry.tilesIn(
      Rect.fromCenter(
        center: box.center,
        width: side * 0.42,
        height: side * 0.42,
      ),
    );
    final gap = side * 0.024;
    final cell = (side - gap * (_cols - 1)) / _cols;
    final edge = cell * 0.08 < ChorusSpace.edge
        ? cell * 0.08
        : ChorusSpace.edge;
    final radius = ChorusSpace.tileRadiusFor(cell);
    final t = progress.value;

    // Columns still inside the mark first, so the ones on their way out are
    // drawn over them.
    for (var col = _cols - 1; col >= 0; col--) {
      final p = travel(col, t);
      final shade = p.clamp(0.0, 1.0);
      for (var row = 0; row < _rows; row++) {
        final from =
            mark[(row < _rows / 2 ? 0 : 2) + (col < _cols / 2 ? 0 : 1)];
        final to = Rect.fromLTWH(
          box.left + col * (cell + gap),
          box.top + row * (cell + gap),
          cell,
          cell,
        );
        final fromColors = from.family.colorsFor(brightness);
        final toColors = (_families[(row, col)] ?? TileFamily.other).colorsFor(
          brightness,
        );
        MarkGeometry.paintTile(
          canvas,
          outer: Rect.lerp(from.outer, to, p)!,
          edge: _lerp(from.edge, edge, p),
          radius: _lerp(MarkGeometry.radiusFor(from.outer.width), radius, p),
          fill: Color.lerp(fromColors.fill, toColors.fill, shade)!,
          edgeColor: Color.lerp(fromColors.edge, toColors.edge, shade)!,
        );
      }
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(RevealPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.brightness != brightness;
}
