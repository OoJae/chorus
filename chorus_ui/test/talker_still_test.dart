// The child's board stays still: the only motion on it is a tile sinking
// under the finger on the press spring and a new word fading in where it
// lands. No tilt, no slide, no bounce, nothing that keeps running.
import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/brand/motion.dart';
import 'package:chorus_ui/brand/pressable_surface.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _phone = Size(360, 800);

Future<void> _pump(
  WidgetTester tester,
  FakeBoardStore store, {
  bool reduced = false,
}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: chorusTheme(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: TalkerScreen(
            store: store,
            speech: FakeSpeech(),
            sync: FakeSyncStatus(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder _tile(String label) =>
    find.byWidgetPredicate((w) => w is TileView && w.tile.label == label);

Finder _face(String label) => find.descendant(
  of: _tile(label),
  matching: find.byKey(PressableSurface.faceKey),
);

/// Where every tile is, by its label.
Map<String, Rect> _tiles(WidgetTester tester) => {
  for (final element in find.byType(TileView).evaluate())
    (element.widget as TileView).tile.label: tester.getRect(
      find.byWidget(element.widget),
    ),
};

/// The opacity the arrival fade gives the tile labelled [label].
double _opacity(WidgetTester tester, String label) => tester
    .widget<FadeTransition>(
      find
          .ancestor(of: _tile(label), matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

/// True when no transform on the board turns, tilts or scales anything: the
/// only transforms allowed are straight moves (the press). The Scaffold's
/// own, for a floating button the board does not have, are not counted.
bool _flat(WidgetTester tester) => tester
    .widgetList<Transform>(
      find.descendant(
        of: find.byType(SafeArea),
        matching: find.byType(Transform),
      ),
    )
    .every((t) {
      final m = t.transform;
      return m.getMaxScaleOnAxis() == 1 &&
          m.entry(0, 0) == 1 &&
          m.entry(1, 1) == 1 &&
          m.entry(0, 1) == 0 &&
          m.entry(1, 0) == 0 &&
          m.entry(3, 2) == 0;
    });

void main() {
  late List<ChorusHaptic> felt;
  setUp(() {
    felt = [];
    ChorusHaptics.sink = felt.add;
  });
  tearDown(() => ChorusHaptics.sink = null);

  testWidgets('an idle board asks for no frames at all', (tester) async {
    await _pump(tester, FakeBoardStore.seeded());
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(_flat(tester), isTrue, reason: 'no tilt, no perspective');
  });

  testWidgets('a tap runs the press and nothing else: the tile sinks 2 dp, '
      'comes back within half a second, is felt, and no other tile moves', (
    tester,
  ) async {
    await _pump(tester, FakeBoardStore.seeded());
    final before = _tiles(tester);
    final rest = tester.getRect(_face('want'));

    final finger = await tester.startGesture(tester.getCenter(_tile('want')));
    var frames = 0;
    for (; frames < 30 && tester.hasRunningAnimations; frames++) {
      await tester.pump(const Duration(milliseconds: 16));
      // Every other tile is exactly where it was, at every frame.
      final now = _tiles(tester);
      for (final label in before.keys) {
        expect(now[label], before[label], reason: label);
      }
      expect(_flat(tester), isTrue);
    }
    expect(
      tester.getRect(_face('want')).top - rest.top,
      closeTo(ChorusSpace.pressSink, 0.05),
      reason: 'sunk onto its thin edge',
    );
    expect(tester.getRect(_face('want')).left, rest.left, reason: 'straight');

    await finger.up();
    final settled = await tester.pumpAndSettle(
      const Duration(milliseconds: 16),
    );
    expect(settled * 16, lessThan(500), reason: 'the press spring, no more');
    expect(tester.getRect(_face('want')), rest);
    expect(_tiles(tester), before);
    expect(felt, [ChorusHaptic.wordTapped]);
    // Settled means settled: nothing keeps asking for frames.
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a word that arrives fades in where it lands over 200 ms, '
      'without a slide, without a haptic, and nothing else moves', (
    tester,
  ) async {
    final store = FakeBoardStore.seeded(leaveEmpty: const {(5, 5)});
    await _pump(tester, store);
    final before = _tiles(tester);
    // Merges wait for the board to be quiet for 2 seconds, timed on a real
    // clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2100)),
    );

    await store.addTile(
      boardId: store.homeBoardId,
      row: 5,
      col: 5,
      label: 'swing',
    );
    await tester.pump();
    expect(_tile('swing'), findsOneWidget);
    final landed = tester.getRect(_tile('swing'));
    expect(_opacity(tester, 'swing'), 0);

    await tester.pump(const Duration(milliseconds: 100));
    final halfway = _opacity(tester, 'swing');
    expect(halfway, greaterThan(0));
    expect(halfway, lessThan(1));
    expect(tester.getRect(_tile('swing')), landed, reason: 'no slide');
    for (final label in before.keys) {
      expect(_opacity(tester, label), 1, reason: label);
    }

    await tester.pump(const Duration(milliseconds: 100));
    expect(_opacity(tester, 'swing'), 1, reason: '200 ms in all');
    // An animation reports itself done on the frame after its last.
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.getRect(_tile('swing')), landed);
    final after = _tiles(tester)..remove('swing');
    expect(after, before, reason: 'every other word kept its place');
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.hasRunningAnimations, isFalse);
    expect(felt, isEmpty, reason: 'never a haptic when a word arrives');
  });

  testWidgets('going to another board shows it at once, with no fade, and '
      'is felt as a tab change', (tester) async {
    final store = FakeBoardStore.seeded();
    await store.addTile(
      boardId: store.wordsBoardId,
      row: 0,
      col: 0,
      label: 'Grandma',
    );
    await _pump(tester, store);
    await tester.tap(find.text('My words'));
    await tester.pump();
    expect(_tile('Grandma'), findsOneWidget);
    expect(_opacity(tester, 'Grandma'), 1);
    expect(felt, [ChorusHaptic.tabChanged]);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  group('under reduced motion', () {
    testWidgets('a tap changes the edge at once and runs no animation', (
      tester,
    ) async {
      await _pump(tester, FakeBoardStore.seeded(), reduced: true);
      final rest = tester.getRect(_face('want'));
      final finger = await tester.startGesture(tester.getCenter(_tile('want')));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.getRect(_face('want')), rest, reason: 'the face stays');
      await finger.up();
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(felt, [ChorusHaptic.wordTapped]);
    });

    testWidgets('a word that arrives crossfades in 150 ms', (tester) async {
      final store = FakeBoardStore.seeded(leaveEmpty: const {(0, 0)});
      await _pump(tester, store, reduced: true);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 2100)),
      );
      await store.addTile(
        boardId: store.homeBoardId,
        row: 0,
        col: 0,
        label: 'swing',
      );
      await tester.pump();
      expect(_opacity(tester, 'swing'), 0);
      await tester.pump(ChorusMotion.reducedFade);
      expect(_opacity(tester, 'swing'), 1);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
