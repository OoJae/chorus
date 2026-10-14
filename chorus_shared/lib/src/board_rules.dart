/// Rules for adding, naming and archiving boards, shared by the replica
/// store, the fakes and the editor.
library;

import 'facts.dart';
import 'tile_text.dart';

/// Longest board name, in characters. Long enough for "Snack time at
/// Grandma's", short enough to fit a tab.
const int maxBoardNameLength = 30;

/// [name] as it is stored: trimmed, with control characters made spaces and
/// every run of spaces or line breaks inside it made one space, so a pasted
/// name cannot break a tab.
String tidyBoardName(String name) => tidyText(name);

/// What is wrong with [name] as a board name, in words for the adult, or
/// null when it can be used. Judged on [tidyBoardName].
String? boardNameProblem(String name) {
  final tidy = tidyBoardName(name);
  if (tidy.isEmpty) return 'Give the board a name.';
  if (tidy.runes.length > maxBoardNameLength) {
    return 'Keep the name to $maxBoardNameLength characters or fewer.';
  }
  return null;
}

/// True when a board in use is already called [name], ignoring case and
/// spacing. Archived boards do not count: their names are free again.
bool boardNameTaken(String name, Iterable<BoardFacts> boards) {
  final wanted = tidyBoardName(name).toLowerCase();
  return boards.any(
    (board) =>
        !board.archived && tidyBoardName(board.name).toLowerCase() == wanted,
  );
}

/// The name offered for a new board: "Board 3" when two boards are in use,
/// counting on past any name a board in use already has.
String defaultBoardName(Iterable<BoardFacts> boards) {
  var n = boards.where((board) => !board.archived).length + 1;
  while (boardNameTaken('Board $n', boards)) {
    n++;
  }
  return 'Board $n';
}

/// A usable name for a board brought in from a file: [wanted] tidied and cut
/// to [maxBoardNameLength], with " 2", " 3" and so on added if a board in
/// use already has it, or [defaultBoardName] when it is empty.
String importedBoardName(String wanted, Iterable<BoardFacts> boards) {
  final base = cutText(tidyBoardName(wanted), maxBoardNameLength);
  if (base.isEmpty) return defaultBoardName(boards);
  if (!boardNameTaken(base, boards)) return base;
  for (var n = 2; ; n++) {
    final suffix = ' $n';
    final name =
        '${cutText(base, maxBoardNameLength - suffix.length).trimRight()}$suffix';
    if (!boardNameTaken(name, boards)) return name;
  }
}

/// Why [board] cannot be archived, in words for the adult, or null when it
/// can. The home board always stays, and so does the last board in use, so
/// the child is never left with nothing to tap.
String? archiveProblem(BoardFacts board, Iterable<BoardFacts> boards) {
  if (board.isHome) return 'The home board stays. It cannot be archived.';
  final live = boards.where((b) => !b.archived);
  if (!live.any((b) => b.id == board.id)) {
    return 'This board is already archived.';
  }
  if (live.length <= 1) return 'Keep at least one board.';
  return null;
}

/// Whether [board] may be archived; see [archiveProblem].
bool canArchive(BoardFacts board, Iterable<BoardFacts> boards) =>
    archiveProblem(board, boards) == null;
