import 'dart:convert';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_boards.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BoardFacts boardOf(FakeBoardStore store, String id) =>
      store.boards.singleWhere((board) => board.id == id);

  List<BoardFacts> live(FakeBoardStore store) =>
      store.boards.where((board) => !board.archived).toList();

  test('the fake store manages boards', () {
    expect(FakeBoardStore.seeded(), isA<BoardManager>());
  });

  group('add', () {
    test(
      'an empty 6 x 6 board with the tidied name, and tells listeners',
      () async {
        final store = FakeBoardStore.seeded();
        var heard = 0;
        store.addListener(() => heard++);
        final id = await store.addBoard('  Snack  time ');
        final board = boardOf(store, id);
        expect(board.name, 'Snack time');
        expect((board.rows, board.cols), (6, 6));
        expect(board.isHome, isFalse);
        expect(board.archived, isFalse);
        expect(gridOf(id, store.tiles, store.boards), isEmpty);
        expect(heard, 1);
      },
    );

    test('the default name never repeats a board in use', () async {
      final store = FakeBoardStore.seeded();
      final first = await store.addBoard(defaultBoardName(store.boards));
      expect(boardOf(store, first).name, 'Board 3');
      final second = await store.addBoard(defaultBoardName(store.boards));
      expect(boardOf(store, second).name, 'Board 4');
      expect(first, isNot(second));
    });

    test('refuses an empty or over-long name', () async {
      final store = FakeBoardStore.seeded();
      await expectLater(store.addBoard('  '), throwsArgumentError);
      await expectLater(store.addBoard('a' * 31), throwsArgumentError);
      expect(store.boards, hasLength(2));
    });

    test('words can be added to the new board', () async {
      final store = FakeBoardStore.seeded();
      final id = await store.addBoard('Snacks');
      expect(
        await store.addTile(boardId: id, row: 0, col: 0, label: 'crisps'),
        isTrue,
      );
      expect(gridOf(id, store.tiles, store.boards)[(0, 0)]!.label, 'crisps');
    });
  });

  group('rename', () {
    test('changes only the name', () async {
      final store = FakeBoardStore.seeded();
      final before = boardOf(store, store.homeBoardId);
      await store.renameBoard(store.homeBoardId, ' Core ');
      final after = boardOf(store, store.homeBoardId);
      expect(after.name, 'Core');
      expect(after.isHome, isTrue);
      expect((after.rows, after.cols), (before.rows, before.cols));
      expect(gridOf(after.id, store.tiles, store.boards), hasLength(36));
    });

    test('refuses a bad name, an unknown board and an archived one', () async {
      final store = FakeBoardStore.seeded();
      await expectLater(
        store.renameBoard(store.wordsBoardId, ''),
        throwsArgumentError,
      );
      await expectLater(
        store.renameBoard('no-such-board', 'Fine'),
        throwsArgumentError,
      );
      await store.archiveBoard(store.wordsBoardId);
      await expectLater(
        store.renameBoard(store.wordsBoardId, 'Back'),
        throwsArgumentError,
      );
    });
  });

  group('archive', () {
    test('never the home board', () async {
      final store = FakeBoardStore.seeded();
      await expectLater(
        store.archiveBoard(store.homeBoardId),
        throwsStateError,
      );
      expect(boardOf(store, store.homeBoardId).archived, isFalse);
    });

    test('the home board is what is left at the end', () async {
      final store = FakeBoardStore.seeded(withWordsBoard: false);
      final id = await store.addBoard('Only other');
      await store.archiveBoard(id);
      // The home board is all that is left, and it stays anyway.
      expect(live(store), [boardOf(store, store.homeBoardId)]);
      await expectLater(
        store.archiveBoard(store.homeBoardId),
        throwsStateError,
      );
    });

    test(
      'takes the board and its words out of sight, deleting nothing',
      () async {
        final store = FakeBoardStore.seeded();
        final id = await store.addBoard('Snacks');
        await store.addTile(boardId: id, row: 0, col: 0, label: 'crisps');
        await store.addTile(boardId: id, row: 0, col: 1, label: 'apple');
        final count = store.tiles.length;
        await store.archiveBoard(id);
        expect(boardOf(store, id).archived, isTrue);
        expect(store.tiles, hasLength(count));
        final words = store.tiles.where((tile) => tile.boardId == id);
        expect(words.every((tile) => tile.archived), isTrue);
        expect(
          words.every((tile) => CellKey.parse(tile.cellKey) is TrayCell),
          isTrue,
        );
        // They do not flood "Needs a home".
        expect(trayOf(store.tiles, store.boards), isEmpty);
        // The other boards keep their words.
        expect(
          gridOf(store.homeBoardId, store.tiles, store.boards),
          hasLength(36),
        );
      },
    );

    test('refuses a board already archived, and an unknown one', () async {
      final store = FakeBoardStore.seeded();
      await store.archiveBoard(store.wordsBoardId);
      await expectLater(
        store.archiveBoard(store.wordsBoardId),
        throwsStateError,
      );
      await expectLater(store.archiveBoard('nope'), throwsArgumentError);
    });

    test("an archived board's name is free again", () async {
      final store = FakeBoardStore.seeded();
      final id = await store.addBoard(defaultBoardName(store.boards));
      expect(boardOf(store, id).name, 'Board 3');
      await store.archiveBoard(id);
      expect(defaultBoardName(store.boards), 'Board 3');
    });
  });

  group('import', () {
    String obf(int size, {String name = 'From another app'}) => jsonEncode({
      'format': 'open-board-0.1',
      'id': 'x',
      'name': name,
      'buttons': [
        for (var r = 0; r < size; r++)
          for (var c = 0; c < size; c++)
            {
              'id': '$r-$c',
              'label': 'w$r$c',
              if (r == 0 && c == 0) 'vocalization': 'hello there',
              if (r == 0 && c == 1) 'background_color': 'rgb(204, 255, 170)',
            },
      ],
      'grid': {
        'rows': size,
        'columns': size,
        'order': [
          for (var r = 0; r < size; r++)
            [for (var c = 0; c < size; c++) '$r-$c'],
        ],
      },
    });

    test('a new board holds the words in their cells', () async {
      final store = FakeBoardStore.seeded();
      final result = await store.importBoard(parseObf(obf(3)));
      final board = boardOf(store, result.boardId);
      expect(board.name, 'From another app');
      expect(result.leftOut, isEmpty);
      final grid = gridOf(board.id, store.tiles, store.boards);
      expect(grid, hasLength(9));
      expect(grid[(0, 0)]!.label, 'w00');
      expect(grid[(0, 0)]!.speech, 'hello there');
      expect(grid[(0, 1)]!.colorKey, 'verb');
      expect(grid[(2, 2)]!.label, 'w22');
      expect(grid[(0, 0)]!.createdByName, 'Mum');
    });

    test('an 8 x 8 board fills 6 x 6 and lists the rest', () async {
      final store = FakeBoardStore.seeded();
      final result = await store.importBoard(parseObf(obf(8)));
      expect(gridOf(result.boardId, store.tiles, store.boards), hasLength(36));
      expect(result.leftOut, hasLength(28));
      expect(result.leftOut.first.label, 'w06');
      // Nothing that did not fit was added anywhere.
      expect(store.tiles.where((tile) => tile.label == 'w77'), isEmpty);
    });

    test('a name in use is numbered, an empty one gets the default', () async {
      final store = FakeBoardStore.seeded();
      final again = await store.importBoard(parseObf(obf(1, name: 'Home')));
      expect(boardOf(store, again.boardId).name, 'Home 2');
      final unnamed = await store.importBoard(parseObf(obf(1, name: '')));
      expect(boardOf(store, unnamed.boardId).name, 'Board 4');
    });

    test('an exported board comes back as a copy', () async {
      final store = FakeBoardStore.seeded();
      final home = boardOf(store, store.homeBoardId);
      final copy = await store.importBoard(
        parseObf(obfJsonOf(home, store.tiles)),
      );
      final original = gridOf(home.id, store.tiles, store.boards);
      final copied = gridOf(copy.boardId, store.tiles, store.boards);
      expect(copied.keys.toSet(), original.keys.toSet());
      for (final cell in original.keys) {
        expect(copied[cell]!.label, original[cell]!.label);
        expect(copied[cell]!.colorKey, original[cell]!.colorKey);
      }
    });
  });

  test('a partner can change no board', () async {
    final store = FakeBoardStore.seeded(role: CircleRole.partner);
    await expectLater(store.addBoard('Mine'), throwsStateError);
    await expectLater(
      store.renameBoard(store.wordsBoardId, 'Mine'),
      throwsStateError,
    );
    await expectLater(store.archiveBoard(store.wordsBoardId), throwsStateError);
    await expectLater(
      store.importBoard(parseObf(obfJsonOf(store.boards.first, store.tiles))),
      throwsStateError,
    );
    expect(store.boards, hasLength(2));
  });
}
