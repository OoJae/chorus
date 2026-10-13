/// The paper backup of a board, as the app sends it to be printed.
///
/// Built from the device's own replica, so the printed page shows what this
/// device shows. Only words that hold a cell are included, and only their
/// text and colour: no photos, no recordings, no names of the adults.
library;

import 'dart:convert';

import 'facts.dart';
import 'tray.dart';

/// The board an adult would print: the home board, else the first board
/// still in use. Null when the circle has none.
BoardFacts? boardToPrint(Iterable<BoardFacts> boards) {
  final live = boards.where((board) => !board.archived);
  return live.where((board) => board.isHome).firstOrNull ?? live.firstOrNull;
}

/// The snapshot of [board] as JSON:
///
/// ```json
/// {"childName": "Ada", "name": "Home", "rows": 6, "cols": 6,
///  "tiles": [{"row": 0, "col": 0, "label": "like", "colorKey": "verb"}]}
/// ```
///
/// Tiles are in row-major order. Archived, tray and contested tiles are
/// left out, because [gridOf] decides which tile holds each cell.
String printSnapshotJson({
  required String childName,
  required BoardFacts board,
  required Iterable<TileFacts> tiles,
  required Iterable<BoardFacts> boards,
}) {
  final grid = gridOf(board.id, tiles, boards);
  final cells = grid.keys.toList()
    ..sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
  return jsonEncode({
    'childName': childName,
    'name': board.name,
    'rows': board.rows,
    'cols': board.cols,
    'tiles': [
      for (final cell in cells)
        {
          'row': cell.$1,
          'col': cell.$2,
          'label': grid[cell]!.label,
          if (grid[cell]!.colorKey != null) 'colorKey': grid[cell]!.colorKey,
        },
    ],
  });
}
