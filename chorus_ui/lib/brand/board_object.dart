/// The board as an object: the app's one loud thing.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/label_fit.dart';
import 'haptics.dart';
import 'motion.dart';
import 'pressable_surface.dart';
import 'tokens.dart';

/// One word on a [BoardObject].
@immutable
class BoardCell {
  const BoardCell({
    required this.row,
    required this.col,
    required this.label,
    this.family = TileFamily.other,
    this.image,
  });

  final int row;
  final int col;
  final String label;
  final TileFamily family;

  /// A symbol or photo drawn above the label.
  final ImageProvider? image;

  @override
  String toString() => 'BoardCell("$label", $row:$col)';
}

/// A board of tiles drawn as a laminated card in real perspective. Each tile
/// sits at its own small depth, so the tiles shift against each other as the
/// card turns.
///
/// It tilts toward the thumb, up to [maxTilt] degrees, while touched, and
/// springs back on [ChorusMotion.settle] with the speed of the release. It
/// leans back as [lean] goes from 0 to 1: the home screen sets that from its
/// scroll offset, and only the transform moves.
///
/// With [onTileTap] each tile is a button that presses and speaks, as on the
/// onboarding board; without it the tiles are a picture, and [onTap] makes
/// the whole board one button, as the home screen's hero. That button takes
/// the keyboard too: Tab reaches it, Enter and Space press it, and an ink
/// ring round the card shows where the keyboard is. [heroTag] makes the card
/// the shared element of a route change.
///
/// Under reduced motion it lies flat and does not tilt.
class BoardObject extends StatefulWidget {
  const BoardObject({
    super.key,
    required this.rows,
    required this.cols,
    required this.cells,
    this.lean,
    this.onTileTap,
    this.onTap,
    this.semanticLabel,
    this.heroTag,
    this.maxTilt = 8,
  });

  final int rows;
  final int cols;
  final List<BoardCell> cells;

  /// 0 stands the board up; 1 leans it fully back and a little smaller.
  final ValueListenable<double>? lean;

  final ValueChanged<BoardCell>? onTileTap;

  /// A tap anywhere on a board without [onTileTap].
  final VoidCallback? onTap;

  /// What a screen reader says for the whole board.
  final String? semanticLabel;

  final Object? heroTag;

  /// The most the board tilts under the thumb, in degrees.
  final double maxTilt;

  /// The card's transform, for tests that check the tilt.
  @visibleForTesting
  static const Key tiltKey = ValueKey('BoardObject.tilt');

  /// The keyboard focus ring of a board that is one button, for tests.
  @visibleForTesting
  static const Key focusRingKey = ValueKey('BoardObject.focusRing');

  @override
  State<BoardObject> createState() => _BoardObjectState();
}

class _BoardObjectState extends State<BoardObject>
    with TickerProviderStateMixin {
  // How strongly depth shows: about 0.0012 reads as a hand-held card.
  static const double _perspective = 0.0012;

  // Even at rest the card lies back a little, as on a table.
  static const double _restLean = 6 * math.pi / 180;

  // How far [BoardObject.lean] takes it.
  static const double _maxLean = 22 * math.pi / 180;
  static const double _leanShrink = 0.1;

  // A flick's turn speed is capped, so a hard fling does not spin the card.
  static const double _maxTurnSpeed = 4;

  // Tilt about the horizontal and the vertical axis, in radians.
  late final AnimationController _tiltX = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _tiltY = AnimationController.unbounded(
    vsync: this,
  );

  final TileLabelSizer _sizer = TileLabelSizer();
  Size _card = Size.zero;
  bool _reduced = false;
  bool _focused = false;
  bool _showRing = false;

  /// True when the whole board is one button: see [BoardObject.onTap].
  bool get _isButton => widget.onTileTap == null && widget.onTap != null;

  static const Map<ShortcutActivator, Intent> _keys = {
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  };

  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (_) => widget.onTap?.call(),
    ),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
      onInvoke: (_) => widget.onTap?.call(),
    ),
  };

  double get _maxTilt => widget.maxTilt * math.pi / 180;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = ChorusMotion.reduced(context);
    if (_reduced) {
      _tiltX.value = 0;
      _tiltY.value = 0;
    }
  }

  @override
  void dispose() {
    _tiltX.dispose();
    _tiltY.dispose();
    super.dispose();
  }

  /// The tilt that dips the card under [position]: the touched side goes
  /// away from the viewer.
  (double, double) _tiltToward(Offset position) {
    final card = _cardRect();
    if (card.isEmpty) return (0, 0);
    final nx = ((position.dx - card.left) / card.width * 2 - 1).clamp(
      -1.0,
      1.0,
    );
    final ny = ((position.dy - card.top) / card.height * 2 - 1).clamp(
      -1.0,
      1.0,
    );
    return (ny * _maxTilt, -nx * _maxTilt);
  }

  /// The card within this widget, which centres it in any extra room.
  Rect _cardRect() {
    final box = context.size ?? Size.zero;
    return Rect.fromCenter(
      center: box.center(Offset.zero),
      width: _card.width,
      height: _card.height,
    );
  }

  void _follow(Offset position) {
    final (x, y) = _tiltToward(position);
    ChorusMotion.springTo(_tiltX, ChorusMotion.press, x);
    ChorusMotion.springTo(_tiltY, ChorusMotion.press, y);
  }

  void _release([Velocity velocity = Velocity.zero]) {
    double speed(double pixels, double half) => half <= 0
        ? 0
        : (pixels / half * _maxTilt).clamp(-_maxTurnSpeed, _maxTurnSpeed);
    final v = velocity.pixelsPerSecond;
    ChorusMotion.springTo(
      _tiltX,
      ChorusMotion.settle,
      0,
      velocity: speed(v.dy, _card.height / 2),
    );
    ChorusMotion.springTo(
      _tiltY,
      ChorusMotion.settle,
      0,
      velocity: speed(-v.dx, _card.width / 2),
    );
  }

  Matrix4 _transform() {
    final lean = (widget.lean?.value ?? 0).clamp(0.0, 1.0);
    final scale = 1 - _leanShrink * lean;
    return Matrix4.identity()
      ..setEntry(3, 2, _perspective)
      ..rotateX(_tiltX.value - _restLean - _maxLean * lean)
      ..rotateY(_tiltY.value)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = _reduced;
    // Laid out when the room changes, never while tilting.
    final card = LayoutBuilder(
      builder: (context, constraints) {
        final layout = _BoardLayout.fit(
          widget.rows,
          widget.cols,
          constraints.biggest,
        );
        _card = layout.size;
        Widget card = RepaintBoundary(
          child: SizedBox.fromSize(
            size: layout.size,
            child: _board(context, layout, reduced),
          ),
        );
        final heroTag = widget.heroTag;
        if (heroTag != null) card = Hero(tag: heroTag, child: card);
        // Outside the hero, so the ring stays behind when the card flies.
        // The stack is there whether or not the ring is, so showing it
        // does not build the card again.
        if (_isButton) {
          card = Stack(
            clipBehavior: Clip.none,
            children: [
              card,
              if (_showRing)
                Positioned(
                  left: -4,
                  top: -4,
                  right: -4,
                  bottom: -4,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: BoardObject.focusRingKey,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: ChorusColors.of(context).ink,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(
                          layout.cardRadius + 4,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
        return Align(widthFactor: 1, heightFactor: 1, child: card);
      },
    );

    Widget object = reduced
        ? card
        : AnimatedBuilder(
            animation: Listenable.merge([_tiltX, _tiltY, ?widget.lean]),
            builder: (context, child) => Transform(
              key: BoardObject.tiltKey,
              alignment: Alignment.center,
              transform: _transform(),
              child: child,
            ),
            child: card,
          );
    if (!reduced || widget.onTap != null) {
      object = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTileTap == null ? widget.onTap : null,
        onPanDown: reduced ? null : (details) => _follow(details.localPosition),
        onPanUpdate: reduced
            ? null
            : (details) => _follow(details.localPosition),
        onPanEnd: reduced ? null : (details) => _release(details.velocity),
        onPanCancel: reduced ? null : _release,
        child: object,
      );
    }
    if (_isButton) {
      object = FocusableActionDetector(
        // Told to screen readers below, with the button itself.
        includeFocusSemantics: false,
        shortcuts: _keys,
        actions: _actions,
        mouseCursor: SystemMouseCursors.click,
        onFocusChange: (focused) => setState(() => _focused = focused),
        onShowFocusHighlight: (show) => setState(() => _showRing = show),
        child: object,
      );
    }

    final tilesSpeak = widget.onTileTap != null;
    return RepaintBoundary(
      child: Semantics(
        container: true,
        explicitChildNodes: tilesSpeak,
        button: _isButton,
        focusable: _isButton ? true : null,
        focused: _isButton ? _focused : null,
        label: widget.semanticLabel,
        onTap: tilesSpeak ? null : widget.onTap,
        excludeSemantics: !tilesSpeak,
        child: object,
      ),
    );
  }

  Widget _board(BuildContext context, _BoardLayout layout, bool reduced) {
    final colors = ChorusColors.of(context);
    final brightness = Theme.of(context).brightness;
    final labelSize = _sizer.sizeFor(
      labels: widget.cells.map((cell) => cell.label),
      tile: Size(layout.cell, layout.cell - layout.tileEdge),
      style: DefaultTextStyle.of(context).style.merge(ChorusType.body),
      scaler: MediaQuery.textScalerOf(context),
      direction: Directionality.of(context),
    );
    final radius = BorderRadius.circular(layout.cardRadius);
    return Stack(
      children: [
        // The card's own laminated edge.
        Positioned.fill(
          top: ChorusSpace.edge,
          child: DecoratedBox(
            decoration: BoxDecoration(color: colors.line, borderRadius: radius),
          ),
        ),
        Positioned.fill(
          bottom: ChorusSpace.edge,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: radius,
            ),
          ),
        ),
        for (final cell in widget.cells)
          if (cell.row >= 0 &&
              cell.row < widget.rows &&
              cell.col >= 0 &&
              cell.col < widget.cols)
            Positioned.fromRect(
              rect: layout.tileRect(cell.row, cell.col),
              child: _depth(
                cell,
                reduced,
                _tile(cell, layout, brightness, labelSize),
              ),
            ),
      ],
    );
  }

  /// Raises [child] off the card by its own few pixels. Flat boards have no
  /// depth to show.
  Widget _depth(BoardCell cell, bool reduced, Widget child) {
    if (reduced) return child;
    const steps = [0.0, 2.0, 4.0, 1.0, 3.0];
    final depth = steps[(cell.row * 3 + cell.col * 2) % steps.length] * 1.5;
    return Transform(
      transform: Matrix4.translationValues(0, 0, -depth),
      child: child,
    );
  }

  Widget _tile(
    BoardCell cell,
    _BoardLayout layout,
    Brightness brightness,
    double labelSize,
  ) {
    final colors = cell.family.colorsFor(brightness);
    final radius = ChorusSpace.tileRadiusFor(layout.cell);
    final content = _TileContent(cell: cell, labelSize: labelSize);
    final onTileTap = widget.onTileTap;
    if (onTileTap != null) {
      return PressableSurface(
        onTap: () => onTileTap(cell),
        semanticLabel: cell.label,
        color: colors.fill,
        edgeColor: colors.edge,
        foregroundColor: tileLabelInk,
        borderRadius: radius,
        haptic: ChorusHaptic.wordTapped,
        child: content,
      );
    }
    final corner = BorderRadius.circular(radius);
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: EdgeInsets.only(top: layout.tileEdge),
          child: DecoratedBox(
            decoration: BoxDecoration(color: colors.edge, borderRadius: corner),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: layout.tileEdge),
          child: DecoratedBox(
            decoration: BoxDecoration(color: colors.fill, borderRadius: corner),
            child: content,
          ),
        ),
      ],
    );
  }
}

/// A tile's label, under its picture when it has one.
class _TileContent extends StatelessWidget {
  const _TileContent({required this.cell, required this.labelSize});

  final BoardCell cell;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    final label = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        cell.label,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: ChorusType.tileLabel(labelSize).copyWith(color: tileLabelInk),
      ),
    );
    final image = cell.image;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: image == null
          ? Center(child: label)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Image(
                    image: image,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                Expanded(flex: 2, child: Center(child: label)),
              ],
            ),
    );
  }
}

/// Where everything on the card goes, worked out once per size.
@immutable
class _BoardLayout {
  const _BoardLayout._(this.rows, this.cols, this.cell);

  /// The largest board of square tiles that fits [room].
  factory _BoardLayout.fit(int rows, int cols, Size room) {
    final across = cols + _gap * (cols - 1) + 2 * _pad;
    final down = rows + _gap * (rows - 1) + 2 * _pad;
    var cell = double.infinity;
    if (room.width.isFinite) cell = room.width / across;
    if (room.height.isFinite) {
      cell = math.min(cell, (room.height - ChorusSpace.edge) / down);
    }
    if (!cell.isFinite) cell = 56;
    return _BoardLayout._(rows, cols, math.max(0, cell));
  }

  // In units of a tile's side.
  static const double _gap = 0.16;
  static const double _pad = 0.32;

  final int rows;
  final int cols;

  /// The side of a tile, edge included.
  final double cell;

  double get gap => cell * _gap;
  double get pad => cell * _pad;
  double get tileEdge => math.min(ChorusSpace.edge, cell * 0.08);
  double get cardRadius => math.min(ChorusSpace.panelRadius, cell * 0.5);

  Size get size => Size(
    cols * cell + (cols - 1) * gap + 2 * pad,
    rows * cell + (rows - 1) * gap + 2 * pad + ChorusSpace.edge,
  );

  Rect tileRect(int row, int col) => Rect.fromLTWH(
    pad + col * (cell + gap),
    pad + row * (cell + gap),
    cell,
    cell,
  );
}
