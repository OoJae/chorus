/// The laminated press: a card on Velcro, pushed.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'haptics.dart';
import 'motion.dart';
import 'tokens.dart';

/// A surface with a darker 3 dp edge under it that, while pressed, sinks
/// 2 dp onto a 1 dp edge, on the [ChorusMotion.press] spring.
///
/// The spring follows the finger: down on touch, back on release or when a
/// scroll takes the touch, turning round wherever it is. Under reduced
/// motion the face stays put and only the edge changes, at once.
///
/// Enter and Space press it too, and keyboard focus draws an ink ring round
/// it. It is never smaller than 48 dp. Screen readers hear a button called
/// [semanticLabel], or by its child's text when that is null.
///
/// A null [onTap] disables it; callers dim a disabled surface themselves.
class PressableSurface extends StatefulWidget {
  const PressableSurface({
    super.key,
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.color,
    this.edgeColor,
    this.foregroundColor,
    this.borderRadius = ChorusSpace.buttonRadius,
    this.padding = EdgeInsets.zero,
    this.haptic,
    this.focusNode,
    this.autofocus = false,
  });

  final VoidCallback? onTap;
  final Widget child;

  /// What a screen reader says. Null reads the child's text.
  final String? semanticLabel;

  /// The face. Null is ink, a primary button.
  final Color? color;

  /// The edge under the face. Null darkens [color] (see [edgeFor]).
  final Color? edgeColor;

  /// Text and icons on the face. Null is card on ink, and otherwise whichever
  /// of paper or tile ink reads on [color].
  final Color? foregroundColor;

  final double borderRadius;

  /// Space between the face's edges and [child].
  final EdgeInsetsGeometry padding;

  /// Felt on every activation. Null, the default, is none: haptics mark
  /// named moments, not every button.
  final ChorusHaptic? haptic;

  final FocusNode? focusNode;
  final bool autofocus;

  /// The face, for tests that measure the press.
  @visibleForTesting
  static const Key faceKey = ValueKey('PressableSurface.face');

  /// The edge, for tests that measure the press.
  @visibleForTesting
  static const Key edgeKey = ValueKey('PressableSurface.edge');

  /// The keyboard focus ring, for tests.
  @visibleForTesting
  static const Key focusRingKey = ValueKey('PressableSurface.focusRing');

  @override
  State<PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<PressableSurface>
    with SingleTickerProviderStateMixin {
  // 0 at rest, 1 fully pressed.
  late final AnimationController _press = AnimationController(vsync: this);

  bool _reduced = false;
  bool _pointerDown = false;
  bool _focused = false;
  bool _showRing = false;

  bool get _enabled => widget.onTap != null;

  static const Map<ShortcutActivator, Intent> _keys = {
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  };

  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (_) => _activateFromKeyboard(),
    ),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
      onInvoke: (_) => _activateFromKeyboard(),
    ),
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = ChorusMotion.reduced(context);
    if (reduced != _reduced) {
      _reduced = reduced;
      _press.stop();
      _press.value = _pointerDown ? 1 : 0;
    }
  }

  @override
  void didUpdateWidget(PressableSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && _press.value != 0) {
      _pointerDown = false;
      _press.value = 0;
    }
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _pressTo(double target) {
    if (_reduced) {
      _press.value = target;
    } else {
      ChorusMotion.springTo(_press, ChorusMotion.press, target);
    }
  }

  void _down() {
    _pointerDown = true;
    _pressTo(1);
  }

  void _up() {
    _pointerDown = false;
    _pressTo(0);
  }

  void _activate() {
    final onTap = widget.onTap;
    if (onTap == null) return;
    ChorusHaptics.play(widget.haptic);
    onTap();
  }

  /// A key press has no up to wait for: press in, then come back.
  void _activateFromKeyboard() {
    if (!_reduced && !_pointerDown) {
      ChorusMotion.springTo(_press, ChorusMotion.press, 1).whenCompleteOrCancel(
        () {
          if (mounted && !_pointerDown) _pressTo(0);
        },
      );
    }
    _activate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final face = widget.color ?? colors.ink;
    final edge = widget.edgeColor ?? edgeFor(face);
    final foreground =
        widget.foregroundColor ??
        (widget.color == null ? colors.card : _readableOn(face));
    final radius = BorderRadius.circular(widget.borderRadius);
    final reduced = _reduced;

    final faceBox = DecoratedBox(
      key: PressableSurface.faceKey,
      decoration: BoxDecoration(color: face, borderRadius: radius),
      child: Padding(
        padding: widget.padding,
        child: Align(
          widthFactor: 1,
          heightFactor: 1,
          child: IconTheme.merge(
            data: IconThemeData(color: foreground),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: foreground),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    // Only transforms change while pressing: nothing is laid out again.
    final surface = Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: ChorusSpace.edge,
          child: AnimatedBuilder(
            animation: _press,
            builder: (context, child) => Transform.translate(
              // Reduced motion: the edge comes up to meet the face instead.
              offset: Offset(
                0,
                reduced ? -ChorusSpace.pressSink * _press.value : 0,
              ),
              child: child,
            ),
            child: DecoratedBox(
              key: PressableSurface.edgeKey,
              decoration: BoxDecoration(color: edge, borderRadius: radius),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: ChorusSpace.edge),
          child: AnimatedBuilder(
            animation: _press,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                0,
                reduced ? 0 : ChorusSpace.pressSink * _press.value,
              ),
              child: child,
            ),
            child: faceBox,
          ),
        ),
        if (_showRing)
          Positioned(
            left: -4,
            top: -4,
            right: -4,
            bottom: -4,
            child: IgnorePointer(
              child: DecoratedBox(
                key: PressableSurface.focusRingKey,
                decoration: BoxDecoration(
                  border: Border.all(color: colors.ink, width: 2),
                  borderRadius: BorderRadius.circular(widget.borderRadius + 4),
                ),
              ),
            ),
          ),
      ],
    );

    return Semantics(
      container: true,
      button: true,
      enabled: _enabled,
      focusable: _enabled,
      focused: _focused,
      label: widget.semanticLabel,
      onTap: _enabled ? _activate : null,
      excludeSemantics: widget.semanticLabel != null,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        includeFocusSemantics: false,
        shortcuts: _keys,
        actions: _actions,
        mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onFocusChange: (focused) => setState(() => _focused = focused),
        onShowFocusHighlight: (show) => setState(() => _showRing = show),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _down() : null,
          onTapUp: _enabled ? (_) => _up() : null,
          onTapCancel: _enabled ? _up : null,
          onTap: _enabled ? _activate : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: ChorusSpace.minTarget,
              minHeight: ChorusSpace.minTarget,
            ),
            child: surface,
          ),
        ),
      ),
    );
  }
}

/// Paper on a dark face, tile ink on a light one: the same in both modes,
/// as the face is.
Color _readableOn(Color face) =>
    ThemeData.estimateBrightnessForColor(face) == Brightness.dark
    ? ChorusColors.light.card
    : tileLabelInk;
