/// Keeps the signed-in app to one tab of a browser.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../screens/other_tab_screen.dart';
import '../../screens/status_views.dart';
import 'tab_seat.dart';

/// Shows [child] only while this tab holds the seat. Without it the tab says
/// that Chorus is open in another tab and offers to use it here instead.
///
/// [child] is out of the tree whenever the seat is not held, so what it
/// opened is closed with it. The gate belongs on the app's first route:
/// when the seat goes, every route above that one is closed too.
class OneTabGate extends StatefulWidget {
  const OneTabGate({
    super.key,
    this.seat,
    this.onTaken,
    this.afterTakeOver,
    this.onHeld,
    required this.child,
  });

  /// This tab's seat, read once. Null for the real one; tests pass a fake.
  final TabSeat? seat;

  /// Called the moment another tab takes the seat, before [child] is
  /// disposed. A tab in the background draws no frames, so that can be a
  /// long time later; whatever must stop sooner is stopped here.
  final VoidCallback? onTaken;

  /// Called once this tab has taken the seat over, before [child] is built:
  /// the tab that had it may have changed what the browser keeps.
  final Future<void> Function()? afterTakeOver;

  /// Called each time this tab comes to hold the seat, after
  /// [afterTakeOver]. Whatever changes what the browser keeps belongs here,
  /// so that a tab without the seat never does it.
  final VoidCallback? onHeld;

  final Widget child;

  @override
  State<OneTabGate> createState() => _OneTabGateState();
}

enum _Seat { asking, held, elsewhere, taken }

class _OneTabGateState extends State<OneTabGate> {
  late final TabSeat _seat = widget.seat ?? openTabSeat();
  late final StreamSubscription<void> _taken;

  _Seat _state = _Seat.asking;

  @override
  void initState() {
    super.initState();
    _taken = _seat.taken.listen((_) => _onTaken());
    _claim();
  }

  @override
  void dispose() {
    // Signed out, or the app is going away: another tab may have the seat.
    unawaited(_taken.cancel());
    _seat.release();
    super.dispose();
  }

  Future<void> _claim() async {
    var held = true;
    try {
      held = await _seat.claim();
    } catch (_) {
      // A seat that cannot be asked for must not keep anyone from the board.
    }
    if (!mounted) return;
    setState(() => _state = held ? _Seat.held : _Seat.elsewhere);
    if (held) widget.onHeld?.call();
  }

  Future<void> _takeOver() async {
    setState(() => _state = _Seat.asking);
    try {
      await _seat.takeOver();
    } catch (_) {
      // The same: the adult asked for Chorus here.
    }
    if (!mounted) return;
    try {
      await widget.afterTakeOver?.call();
    } catch (_) {
      // What this tab read before is still there to go on with.
    }
    if (!mounted) return;
    setState(() => _state = _Seat.held);
    widget.onHeld?.call();
  }

  void _onTaken() {
    if (!mounted) return;
    widget.onTaken?.call();
    // Whatever is open over the app (the child's board, the editor, a
    // dialog) belongs to it, and would cover the notice.
    Navigator.maybeOf(context)?.popUntil((route) => route.isFirst);
    setState(() => _state = _Seat.taken);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      // The shell's own first look, so nothing flickers on the way in.
      _Seat.asking => const Scaffold(
        body: SafeArea(child: LoadingView(message: 'Opening Chorus…')),
      ),
      _Seat.held => widget.child,
      _Seat.elsewhere => OtherTabScreen(onUseHere: _takeOver),
      _Seat.taken => OtherTabScreen(onUseHere: _takeOver, moved: true),
    };
  }
}
