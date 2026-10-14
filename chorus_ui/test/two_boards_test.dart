// The second board joined up with photos, voices, the live session, the
// tray and the edit log: everything acts on the board the tabs chose.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts_live.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/editor/replaced_changes_panel.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_live.dart';
import 'package:chorus_ui/fakes_media.dart';
import 'package:chorus_ui/talker/talker_controller.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/talker/talker_tabs.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/board_tabs.dart';
import 'package:chorus_ui/widgets/sync_chip.dart';
import 'package:chorus_ui/widgets/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget screen, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: chorusTheme(), home: screen));
}

void main() {
  group('TalkerScreen with two boards', () {
    testWidgets('keeps its whole status row, with the tabs under it', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      final speech = FakeSpeech()..offlineVoiceReady.value = false;
      final live = FakeLiveSession();
      addTearDown(live.dispose);
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          live: live,
        ),
        const Size(1200, 1600),
      );
      expect(find.byType(SyncChip), findsOneWidget);
      expect(find.bySemanticsLabel(liveConnectedMessage), findsOneWidget);
      expect(find.bySemanticsLabel(noOfflineVoiceMessage), findsOneWidget);
      expect(find.text(leaveLabel), findsOneWidget);

      final tabs = find.byType(TalkerBoardTabs);
      expect(
        find.descendant(of: tabs, matching: find.text('Home')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tabs, matching: find.text('My words')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(tabs).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.text(leaveLabel)).dy),
      );
      expect(
        tester.getBottomLeft(tabs).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.text('want')).dy),
      );
    });

    testWidgets('the other board is shown at once, with its photo, its '
        'recorded voice and an adult\'s pulse', (tester) async {
      final store = FakeMediaBoardStore.seeded();
      await store.addTile(
        boardId: store.wordsBoardId,
        row: 0,
        col: 0,
        label: 'Grandma',
      );
      final grandma = store.tiles.singleWhere((t) => t.label == 'Grandma');
      final media = FakeMediaStore();
      await store.setTileMedia(grandma.id, imageHash: media.arrive(tinyPng));
      final speech = FakeSpeech();
      final speaker = FakeTileSpeaker(speech: speech);
      final live = FakeLiveSession();
      addTearDown(live.dispose);
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          live: live,
          media: media,
          speaker: speaker,
        ),
        const Size(1200, 1600),
      );
      expect(find.text('Grandma'), findsNothing);
      expect(find.byKey(TileView.photoKey), findsNothing);

      // A word is in the strip, so nothing would merge by itself: going to
      // another board is the child's own act and happens anyway.
      await tester.tap(find.text('want'));
      await tester.tap(find.text('My words'));
      await tester.pump();
      expect(find.text('want'), findsOneWidget, reason: 'only in the strip');
      expect(find.text('Grandma'), findsOneWidget);
      expect(find.byKey(TileView.photoKey), findsOneWidget);

      await tester.tap(find.text('Grandma'));
      await tester.pump();
      expect(speaker.said.last.id, grandma.id);

      live.receivePulse(grandma.id);
      await tester.pump();
      expect(live.pulsing, {grandma.id});
      expect(
        tester
            .widgetList<DecoratedBox>(
              find.ancestor(
                of: find.text('Grandma'),
                matching: find.byType(DecoratedBox),
              ),
            )
            .any(
              (box) =>
                  box.position == DecorationPosition.foreground &&
                  ((box.decoration as BoxDecoration).border as Border)
                          .top
                          .color
                          .a >
                      0,
            ),
        isTrue,
      );

      await tester.tap(find.text('Home'));
      await tester.pump();
      expect(find.text('Grandma'), findsNothing);
      expect(find.text('more'), findsOneWidget);
      // Let the glow fade so no timer is left behind.
      await tester.pump(const Duration(seconds: 3));
    });

    test('showBoard keeps one held snapshot per board: a first visit shows '
        'the board as it is, a return visit shows it as it was left', () async {
      final store = FakeBoardStore.seeded(leaveEmpty: const {(5, 5)});
      final speech = FakeSpeech();
      final talker = TalkerController(
        store: store,
        speech: speech,
        quiet: const Duration(hours: 1),
      );
      addTearDown(talker.dispose);
      expect(talker.boardId, store.homeBoardId);

      await store.addTile(
        boardId: store.homeBoardId,
        row: 5,
        col: 5,
        label: 'swing',
      );
      expect(talker.waitingCount, 1);

      // A first visit: nothing held for this board, so it is shown as it is.
      talker.showBoard(store.wordsBoardId);
      expect(talker.boardId, store.wordsBoardId);
      expect(talker.waitingCount, 0);
      expect(talker.snapshot!.cells, isEmpty);

      // A word added to this board waits as on any board.
      await store.addTile(
        boardId: store.wordsBoardId,
        row: 0,
        col: 0,
        label: 'Grandma',
      );
      expect(talker.boardId, store.wordsBoardId);
      expect(talker.waitingCount, 1);

      // Back home the board is as the child left it; the word added
      // meanwhile is still waiting for a safe point.
      talker.showBoard(store.homeBoardId);
      expect(talker.snapshot!.cells[(5, 5)], isNull);
      expect(talker.waitingCount, 1);
      expect(talker.needsAdult, isFalse);

      // And the other board is as it was left too.
      talker.showBoard(store.wordsBoardId);
      expect(talker.snapshot!.cells, isEmpty);
      expect(talker.waitingCount, 1);
    });

    test('switching boards and back does not apply a change that needs an '
        'adult', () async {
      final store = FakeBoardStore.seeded();
      final talker = TalkerController(
        store: store,
        speech: FakeSpeech(),
        // Long enough that nothing merges by itself during the test.
        quiet: const Duration(hours: 1),
      );
      addTearDown(talker.dispose);
      final want = store.tiles.singleWhere((t) => t.label == 'want');
      final cell = talker.snapshot!.cells.entries
          .singleWhere((e) => e.value.id == want.id)
          .key;

      // An adult removes a word the child uses and puts another in its
      // cell before the board reaches a safe point: the cell would change
      // meaning.
      await store.archiveTile(want.id);
      await store.addTile(
        boardId: store.homeBoardId,
        row: cell.$1,
        col: cell.$2,
        label: 'swing',
      );
      expect(talker.needsAdult, isTrue);
      expect(talker.snapshot!.cells[cell]!.label, 'want');

      talker.showBoard(store.wordsBoardId);
      talker.showBoard(store.homeBoardId);
      expect(talker.snapshot!.cells[cell]!.label, 'want');
      expect(talker.needsAdult, isTrue);
      expect(talker.checkSafePoint(), isFalse);
      expect(talker.snapshot!.cells[cell]!.label, 'want');

      // Only the adult's confirmation moves it.
      talker.applyAdultChanges();
      expect(talker.snapshot!.cells[cell]!.label, 'swing');
      expect(talker.needsAdult, isFalse);
    });

    testWidgets('a word an adult points at on the other board rings that '
        "board's tab", (tester) async {
      final store = FakeBoardStore.seeded();
      await store.addTile(
        boardId: store.wordsBoardId,
        row: 0,
        col: 0,
        label: 'Grandma',
      );
      final grandma = store.tiles.singleWhere((t) => t.label == 'Grandma');
      final live = FakeLiveSession();
      addTearDown(live.dispose);
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: FakeSpeech(),
          sync: FakeSyncStatus(),
          live: live,
        ),
        const Size(1200, 1600),
      );

      double ring(String tab) {
        final box = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: find.descendant(
                  of: find.byType(TalkerBoardTabs),
                  matching: find.text(tab),
                ),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is DecoratedBox &&
                      w.position == DecorationPosition.foreground,
                ),
              )
              .first,
        );
        final border = (box.decoration as BoxDecoration).border! as Border;
        expect(border.top.width, 4);
        return border.top.color.a;
      }

      expect(ring('My words'), 0);
      final tabs = tester.getRect(find.byType(TalkerBoardTabs));

      live.receivePulse(grandma.id);
      await tester.pump();
      expect(ring('My words'), 1);
      expect(ring('Home'), 0);
      expect(find.text('Grandma'), findsNothing, reason: 'not switched');
      expect(tester.getRect(find.byType(TalkerBoardTabs)), tabs);

      // On that board the word itself glows, so its tab needs no ring.
      await tester.tap(find.text('My words'));
      await tester.pump();
      expect(ring('My words'), 0);

      await tester.pump(livePulseFor);
      await tester.pump();
      expect(ring('My words'), 0);
    });
  });

  group("the child's tabs stay where they are", () {
    Finder tab(String name) => find.descendant(
      of: find.byType(TalkerBoardTabs),
      matching: find.text(name),
    );
    Finder tile(String label) =>
        find.byWidgetPredicate((w) => w is TileView && w.tile.label == label);
    Map<String, Rect> tiles(WidgetTester tester) => {
      for (final element in find.byType(TileView).evaluate())
        (element.widget as TileView).tile.label: tester.getRect(
          find.byWidget(element.widget),
        ),
    };

    testWidgets('an adult archives the board the child is on: it stays on '
        'show with its tab, nothing moves, and the tab back to Home is '
        'there', (tester) async {
      final store = FakeBoardStore.seeded();
      await store.addTile(
        boardId: store.wordsBoardId,
        row: 0,
        col: 0,
        label: 'Grandma',
      );
      final speech = FakeSpeech();
      await _pump(
        tester,
        TalkerScreen(store: store, speech: speech, sync: FakeSyncStatus()),
        const Size(360, 800),
      );
      await tester.tap(tab('My words'));
      await tester.pump();
      final grandma = tester.getRect(tile('Grandma'));
      final tabs = tester.getRect(find.byType(TalkerBoardTabs));

      // On another device.
      await store.archiveBoard(store.wordsBoardId);
      await tester.pump();
      await tester.tap(tile('Grandma'));
      await tester.pump();
      expect(speech.spoken.last, 'Grandma');
      expect(tester.getRect(tile('Grandma')), grandma);
      expect(tester.getRect(find.byType(TalkerBoardTabs)), tabs);
      expect(tab('My words'), findsOneWidget);
      expect(tab('Home'), findsOneWidget);

      // The way back: Home is where it was, and the grid under the tabs
      // does not move up when the archived board's tab goes.
      final home = tester.getRect(find.byKey(ValueKey(store.homeBoardId)));
      await tester.tap(tab('Home'));
      await tester.pump();
      expect(tile('want'), findsOneWidget);
      expect(tab('My words'), findsNothing);
      expect(tester.getRect(find.byKey(ValueKey(store.homeBoardId))), home);
      expect(tester.getRect(find.byType(TalkerBoardTabs)), tabs);
      expect(tester.getRect(tile('like')).top, grandma.top);
    });

    testWidgets('boards added, archived and renamed elsewhere wait while '
        'the child is building a sentence: no tile and no tab moves', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: FakeSpeech(),
          sync: FakeSyncStatus(),
        ),
        const Size(360, 800),
      );
      await tester.tap(tile('want'));
      await tester.pump();
      final before = tiles(tester);
      final tabs = {
        for (final id in [store.homeBoardId, store.wordsBoardId])
          id: tester.getRect(find.byKey(ValueKey(id))),
      };

      Future<void> expectStill() async {
        await tester.pump();
        expect(tiles(tester), before);
        for (final MapEntry(key: id, value: rect) in tabs.entries) {
          expect(tester.getRect(find.byKey(ValueKey(id))), rect, reason: id);
        }
        expect(tab('My words'), findsOneWidget);
      }

      await store.archiveBoard(store.wordsBoardId);
      await expectStill();
      final school = await store.addBoard('School');
      await expectStill();
      await store.renameBoard(school, 'Class');
      await expectStill();
      await store.addBoard('Park');
      await expectStill();
      expect(tab('School'), findsNothing);
      expect(tab('Class'), findsNothing);
      expect(tab('Park'), findsNothing);
    });

    testWidgets('at a safe point the changes land in place: a new board '
        'takes the empty place, and the grid does not move', (tester) async {
      final store = FakeBoardStore.seeded();
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: FakeSpeech(),
          sync: FakeSyncStatus(),
        ),
        const Size(360, 800),
      );
      final before = tiles(tester);
      final myWords = tester.getRect(find.byKey(ValueKey(store.wordsBoardId)));
      // Merges wait for the board to be quiet for 2 seconds, timed on a
      // real clock.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 2100)),
      );

      await store.archiveBoard(store.wordsBoardId);
      await tester.pump();
      expect(tab('My words'), findsNothing);
      expect(tab('Home'), findsOneWidget, reason: 'the row stays');
      expect(tiles(tester), before);

      final school = await store.addBoard('School');
      await tester.pump();
      expect(tab('School'), findsOneWidget);
      expect(tester.getRect(find.byKey(ValueKey(school))), myWords);
      expect(tiles(tester), before);
    });

    test('nextTabs keeps every place: a board that leaves leaves a gap, the '
        'board on show keeps its tab, a new board fills the first gap', () {
      BoardFacts board(String id, {bool home = false, bool archived = false}) =>
          BoardFacts(
            id: id,
            name: id,
            rows: 6,
            cols: 6,
            isHome: home,
            archived: archived,
          );
      final home = board('home', home: true);
      final a = board('a'), b = board('b'), c = board('c');
      List<String?> ids(List<BoardFacts?> tabs) => [
        for (final t in tabs) t?.id,
      ];

      // The first tabs: home first, then the circle's order.
      expect(ids(TalkerController.nextTabs(const [], [a, home, b])), [
        'home',
        'a',
        'b',
      ]);
      final tabs = [home, a, b];
      // "a" is archived while "b" is on show: a gap, nothing moves.
      expect(
        ids(
          TalkerController.nextTabs(tabs, [
            home,
            board('a', archived: true),
            b,
          ], onShow: 'b'),
        ),
        ['home', null, 'b'],
      );
      // "b" is archived while on show: it keeps its tab.
      expect(
        ids(
          TalkerController.nextTabs(tabs, [
            home,
            a,
            board('b', archived: true),
          ], onShow: 'b'),
        ),
        ['home', 'a', 'b'],
      );
      // A new board takes the first gap, else goes at the end.
      expect(ids(TalkerController.nextTabs([home, null, b], [home, b, c])), [
        'home',
        'c',
        'b',
      ]);
      expect(ids(TalkerController.nextTabs(tabs, [home, a, b, c])), [
        'home',
        'a',
        'b',
        'c',
      ]);
      // A rename is the same place with the new name.
      final renamed = TalkerController.nextTabs(tabs, [
        home,
        const BoardFacts(id: 'a', name: 'School', rows: 6, cols: 6),
        b,
      ]);
      expect(renamed[1]!.name, 'School');
    });

    test('a second board shows as tabs only at a safe point, and once shown '
        'the tabs stay', () async {
      final store = FakeBoardStore.seeded(withWordsBoard: false);
      final talker = TalkerController(
        store: store,
        speech: FakeSpeech(),
        quiet: Duration.zero,
      );
      addTearDown(talker.dispose);
      expect(talker.showsTabs, isFalse);

      talker.tapTile(store.tiles.first);
      final school = await store.addBoard('School');
      expect(talker.showsTabs, isFalse, reason: 'a sentence is being built');

      talker.clearStrip();
      expect(talker.checkSafePoint(), isTrue);
      expect([for (final t in talker.tabs) t?.name], ['Home', 'School']);

      await store.archiveBoard(school);
      expect(talker.showsTabs, isTrue, reason: 'the grid never moves up');
      expect([for (final t in talker.tabs) t?.name], ['Home', null]);
    });
  });

  group('EditorScreen with two boards', () {
    for (final size in const [Size(1400, 1000), Size(600, 2400)]) {
      testWidgets('tabs sit above the grid with model mode, and adding a '
          'word goes to the chosen board (${size.width.toInt()} wide)', (
        tester,
      ) async {
        final store = FakeMediaBoardStore.seeded();
        final live = FakeLiveSession();
        addTearDown(live.dispose);
        BoardFacts? printed;
        await _pump(
          tester,
          EditorScreen(
            store: store,
            sync: FakeSyncStatus(),
            live: live,
            media: FakeMediaStore(),
            capture: FakeMediaCapture(hasCamera: false),
            onPrint: (board) => printed = board,
          ),
          size,
        );
        final tabs = find.byType(BoardTabs);
        expect(tabs, findsOneWidget);
        expect(find.byType(Switch), findsOneWidget, reason: 'model mode');
        expect(
          tester.getBottomLeft(tabs).dy,
          lessThanOrEqualTo(tester.getTopLeft(find.text('want')).dy),
        );

        await tester.tap(find.byTooltip(printThisBoardLabel));
        expect(printed!.id, store.homeBoardId);

        await tester.tap(find.text('My words'));
        await tester.pumpAndSettle();
        expect(find.text('want'), findsNothing);

        await tester.tap(
          find.bySemanticsLabel('Empty spot, row 1, column 1. Add a word here'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Add a word'), findsOneWidget);
        expect(find.text('Photo (optional)'), findsOneWidget);
        await tester.enterText(find.byType(TextField).first, 'Grandma');
        await tester.tap(find.widgetWithText(FilledButton, 'Add to board'));
        await tester.pumpAndSettle();

        final added = store.tiles.singleWhere((t) => t.label == 'Grandma');
        expect(added.boardId, store.wordsBoardId);
        expect(added.cellKey, placedKey(store.wordsBoardId, 0, 0));
        expect(find.text('Grandma'), findsOneWidget);

        await tester.tap(find.byTooltip(printThisBoardLabel));
        expect(printed!.id, store.wordsBoardId);
      });
    }
  });

  testWidgets('Replaced changes can be limited to one board', (tester) async {
    // Nothing is replaced here; the panel only has to take a board id and
    // stay empty for a board with no edits. The filter itself is exercised
    // in replaced_changes_test.dart.
    final store = FakeBoardStore.seeded();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReplacedChangesPanel(store: store, boardId: store.wordsBoardId),
        ),
      ),
    );
    expect(find.byType(Text), findsNothing);
  });
}
