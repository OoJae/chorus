/// The home board every new circle starts with: the 36-word Universal Core
/// vocabulary as colour-coded text tiles. See STARTER_BOARD_LICENSE.md.
library;

import 'package:uuid/uuid.dart';

import 'cell_key.dart';
import 'facts.dart';

/// One word of the starter board and the cell it starts in.
class StarterWord {
  const StarterWord(this.label, this.row, this.col, this.colorKey);

  final String label;
  final int row;
  final int col;

  /// Part-of-speech key; always a key of [colorForKey].
  final String colorKey;

  @override
  String toString() => 'StarterWord("$label", $row:$col, $colorKey)';
}

const int starterRows = 6;
const int starterCols = 6;

/// The starter vocabulary in row-major order: entry `i` sits at row
/// `i ~/ starterCols`, column `i % starterCols`.
const List<StarterWord> universalCore36 = [
  StarterWord('like', 0, 0, 'verb'),
  StarterWord('want', 0, 1, 'verb'),
  StarterWord('get', 0, 2, 'verb'),
  StarterWord('make', 0, 3, 'verb'),
  StarterWord('good', 0, 4, 'descriptor'),
  StarterWord('more', 0, 5, 'descriptor'),
  StarterWord('not', 1, 0, 'negation'),
  StarterWord('go', 1, 1, 'verb'),
  StarterWord('look', 1, 2, 'verb'),
  StarterWord('turn', 1, 3, 'verb'),
  StarterWord('help', 1, 4, 'verb'),
  StarterWord('different', 1, 5, 'descriptor'),
  StarterWord('I', 2, 0, 'pronoun'),
  StarterWord('he', 2, 1, 'pronoun'),
  StarterWord('open', 2, 2, 'verb'),
  StarterWord('do', 2, 3, 'verb'),
  StarterWord('put', 2, 4, 'verb'),
  StarterWord('same', 2, 5, 'descriptor'),
  StarterWord('you', 3, 0, 'pronoun'),
  StarterWord('she', 3, 1, 'pronoun'),
  StarterWord('that', 3, 2, 'pronoun'),
  StarterWord('up', 3, 3, 'descriptor'),
  StarterWord('all', 3, 4, 'determiner'),
  StarterWord('some', 3, 5, 'determiner'),
  StarterWord('it', 4, 0, 'pronoun'),
  StarterWord('here', 4, 1, 'descriptor'),
  StarterWord('in', 4, 2, 'descriptor'),
  StarterWord('on', 4, 3, 'descriptor'),
  StarterWord('can', 4, 4, 'verb'),
  StarterWord('finished', 4, 5, 'verb'),
  StarterWord('where', 5, 0, 'question'),
  StarterWord('what', 5, 1, 'question'),
  StarterWord('why', 5, 2, 'question'),
  StarterWord('who', 5, 3, 'question'),
  StarterWord('when', 5, 4, 'question'),
  StarterWord('stop', 5, 5, 'verb'),
];

/// Tile background per part-of-speech key, as 0xAARRGGBB. A modified
/// Fitzgerald-style key.
const Map<String, int> colorForKey = {
  'verb': 0xFFCCFFAA,
  'pronoun': 0xFFFFFFAA,
  'question': 0xFFCCAAFF,
  'descriptor': 0xFFAACCFF,
  'determiner': 0xFFCCCCCC,
  'negation': 0xFFCCAA88,
};

/// UUID v5 of [name] in the namespace [namespaceUuid], lowercase.
///
/// The same inputs always give the same id, so a retried seed writes the
/// same rows instead of new ones. Throws if [namespaceUuid] is not a UUID.
String deterministicId(String namespaceUuid, String name) =>
    const Uuid().v5(namespaceUuid.toLowerCase(), name).toLowerCase();

/// Id of the circle's home board.
String starterBoardId(String circleId) =>
    deterministicId(circleId, 'board:home');

/// The circle's home board: 'Home', 6x6.
BoardFacts starterBoard(String circleId) => BoardFacts(
      id: starterBoardId(circleId),
      name: 'Home',
      rows: starterRows,
      cols: starterCols,
      isHome: true,
    );

/// The 36 starter tiles, placed on the circle's home board in row-major
/// order. Each id is derived from the circle and the tile's cell key.
List<TileFacts> starterTiles({
  required String circleId,
  required String createdBy,
  required String createdByName,
  DateTime? createdAt,
}) {
  final boardId = starterBoardId(circleId);
  return [
    for (final word in universalCore36)
      _starterTile(
        circleId: circleId,
        boardId: boardId,
        word: word,
        createdBy: createdBy,
        createdByName: createdByName,
        createdAt: createdAt,
      ),
  ];
}

TileFacts _starterTile({
  required String circleId,
  required String boardId,
  required StarterWord word,
  required String createdBy,
  required String createdByName,
  required DateTime? createdAt,
}) {
  final cellKey = placedKey(boardId, word.row, word.col);
  return TileFacts(
    id: deterministicId(circleId, 'tile:$cellKey'),
    boardId: boardId,
    cellKey: cellKey,
    label: word.label,
    colorKey: word.colorKey,
    createdBy: createdBy,
    createdByName: createdByName,
    createdAt: createdAt,
  );
}
