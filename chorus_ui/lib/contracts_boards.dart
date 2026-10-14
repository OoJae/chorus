/// Adding, renaming, archiving and importing boards, as the editor sees it.
///
/// Kept apart from `contracts.dart` so a store can offer it or not: the "+"
/// tab, the long-press menu on a tab and "Import a board (.obf)" appear only
/// for a `BoardStore` that also implements [BoardManager].
library;

import 'package:chorus_shared/chorus_shared.dart';

export 'package:chorus_shared/chorus_shared.dart'
    show
        ObfBoard,
        ObfError,
        ObfPlacement,
        archiveProblem,
        boardNameProblem,
        canArchive,
        defaultBoardName,
        maxBoardNameLength,
        parseObf;

/// What an import made: the new board, and the words that did not fit on
/// it, for the adult to see.
class BoardImport {
  const BoardImport({required this.boardId, this.leftOut = const []});

  final String boardId;

  /// Words outside the new board's grid, in the order the file had them.
  /// Nothing was added for them.
  final List<ObfPlacement> leftOut;
}

/// The circle's boards, as an adult manages them.
///
/// Implemented by the same object as the `BoardStore`, which notifies its
/// listeners when `boards` changes. Every method throws [StateError] for a
/// read-only partner. A new board is the same size as the starter board
/// (6 x 6), so the cells of every board line up.
abstract class BoardManager {
  /// Adds an empty board called [name] (tidied: see `tidyBoardName`) and
  /// completes with its id. Throws [ArgumentError] for a name
  /// [boardNameProblem] refuses.
  Future<String> addBoard(String name);

  /// Renames a board. Throws [ArgumentError] for a name [boardNameProblem]
  /// refuses or a board that is not in use.
  Future<void> renameBoard(String boardId, String name);

  /// Archives a board and the words on it (each archived and given its
  /// tray key, as `archiveTile` does), so they leave with the board instead
  /// of filling "Needs a home". Nothing is deleted. Throws [StateError] when
  /// [archiveProblem] says no: the home board and the last board in use
  /// always stay. Throws [ArgumentError] for an unknown board.
  Future<void> archiveBoard(String boardId);

  /// Adds a new board holding [board]'s words in the cells they had, as far
  /// as they fit (see `obfPlacements`). The name comes from the file
  /// (see `importedBoardName`).
  Future<BoardImport> importBoard(ObfBoard board);
}
