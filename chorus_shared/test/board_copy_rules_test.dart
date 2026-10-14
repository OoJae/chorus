import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

void main() {
  const home = BoardFacts(
    id: 'home',
    name: 'Home',
    rows: 2,
    cols: 3,
    isHome: true,
  );
  const other = BoardFacts(id: 'other', name: 'Food', rows: 2, cols: 3);
  final boards = [home, other];

  TileFacts tile(
    String id,
    String label,
    String cellKey, {
    String board = 'home',
    bool archived = false,
    String? imageHash,
  }) => TileFacts(
    id: id,
    boardId: board,
    cellKey: cellKey,
    label: label,
    colorKey: 'noun',
    imageHash: imageHash,
    archived: archived,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  group('copy name', () {
    test('needs a name of at most 40 characters', () {
      expect(copyNameProblem(''), 'Give the copy a name.');
      expect(copyNameProblem('Before the school trip'), isNull);
      expect(copyNameProblem('a' * 41), isNotNull);
    });
  });

  group('the words a copy keeps', () {
    test('are the placed words of that board, row by row', () {
      final tiles = [
        tile('b', 'drink', placedKey('home', 1, 0), imageHash: 'h'),
        tile('a', 'eat', placedKey('home', 0, 2)),
        tile('c', 'apple', placedKey('other', 0, 0), board: 'other'),
        tile('d', 'gone', trayKey('d')),
        tile('e', 'old', placedKey('home', 0, 0), archived: true),
      ];
      final words = copyWordsOf('home', tiles, boards);
      expect(words.map((w) => w.label), ['eat', 'drink']);
      expect(words[0].cellKey, 'home:0:2');
      expect(words[1].imageHash, 'h');
      expect(words[1].colorKey, 'noun');
      expect(words[1].cell, const PlacedCell('home', 1, 0));
    });

    test('a word with a key that is not a cell has no cell', () {
      const word = CopyWordFacts(label: 'x', cellKey: 'tray:1');
      expect(word.cell, isNull);
    });
  });

  group('putting a word back', () {
    const eat = CopyWordFacts(label: 'Eat', cellKey: 'home:0:0');

    test('a word still on the board is on the board, ignoring case', () {
      final tiles = [tile('a', ' eat ', placedKey('home', 1, 2))];
      expect(copyWordState(eat, 'home', tiles, boards), CopyWordState.onBoard);
    });

    test('a word waiting in "Needs a home" for the board is waiting', () {
      final tiles = [tile('a', 'eat', trayKey('a'))];
      expect(copyWordState(eat, 'home', tiles, boards), CopyWordState.waiting);
    });

    test('a removed word, or one on another board, is gone', () {
      final tiles = [
        tile('a', 'eat', trayKey('a'), archived: true),
        tile('b', 'eat', placedKey('other', 0, 0), board: 'other'),
      ];
      expect(copyWordState(eat, 'home', tiles, boards), CopyWordState.gone);
    });
  });
}
