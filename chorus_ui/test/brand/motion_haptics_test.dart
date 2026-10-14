// The motion tokens, the reduced-motion rule, and haptics as named moments.
import 'dart:math' as math;

import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/brand/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Seconds until [spring], pulled from 0 to 1, stays within 1% of 1.
double _settles(SpringDescription spring) {
  final simulation = SpringSimulation(spring, 0, 1, 0);
  var last = 0.0;
  for (var t = 0.0; t < 3; t += 0.001) {
    if ((simulation.x(t) - 1).abs() > 0.01) last = t;
  }
  return last;
}

double _overshoot(SpringDescription spring) {
  final simulation = SpringSimulation(spring, 0, 1, 0);
  var most = 0.0;
  for (var t = 0.0; t < 3; t += 0.001) {
    most = math.max(most, simulation.x(t));
  }
  return most - 1;
}

void main() {
  group('springs', () {
    test('stiffness and damping ratio from the plan', () {
      void check(SpringDescription spring, double stiffness, double ratio) {
        expect(spring.mass, 1);
        expect(spring.stiffness, stiffness);
        expect(spring.damping, closeTo(ratio * 2 * math.sqrt(stiffness), 1e-9));
      }

      check(ChorusMotion.press, 900, 0.9);
      check(ChorusMotion.settle, 380, 0.86);
      check(ChorusMotion.chorus, 220, 0.68);
    });

    test('press is quick and does not bounce; chorus bounces visibly', () {
      expect(_settles(ChorusMotion.press), lessThan(0.25));
      expect(_settles(ChorusMotion.settle), lessThan(0.5));
      expect(_overshoot(ChorusMotion.press), lessThan(0.01));
      expect(_overshoot(ChorusMotion.chorus), greaterThan(0.05));
    });

    testWidgets('springTo turns round from where it is, at its speed', (
      tester,
    ) async {
      final controller = AnimationController(vsync: const TestVSync());
      addTearDown(controller.dispose);
      ChorusMotion.springTo(controller, ChorusMotion.settle, 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final halfway = controller.value;
      expect(halfway, inExclusiveRange(0, 1));
      expect(controller.velocity, greaterThan(0));

      ChorusMotion.springTo(controller, ChorusMotion.settle, 0);
      expect(controller.value, halfway, reason: 'no jump');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      // Still carried on a little by its speed, then back.
      await tester.pump(const Duration(seconds: 1));
      expect(controller.value, closeTo(0, 0.01));
    });
  });

  test('the curves and their durations', () {
    expect(ChorusMotion.entrance, const Cubic(0.16, 1, 0.3, 1));
    expect(ChorusMotion.toggle, const Cubic(0.65, 0, 0.35, 1));
    expect(ChorusMotion.entranceShort, const Duration(milliseconds: 300));
    expect(ChorusMotion.entranceLong, const Duration(milliseconds: 450));
    expect(ChorusMotion.toggleDuration, const Duration(milliseconds: 200));
    expect(ChorusMotion.wordFade, const Duration(milliseconds: 200));
  });

  testWidgets('reduced motion is what the system asks for, and every '
      'movement becomes a 150 ms crossfade', (tester) async {
    late bool reduced;
    late Duration duration;
    Future<void> pumpWith(bool disable) => tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: disable),
        child: Builder(
          builder: (context) {
            reduced = ChorusMotion.reduced(context);
            duration = ChorusMotion.duration(
              context,
              ChorusMotion.entranceLong,
            );
            return const SizedBox();
          },
        ),
      ),
    );

    await pumpWith(true);
    expect(reduced, isTrue);
    expect(duration, const Duration(milliseconds: 150));

    await pumpWith(false);
    expect(reduced, isFalse);
    expect(duration, ChorusMotion.entranceLong);
  });

  testWidgets('with no MediaQuery, motion is not reduced', (tester) async {
    late bool reduced;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          reduced = ChorusMotion.reduced(context);
          return const SizedBox();
        },
      ),
    );
    expect(reduced, isFalse);
  });

  group('haptics', () {
    tearDown(() => ChorusHaptics.sink = null);

    test('every named moment reaches the injected sink, and none plays '
        'nothing', () {
      final felt = <ChorusHaptic>[];
      ChorusHaptics.sink = felt.add;
      ChorusHaptics.wordTapped();
      ChorusHaptics.sentenceSpoken();
      ChorusHaptics.leftBoard();
      ChorusHaptics.wordAdded();
      ChorusHaptics.wordPlaced();
      ChorusHaptics.clashArrived();
      ChorusHaptics.tabChanged();
      ChorusHaptics.failed();
      ChorusHaptics.play(null);
      expect(felt, ChorusHaptic.values);
    });

    testWidgets('on the device each moment plays its own feedback', (
      tester,
    ) async {
      final played = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            played.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      for (final moment in ChorusHaptic.values) {
        ChorusHaptics.play(moment);
      }
      await tester.pump();
      expect(played, [
        'HapticFeedbackType.lightImpact', // word tapped
        'HapticFeedbackType.mediumImpact', // sentence spoken
        'HapticFeedbackType.heavyImpact', // left the board
        'HapticFeedbackType.mediumImpact', // word added
        'HapticFeedbackType.mediumImpact', // word placed
        'HapticFeedbackType.heavyImpact', // clash arrived
        'HapticFeedbackType.selectionClick', // tab changed
        null, // failed: a plain vibration
      ]);
    });

    testWidgets('a platform that refuses haptics is not an error', (
      tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => throw PlatformException(code: 'unavailable'),
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      ChorusHaptics.failed();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
