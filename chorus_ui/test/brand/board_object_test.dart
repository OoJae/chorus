// The board as an object: it reports the tapped word, stands in real
// perspective, tilts toward the thumb and springs back, leans back with the
// scroll, and lies flat under reduced motion.
import 'dart:math' as math;

import 'package:chorus_ui/brand/board_object.dart';
import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The onboarding board: "I want more" over "help go stop".
const _cells = [
  BoardCell(row: 0, col: 0, label: 'I', family: TileFamily.person),
  BoardCell(row: 0, col: 1, label: 'want', family: TileFamily.action),
  BoardCell(row: 0, col: 2, label: 'more', family: TileFamily.describe),
  BoardCell(row: 1, col: 0, label: 'help', family: TileFamily.action),
  BoardCell(row: 1, col: 1, label: 'go', family: TileFamily.action),
  BoardCell(row: 1, col: 2, label: 'stop', family: TileFamily.action),
];

Future<void> _pump(
  WidgetTester tester, {
  ValueChanged<BoardCell>? onTileTap,
  ValueListenable<double>? lean,
  bool reduced = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: chorusTheme(),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: BoardObject(
                rows: 2,
                cols: 3,
                cells: _cells,
                lean: lean,
                onTileTap: onTileTap,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

Finder _word(String label) => find.text(label);

/// The tile's drawn rectangle, as projected on screen.
Rect _tile(WidgetTester tester, String label) => tester.getRect(
  find.ancestor(of: _word(label), matching: find.byType(Positioned)).first,
);

Matrix4 _tilt(WidgetTester tester) =>
    tester.widget<Transform>(find.byKey(BoardObject.tiltKey)).transform;

void main() {
  late List<ChorusHaptic> felt;
  setUp(() {
    felt = [];
    ChorusHaptics.sink = felt.add;
  });
  tearDown(() => ChorusHaptics.sink = null);

  testWidgets('a tap on a tile reports that cell, with a light tap felt', (
    tester,
  ) async {
    final tapped = <BoardCell>[];
    await _pump(tester, onTileTap: tapped.add);
    await tester.tap(_word('want'));
    await tester.pumpAndSettle();
    await tester.tap(_word('stop'));
    await tester.pumpAndSettle();
    expect(tapped.map((c) => (c.label, c.row, c.col)), [
      ('want', 0, 1),
      ('stop', 1, 2),
    ]);
    expect(felt, [ChorusHaptic.wordTapped, ChorusHaptic.wordTapped]);
  });

  testWidgets('each tile is a button a screen reader can name', (tester) async {
    final semantics = tester.ensureSemantics();
    final tapped = <BoardCell>[];
    await _pump(tester, onTileTap: tapped.add);
    expect(
      tester.getSemantics(find.bySemanticsLabel('more')),
      isSemantics(label: 'more', isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('it stands in real perspective, its tiles at different depths', (
    tester,
  ) async {
    await _pump(tester);
    final matrix = _tilt(tester);
    // The perspective row, turned with the card: its length is the depth
    // strength.
    final perspective = math.sqrt(
      math.pow(matrix.entry(3, 0), 2) +
          math.pow(matrix.entry(3, 1), 2) +
          math.pow(matrix.entry(3, 2), 2),
    );
    expect(perspective, closeTo(0.0012, 1e-9));
    final depths = {
      for (final transform in tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(BoardObject),
          matching: find.byType(Transform),
        ),
      ))
        transform.transform.getTranslation().z,
    };
    expect(depths.length, greaterThan(1));
    expect(depths.every((z) => z.abs() <= 8), isTrue);
  });

  testWidgets('held at the right, the board dips there by up to 8 degrees, '
      'then springs back', (tester) async {
    await _pump(tester);
    final rest = _tilt(tester).clone();
    final restRatio = _tile(tester, 'more').height / _tile(tester, 'I').height;

    final board = tester.getRect(find.byType(BoardObject));
    final gesture = await tester.startGesture(
      Offset(board.right - 2, board.center.dy),
    );
    await tester.pumpAndSettle();
    final tiltedRatio =
        _tile(tester, 'more').height / _tile(tester, 'I').height;
    // The right column is pushed away, so it looks smaller than the left.
    expect(tiltedRatio, lessThan(1));
    expect(tiltedRatio, lessThan(restRatio));

    // The turn about the vertical axis is the tilt, at most 8 degrees.
    final turned = _tilt(tester);
    final yaw = math.asin(turned.entry(0, 2).clamp(-1.0, 1.0));
    expect(yaw.abs(), greaterThan(4 * math.pi / 180));
    expect(yaw.abs(), lessThanOrEqualTo(8 * math.pi / 180 + 1e-6));

    await gesture.cancel();
    await tester.pumpAndSettle();
    final back = _tilt(tester);
    for (var i = 0; i < 16; i++) {
      expect(back.storage[i], closeTo(rest.storage[i], 1e-4));
    }
  });

  testWidgets('a drag that lets go still springs back to rest', (tester) async {
    await _pump(tester);
    final rest = _tilt(tester).clone();
    final board = tester.getRect(find.byType(BoardObject));
    await tester.timedDragFrom(
      board.center,
      const Offset(-120, 0),
      const Duration(milliseconds: 120),
    );
    // Let go, it is still carried by the speed of the flick.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));
    expect(_tilt(tester).storage, isNot(equals(rest.storage)));
    await tester.pumpAndSettle();
    for (var i = 0; i < 16; i++) {
      expect(_tilt(tester).storage[i], closeTo(rest.storage[i], 1e-4));
    }
  });

  testWidgets('it leans back and shrinks as the lean goes up, without '
      'being built again', (tester) async {
    final lean = ValueNotifier<double>(0);
    addTearDown(lean.dispose);
    await _pump(tester, lean: lean);
    final upright = _tile(tester, 'go');

    lean.value = 1;
    await tester.pump();
    final leaned = _tile(tester, 'go');
    expect(leaned.height, lessThan(upright.height * 0.95));
    expect(leaned.width, lessThan(upright.width));

    lean.value = 0;
    await tester.pump();
    expect(_tile(tester, 'go').height, closeTo(upright.height, 0.01));
  });

  testWidgets('under reduced motion it lies flat and does not tilt, and taps '
      'still work', (tester) async {
    final tapped = <BoardCell>[];
    final lean = ValueNotifier<double>(1);
    addTearDown(lean.dispose);
    await _pump(tester, onTileTap: tapped.add, lean: lean, reduced: true);

    void expectFlat() {
      for (final transform in tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(BoardObject),
          matching: find.byType(Transform),
        ),
      )) {
        final m = transform.transform;
        expect(m.entry(3, 2), 0, reason: 'no perspective');
        expect(m.getTranslation().z, 0, reason: 'no depth');
        expect(m.entry(0, 2), 0, reason: 'no turn');
        expect(m.entry(1, 2), 0, reason: 'no turn');
      }
    }

    expect(find.byKey(BoardObject.tiltKey), findsNothing);
    expectFlat();

    final board = tester.getRect(find.byType(BoardObject));
    final gesture = await tester.startGesture(
      Offset(board.right - 2, board.center.dy),
    );
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expectFlat();
    await gesture.cancel();

    await tester.tap(_word('go'));
    await tester.pump();
    expect(tapped.single.label, 'go');
  });

  testWidgets('as one button it takes the keyboard: Tab reaches it, Enter '
      'and Space open it, and an ink ring shows it', (tester) async {
    final semantics = tester.ensureSemantics();
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: chorusTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: BoardObject(
                rows: 2,
                cols: 3,
                cells: _cells,
                semanticLabel: "Maya's board",
                onTap: () => opened++,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(BoardObject.focusRingKey), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.byKey(BoardObject.focusRingKey), findsOneWidget);
    final ring = tester.widget<DecoratedBox>(
      find.byKey(BoardObject.focusRingKey),
    );
    final border = (ring.decoration as BoxDecoration).border! as Border;
    expect(border.top.color, ChorusColors.light.ink);
    expect(border.top.width, 2);
    expect(
      tester.getSemantics(find.bySemanticsLabel("Maya's board")),
      isSemantics(
        label: "Maya's board",
        isButton: true,
        isFocusable: true,
        isFocused: true,
        hasTapAction: true,
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(opened, 2);

    // A pointer tap still opens it, and the ring is for the keyboard only.
    await tester.tap(find.byType(BoardObject));
    await tester.pumpAndSettle();
    expect(opened, 3);
    expect(find.byKey(BoardObject.focusRingKey), findsNothing);
    semantics.dispose();
  });

  testWidgets('a board whose tiles speak is not itself a button', (
    tester,
  ) async {
    await _pump(tester, onTileTap: (_) {});
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.byKey(BoardObject.focusRingKey), findsNothing);
  });

  testWidgets('with a hero tag the card is the shared element', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: chorusTheme(),
        home: const Scaffold(
          body: BoardObject(
            rows: 2,
            cols: 3,
            cells: _cells,
            heroTag: 'maya-board',
          ),
        ),
      ),
    );
    expect(tester.widget<Hero>(find.byType(Hero)).tag, 'maya-board');
  });
}
