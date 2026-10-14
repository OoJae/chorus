import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

const circleA = '3f2b6c1e-8d4a-4b7e-9c15-0a6d2e7f4b91';
const circleB = '9a1d4e70-2c3b-4f58-8e6a-5b7c0d1e2f34';
const adult = '5c8e2a44-1b7d-4e9f-a3c6-7d2f0b9e1a55';

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

List<TileFacts> tilesFor(String circleId) => starterTiles(
  circleId: circleId,
  createdBy: adult,
  createdByName: 'Mum',
  createdAt: DateTime.utc(2026, 10, 13),
);

void main() {
  group('universalCore36', () {
    test('is the 36 words in row-major order', () {
      expect(universalCore36.map((w) => w.label).toList(), [
        'like', 'want', 'get', 'make', 'good', 'more', //
        'not', 'go', 'look', 'turn', 'help', 'different', //
        'I', 'he', 'open', 'do', 'put', 'same', //
        'you', 'she', 'that', 'up', 'all', 'some', //
        'it', 'here', 'in', 'on', 'can', 'finished', //
        'where', 'what', 'why', 'who', 'when', 'stop', //
      ]);
    });

    test('has 36 unique words', () {
      expect(universalCore36, hasLength(36));
      expect(
        universalCore36.map((w) => w.label.toLowerCase()).toSet(),
        hasLength(36),
      );
    });

    test(
      'uses every cell of the 6x6 grid exactly once, in row-major order',
      () {
        expect(starterRows * starterCols, 36);
        final cells = [for (final w in universalCore36) (w.row, w.col)];
        expect(cells, [
          for (var r = 0; r < starterRows; r++)
            for (var c = 0; c < starterCols; c++) (r, c),
        ]);
        expect(cells.toSet(), hasLength(36));
      },
    );

    test('every colorKey has a colour, and every colour is used', () {
      final used = universalCore36.map((w) => w.colorKey).toSet();
      expect(used, colorForKey.keys.toSet());
      for (final argb in colorForKey.values) {
        expect(argb >> 24, 0xFF, reason: 'colours are opaque');
      }
    });

    test('colours are the light fills of the six tile families', () {
      expect(colorForKey, {
        'verb': 0xFFC7EFB2,
        'pronoun': 0xFFFFEFA0,
        'descriptor': 0xFFC0DBFF,
        'question': 0xFFDDCBFF,
        'negation': 0xFFFFD2AE,
        'determiner': 0xFFE5E4E0,
      });
    });

    test('part-of-speech counts', () {
      int count(String key) =>
          universalCore36.where((w) => w.colorKey == key).length;
      expect(count('verb'), 14);
      expect(count('pronoun'), 6);
      expect(count('question'), 5);
      expect(count('descriptor'), 8);
      expect(count('determiner'), 2);
      expect(count('negation'), 1);
    });
  });

  group('deterministicId', () {
    test('is UUID v5', () {
      // Published vector: uuid5(NAMESPACE_DNS, 'python.org').
      expect(
        deterministicId('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'python.org'),
        '886313e1-3b8a-5372-9b90-0c9aee199e5d',
      );
    });

    test('is stable across calls and lowercase', () {
      final id = deterministicId(circleA, 'board:home');
      expect(deterministicId(circleA, 'board:home'), id);
      expect(deterministicId(circleA.toUpperCase(), 'board:home'), id);
      expect(id, matches(_uuid));
    });

    test('differs by name and by circle', () {
      expect(
        deterministicId(circleA, 'a'),
        isNot(deterministicId(circleA, 'b')),
      );
      expect(
        deterministicId(circleA, 'a'),
        isNot(deterministicId(circleB, 'a')),
      );
    });
  });

  group('starterBoard', () {
    test('is the 6x6 home board with a deterministic id', () {
      final board = starterBoard(circleA);
      expect(board.id, starterBoardId(circleA));
      expect(board.id, deterministicId(circleA, 'board:home'));
      expect(board.name, 'Home');
      expect(board.rows, 6);
      expect(board.cols, 6);
      expect(board.isHome, isTrue);
      expect(board.archived, isFalse);
      expect(starterBoard(circleA), board);
    });

    test('differs across circles', () {
      expect(starterBoardId(circleA), isNot(starterBoardId(circleB)));
    });
  });

  group('starterTiles', () {
    test('are stable across calls', () {
      expect(tilesFor(circleA), tilesFor(circleA));
    });

    test('have 36 unique ids, different in another circle', () {
      final a = tilesFor(circleA).map((t) => t.id).toSet();
      final b = tilesFor(circleB).map((t) => t.id).toSet();
      expect(a, hasLength(36));
      expect(b, hasLength(36));
      expect(a.intersection(b), isEmpty);
      for (final id in a) {
        expect(id, matches(_uuid));
      }
    });

    test('keys parse as PlacedCell on the starter board', () {
      final board = starterBoard(circleA);
      final tiles = tilesFor(circleA);
      for (var i = 0; i < tiles.length; i++) {
        final tile = tiles[i];
        final word = universalCore36[i];
        final key = CellKey.parse(tile.cellKey);
        expect(key, PlacedCell(board.id, word.row, word.col));
        expect(board.contains(word.row, word.col), isTrue);
        expect(tile.boardId, board.id);
        expect(tile.id, deterministicId(circleA, 'tile:${tile.cellKey}'));
      }
    });

    test('carry the word, its colour key and the creating adult', () {
      final when = DateTime.utc(2026, 10, 13);
      final tiles = tilesFor(circleA);
      for (var i = 0; i < tiles.length; i++) {
        final tile = tiles[i];
        final word = universalCore36[i];
        expect(tile.label, word.label);
        expect(tile.spokenText, word.label);
        expect(tile.colorKey, word.colorKey);
        expect(tile.archived, isFalse);
        expect(tile.createdBy, adult);
        expect(tile.createdByName, 'Mum');
        expect(tile.createdAt, when);
      }
    });

    test('createdAt is optional', () {
      final tiles = starterTiles(
        circleId: circleA,
        createdBy: adult,
        createdByName: 'Mum',
      );
      expect(tiles.every((t) => t.createdAt == null), isTrue);
    });

    test('fill the starter board with nothing left for the tray', () {
      final board = starterBoard(circleA);
      final tiles = tilesFor(circleA);
      expect(gridOf(board.id, tiles, [board]), hasLength(36));
      expect(emptyCells(board, tiles, [board]), isEmpty);
      expect(trayOf(tiles, [board]), isEmpty);
    });
  });
}
