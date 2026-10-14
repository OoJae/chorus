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

/// Lays a scanning highlight over [child], the board's grid, while this
/// device has scanning on (see [DeviceSettings.scanMode]).
///
/// The highlight is a thick ink ring, with a thin line of the page's colour
/// inside it, drawn over the cells: it takes no space and moves nothing.
/// One switch: the highlight steps by itself every [DeviceSettings.scanStep],
/// a row at a time, then a word at a time in the row chosen; space or enter
/// selects. Two switches: space moves the highlight, enter selects. A chosen
/// word goes to [onSelect], as a tap would. With the spoken preview on,
/// each highlighted word is said quietly.
///
/// The keys are taken from the whole keyboard while this board is the
/// screen on top, so they work whatever has focus.
class SwitchScanner extends StatefulWidget {
  const SwitchScanner({
    super.key,
    required this.snapshot,
    required this.speech,
    required this.onSelect,
    required this.gap,
    required this.child,
  });

  final BoardSnapshot snapshot;
  final SpeechService speech;
  final ValueChanged<TileFacts> onSelect;

  /// Space round each cell, as the grid draws it.
  final double gap;
  final Widget child;

  @override
  State<SwitchScanner> createState() => _SwitchScannerState();
}

class _SwitchScannerState extends State<SwitchScanner> {
  DeviceSettings _settings = const DeviceSettings();
  late ScanOrder _order = _orderOf(widget.snapshot);
  ScanPosition? _at;
  Timer? _timer;
  bool _listening = false;

  ScanMode get _mode => switchAccessEnabled ? _settings.scanMode : ScanMode.off;

  static ScanOrder _orderOf(BoardSnapshot snapshot) => ScanOrder([
    for (final MapEntry(key: (row, col)) in snapshot.cells.entries)
      if (row < snapshot.board.rows && col < snapshot.board.cols) (row, col),
  ]);

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
    if (!identical(oldWidget.snapshot, widget.snapshot)) {
      _order = _orderOf(widget.snapshot);
      _at = _order.keep(_at);
    }
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
      return;
    }
    _at = _order.start;
    HardwareKeyboard.instance.addHandler(_onKey);
    _listening = true;
    _schedule();
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
    _preview();
  }

  void _choose() {
    final at = _at;
    if (at == null) {
      setState(() => _at = _order.start);
      return;
    }
    final selection = _order.select(at);
    if (selection == null) return;
    setState(() => _at = selection.next);
    final chosen = selection.chosen;
    if (chosen != null) {
      final tile = widget.snapshot.cells[chosen];
      if (tile != null) widget.onSelect(tile);
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
    final tile = widget.snapshot.cells[(at.row, col)];
    if (tile == null) return;
    final text = tile.spokenText;
    final Future<void> said = switch (widget.speech) {
      final QuietSpeech quiet => quiet.speakQuietly(text),
      final speech => speech.speak(text),
    };
    unawaited(said.catchError((Object _) {}));
  }

  static final Set<LogicalKeyboardKey> _selectKeys = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };

  bool _onKey(KeyEvent event) {
    if (!mounted || _mode == ScanMode.off) return false;
    // Only the board on top scans: a sheet or screen over it keeps its keys.
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
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
    if (rows <= 0 || cols <= 0) return;
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
