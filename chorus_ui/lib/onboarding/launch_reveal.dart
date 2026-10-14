/// The launch: the chorus reveal over the app's first screen, once.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../brand/motion.dart';
import '../brand/reveal.dart';
import '../brand/tokens.dart';

/// Plays the [ChorusReveal] over [child] once for the life of this widget,
/// then fades it away so [child] comes in. Wrapped round the app, that is
/// once per cold start.
///
/// [child] is built from the first frame, under the reveal: whatever it
/// opens (the saved sign-in, the boards on this device) starts at once, so
/// the reveal costs the child's board no time. While the reveal is up,
/// touches stop at it and a screen reader hears only "Chorus".
///
/// The reveal starts from the mark at the size and place the Android
/// system splash leaves it ([splashMark] dp, in the middle of the screen),
/// so the hand-over from the splash does not jump. Under reduced motion the
/// reveal shows its last frame and then crossfades away in
/// [ChorusMotion.reducedFade].
class LaunchReveal extends StatefulWidget {
  const LaunchReveal({super.key, required this.child, this.play = true});

  final Widget child;

  /// False shows [child] at once, with no reveal.
  final bool play;

  /// The side of the mark on the Android launch screen: a 288 dp picture
  /// with the mark drawn 136 dp wide (see `docs/brand/render.js`).
  static const double splashMark = 136;

  /// How much of the reveal's square the mark takes at its first frame.
  static const double _markShare = ChorusReveal.markShare;

  /// The side of the reveal on a screen of [size]: as large as the splash
  /// mark needs, and never wider than the screen less a margin.
  static double revealSizeFor(Size size) => math.max(
    0,
    math.min(splashMark / _markShare, size.shortestSide - 2 * 16),
  );

  /// Whether the reveal round [context] is over, or there is none. A screen
  /// holds its own entrance until then; [context] is rebuilt when it ends.
  static bool isOver(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RevealScope>()?.over ?? true;

  /// The layer the reveal is drawn on, for tests.
  @visibleForTesting
  static const Key overlayKey = ValueKey('LaunchReveal.overlay');

  @override
  State<LaunchReveal> createState() => _LaunchRevealState();
}

class _LaunchRevealState extends State<LaunchReveal>
    with SingleTickerProviderStateMixin {
  // 1 while the reveal covers the app, 0 once it has faded away.
  late final AnimationController _cover = AnimationController(
    vsync: this,
    value: 1,
  );

  late bool _over = !widget.play;
  late bool _gone = !widget.play;

  @override
  void dispose() {
    _cover.dispose();
    super.dispose();
  }

  void _revealDone() {
    if (!mounted || _over) return;
    setState(() => _over = true);
    _cover.duration = ChorusMotion.duration(
      context,
      ChorusMotion.entranceShort,
    );
    _cover.animateBack(0, curve: ChorusMotion.entrance).whenCompleteOrCancel(
      () {
        if (mounted) setState(() => _gone = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // The same tree under the reveal and after it, so the app underneath
    // keeps its state when the reveal goes.
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.topLeft,
      children: [
        _RevealScope(
          over: _over,
          child: ExcludeSemantics(excluding: !_over, child: widget.child),
        ),
        if (!_gone)
          Positioned.fill(
            key: LaunchReveal.overlayKey,
            child: FadeTransition(
              opacity: _cover,
              child: AbsorbPointer(
                child: ColoredBox(
                  color: ChorusColors.of(context).card,
                  child: Center(
                    child: ChorusReveal(
                      size: LaunchReveal.revealSizeFor(
                        MediaQuery.sizeOf(context),
                      ),
                      onDone: _revealDone,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RevealScope extends InheritedWidget {
  const _RevealScope({required this.over, required super.child});

  final bool over;

  @override
  bool updateShouldNotify(_RevealScope oldWidget) => oldWidget.over != over;
}
