/// Switch scanning on the child's board: one or two switches, which send
/// space and enter (as Bluetooth switches do).
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_device.dart';
import '../device/device_settings_scope.dart';
import '../features/flags/w3.dart';
import 'scan_order.dart';

/// The ring round the highlighted row or word, for tests.
const Key scanHighlightKey = ValueKey('SwitchScanner.highlight');

/// The ring round the sentence strip while scanning is on it, for tests.
const Key scanStripHighlightKey = ValueKey('SwitchScanner.stripHighlight');

/// Lays a scanning highlight over [child], the board's grid, while this
/// device has scanning on (see [DeviceSettings.scanMode]).
///
/// The highlight is a thick ink ring, with a thin line of the page's colour
/// inside it, drawn over the cells: it takes no space and moves nothing.
/// One switch: the highlight steps by itself every [DeviceSettings.scanStep],
/// a row at a time, then a word at a time in the row chosen; space or enter
/// selects. Two switches: space moves the highlight, enter selects. A chosen
/// word goes to [onSelect], as a tap would. With the spoken preview on,
/// each highlighted word is said quietly. While the strip holds words, the
/// last stop after the rows is the strip itself (see [onStrip]), so a
/// switch user can say the sentence and start a new one.
///
/// The keys are taken from the whole keyboard while this board is the
/// screen on top, so they work with nothing focused or a word focused; a
/// control outside the grid that the keyboard is on keeps its own keys.
class SwitchScanner extends StatefulWidget {
  const SwitchScanner({
    super.key,
    required this.snapshot,
    required this.speech,
    required this.onSelect,
    required this.gap,
    required this.child,
    this.hides,
    this.shown,
    this.previewIn,
    this.onStrip,
    this.stripHighlight,
  });

  final BoardSnapshot snapshot;
  final SpeechService speech;
  final ValueChanged<TileFacts> onSelect;

  /// Whether the cell of a tile is shown blank (a hidden word): scanning
  /// never stops on it, says it or chooses it.
  final bool Function(String tileId)? hides;

  /// A tile as the grid shows it (in the second language, say): what is
  /// previewed and chosen, as a tap would.
  final TileFacts Function(TileFacts tile)? shown;

  /// Says a word shown in another language with that language's voice;
  /// false when there is none, and the word is previewed as the store has
  /// it.
  final Future<bool> Function(String text)? previewIn;

  /// Says the sentence on the strip and clears it, when a switch chooses
  /// the strip. Null while the strip is empty: scanning then never stops
  /// there.
  final VoidCallback? onStrip;

  /// True while the highlight is on the strip; the strip draws its own
  /// ring, so nothing moves.
  final ValueNotifier<bool>? stripHighlight;

  /// Space round each cell, as the grid draws it.
  final double gap;
  final Widget child;

  @override
  State<SwitchScanner> createState() => _SwitchScannerState();
}

class _SwitchScannerState extends State<SwitchScanner> {
  DeviceSettings _settings = const DeviceSettings();
  late ScanOrder _order = _orderOf(
    widget.snapshot,
    widget.hides,
    strip: widget.onStrip != null,
  );
  ScanPosition? _at;
  Timer? _timer;
  bool _listening = false;

  ScanMode get _mode => switchAccessEnabled ? _settings.scanMode : ScanMode.off;

  /// The rows to scan; with [strip], the strip as one more row after the
  /// grid's last (see [_stripRow]).
  static ScanOrder _orderOf(
    BoardSnapshot snapshot,
    bool Function(String tileId)? hides, {
    required bool strip,
  }) => ScanOrder([
    for (final MapEntry(key: (row, col), value: tile) in snapshot.cells.entries)
      if (row < snapshot.board.rows &&
          col < snapshot.board.cols &&
          !(hides?.call(tile.id) ?? false))
        (row, col),
    if (strip) (snapshot.board.rows, 0),
  ]);

  /// The row index that stands for the sentence strip: just past the grid.
  int get _stripRow => widget.snapshot.board.rows;

  bool get _onStrip =>
      _mode != ScanMode.off &&
      widget.onStrip != null &&
      _at?.row == _stripRow &&
      _at?.phase == ScanPhase.rows;

  /// Tells the strip whether the highlight is on it. [later] while a frame
  /// is being built: the strip is not this widget's child.
  void _showOnStrip({bool later = false}) {
    final highlight = widget.stripHighlight;
    if (highlight == null || highlight.value == _onStrip) return;
    if (later) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showOnStrip();
      });
      return;
    }
    highlight.value = _onStrip;
  }

  /// The word in the cell at ([row], [col]) as the grid shows it; null for
  /// an empty or hidden cell.
  TileFacts? _tileAt(int row, int col) {
    final tile = widget.snapshot.cells[(row, col)];
    if (tile == null || (widget.hides?.call(tile.id) ?? false)) return null;
    return tile;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = DeviceSettingsScope.of(context);
    if (settings == _settings && (_listening || _mode == ScanMode.off)) {
      return;
    }
    _settings = settings;
    _restart();
  }

  @override
  void didUpdateWidget(SwitchScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Every time: a word hidden or shown again, or "Show everything",
    // changes what is scanned without a new snapshot. A board is a few
    // dozen cells, so this is cheap.
    _order = _orderOf(
      widget.snapshot,
      widget.hides,
      strip: widget.onStrip != null,
    );
    _at = _order.keep(_at);
    _showOnStrip(later: true);
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _restart() {
    _stop();
    if (_mode == ScanMode.off) {
      _at = null;
      _showOnStrip(later: true);
      return;
    }
    _at = _order.start;
    HardwareKeyboard.instance.addHandler(_onKey);
    _listening = true;
    _schedule();
    _showOnStrip(later: true);
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (_listening) HardwareKeyboard.instance.removeHandler(_onKey);
    _listening = false;
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (_mode != ScanMode.oneSwitch) return;
    _timer = Timer.periodic(_settings.scanStep, (_) {
      // Rests while a screen is over the board.
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) _move();
    });
  }

  void _move() {
    if (!mounted) return;
    final at = _at;
    setState(() => _at = at == null ? _order.start : _order.next(at));
    _showOnStrip();
    _preview();
  }

  void _choose() {
    final at = _at;
    if (at == null) {
      setState(() => _at = _order.start);
      return;
    }
    final onStrip = widget.onStrip;
    if (onStrip != null && _onStrip) {
      // The strip: the sentence is said, and a new one starts at the top.
      setState(() => _at = _order.start);
      _showOnStrip();
      onStrip();
      _schedule();
      return;
    }
    final selection = _order.select(at);
    if (selection == null) return;
    setState(() => _at = selection.next);
    final chosen = selection.chosen;
    if (chosen != null) {
      final tile = _tileAt(chosen.$1, chosen.$2);
      if (tile != null) widget.onSelect(widget.shown?.call(tile) ?? tile);
    } else {
      _preview();
    }
    // The highlight rests a full step on its new place.
    _schedule();
  }

  /// Says the highlighted word quietly, when the preview is on.
  void _preview() {
    if (!_settings.scanPreview) return;
    final at = _at;
    final col = at?.col;
    if (at == null || col == null) return;
    final tile = _tileAt(at.row, col);
    if (tile == null) return;
    final shown = widget.shown?.call(tile) ?? tile;
    final previewIn = widget.previewIn;
    unawaited(
      (identical(shown, tile) || previewIn == null
              ? _quietly(tile.spokenText)
              : _inLanguage(previewIn, shown, tile))
          .catchError((Object _) {}),
    );
  }

  /// A word shown in another language, in its voice; with none, the word
  /// as the store has it, as a tap would say it.
  Future<void> _inLanguage(
    Future<bool> Function(String text) previewIn,
    TileFacts shown,
    TileFacts tile,
  ) async {
    if (await previewIn(shown.spokenText)) return;
    await _quietly(tile.spokenText);
  }

  Future<void> _quietly(String text) => switch (widget.speech) {
    final QuietSpeech quiet => quiet.speakQuietly(text),
    final speech => speech.speak(text),
  };

  static final Set<LogicalKeyboardKey> _selectKeys = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };

  bool _onKey(KeyEvent event) {
    if (!mounted || _mode == ScanMode.off) return false;
    // Only the board on top scans: a sheet or screen over it keeps its keys.
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    // A control outside the grid that the keyboard is on (an adult who
    // tabbed to "Hold to leave") keeps its keys, so its hold still works.
    final focus = FocusManager.instance.primaryFocus;
    final focused = focus?.context;
    if (focus is! FocusScopeNode &&
        focused != null &&
        focused.findAncestorStateOfType<_SwitchScannerState>() != this) {
      return false;
    }
    final key = event.logicalKey;
    final isSpace = key == LogicalKeyboardKey.space;
    final isSelect = _selectKeys.contains(key);
    if (!isSpace && !isSelect) return false;
    // A held switch repeats: only the press counts.
    if (event is KeyDownEvent) {
      if (_mode == ScanMode.twoSwitches && isSpace) {
        _move();
      } else {
        _choose();
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final at = _at;
    if (_mode == ScanMode.off || at == null) return widget.child;
    final board = widget.snapshot.board;
    final colors = ChorusColors.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: CustomPaint(
            key: scanHighlightKey,
            painter: _ScanRing(
              at: at,
              rows: board.rows,
              cols: board.cols,
              gap: widget.gap,
              outer: colors.ink,
              inner: colors.surface,
            ),
          ),
        ),
      ],
    );
  }
}

/// The ring: round the whole row, or round one word.
class _ScanRing extends CustomPainter {
  const _ScanRing({
    required this.at,
    required this.rows,
    required this.cols,
    required this.gap,
    required this.outer,
    required this.inner,
  });

  final ScanPosition at;
  final int rows;
  final int cols;
  final double gap;
  final Color outer;
  final Color inner;

  @override
  void paint(Canvas canvas, Size size) {
    // Past the grid (the strip): the strip draws its own ring.
    if (rows <= 0 || cols <= 0 || at.row >= rows) return;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final col = at.col;
    final rect = col == null
        ? Rect.fromLTWH(0, at.row * cellH, size.width, cellH)
        : Rect.fromLTWH(col * cellW, at.row * cellH, cellW, cellH);
    final ring = RRect.fromRectAndRadius(
      rect.deflate(gap / 2),
      const Radius.circular(ChorusSpace.tileRadius),
    );
    final line = Paint()..style = PaintingStyle.stroke;
    canvas.drawRRect(
      ring.deflate(3),
      line
        ..color = outer
        ..strokeWidth = 6,
    );
    canvas.drawRRect(
      ring.deflate(7),
      line
        ..color = inner
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ScanRing old) =>
      old.at != at ||
      old.rows != rows ||
      old.cols != cols ||
      old.gap != gap ||
      old.outer != outer ||
      old.inner != inner;
}
