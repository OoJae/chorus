import 'dart:convert';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

void main() {
  const home = BoardFacts(
    id: 'home',
    name: 'Home',
    rows: 3,
    cols: 3,
    isHome: true,
  );
  const food = BoardFacts(id: 'food', name: 'Food', rows: 2, cols: 2);
  const old = BoardFacts(
    id: 'old',
    name: 'Old',
    rows: 2,
    cols: 2,
    archived: true,
  );
  const boards = [home, food, old];

  TileFacts tile(
    String id,
    String label, {
    String board = 'home',
    int row = 0,
    int col = 0,
    String? speech,
  }) => TileFacts(
    id: id,
    boardId: board,
    cellKey: placedKey(board, row, col),
    label: label,
    speech: speech,
  );

  group('findWords', () {
    final tiles = [
      tile('t1', 'eat', row: 0, col: 1),
      tile('t2', 'more', row: 1, col: 2),
      tile('t3', 'Eating out', board: 'food', row: 1, col: 0),
      tile('t4', 'yum', board: 'food', speech: 'I like to eat'),
      tile('t5', 'eat', board: 'old'),
      TileFacts(
        id: 't6',
        boardId: 'home',
        cellKey: trayKey('t6'),
        label: 'eat',
      ),
    ];

    test('finds by label and spoken text, best match first', () {
      final found = findWords('  EAT ', tiles, boards);
      expect([for (final f in found) f.tile.id], ['t1', 't3', 't4']);
      expect(found.first.board, home);
      expect((found.first.row, found.first.col), (0, 1));
      expect(found[1].board, food);
      expect((found[1].row, found[1].col), (1, 0));
    });

    test('leaves out archived boards and the tray', () {
      final ids = [for (final f in findWords('eat', tiles, boards)) f.tile.id];
      expect(ids, isNot(contains('t5')));
      expect(ids, isNot(contains('t6')));
    });

    test('an empty query finds nothing, a miss finds nothing', () {
      expect(findWords('', tiles, boards), isEmpty);
      expect(findWords('  ', tiles, boards), isEmpty);
      expect(findWords('zebra', tiles, boards), isEmpty);
    });

    test('keeps to the limit', () {
      final many = [
        for (var i = 0; i < 9; i++)
          tile('m$i', 'more $i', row: i ~/ 3, col: i % 3),
      ];
      expect(findWords('more', many, boards, limit: 4), hasLength(4));
    });
  });

  group('wordStem', () {
    test('forgives plurals and -ing', () {
      expect(wordStem('cars'), wordStem('car'));
      expect(wordStem('eating'), wordStem('eat'));
      expect(wordStem('running'), wordStem('run'));
      expect(wordStem('making'), wordStem('make'));
      expect(wordStem('bubbles'), wordStem('bubble'));
      expect(wordStem('boxes'), wordStem('box'));
      expect(wordStem('babies'), wordStem('baby'));
      expect(wordStem('Helping'), wordStem('help'));
    });

    test('leaves short words alone', () {
      expect(wordStem('is'), 'is');
      expect(wordStem('yes'), 'yes');
      expect(wordStem('sing'), 'sing');
      expect(wordStem('glass'), 'glass');
      expect(wordStem('is'), isNot(wordStem('I')));
    });
  });

  group('matchSpokenWords', () {
    final tiles = [
      tile('more', 'more'),
      tile('bubble', 'bubble'),
      tile('want', 'want', speech: 'I want'),
      tile('done', 'all done'),
      tile('all', 'all'),
      tile('eat', 'eat'),
      tile('i', 'I'),
    ];

    test('finds the words in the order they were said', () {
      final hit = matchSpokenWords('Do you want MORE bubbles?', tiles);
      expect([for (final t in hit) t.id], ['want', 'more', 'bubble']);
    });

    test('a label of several words wins over its parts', () {
      final hit = matchSpokenWords("We're all done eating", tiles);
      expect([for (final t in hit) t.id], ['done', 'eat']);
    });

    test('a word said twice in a row glows once', () {
      final hit = matchSpokenWords('more more more', tiles);
      expect([for (final t in hit) t.id], ['more']);
    });

    test('spoken text matches too', () {
      final hit = matchSpokenWords('I want', tiles);
      expect([for (final t in hit) t.id], ['want']);
    });

    test('nothing heard, nothing matched; the limit holds', () {
      expect(matchSpokenWords('', tiles), isEmpty);
      expect(matchSpokenWords('the cat sat', tiles), isEmpty);
      expect(
        matchSpokenWords('more eat more eat more eat', tiles, limit: 3),
        hasLength(3),
      );
    });
  });

  group('modelledVersusSaid', () {
    final monday = DateTime.utc(2026, 10, 12);
    final tiles = [
      tile('a', 'Go'),
      tile('b', 'go', board: 'food'),
      tile('c', 'help', row: 1),
      tile('d', 'more', row: 2),
    ];
    WordUse use(String id, DateTime at) =>
        WordUse(tileId: id, boardId: 'home', spokenAt: at);
    final tue = monday.add(const Duration(days: 1));

    test('counts per word, most modelled first', () {
      final rows = modelledVersusSaid(
        [use('a', tue), use('b', tue), use('d', tue)],
        [
          use('a', tue),
          use('b', tue),
          use('a', tue),
          use('c', tue),
          use('c', tue),
          // Last week and unknown tiles are not counted.
          use('a', monday.subtract(const Duration(days: 1))),
          use('zz', tue),
        ],
        tiles,
        monday,
      );
      expect(rows, [
        const ModelledCount('Go', modelled: 3, said: 2),
        const ModelledCount('help', modelled: 2, said: 0),
      ]);
      expect(modelledLine(3, 2), 'modelled 3 · said 2');
    });

    test('the week summary carries it through JSON', () {
      final week = WeekSummary(
        weekStart: monday,
        topWords: const [],
        firstTimeWords: const [],
        addedWords: const [],
        notUsedYet: const [],
        totalUses: 0,
        wordsUsed: 0,
        modelled: const [ModelledCount('go', modelled: 4, said: 1)],
      );
      final back = WeekSummary.fromJson(
        jsonDecode(jsonEncode(week.toJson())) as Map<String, Object?>,
      );
      expect(back.modelled, week.modelled);
      final older = week.toJson()..remove('modelled');
      expect(WeekSummary.fromJson(older).modelled, isEmpty);
    });
  });
}
