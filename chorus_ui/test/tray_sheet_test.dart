// "Needs a home": a sheet along the bottom of a phone, the column beside the
// board on a wide screen. A clash arriving lifts the sheet once and is felt
// once; "Place in next free spot" flies the card into its cell on the settle
// spring and is felt as a placed word.
import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/editor/tile_flight.dart';
import 'package:chorus_ui/editor/tray_panel.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _phone = Size(360, 800);
const _wide = Size(1440, 900);

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = _phone,
  bool reduced = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: chorusTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!,
      ),
      home: screen,
    ),
  );
}

/// The visible part of the phone's sheet.
Rect _sheet(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byKey(EditorScreen.traySheetKey),
        matching: find.byType(Material),
      )
      .first,
);

/// The tile of [label] in the editor's grid.
Finder _inGrid(String label) => find.descendant(
  of: find.byType(EditorGrid),
  matching: find.ancestor(
    of: find.text(label),
    matching: find.byType(TileView),
  ),
);

/// Whether [finder] is drawn: no fully transparent Opacity above it.
bool _drawn(WidgetTester tester, Finder finder) => tester
    .widgetList<Opacity>(
      find.ancestor(of: finder, matching: find.byType(Opacity)),
    )
    .every((opacity) => opacity.opacity > 0);

void main() {
  final felt = <ChorusHaptic>[];
  setUp(() {
    felt.clear();
    ChorusHaptics.sink = felt.add;
  });
  tearDown(() => ChorusHaptics.sink = null);

  group('on a phone', () {
    testWidgets('the tray is a sheet along the bottom, titled in the status '
        'face with its count', (tester) async {
      final store = FakeBoardStore.seeded(leaveEmpty: const {(5, 5)})
        ..remoteConflict(row: 0, col: 0, label: 'playground');
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));

      final title = find.text('Needs a home · 1');
      expect(title, findsOneWidget);
      final style = tester.renderObject<RenderParagraph>(title).text.style!;
      expect(style.fontFamily, ChorusType.status.fontFamily);
      final sheet = _sheet(tester);
      expect(sheet.bottom, _phone.height);
      expect(sheet.top, greaterThan(_phone.height * 0.8), reason: 'resting');
      expect(
        tester.getRect(title).top,
        greaterThanOrEqualTo(sheet.top),
        reason: 'the heading shows while it rests',
      );
      // The board is above it, whole and untouched.
      expect(_inGrid('playground'), findsNothing, reason: 'still waiting');
      expect(tester.getRect(find.byType(EditorGrid)).top, lessThan(sheet.top));
    });

    testWidgets('its heading opens and closes it, also for a screen reader', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final store = FakeBoardStore.seeded(leaveEmpty: const {(5, 5)})
        ..remoteConflict(row: 0, col: 0, label: 'playground');
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
      final resting = _sheet(tester).top;

      await tester.tap(find.byKey(TrayPanel.headingKey));
      await tester.pumpAndSettle();
      expect(_sheet(tester).top, lessThan(resting - 200));
      expect(
        tester.getRect(find.text('Place in next free spot')).bottom,
        lessThanOrEqualTo(_phone.height),
      );

      tester.semantics.tap(find.semantics.byLabel('Needs a home · 1'));
      await tester.pumpAndSettle();
      expect(_sheet(tester).top, moreOrLessEquals(resting, epsilon: 1));
      semantics.dispose();
    });

    testWidgets('a clash arriving lifts the sheet once and is felt once', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded(leaveEmpty: const {(5, 5)});
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
      final resting = _sheet(tester).top;
      expect(find.text('Needs a home'), findsOneWidget);

      store.remoteConflict(row: 0, col: 0, label: 'playground');
      await tester.pump();
      // On the settle spring: moving, not there yet.
      await tester.pump(const Duration(milliseconds: 60));
      final moving = _sheet(tester).top;
      expect(moving, lessThan(resting));
      await tester.pumpAndSettle();
      final lifted = _sheet(tester).top;
      expect(lifted, lessThan(moving));
      expect(felt, [ChorusHaptic.clashArrived]);
      // Its card is in view, under the heading.
      expect(
        tester.getRect(find.text('Place in next free spot')).bottom,
        lessThanOrEqualTo(_phone.height),
      );

      // Put down again, then other changes arrive: no second lift.
      await tester.tap(find.byKey(TrayPanel.headingKey));
      await tester.pumpAndSettle();
      expect(_sheet(tester).top, moreOrLessEquals(resting, epsilon: 1));
      await store.addTile(
        boardId: store.wordsBoardId,
        row: 0,
        col: 0,
        label: 'Grandma',
      );
      store.remoteAdd(row: 5, col: 5, label: 'swing');
      await tester.pumpAndSettle();
      expect(_sheet(tester).top, moreOrLessEquals(resting, epsilon: 1));
      expect(felt, [ChorusHaptic.clashArrived]);

      // A second clash is news again.
      store.remoteConflict(row: 1, col: 1, label: 'slide');
      await tester.pumpAndSettle();
      expect(_sheet(tester).top, lessThan(resting));
      expect(felt, [ChorusHaptic.clashArrived, ChorusHaptic.clashArrived]);
    });

    testWidgets('under reduced motion the lift is at once', (tester) async {
      final store = FakeBoardStore.seeded(leaveEmpty: const {(5, 5)});
      await _pump(
        tester,
        EditorScreen(store: store, sync: FakeSyncStatus()),
        reduced: true,
      );
      final resting = _sheet(tester).top;
      store.remoteConflict(row: 0, col: 0, label: 'playground');
      await tester.pump();
      await tester.pump();
      final lifted = _sheet(tester).top;
      expect(lifted, lessThan(resting - 200));
      await tester.pump(const Duration(seconds: 1));
      expect(_sheet(tester).top, lifted, reason: 'nothing left to move');
      expect(felt, [ChorusHaptic.clashArrived]);
    });

    testWidgets('placing a word lowers the sheet off the board', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded(leaveEmpty: const {(5, 5)})
        ..remoteConflict(row: 0, col: 0, label: 'playground');
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
      final resting = _sheet(tester).top;
      await tester.tap(find.byKey(TrayPanel.headingKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Place in next free spot'));
      await tester.pumpAndSettle();
      expect(_sheet(tester).top, moreOrLessEquals(resting, epsilon: 1));
      expect(find.text('Needs a home'), findsOneWidget);
      expect(_inGrid('playground'), findsOneWidget);
      expect(felt, [ChorusHaptic.wordPlaced]);
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('on a wide screen', () {
    testWidgets('the tray is the panel beside the board, not a sheet', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded(leaveEmpty: const {(5, 5)})
        ..remoteConflict(row: 0, col: 0, label: 'playground');
      await _pump(
        tester,
        EditorScreen(store: store, sync: FakeSyncStatus()),
        size: _wide,
      );
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      final column = tester.getRect(find.byKey(EditorScreen.sideColumnKey));
      expect(
        column.contains(tester.getCenter(find.text('Needs a home · 1'))),
        isTrue,
      );
      expect(
        tester.getRect(find.byType(EditorGrid)).right,
        lessThan(column.left),
      );
    });

    testWidgets('"Place in next free spot" flies the card into its cell on '
        'the settle spring, and is felt', (tester) async {
      final store = FakeBoardStore.seeded(leaveEmpty: const {(5, 5)})
        ..remoteConflict(row: 0, col: 0, label: 'playground');
      await _pump(
        tester,
        EditorScreen(store: store, sync: FakeSyncStatus()),
        size: _wide,
      );
      // The waiting word: a clash card shows the word in the spot first.
      final from = tester.getRect(
        find
            .descendant(
              of: find.byType(TrayPanel),
              matching: find.byType(TileView),
            )
            .last,
      );
      final to = tester
          .state<EditorGridState>(find.byType(EditorGrid))
          .cellRect(5, 5)!;

      await tester.tap(find.text('Place in next free spot'));
      await tester.pump();
      expect(felt, [ChorusHaptic.wordPlaced]);
      // Placed at once, kept out of sight until its card lands.
      expect(_inGrid('playground'), findsOneWidget);
      expect(_drawn(tester, _inGrid('playground')), isFalse);
      final flight = find.byType(TileFlight);
      expect(flight, findsOneWidget);

      Rect card() => tester.getRect(
        find.descendant(of: flight, matching: find.byType(TileView)),
      );
      await tester.pump();
      final start = card();
      expect((start.center - from.center).distance, lessThan(40));
      await tester.pump(const Duration(milliseconds: 120));
      final middle = card();
      expect(
        (middle.center - to.center).distance,
        lessThan((start.center - to.center).distance),
      );
      expect(
        (middle.center - to.center).distance,
        greaterThan(2),
        reason: 'on its way, not there at once',
      );

      await tester.pumpAndSettle();
      expect(flight, findsNothing);
      expect(_drawn(tester, _inGrid('playground')), isTrue);
      final placed = tester.getRect(_inGrid('playground'));
      expect(placed.center.dx, moreOrLessEquals(to.center.dx, epsilon: 1));
      expect(placed.center.dy, moreOrLessEquals(to.center.dy, epsilon: 1));
      expect(felt, [ChorusHaptic.wordPlaced]);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('under reduced motion the card does not travel: it fades in '
        'at its cell', (tester) async {
      final store = FakeBoardStore.seeded(leaveEmpty: const {(5, 5)})
        ..remoteConflict(row: 0, col: 0, label: 'playground');
      await _pump(
        tester,
        EditorScreen(store: store, sync: FakeSyncStatus()),
        size: _wide,
        reduced: true,
      );
      final to = tester
          .state<EditorGridState>(find.byType(EditorGrid))
          .cellRect(5, 5)!;

      await tester.tap(find.text('Place in next free spot'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final flight = find.byType(TileFlight);
      final card = tester.getRect(
        find.descendant(of: flight, matching: find.byType(TileView)),
      );
      expect(card, to);
      final fade = tester
          .widgetList<Opacity>(
            find.descendant(of: flight, matching: find.byType(Opacity)),
          )
          .first
          .opacity;
      expect(fade, greaterThan(0));
      expect(fade, lessThan(1));

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(flight, findsNothing);
      expect(_drawn(tester, _inGrid('playground')), isTrue);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a spot taken meanwhile places nothing and flies nothing', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded(leaveEmpty: const {(5, 5)})
        ..remoteConflict(row: 0, col: 0, label: 'playground');
      await _pump(
        tester,
        EditorScreen(store: store, sync: FakeSyncStatus()),
        size: _wide,
      );
      // A clash card offers "Choose a new spot".
      await tester.tap(find.text('Choose a new spot'));
      await tester.pumpAndSettle();
      // Another adult fills the spot while the picker is open: it is no
      // longer offered, and nothing is placed.
      store.remoteAdd(row: 5, col: 5, label: 'swing');
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('Put the word here')), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(TileFlight), findsNothing);
      expect(felt, isEmpty);
      expect(find.text('Needs a home · 1'), findsOneWidget);
    });
  });
}
