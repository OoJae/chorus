/// The signature move: the board on home flattens as it flies into the
/// child's board.
library;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';

import '../brand/motion.dart';

/// The hero tag that pairs a board's picture on home with the same board's
/// grid on the child's board. Both sides must use it: home wraps its hero in
/// a [BoardHero] with it, and the child's board wraps its grid in a [Hero]
/// with it.
String boardHeroTag(String boardId) => 'board-$boardId';

/// How long the move takes: as long as [ChorusMotion.settle] takes to come
/// to rest.
const Duration boardFlightDuration = Duration(milliseconds: 400);

/// A spring's travel from 0 to 1 over [duration], as a curve, so a route
/// driven by a timed controller still moves on the spring.
///
/// Clamped to 0..1: the settle spring overshoots by half a percent, which
/// cannot be seen, and an animation past 1 would break the curves layered
/// on it.
class SpringCurve extends Curve {
  SpringCurve(SpringDescription spring, Duration duration)
    : _spring = SpringSimulation(spring, 0, 1, 0),
      _seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;

  final SpringSimulation _spring;
  final double _seconds;

  @override
  double transformInternal(double t) =>
      _spring.x(t * _seconds).clamp(0.0, 1.0).toDouble();
}

/// The route to the child's board from home.
///
/// It opens on the [ChorusMotion.settle] spring over [boardFlightDuration],
/// which is also the time and the spring of the hero's flight; the page
/// fades in under the flying board. Under reduced motion it is a
/// [ChorusMotion.reducedFade] crossfade, and home leaves the hero out, so
/// nothing flies.
class BoardRoute<T> extends PageRoute<T> {
  BoardRoute({
    required this.builder,
    this.reducedMotion = false,
    super.settings,
    super.fullscreenDialog = true,
  });

  final WidgetBuilder builder;

  /// True when the system asks for reduced motion: read where the route is
  /// pushed, with `ChorusMotion.reduced`.
  final bool reducedMotion;

  static final Curve _settle = SpringCurve(
    ChorusMotion.settle,
    boardFlightDuration,
  );

  CurvedAnimation? _onSpring;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration =>
      reducedMotion ? ChorusMotion.reducedFade : boardFlightDuration;

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  @override
  Animation<double> createAnimation() {
    final linear = super.createAnimation();
    if (reducedMotion) return linear;
    return _onSpring = CurvedAnimation(parent: linear, curve: _settle);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    // Under the flight the page is there before the board lands.
    opacity: reducedMotion
        ? animation
        : CurvedAnimation(parent: animation, curve: const Interval(0, 0.6)),
    child: child,
  );

  @override
  void dispose() {
    _onSpring?.dispose();
    super.dispose();
  }
}

/// Home's half of the move: a [Hero] round the standing board ([child], a
/// `BoardObject` without a hero tag of its own).
///
/// The flight starts exactly as the board stands on home, in perspective,
/// leaned back and tilted by the thumb, and flattens on the way as the
/// route's settle spring runs, landing as [flat]: the same board with no
/// perspective. On the way back it stands up again.
///
/// Over the last part of the way the board it lands on (the other hero's
/// child, drawn at its own size and scaled) fades in over it, so the landing
/// is not a swap from a square miniature to the full grid.
///
/// The child's board's [Hero] must leave `flightShuttleBuilder` unset, so
/// this one draws the flight in both directions.
class BoardHero extends StatelessWidget {
  const BoardHero({
    super.key,
    required this.tag,
    required this.flat,
    required this.child,
  });

  final Object tag;

  /// The board drawn flat, as it lands.
  final Widget flat;

  final Widget child;

  /// The flying board's transform, for tests.
  @visibleForTesting
  static const Key shuttleKey = ValueKey('BoardHero.shuttle');

  /// The fade of the board the flight lands on, for tests.
  @visibleForTesting
  static const Key landingKey = ValueKey('BoardHero.landing');

  @override
  Widget build(BuildContext context) =>
      Hero(tag: tag, flightShuttleBuilder: _shuttle, child: child);

  Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    // Home is where the flight leaves from on the way in, and lands on the
    // way back. Either way 0 is home and 1 the child's board.
    final home = direction == HeroFlightDirection.push
        ? fromHeroContext
        : toHeroContext;
    final pose = standingPoseOf(home);
    final flat = MediaQuery(
      data: MediaQuery.of(flightContext).copyWith(disableAnimations: true),
      child: this.flat,
    );
    final Widget standing = pose == null
        ? flat
        : FittedBox(
            child: SizedBox.fromSize(
              size: pose.box,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: pose.card.width,
                    height: pose.card.height,
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) => Transform(
                        key: shuttleKey,
                        transform: pose.at(animation.value),
                        child: child,
                      ),
                      child: flat,
                    ),
                  ),
                ],
              ),
            ),
          );
    // Over the last part of the way the child's own board shows through,
    // drawn once at the size it lands at and scaled, so the landing is not
    // a swap from a square miniature to the full grid.
    final landing = _landingOf(
      direction == HeroFlightDirection.push ? toHeroContext : fromHeroContext,
    );
    // The overlay has no Material: without one, text would take the
    // framework's warning style.
    return Material(
      type: MaterialType.transparency,
      child: landing == null
          ? standing
          : Stack(
              fit: StackFit.expand,
              children: [
                FadeTransition(
                  opacity: animation
                      .drive(CurveTween(curve: _handOver))
                      .drive(Tween(begin: 1.0, end: 0.0)),
                  child: standing,
                ),
                FadeTransition(
                  key: landingKey,
                  opacity: animation.drive(CurveTween(curve: _handOver)),
                  child: FittedBox(
                    child: SizedBox.fromSize(
                      size: landing.size,
                      child: landing.child,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// When the flying board hands over to the board it lands on.
  static const Curve _handOver = Interval(0.6, 1);

  /// The board the flight lands on, and its size there; null when it has
  /// not been laid out.
  static ({Size size, Widget child})? _landingOf(BuildContext heroContext) {
    final hero = heroContext.widget;
    final RenderObject? box;
    try {
      box = heroContext.findRenderObject();
    } on Object {
      return null;
    }
    if (hero is! Hero || box is! RenderBox || !box.hasSize) return null;
    if (box.size.isEmpty) return null;
    return (size: box.size, child: hero.child);
  }
}

/// How the board inside a [BoardHero] stands at this moment.
@immutable
class BoardPose {
  const BoardPose({
    required this.box,
    required this.card,
    required this.standing,
    required this.lying,
  });

  /// The hero's own box.
  final Size box;

  /// The tilted box inside it.
  final Size card;

  /// From [card] to [box], as last painted: perspective, lean and tilt.
  final Matrix4 standing;

  /// From [card] to [box] with no turn at all.
  final Matrix4 lying;

  /// [standing] at 0, [lying] at 1, and in between on the way.
  Matrix4 at(double flatness) {
    final t = flatness.clamp(0.0, 1.0);
    final out = Matrix4.zero();
    for (var i = 0; i < 16; i++) {
      out.storage[i] =
          standing.storage[i] + (lying.storage[i] - standing.storage[i]) * t;
    }
    return out;
  }
}

/// How the board under [heroContext] stands, read from what was last
/// painted: the first transform under the hero is the board's own turn.
///
/// Reads the render tree only, so it may be called while a flight is being
/// built. Null when nothing turns the board (reduced motion) or it is not
/// laid out.
BoardPose? standingPoseOf(BuildContext heroContext) {
  final RenderObject? hero;
  try {
    hero = heroContext.findRenderObject();
  } on Object {
    return null;
  }
  if (hero is! RenderBox || !hero.attached || !hero.hasSize) return null;
  RenderTransform? turn;
  void visit(RenderObject child) {
    if (turn != null) return;
    if (child is RenderTransform) {
      turn = child;
      return;
    }
    child.visitChildren(visit);
  }

  hero.visitChildren(visit);
  final found = turn;
  final card = found?.child;
  if (found == null || card == null || !found.hasSize) return null;
  final lying = found.getTransformTo(hero);
  final own = Matrix4.identity();
  found.applyPaintTransform(card, own);
  final standing = lying.clone()..multiply(own);
  if (!standing.storage.every((v) => v.isFinite)) return null;
  return BoardPose(
    box: hero.size,
    card: found.size,
    standing: standing,
    lying: lying,
  );
}
