/// Named copies of a board, such as "Before the school trip": what a copy
/// holds, and whether one of its words can be put back.
///
/// A copy is kept on the server and never changes the board. Putting a word
/// back adds it as a new word in "Needs a home", so an adult chooses its
/// cell; a placed word is never moved or replaced.
library;

import 'cell_key.dart';
import 'facts.dart';
import 'tile_text.dart';
import 'tray.dart';

/// Longest copy name, in characters.
const int maxCopyNameLength = 40;

/// Most copies one circle keeps.
const int maxCopiesPerCircle = 100;

/// What is wrong with [name] as a copy name, in words for the adult, or
/// null when it can be used. Judged on [tidyText].
String? copyNameProblem(String name) {
  final tidy = tidyText(name);
  if (tidy.isEmpty) return 'Give the copy a name.';
  if (tidy.runes.length > maxCopyNameLength) {
    return 'Keep the name to $maxCopyNameLength characters or fewer.';
  }
  return null;
}

/// One word as a copy keeps it.
class CopyWordFacts {
  const CopyWordFacts({
    required this.label,
    required this.cellKey,
    this.speech,
    this.colorKey,
    this.imageHash,
  });

  final String label;
  final String? speech;
  final String? colorKey;
  final String? imageHash;

  /// The cell it held when the copy was taken: `<boardId>:<row>:<col>`.
  final String cellKey;

  /// The cell it held, or null for a key that is not a placed one.
  PlacedCell? get cell => switch (CellKey.parse(cellKey)) {
    PlacedCell cell => cell,
    _ => null,
  };

  @override
  bool operator ==(Object other) =>
      other is CopyWordFacts &&
      other.label == label &&
      other.speech == speech &&
      other.colorKey == colorKey &&
      other.imageHash == imageHash &&
      other.cellKey == cellKey;

  @override
  int get hashCode => Object.hash(label, speech, colorKey, imageHash, cellKey);

  @override
  String toString() => 'CopyWordFacts("$label", $cellKey)';
}

/// The words on [boardId] as [gridOf] shows them, in row-major order: what
/// a copy of the board keeps.
List<CopyWordFacts> copyWordsOf(
  String boardId,
  Iterable<TileFacts> tiles,
  Iterable<BoardFacts> boards,
) {
  final grid = gridOf(boardId, tiles, boards);
  final cells = grid.keys.toList()
    ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  return [
    for (final cell in cells)
      CopyWordFacts(
        label: grid[cell]!.label,
        speech: grid[cell]!.speech,
        colorKey: grid[cell]!.colorKey,
        imageHash: grid[cell]!.imageHash,
        cellKey: placedKey(boardId, cell.$1, cell.$2),
      ),
  ];
}

/// Where a word of a copy is now, on its board.
enum CopyWordState {
  /// A word with the same label is on the board.
  onBoard,

  /// A word with the same label is waiting in "Needs a home" for the board.
  waiting,

  /// Neither: it can be put back.
  gone,
}

String _sameWord(String label) => tidyText(label).toLowerCase();

/// Where [word] of a copy of [boardId] is now, judged by its label, ignoring
/// case and spacing.
CopyWordState copyWordState(
  CopyWordFacts word,
  String boardId,
  Iterable<TileFacts> tiles,
  Iterable<BoardFacts> boards,
) {
  final wanted = _sameWord(word.label);
  final onBoard = gridOf(
    boardId,
    tiles,
    boards,
  ).values.any((tile) => _sameWord(tile.label) == wanted);
  if (onBoard) return CopyWordState.onBoard;
  final waiting = trayOf(tiles, boards).any(
    (entry) =>
        entry.tile.boardId == boardId && _sameWord(entry.tile.label) == wanted,
  );
  return waiting ? CopyWordState.waiting : CopyWordState.gone;
}
