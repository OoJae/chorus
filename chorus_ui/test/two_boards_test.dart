// The second board joined up with photos, voices, the live session, the
// tray and the edit log: everything acts on the board the tabs chose.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/editor/replaced_changes_panel.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_live.dart';
import 'package:chorus_ui/fakes_media.dart';
import 'package:chorus_ui/talker/talker_controller.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/board_tabs.dart';
import 'package:chorus_ui/widgets/sync_chip.dart';
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

      final tabs = find.byType(BoardTabs);
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
      expect(find.byType(Image), findsNothing);

      // A word is in the strip, so nothing would merge by itself: going to
      // another board is the child's own act and happens anyway.
      await tester.tap(find.text('want'));
      await tester.tap(find.text('My words'));
      await tester.pump();
      expect(find.text('want'), findsOneWidget, reason: 'only in the strip');
      expect(find.text('Grandma'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

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

    test('showBoard drops a waiting plan and keeps the board through later '
        'merges', () async {
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

      // Back home, the word added meanwhile is simply there.
      talker.showBoard(store.homeBoardId);
      expect(talker.snapshot!.cells[(5, 5)]!.label, 'swing');
      expect(talker.waitingCount, 0);
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
