// The home hero: the child's own board, drawn live from the store, with its
// words' colours, symbols and photos; a still grey skeleton while it loads;
// and a tap that opens the board.
import 'dart:typed_data';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/brand/board_object.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_media.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_media.dart';
import 'package:chorus_ui/home/home.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  BoardStore store, {
  MediaStore? media,
  VoidCallback? onOpen,
  bool loading = false,
  bool reduced = false,
  bool dark = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: dark ? chorusDarkTheme() : chorusTheme(),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 323,
              child: HomeHero(
                store: store,
                childName: 'Maya',
                media: media,
                onOpen: onOpen,
                loading: loading,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

TileFacts _tile(BoardStore store, String label) =>
    store.tiles.firstWhere((tile) => tile.label == label);

void main() {
  group('the cells', () {
    test('are the home board\'s placed words, each in its colour family', () {
      final store = FakeBoardStore.seeded();
      final board = heroBoardOf(store)!;
      expect(board.isHome, isTrue);
      final cells = heroCellsOf(board, store);
      expect(cells, hasLength(36));
      for (final cell in cells) {
        final tile = _tile(store, cell.label);
        expect(
          CellKey.parse(tile.cellKey),
          PlacedCell(board.id, cell.row, cell.col),
          reason: cell.label,
        );
      }
      expect(
        cells.firstWhere((cell) => cell.label == 'I').family,
        TileFamily.person,
      );
      expect(
        cells.firstWhere((cell) => cell.label == 'want').family,
        TileFamily.action,
      );
    });

    test('a word with a symbol shows it, and every starter word has '
        'one', () {
      final store = FakeBoardStore.seeded();
      final cells = heroCellsOf(heroBoardOf(store)!, store);
      final want = cells.firstWhere((cell) => cell.label == 'want');
      expect(want.image, isA<AssetImage>());
      expect((want.image! as AssetImage).assetName, 'assets/symbols/want.png');
      final stop = cells.firstWhere((cell) => cell.label == 'stop');
      expect((stop.image! as AssetImage).assetName, 'assets/symbols/stop.png');
      expect(cells.where((cell) => cell.image == null), isEmpty);
    });

    test('a word\'s own photo wins over its symbol once it is on this '
        'device', () async {
      final store = FakeMediaBoardStore.seeded();
      final media = FakeMediaStore();
      final hash = await media.addImage(Uint8List.fromList([1, 2, 3]));
      await store.setTileMedia(_tile(store, 'want').id, imageHash: hash);
      final cells = heroCellsOf(heroBoardOf(store)!, store, media: media);
      final want = cells.firstWhere((cell) => cell.label == 'want');
      expect(want.image, same(media.imageFor(hash)));
    });

    test('a removed word and a word waiting for a home are not on the '
        'board', () async {
      final store = FakeBoardStore.seeded(leaveEmpty: {(0, 0)});
      await store.archiveTile(_tile(store, 'want').id);
      // A word added to a full cell waits in the tray.
      await store.addTile(
        boardId: store.homeBoardId,
        row: 1,
        col: 1,
        label: 'juice',
      );
      final cells = heroCellsOf(heroBoardOf(store)!, store);
      expect(cells.map((cell) => cell.label), isNot(contains('want')));
      expect(cells.map((cell) => cell.label), isNot(contains('juice')));
      expect(cells.where((cell) => (cell.row, cell.col) == (0, 0)), isEmpty);
      expect(cells, hasLength(34));
    });

    test('a circle with no board in use has no hero board', () async {
      final store = FakeBoardStore.seeded(withWordsBoard: false);
      expect(heroBoardOf(store), isNotNull);
      expect(heroBoardOf(_NoBoards()), isNull);
    });
  });

  testWidgets('it follows the store: a word added on another device '
      'appears on the hero', (tester) async {
    final store = FakeBoardStore.seeded(leaveEmpty: {(0, 0)});
    await _pump(tester, store);
    expect(find.text('juice'), findsNothing);

    await store.addTile(
      boardId: store.homeBoardId,
      row: 0,
      col: 0,
      label: 'juice',
      colorKey: 'verb',
    );
    await tester.pump();
    expect(find.text('juice'), findsOneWidget);
  });

  testWidgets('a tap opens the board, and the board is one button a screen '
      'reader can name', (tester) async {
    final semantics = tester.ensureSemantics();
    var opened = 0;
    await _pump(tester, FakeBoardStore.seeded(), onOpen: () => opened++);
    expect(
      tester.getSemantics(find.bySemanticsLabel("Maya's board, 36 words")),
      isSemantics(
        label: "Maya's board, 36 words",
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.byKey(HomeHero.boardKey));
    await tester.pumpAndSettle();
    expect(opened, 1);
    semantics.dispose();
  });

  testWidgets('with motion it is the shared element, tagged by its board', (
    tester,
  ) async {
    final store = FakeBoardStore.seeded();
    await _pump(tester, store, onOpen: () {});
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'board-${store.homeBoardId}');
    expect(hero.tag, boardHeroTag(store.homeBoardId));
    // The card inside has no hero of its own.
    expect(find.byType(Hero), findsOneWidget);
  });

  testWidgets('under reduced motion it lies flat and nothing flies', (
    tester,
  ) async {
    var opened = 0;
    await _pump(
      tester,
      FakeBoardStore.seeded(),
      onOpen: () => opened++,
      reduced: true,
    );
    expect(find.byType(Hero), findsNothing);
    expect(find.byKey(BoardObject.tiltKey), findsNothing);
    await tester.tap(find.byKey(HomeHero.boardKey));
    await tester.pump();
    expect(opened, 1);
  });

  testWidgets('while it loads it is a still skeleton of grey tiles that '
      'screen readers skip', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, FakeBoardStore.seeded(), loading: true, onOpen: () {});
    expect(find.byKey(HomeHero.skeletonKey), findsOneWidget);
    expect(find.byKey(HomeHero.boardKey), findsNothing);
    final skeleton = tester.widget<BoardObject>(
      find.byKey(HomeHero.skeletonKey),
    );
    expect(skeleton.cells, hasLength(36));
    expect(skeleton.cells.every((cell) => cell.label.isEmpty), isTrue);
    expect(
      skeleton.cells.every((cell) => cell.family == TileFamily.other),
      isTrue,
      reason: 'grey laminated tiles',
    );
    expect(skeleton.onTap, isNull);
    expect(find.byType(Hero), findsNothing);
    expect(find.bySemanticsLabel(RegExp('board')), findsNothing);
    // It holds the board's space.
    expect(tester.getSize(find.byKey(HomeHero.skeletonKey)).width, 320);
    semantics.dispose();
  });

  testWidgets('before the circle has a board here it is the skeleton too', (
    tester,
  ) async {
    await _pump(tester, _NoBoards(), onOpen: () {});
    expect(find.byKey(HomeHero.skeletonKey), findsOneWidget);
  });

  testWidgets('in the dark its card is slate and its tiles the dark fills', (
    tester,
  ) async {
    await _pump(tester, FakeBoardStore.seeded(), dark: true);
    expect(tester.takeException(), isNull);
    final boxes = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byKey(HomeHero.boardKey),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => (box.decoration as BoxDecoration).color)
        .toSet();
    expect(boxes, contains(ChorusColors.dark.surface));
    expect(boxes, contains(TileFamily.action.dark.fill));
    expect(boxes, isNot(contains(TileFamily.action.light.fill)));
  });
}

/// A circle whose board has not reached this device.
class _NoBoards extends FakeBoardStore {
  _NoBoards() : super.seeded();

  @override
  List<BoardFacts> get boards => const [];
}
