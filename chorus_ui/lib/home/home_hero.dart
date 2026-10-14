/// The home screen's hero: the child's own board as an object.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../brand/board_object.dart';
import '../brand/motion.dart';
import '../brand/symbols.dart';
import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_media.dart';
import 'board_flight.dart';

/// The board home shows: the home board, else the first board still in use.
/// Null when the circle has none on this device yet.
BoardFacts? heroBoardOf(BoardStore store) => boardToPrint(store.boards);

/// The words [board] shows, as [BoardObject] cells: the tiles that hold a
/// cell (as the child's board decides it), each in its colour family, with
/// its own photo when this device has it and otherwise the symbol for its
/// word, if there is one.
List<BoardCell> heroCellsOf(
  BoardFacts board,
  BoardStore store, {
  MediaStore? media,
}) {
  final grid = gridOf(board.id, store.tiles, store.boards);
  return [
    for (final MapEntry(key: (row, col), value: tile) in grid.entries)
      BoardCell(
        row: row,
        col: col,
        label: tile.label,
        family: TileFamily.forKey(tile.colorKey),
        image: media?.imageFor(tile.imageHash) ?? symbolImageFor(tile.label),
      ),
  ];
}

/// The cells of a board still on its way: grey laminated tiles with no
/// words, holding the board's space.
List<BoardCell> skeletonCells({
  int rows = starterRows,
  int cols = starterCols,
}) => [
  for (var row = 0; row < rows; row++)
    for (var col = 0; col < cols; col++)
      BoardCell(row: row, col: col, label: ''),
];

/// The child's board on home, drawn live from [store]: it changes as words
/// are added, here or on another device, and gains a photo as soon as it is
/// on this device.
///
/// It tilts under the thumb and leans back with [lean]. A tap calls
/// [onOpen], and the board flies flat into the child's board (see
/// [BoardHero]) when the system allows motion.
///
/// While [loading], or before the circle has a board here, it is a still
/// skeleton of grey tiles that keeps the board's space; screen readers skip
/// it, as the note under it says what is happening.
class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.store,
    required this.childName,
    this.media,
    this.lean,
    this.onOpen,
    this.loading = false,
  });

  final BoardStore store;
  final String childName;
  final MediaStore? media;
  final ValueListenable<double>? lean;

  /// Opens the child's board. Null leaves the board a picture.
  final VoidCallback? onOpen;

  /// True while the boards saved on this device are still being read.
  final bool loading;

  /// The hero's board, for tests.
  @visibleForTesting
  static const Key boardKey = ValueKey('HomeHero.board');

  /// The skeleton, for tests.
  @visibleForTesting
  static const Key skeletonKey = ValueKey('HomeHero.skeleton');

  @override
  Widget build(BuildContext context) {
    final media = this.media;
    return ListenableBuilder(
      listenable: media == null ? store : Listenable.merge([store, media]),
      builder: (context, _) {
        final board = loading ? null : heroBoardOf(store);
        if (board == null) {
          return ExcludeSemantics(
            child: BoardObject(
              key: skeletonKey,
              rows: starterRows,
              cols: starterCols,
              cells: skeletonCells(),
              lean: lean,
            ),
          );
        }
        final cells = heroCellsOf(board, store, media: media);
        final onOpen = this.onOpen;
        final words = cells.length;
        final standing = BoardObject(
          key: boardKey,
          rows: board.rows,
          cols: board.cols,
          cells: cells,
          lean: lean,
          onTap: onOpen,
          semanticLabel: words == 0
              ? "$childName's board, no words yet"
              : words == 1
              ? "$childName's board, 1 word"
              : "$childName's board, $words words",
        );
        if (onOpen == null || ChorusMotion.reduced(context)) return standing;
        return BoardHero(
          tag: boardHeroTag(board.id),
          flat: BoardObject(rows: board.rows, cols: board.cols, cells: cells),
          child: standing,
        );
      },
    );
  }
}
