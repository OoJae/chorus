// The signature move: the board on home flies into the child's board,
// flattening on the settle spring as it goes, and stands up again on the
// way back. Under reduced motion nothing flies: the page crossfades.
import 'dart:math' as math;

import 'package:chorus_ui/brand/board_object.dart';
import 'package:chorus_ui/brand/motion.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/home/home.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

/// How much perspective [m] has: the length of its bottom row's turn.
double _depth(Matrix4 m) => math.sqrt(
  math.pow(m.entry(3, 0), 2) +
      math.pow(m.entry(3, 1), 2) +
      math.pow(m.entry(3, 2), 2),
);

const Key _grid = ValueKey('child board grid');

/// Home with the hero, and a page standing in for the child's board whose
/// grid is the other half of the hero.
Future<BoardStore> _pumpHome(
  WidgetTester tester, {
  bool reduced = false,
}) async {
  final store = FakeBoardStore.seeded();
  final tag = boardHeroTag(heroBoardOf(store)!.id);
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: chorusTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 320,
              height: 323,
              child: HomeHero(
                store: store,
                childName: 'Maya',
                onOpen: () => Navigator.of(context).push(
                  BoardRoute<void>(
                    reducedMotion: ChorusMotion.reduced(context),
                    builder: (routeContext) => Scaffold(
                      body: Column(
                        children: [
                          const SizedBox(height: 200),
                          Expanded(
                            child: Hero(
                              tag: tag,
                              child: const SizedBox.expand(key: _grid),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(routeContext).pop(),
                            child: const Text('Leave'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return store;
}

void main() {
  test('the settle spring as a curve starts at 0, ends at 1 and never '
      'leaves 0..1', () {
    final curve = SpringCurve(ChorusMotion.settle, boardFlightDuration);
    expect(curve.transform(0), 0);
    expect(curve.transform(1), 1);
    for (var i = 0; i <= 100; i++) {
      final v = curve.transform(i / 100);
      expect(v, inInclusiveRange(0, 1));
    }
    // Most of the way there in the first half, as a spring is.
    expect(curve.transform(0.5), greaterThan(0.85));
    // And it is the settle spring itself.
    final spring = SpringSimulation(ChorusMotion.settle, 0, 1, 0);
    expect(curve.transform(0.25), closeTo(spring.x(0.1), 1e-9));
  });

  test('the route takes the settle spring\'s time, or a short crossfade '
      'under reduced motion', () {
    final normal = BoardRoute<void>(builder: (_) => const SizedBox());
    final reduced = BoardRoute<void>(
      builder: (_) => const SizedBox(),
      reducedMotion: true,
    );
    expect(normal.transitionDuration, boardFlightDuration);
    expect(normal.reverseTransitionDuration, boardFlightDuration);
    expect(reduced.transitionDuration, ChorusMotion.reducedFade);
    expect(normal.fullscreenDialog, isTrue);
    expect(boardHeroTag('abc'), 'board-abc');
  });

  testWidgets('the board leaves home standing, flattens on the way, and '
      'lands flat on the child\'s board', (tester) async {
    await _pumpHome(tester);
    // As it stands on home: in perspective.
    final home = tester.element(find.byType(Hero));
    final pose = standingPoseOf(home)!;
    expect(_depth(pose.standing), greaterThan(0.001));
    expect(_depth(pose.lying), 0);

    await tester.tap(find.byKey(HomeHero.boardKey));
    await tester.pump();
    await tester.pump();
    final first = tester
        .widget<Transform>(find.byKey(BoardHero.shuttleKey))
        .transform;
    // Leaves as it stood.
    expect(_depth(first), greaterThan(_depth(pose.standing) * 0.8));

    await tester.pump(const Duration(milliseconds: 120));
    final middle = tester
        .widget<Transform>(find.byKey(BoardHero.shuttleKey))
        .transform;
    expect(_depth(middle), lessThan(_depth(first)));
    expect(_depth(middle), greaterThan(0));

    await tester.pumpAndSettle();
    expect(find.byKey(BoardHero.shuttleKey), findsNothing);
    expect(find.byKey(_grid), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('just before it lands it is all but flat, and as large as the '
      'grid', (tester) async {
    await _pumpHome(tester);
    await tester.tap(find.byKey(HomeHero.boardKey));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 370));
    final late = tester
        .widget<Transform>(find.byKey(BoardHero.shuttleKey))
        .transform;
    expect(_depth(late), lessThan(0.0001));
    // The flying board has grown toward the grid's width.
    final shuttle = tester.getRect(find.byKey(BoardHero.shuttleKey));
    expect(shuttle.width, greaterThan(320));
    await tester.pumpAndSettle();
  });

  testWidgets('over the last part of the way the board it lands on fades in '
      'over the flying one, so the landing is not a swap', (tester) async {
    await _pumpHome(tester);
    await tester.tap(find.byKey(HomeHero.boardKey));
    await tester.pump();
    await tester.pump();
    double landing() => tester
        .widget<FadeTransition>(find.byKey(BoardHero.landingKey))
        .opacity
        .value;
    // The child's board's own grid is drawn in the flight, at its size.
    expect(
      find.descendant(
        of: find.byKey(BoardHero.landingKey),
        matching: find.byKey(_grid),
      ),
      findsOneWidget,
    );
    expect(landing(), 0);
    await tester.pump(const Duration(milliseconds: 360));
    expect(landing(), greaterThan(0.5));
    final standing = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byKey(BoardHero.shuttleKey),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(standing.opacity.value, closeTo(1 - landing(), 1e-9));
    await tester.pumpAndSettle();
    expect(find.byKey(BoardHero.landingKey), findsNothing);
  });

  testWidgets('on the way back it stands up again', (tester) async {
    await _pumpHome(tester);
    await tester.tap(find.byKey(HomeHero.boardKey));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leave'));
    await tester.pump();
    await tester.pump();
    final leaving = tester
        .widget<Transform>(find.byKey(BoardHero.shuttleKey))
        .transform;
    await tester.pump(const Duration(milliseconds: 300));
    final arriving = tester
        .widget<Transform>(find.byKey(BoardHero.shuttleKey))
        .transform;
    expect(_depth(arriving), greaterThan(_depth(leaving)));
    await tester.pumpAndSettle();
    expect(find.byKey(HomeHero.boardKey), findsOneWidget);
    expect(find.byKey(BoardObject.tiltKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('under reduced motion nothing flies: the page crossfades in '
      '150 ms', (tester) async {
    await _pumpHome(tester, reduced: true);
    expect(find.byType(Hero), findsNothing);
    await tester.tap(find.byKey(HomeHero.boardKey));
    await tester.pump();
    expect(find.byKey(BoardHero.shuttleKey), findsNothing);
    await tester.pump(const Duration(milliseconds: 75));
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byKey(_grid),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 80));
    expect(fade.opacity.value, 1);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
