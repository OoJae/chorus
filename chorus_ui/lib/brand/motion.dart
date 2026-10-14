/// How things move in Chorus: three springs, two curves, and the
/// reduced-motion rule.
library;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Springs are driven from the finger, so every movement can be caught and
/// turned round halfway. Timed motion uses the two curves.
///
/// The child's board stays still: only the press and a 200 ms fade when a
/// new word lands ([wordFade]). The rest is for launch, onboarding, home and
/// the adult screens.
abstract final class ChorusMotion {
  /// Tiles and buttons sinking on touch-down and coming back on release:
  /// about 0.18 s, no bounce.
  static final SpringDescription press = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 900,
    ratio: 0.9,
  );

  /// Sheets, the hero's tilt coming back, the shared-element move, a tray
  /// card flying to its cell: about 0.4 s.
  static final SpringDescription settle = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 380,
    ratio: 0.86,
  );

  /// The launch reveal only, once: a visible bounce.
  static final SpringDescription chorus = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 220,
    ratio: 0.68,
  );

  /// Things arriving, over [entranceShort] to [entranceLong].
  static const Curve entrance = Cubic(0.16, 1, 0.3, 1);
  static const Duration entranceShort = Duration(milliseconds: 300);
  static const Duration entranceLong = Duration(milliseconds: 450);

  /// Things switching between two states, over [toggleDuration].
  static const Curve toggle = Cubic(0.65, 0, 0.35, 1);
  static const Duration toggleDuration = Duration(milliseconds: 200);

  /// A new word appearing in place on the child's board: a fade, never a
  /// slide.
  static const Duration wordFade = Duration(milliseconds: 200);

  /// What every spring and tilt becomes when the system asks for reduced
  /// motion: a crossfade this long.
  static const Duration reducedFade = Duration(milliseconds: 150);

  /// Whether the system asks for reduced motion around [context]. False
  /// where there is no MediaQuery.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [normal], or the [reducedFade] crossfade under reduced motion.
  static Duration duration(BuildContext context, Duration normal) =>
      reduced(context) ? reducedFade : normal;

  /// Runs [controller] to [target] on [spring], starting from where it is
  /// and as fast as it is already moving, so a spring caught halfway turns
  /// round instead of starting again.
  static TickerFuture springTo(
    AnimationController controller,
    SpringDescription spring,
    double target, {
    double? velocity,
  }) => controller.animateWith(
    SpringSimulation(
      spring,
      controller.value,
      target,
      velocity ?? controller.velocity,
    ),
  );
}
