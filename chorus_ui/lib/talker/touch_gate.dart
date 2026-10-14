/// How a word on the child's board answers a touch: hold time, ignore
/// repeat taps and select on release (see [DeviceSettings]).
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../brand/haptics.dart';
import '../contracts_device.dart';
import '../device/device_settings_scope.dart';
import '../features/flags/w3.dart';

/// Wraps one word's tap. [builder] gets the tap to give the tile, and the
/// haptic the tile should play on its own taps.
///
/// With the device's touch settings as they have always been (or the
/// feature off) the tile gets [onActivate] itself and nothing changes.
/// Otherwise:
///
/// * select on release: the word speaks when the finger lifts, if it was
///   held at least the hold time;
/// * not on release: the word speaks once it has been held for the hold
///   time, while the finger is still down (at once with no hold time);
/// * ignore repeat taps: after a word speaks, the board ignores words for
///   that long.
///
/// A keyboard press or a screen reader's tap has no finger to hold, so it
/// speaks at once (still minding repeat taps). A long press on a word only
/// ever does the above: it never reaches "Hold to leave".
class TouchGate extends StatefulWidget {
  const TouchGate({
    super.key,
    required this.onActivate,
    required this.builder,
    this.haptic = ChorusHaptic.wordTapped,
  });

  final VoidCallback onActivate;

  /// With touch as always, the tile gets [onActivate] and [haptic] itself.
  /// Otherwise it gets the gate's tap and no haptic: the gate plays
  /// [haptic] only when the word really speaks, so a touch that is ignored
  /// is not felt as a word.
  final Widget Function(VoidCallback onTap, ChorusHaptic? haptic) builder;

  /// Felt each time the word speaks.
  final ChorusHaptic? haptic;

  @override
  State<TouchGate> createState() => _TouchGateState();
}

class _TouchGateState extends State<TouchGate> {
  /// The finger on this word now, if any.
  int? _pointer;
  Timer? _holdTimer;

  /// The finger now on the word has been there for the hold time.
  bool _held = false;

  /// Whether the finger that just lifted was held long enough; read by the
  /// tile's tap, which comes straight after the lift in the same event.
  bool? _justLifted;

  DeviceSettings _settings = const DeviceSettings();
  TouchClock? _clock;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _speak() {
    final clock = _clock;
    if (clock != null && !clock.allow(_settings.repeatGuard)) return;
    ChorusHaptics.play(widget.haptic);
    widget.onActivate();
  }

  void _down(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    final hold = _settings.holdTime;
    _held = hold == Duration.zero;
    if (_held) {
      if (!_settings.selectOnRelease) _speak();
      return;
    }
    _holdTimer = Timer(hold, () {
      if (!mounted || _pointer == null) return;
      _held = true;
      if (!_settings.selectOnRelease) _speak();
    });
  }

  void _up(PointerEvent event, {required bool lifted}) {
    if (event.pointer != _pointer) return;
    _holdTimer?.cancel();
    _holdTimer = null;
    _pointer = null;
    if (!lifted) return;
    _justLifted = _held;
    // The tile's tap comes in the same event as the lift; after it, a tap
    // with no finger is a keyboard or a screen reader.
    scheduleMicrotask(() => _justLifted = null);
  }

  /// The tile's own tap: after a lift, or from a keyboard or screen reader.
  void _tileTapped() {
    final heldLongEnough = _justLifted;
    _justLifted = null;
    if (heldLongEnough == null) {
      // No finger: a keyboard or a screen reader.
      _speak();
      return;
    }
    // Not on release: it spoke while held, or was not held long enough.
    if (!_settings.selectOnRelease || !heldLongEnough) return;
    _speak();
  }

  @override
  Widget build(BuildContext context) {
    _settings = touchSettingsEnabled
        ? DeviceSettingsScope.of(context)
        : const DeviceSettings();
    _clock = DeviceSettingsScope.clockOf(context);
    if (_settings.plainTouch) {
      return widget.builder(widget.onActivate, widget.haptic);
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerUp: (event) => _up(event, lifted: true),
      onPointerCancel: (event) => _up(event, lifted: false),
      child: widget.builder(_tileTapped, null),
    );
  }
}
