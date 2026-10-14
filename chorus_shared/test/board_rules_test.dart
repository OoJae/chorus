import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

void main() {
  const home = BoardFacts(
    id: 'home',
    name: 'Home',
    rows: 6,
    cols: 6,
    isHome: true,
  );
  const words = BoardFacts(id: 'words', name: 'My words', rows: 6, cols: 6);
  BoardFacts board(String id, String name, {bool archived = false}) =>
      BoardFacts(id: id, name: name, rows: 6, cols: 6, archived: archived);

  group('default name', () {
    test('counts the boards in use', () {
      expect(defaultBoardName([home]), 'Board 2');
      expect(defaultBoardName([home, words]), 'Board 3');
      expect(defaultBoardName(const []), 'Board 1');
    });

    test('never repeats the name of a board in use', () {
      expect(defaultBoardName([home, board('a', 'board 3')]), 'Board 4');
      expect(
        defaultBoardName([home, board('a', 'Board 3'), board('b', 'Board 4')]),
        'Board 5',
      );
    });

    test('archived boards neither count nor block a name', () {
      expect(
        defaultBoardName([home, words, board('a', 'Board 3', archived: true)]),
        'Board 3',
      );
    });
  });

  group('name validation', () {
    test('trims and accepts 1 to 30 characters', () {
      expect(boardNameProblem('Snacks'), isNull);
      expect(boardNameProblem('  Snacks  '), isNull);
      expect(boardNameProblem('a'), isNull);
      expect(boardNameProblem('a' * 30), isNull);
      expect(boardNameProblem(' ${'a' * 30} '), isNull);
    });

    test('refuses an empty name or one over 30 characters', () {
      expect(boardNameProblem(''), 'Give the board a name.');
      expect(boardNameProblem('   \n'), 'Give the board a name.');
      expect(
        boardNameProblem('a' * 31),
        'Keep the name to 30 characters or fewer.',
      );
    });

    test('counts characters, not code units', () {
      expect(boardNameProblem('\u{1F34E}' * 30), isNull);
      expect(boardNameProblem('\u{1F34E}' * 31), isNotNull);
    });

    test('tidies spaces and line breaks', () {
      expect(tidyBoardName('  Snack\n  time '), 'Snack time');
    });

    test('makes control characters spaces, so a pasted or imported name '
        'stays on one line', () {
      expect(tidyBoardName('Snack\u0000time\u0085now\u007F'), 'Snack time now');
      expect(boardNameProblem('\u0000\u0001'), 'Give the board a name.');
    });
  });

  group('tile text', () {
    test('tidies onto one line, and cuts to a length when asked', () {
      expect(tidyText(' I\r\nwant\t\tmore '), 'I want more');
      expect(tidyText('juice\u0007box'), 'juice box');
      expect(tidyText('a' * 40, maxLength: 30), 'a' * 30);
      // A cut that ends on a space leaves no space at the end.
      expect(tidyText('${'a' * 29} b', maxLength: 30), 'a' * 29);
      expect(tidyText('more', maxLength: 30), 'more');
    });

    test('cuts by character, never through one', () {
      expect(cutText('\u{1F34E}' * 3, 2), '\u{1F34E}' * 2);
      expect(cutText('ab', 5), 'ab');
    });
  });

  group('imported name', () {
    test('keeps a free name, tidied', () {
      expect(importedBoardName('  Snacks ', [home]), 'Snacks');
    });

    test('numbers a name already in use', () {
      expect(importedBoardName('Home', [home]), 'Home 2');
      expect(importedBoardName('home', [home, board('a', 'Home 2')]), 'home 3');
    });

    test('cuts a long name to fit, number included', () {
      final long = 'x' * 40;
      expect(importedBoardName(long, [home]), 'x' * 30);
      expect(
        importedBoardName(long, [home, board('a', 'x' * 30)]),
        '${'x' * 28} 2',
      );
    });

    test('falls back to the default name', () {
      expect(importedBoardName('  ', [home, words]), 'Board 3');
    });
  });

  group('archiving', () {
    test('never the home board', () {
      expect(canArchive(home, [home, words]), isFalse);
      expect(archiveProblem(home, [home, words]), contains('home board'));
    });

    test('never the last board in use', () {
      final only = board('a', 'Only');
      expect(
        canArchive(only, [only, board('b', 'Old', archived: true)]),
        isFalse,
      );
      expect(archiveProblem(only, [only]), 'Keep at least one board.');
    });

    test('any other board in use', () {
      expect(canArchive(words, [home, words]), isTrue);
      expect(archiveProblem(words, [home, words]), isNull);
    });

    test('not a board that is already archived', () {
      final old = board('a', 'Old', archived: true);
      expect(canArchive(old, [home, words, old]), isFalse);
    });
  });
}
