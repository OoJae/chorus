/// Where every tile of a circle currently is: on a board cell, or waiting in
/// the tray for an adult to place it.
///
/// Run these after every merge. The sync engine reports a lost cell only by
/// rewriting the loser's key, so the tray has to be derived, not listened for.
library;

import 'cell_key.dart';
import 'facts.dart';

/// Why a tile is in the tray.
enum TrayReason {
  /// Another tile claimed the same cell first; the engine suffixed this one.
  contested,

  /// Carries a tray key: never placed, or taken off the board.
  unplaced,

  /// Names a cell that cannot be shown: the board is missing or archived,
  /// the cell is outside the grid, or the key is not understood.
  offGrid,

  /// Shares a placed key with an older tile. Only possible if the unique
  /// index is ever dropped.
  duplicateCell,
}

/// A tile that needs an adult to give it a home.
class TrayEntry {
  const TrayEntry(this.tile, this.reason, {this.wanted});

  final TileFacts tile;
  final TrayReason reason;

  /// The cell the tile asked for. Set for [TrayReason.contested] and
  /// [TrayReason.duplicateCell], null otherwise.
  final PlacedCell? wanted;

  @override
  bool operator ==(Object other) =>
      other is TrayEntry &&
      other.tile == tile &&
      other.reason == reason &&
      other.wanted == wanted;

  @override
  int get hashCode => Object.hash(tile, reason, wanted);

  @override
  String toString() =>
      'TrayEntry(${tile.id}, ${reason.name}'
      '${wanted == null ? '' : ', wanted $wanted'})';
}

/// Oldest first; tiles without a creation time last; ties broken by id.
int _byAge(TileFacts a, TileFacts b) {
  final at = a.createdAt, bt = b.createdAt;
  if (at != null && bt != null) {
    final c = at.compareTo(bt);
    if (c != 0) return c;
  } else if (at != null) {
    return -1;
  } else if (bt != null) {
    return 1;
  }
  return a.id.compareTo(b.id);
}

/// Sorts every non-archived tile into the cell it holds or a tray entry.
({Map<PlacedCell, TileFacts> held, List<TrayEntry> tray}) _sortTiles(
  Iterable<TileFacts> tiles,
  Iterable<BoardFacts> boards,
) {
  final boardById = {for (final b in boards) b.id: b};
  final held = <PlacedCell, TileFacts>{};
  final tray = <TrayEntry>[];

  // Oldest first, so the first tile to reach a cell is the one that keeps it.
  final live = tiles.where((t) => !t.archived).toList()..sort(_byAge);
  for (final tile in live) {
    switch (CellKey.parse(tile.cellKey)) {
      case TrayCell():
        tray.add(TrayEntry(tile, TrayReason.unplaced));
      case ContestedCell(:final wanted):
        tray.add(TrayEntry(tile, TrayReason.contested, wanted: wanted));
      case UnknownCell():
        tray.add(TrayEntry(tile, TrayReason.offGrid));
      case PlacedCell cell:
        final board = boardById[cell.boardId];
        if (board == null ||
            board.archived ||
            !board.contains(cell.row, cell.col)) {
          tray.add(TrayEntry(tile, TrayReason.offGrid));
        } else if (held.containsKey(cell)) {
          tray.add(TrayEntry(tile, TrayReason.duplicateCell, wanted: cell));
        } else {
          held[cell] = tile;
        }
    }
  }
  return (held: held, tray: tray);
}

/// The non-archived tiles that need an adult to give them a home, ordered by
/// creation time (tiles without one last), then id.
///
/// The position is read from each tile's `cellKey` alone.
List<TrayEntry> trayOf(
  Iterable<TileFacts> tiles,
  Iterable<BoardFacts> boards,
) => _sortTiles(tiles, boards).tray;

/// The tiles occupying cells of one board, keyed by (row, col).
///
/// Excludes archived, tray, contested and off-grid tiles, and is empty for a
/// missing or archived board. If two tiles carry the same placed key, the
/// one created first (no creation time counts as last), then the smallest
/// id, holds the cell; the other is in [trayOf] as
/// [TrayReason.duplicateCell].
Map<(int, int), TileFacts> gridOf(
  String boardId,
  Iterable<TileFacts> tiles,
  Iterable<BoardFacts> boards,
) {
  final held = _sortTiles(tiles, boards).held;
  return {
    for (final MapEntry(key: cell, value: tile) in held.entries)
      if (cell.boardId == boardId) (cell.row, cell.col): tile,
  };
}

/// The cells of [board] that [gridOf] shows no tile in, in row-major order.
///
/// The size and archived flag come from the entry for [board]'s id in
/// [boards], the one [gridOf] and [trayOf] judge placement by, so a stale
/// [board] never offers a cell that would be off-grid. Empty when that entry
/// is missing or archived, since nothing may be placed there.
///
/// An archived tile that still carries a placed key is not counted here but
/// still holds its key in the replica, so placing into such a cell can be
/// refused; callers must be ready to fall back to the tray key.
List<(int, int)> emptyCells(
  BoardFacts board,
  Iterable<TileFacts> tiles,
  Iterable<BoardFacts> boards,
) {
  final live = boards.where((b) => b.id == board.id).lastOrNull;
  if (live == null || live.archived) return const [];
  final grid = gridOf(live.id, tiles, boards);
  return [
    for (var row = 0; row < live.rows; row++)
      for (var col = 0; col < live.cols; col++)
        if (!grid.containsKey((row, col))) (row, col),
  ];
}
