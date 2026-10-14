// Boards from the editor: the "+" tab, the long press on a tab to rename or
// archive, "Import a board (.obf)", and the tabs themselves, which keep
// their order and size and scroll when there are more than fit.
import 'dart:convert';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/editor/board_actions.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/editor/obf_picker.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/board_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(1280, 800),
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

Finder _tab(String name) =>
    find.descendant(of: find.byType(BoardTabs), matching: find.text(name));

List<BoardFacts> _live(BoardStore store) =>
    store.boards.where((board) => !board.archived).toList();

/// An OBF board of [size] x [size] words, each named "w" and its row and
/// column, as "w06".
String _obf(int size, {String name = 'From another app'}) => jsonEncode({
  'format': 'open-board-0.1',
  'id': 'x',
  'name': name,
  'buttons': [
    for (var r = 0; r < size; r++)
      for (var c = 0; c < size; c++) {'id': '$r-$c', 'label': 'w$r$c'},
  ],
  'grid': {
    'rows': size,
    'columns': size,
    'order': [
      for (var r = 0; r < size; r++) [for (var c = 0; c < size; c++) '$r-$c'],
    ],
  },
});

void main() {
  final felt = <ChorusHaptic>[];
  setUp(() {
    felt.clear();
    ChorusHaptics.sink = felt.add;
  });
  tearDown(() => ChorusHaptics.sink = null);

  group('the "+" tab', () {
    testWidgets('adds an empty board with the next free name and shows it', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
      expect(find.bySemanticsLabel(BoardTabs.addLabel), findsOneWidget);

      await tester.tap(find.byKey(BoardTabs.addKey));
      await tester.pumpAndSettle();
      expect(find.text('Add a board'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Board 3',
      );
      await tester.tap(find.text('Add board'));
      await tester.pumpAndSettle();

      final added = _live(store).singleWhere((b) => b.name == 'Board 3');
      expect(gridOf(added.id, store.tiles, store.boards), isEmpty);
      // The new board is the one on show: empty, in the same grid.
      expect(_tab('Board 3'), findsOneWidget);
      expect(find.text('want'), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp(r'^Empty spot, row 1, column 1')),
        findsOneWidget,
      );
    });

    testWidgets('refuses an empty name and one in use, in plain words', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
      await tester.tap(find.byKey(BoardTabs.addKey));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), ' my  WORDS ');
      await tester.tap(find.text('Add board'));
      await tester.pump();
      expect(
        find.text('Another board is already called "my WORDS".'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Add board'));
      await tester.pump();
      expect(find.text('Give the board a name.'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(_live(store), hasLength(2));
    });

    testWidgets('a circle with one board still gets the "+" tab', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded(withWordsBoard: false);
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
      expect(find.byKey(BoardTabs.addKey), findsOneWidget);
      expect(_tab('Home'), findsOneWidget);
    });

    testWidgets('a partner gets no "+" tab, no long press and no menu', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded(role: CircleRole.partner);
      await _pump(
        tester,
        EditorScreen(
          store: store,
          sync: FakeSyncStatus(),
          pickObfFile: () async => null,
        ),
      );
      expect(find.byKey(BoardTabs.addKey), findsNothing);
      expect(find.byTooltip(boardMenuLabel), findsNothing);
      await tester.longPress(_tab('My words'));
      await tester.pumpAndSettle();
      expect(find.text(renameBoardLabel), findsNothing);
      // The tabs still switch boards.
      await tester.tap(_tab('My words'));
      await tester.pumpAndSettle();
      expect(find.text('want'), findsNothing);
    });
  });

  group('a long press on a tab', () {
    testWidgets('renames the board', (tester) async {
      final store = FakeBoardStore.seeded();
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
      await tester.longPress(_tab('My words'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(renameBoardLabel));
      await tester.pumpAndSettle();
      expect(find.text('Rename "My words"'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Snacks');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        store.boards.singleWhere((b) => b.id == store.wordsBoardId).name,
        'Snacks',
      );
      expect(_tab('Snacks'), findsOneWidget);
    });

    testWidgets('archives a board after asking, and shows home again', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      await store.addTile(
        boardId: store.wordsBoardId,
        row: 0,
        col: 0,
        label: 'Grandma',
      );
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
      await tester.tap(_tab('My words'));
      await tester.pumpAndSettle();
      expect(find.text('Grandma'), findsOneWidget);

      await tester.longPress(_tab('My words'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(archiveBoardLabel));
      await tester.pumpAndSettle();
      expect(find.text('Archive "My words"?'), findsOneWidget);
      expect(
        find.text(
          'Maya will no longer see this board or its word. Nothing is '
          'deleted.',
        ),
        findsOneWidget,
      );

      // "Keep" changes nothing.
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(_live(store), hasLength(2));

      await tester.longPress(_tab('My words'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(archiveBoardLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
      await tester.pumpAndSettle();

      expect(_live(store).map((b) => b.name), ['Home']);
      expect(_tab('My words'), findsNothing);
      expect(find.text('want'), findsOneWidget, reason: 'home on show');
      // Nothing was deleted.
      expect(store.tiles.where((t) => t.label == 'Grandma'), hasLength(1));
    });

    testWidgets('the home board cannot be archived, and says why', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
      await tester.longPress(_tab('Home'));
      await tester.pumpAndSettle();
      expect(
        find.text('The home board stays. It cannot be archived.'),
        findsOneWidget,
      );
      final archive = tester.widget<ListTile>(
        find.widgetWithText(ListTile, archiveBoardLabel),
      );
      expect(archive.enabled, isFalse);
      await tester.tap(find.text(archiveBoardLabel), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.textContaining('Archive "Home"'), findsNothing);
      expect(store.boards.firstWhere((b) => b.isHome).archived, isFalse);
    });

    testWidgets('the menu offers the same, for a keyboard or a screen '
        'reader, and refuses the home board', (tester) async {
      final store = FakeBoardStore.seeded();
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
      await tester.tap(find.byTooltip(boardMenuLabel));
      await tester.pumpAndSettle();
      expect(find.text(renameBoardLabel), findsOneWidget);
      expect(
        tester
            .widget<PopupMenuItem<String>>(
              find.widgetWithText(PopupMenuItem<String>, archiveBoardLabel),
            )
            .enabled,
        isFalse,
      );
      // No file picker in a test: no import.
      expect(find.text(importBoardLabel), findsNothing);
    });

    testWidgets('a screen reader hears the long press as an action of the '
        'tab', (tester) async {
      final semantics = tester.ensureSemantics();
      final store = FakeBoardStore.seeded();
      await _pump(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
      // One node: a button named by its board, with the long press.
      expect(
        tester.getSemantics(_tab('My words')),
        isSemantics(
          label: 'Board: My words',
          isButton: true,
          isSelected: false,
          hasTapAction: true,
          hasLongPressAction: true,
        ),
      );
      expect(
        tester.getSemantics(_tab('Home')),
        isSemantics(label: 'Board: Home', isButton: true, isSelected: true),
      );
      tester.semantics.longPress(find.semantics.byLabel('Board: My words'));
      await tester.pumpAndSettle();
      expect(find.text(renameBoardLabel), findsOneWidget);
      semantics.dispose();
    });
  });

  group('the tabs', () {
    List<BoardFacts> boards(int n) => [
      for (var i = 0; i < n; i++)
        BoardFacts(
          id: 'b$i',
          name: i == 0 ? 'Home' : 'Board ${i + 1}',
          rows: 6,
          cols: 6,
          isHome: i == 0,
        ),
    ];

    Future<void> tabs(
      WidgetTester tester,
      List<BoardFacts> boards, {
      String selected = 'b0',
      VoidCallback? onAdd,
      ValueChanged<BoardFacts>? onLongPress,
      ValueChanged<String>? onSelect,
      bool reduced = false,
    }) => _pump(
      tester,
      Scaffold(
        body: Center(
          child: SizedBox(
            width: 340,
            child: BoardTabs(
              boards: boards,
              selectedId: selected,
              onSelect: onSelect ?? (_) {},
              onAdd: onAdd,
              onLongPress: onLongPress,
            ),
          ),
        ),
      ),
      size: const Size(360, 640),
      reduced: reduced,
    );

    testWidgets('keep their order and size when a board is added, and '
        'scroll sideways past what fits', (tester) async {
      await tabs(tester, boards(2), onAdd: () {});
      final home = tester.getRect(_tab('Home'));
      final second = tester.getRect(_tab('Board 2'));
      expect(home.left, lessThan(second.left));

      await tabs(tester, boards(3), onAdd: () {});
      expect(tester.getRect(_tab('Home')), home);
      expect(tester.getRect(_tab('Board 2')), second);

      await tabs(tester, boards(7), onAdd: () {});
      expect(tester.getRect(_tab('Home')), home);
      expect(tester.getRect(_tab('Board 2')), second);
      final lefts = [
        for (var i = 2; i <= 7; i++) tester.getRect(_tab('Board $i')).left,
      ];
      expect(lefts, orderedEquals([...lefts]..sort()));
      // More than fit: the last is off the end, and the row says it scrolls.
      final row = tester.getRect(find.byType(BoardTabs));
      expect(tester.getRect(_tab('Board 7')).left, greaterThan(row.right));
      expect(
        tester.widget<Scrollbar>(find.byType(Scrollbar)).thumbVisibility,
        isTrue,
      );

      await tester.drag(find.byType(BoardTabs), const Offset(-2000, 0));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(BoardTabs.addKey)).right, row.right);
      expect(tester.getRect(_tab('Board 7')).right, lessThan(row.right));
    });

    testWidgets("the child's tabs only switch boards, and the switch is "
        'felt', (tester) async {
      String? chosen;
      await tabs(tester, boards(3), onSelect: (id) => chosen = id);
      expect(find.byKey(BoardTabs.addKey), findsNothing);

      await tester.tap(_tab('Home'));
      expect(chosen, isNull);
      expect(felt, isEmpty, reason: 'the board on show: nothing changes');

      await tester.tap(_tab('Board 2'));
      expect(chosen, 'b1');
      expect(felt, [ChorusHaptic.tabChanged]);

      // No long press for the child, to a screen reader either.
      final semantics = tester.ensureSemantics();
      expect(
        tester.getSemantics(_tab('Board 3')),
        isSemantics(
          label: 'Board: Board 3',
          isButton: true,
          hasTapAction: true,
          hasLongPressAction: false,
        ),
      );
      semantics.dispose();
      chosen = null;
      await tester.longPress(_tab('Board 3'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('a long press reports the board', (tester) async {
      BoardFacts? pressed;
      await tabs(tester, boards(3), onLongPress: (b) => pressed = b);
      await tester.longPress(_tab('Board 2'));
      expect(pressed?.id, 'b1');
    });

    for (final reduced in [false, true]) {
      testWidgets('a tab chosen off the end is brought into view'
          '${reduced ? ', at once under reduced motion' : ''}', (tester) async {
        final all = boards(7);
        await tabs(tester, all, onAdd: () {}, reduced: reduced);
        final row = tester.getRect(find.byType(BoardTabs));
        expect(tester.getRect(_tab('Board 6')).left, greaterThan(row.right));

        await tabs(tester, all, selected: 'b5', onAdd: () {}, reduced: reduced);
        // The frame after the change: under reduced motion it is there.
        await tester.pump();
        if (reduced) {
          expect(
            tester.getRect(_tab('Board 6')).right,
            lessThanOrEqualTo(row.right),
          );
        }
        await tester.pumpAndSettle();
        final shown = tester.getRect(_tab('Board 6'));
        expect(shown.right, lessThanOrEqualTo(row.right + 0.5));
        expect(shown.left, greaterThanOrEqualTo(row.left - 0.5));
      });
    }
  });

  group('Import a board (.obf)', () {
    Future<void> openImport(WidgetTester tester) async {
      await tester.tap(find.byTooltip(boardMenuLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(importBoardLabel));
      await tester.pumpAndSettle();
    }

    testWidgets('an 8 by 8 board comes in as a new board, and the words '
        'that did not fit are listed', (tester) async {
      final store = FakeBoardStore.seeded();
      await _pump(
        tester,
        EditorScreen(
          store: store,
          sync: FakeSyncStatus(),
          pickObfFile: () async => PickedFile(name: 'board.obf', text: _obf(8)),
        ),
      );
      await openImport(tester);

      expect(find.text('Imported "From another app"'), findsOneWidget);
      expect(find.text('36 words are on the new board.'), findsOneWidget);
      expect(
        find.text(
          'These 28 words did not fit on a 6 by 6 board, so they were left '
          'out:',
        ),
        findsOneWidget,
      );
      expect(find.text('w06 (row 1, column 7)'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      final board = _live(
        store,
      ).singleWhere((b) => b.name == 'From another app');
      expect(gridOf(board.id, store.tiles, store.boards), hasLength(36));
      // It is the board on show.
      expect(find.text('w00'), findsOneWidget);
      expect(find.text('want'), findsNothing);
    });

    testWidgets('a file that is not a board says why and adds nothing', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      await _pump(
        tester,
        EditorScreen(
          store: store,
          sync: FakeSyncStatus(),
          pickObfFile: () async =>
              const PickedFile(name: 'notes.obf', text: 'hello'),
        ),
      );
      await openImport(tester);
      expect(find.text('This board could not be imported'), findsOneWidget);
      expect(find.text(const ObfNotJson().message), findsOneWidget);
      expect(felt, [ChorusHaptic.failed]);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(_live(store), hasLength(2));
    });

    testWidgets('a file too large is refused', (tester) async {
      final store = FakeBoardStore.seeded();
      await _pump(
        tester,
        EditorScreen(
          store: store,
          sync: FakeSyncStatus(),
          pickObfFile: () async => throw const PickedFileTooLarge(),
        ),
      );
      await openImport(tester);
      expect(find.text(fileTooLargeMessage), findsOneWidget);
      expect(_live(store), hasLength(2));
    });

    testWidgets('closing the picker imports nothing and says nothing', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      await _pump(
        tester,
        EditorScreen(
          store: store,
          sync: FakeSyncStatus(),
          pickObfFile: () async => null,
        ),
      );
      await openImport(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(_live(store), hasLength(2));
    });
  });

  group('export', () {
    testWidgets('the board menu exports the board on show', (tester) async {
      final store = FakeBoardStore.seeded();
      final exported = <BoardFacts>[];
      await _pump(
        tester,
        EditorScreen(
          store: store,
          sync: FakeSyncStatus(),
          pickObfFile: () async => null,
          onExport: exported.add,
        ),
      );
      await tester.tap(_tab('My words'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(boardMenuLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(exportBoardLabel));
      await tester.pumpAndSettle();
      expect(exported.map((board) => board.name), ['My words']);
    });

    testWidgets('without onExport the menu has no export', (tester) async {
      final store = FakeBoardStore.seeded();
      await _pump(
        tester,
        EditorScreen(
          store: store,
          sync: FakeSyncStatus(),
          pickObfFile: () async => null,
        ),
      );
      await tester.tap(find.byTooltip(boardMenuLabel));
      await tester.pumpAndSettle();
      expect(find.text(renameBoardLabel), findsOneWidget);
      expect(find.text(exportBoardLabel), findsNothing);
    });

    testWidgets('a partner given an export gets it alone: nothing that '
        'changes the boards', (tester) async {
      final store = FakeBoardStore.seeded(role: CircleRole.partner);
      final exported = <BoardFacts>[];
      await _pump(
        tester,
        EditorScreen(
          store: store,
          sync: FakeSyncStatus(),
          pickObfFile: () async => null,
          onExport: exported.add,
        ),
      );
      await tester.tap(find.byTooltip(boardMenuLabel));
      await tester.pumpAndSettle();
      expect(find.text(renameBoardLabel), findsNothing);
      expect(find.text(archiveBoardLabel), findsNothing);
      expect(find.text(importBoardLabel), findsNothing);
      await tester.tap(find.text(exportBoardLabel));
      await tester.pumpAndSettle();
      expect(exported, hasLength(1));
    });
  });

  group('the attention ring', () {
    for (final dark in [false, true]) {
      testWidgets('is ink, not a colour, ${dark ? 'on slate' : 'on card'}', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? chorusDarkTheme() : chorusTheme(),
            home: Scaffold(
              body: BoardTabs(
                boards: const [
                  BoardFacts(
                    id: 'b0',
                    name: 'Home',
                    rows: 6,
                    cols: 6,
                    isHome: true,
                  ),
                  BoardFacts(id: 'b1', name: 'Park', rows: 6, cols: 6),
                ],
                selectedId: 'b0',
                onSelect: (_) {},
                attentionIds: const {'b1'},
              ),
            ),
          ),
        );
        final ink = dark ? ChorusColors.dark.ink : ChorusColors.light.ink;
        final rings = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .where((box) => box.position == DecorationPosition.foreground)
            .map((box) => (box.decoration as BoxDecoration).border)
            .whereType<Border>()
            .where((border) => border.top.width == 4)
            .map((border) => border.top.color)
            .toList();
        expect(rings, contains(ink));
        expect(rings.where((color) => color.a > 0), everyElement(ink));
      });
    }
  });
}
