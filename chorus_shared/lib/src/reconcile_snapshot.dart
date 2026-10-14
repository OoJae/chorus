/// The held snapshot: what the child's board shows, and how it may change.
///
/// The talker renders from a [BoardSnapshot] rather than from the replica, so
/// a merge never moves a word under the child's finger. [reconcileSnapshot]
/// splits the difference between the held snapshot and the replica into
/// changes that are safe to apply and changes an adult has to accept.
library;

import 'facts.dart';
import 'tray.dart';

/// One board and the tiles occupying its cells, keyed by (row, col).
class BoardSnapshot {
  const BoardSnapshot(this.board, this.cells);

  final BoardFacts board;
  final Map<(int, int), TileFacts> cells;

  /// The snapshot of [board] as the replica has it now. Uses [gridOf], so
  /// archived, tray, contested and off-grid tiles are left out.
  static BoardSnapshot of(
    BoardFacts board,
    Iterable<TileFacts> tiles,
    Iterable<BoardFacts> boards,
  ) => BoardSnapshot(board, Map.unmodifiable(gridOf(board.id, tiles, boards)));

  @override
  bool operator ==(Object other) {
    if (other is! BoardSnapshot ||
        other.board != board ||
        other.cells.length != cells.length) {
      return false;
    }
    for (final entry in cells.entries) {
      if (other.cells[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    board,
    Object.hashAllUnordered(
      cells.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() => 'BoardSnapshot(${board.id}, ${cells.length} tiles)';
}

/// How one cell differs between the held snapshot and the replica.
enum ChangeKind {
  /// A tile the child has not seen arrives in a cell that is empty. Automatic.
  added,

  /// The same tile in the same cell with different content. Automatic.
  updated,

  /// A tile is gone and nothing takes its cell; leaves a gap. Automatic.
  removed,

  /// The cell would show a different tile than it shows now. Needs an adult.
  replaced,

  /// A tile the child can see would appear in a different cell. Needs an adult.
  relocated,
}

/// One difference at cell ([row], [col]).
///
/// [before] is the tile as the child sees it now and [after] the tile as the
/// replica has it. For [ChangeKind.relocated], [row] and [col] are the cell
/// the tile would move into, which is empty in the held snapshot; [before]
/// still carries the cell it is shown in.
class SnapshotChange {
  const SnapshotChange(
    this.kind,
    this.row,
    this.col, {
    this.before,
    this.after,
  });

  final ChangeKind kind;
  final int row;
  final int col;
  final TileFacts? before;
  final TileFacts? after;

  @override
  bool operator ==(Object other) =>
      other is SnapshotChange &&
      other.kind == kind &&
      other.row == row &&
      other.col == col &&
      other.before == before &&
      other.after == after;

  @override
  int get hashCode => Object.hash(kind, row, col, before, after);

  @override
  String toString() =>
      'SnapshotChange(${kind.name}, $row:$col, ${before?.id} -> ${after?.id})';
}

/// The result of [reconcileSnapshot].
class SnapshotPlan {
  const SnapshotPlan({
    required this.next,
    required this.auto,
    required this.needsAdult,
  });

  /// The held snapshot with only the [auto] changes applied. Its board is
  /// the replica's unless the grid was resized; see [reconcileSnapshot].
  final BoardSnapshot next;

  /// Changes that may be applied at the next safe point.
  final List<SnapshotChange> auto;

  /// Changes that would alter what a cell the child knows means. They stay
  /// out of [next] until an adult applies them.
  final List<SnapshotChange> needsAdult;

  int get waitingCount => auto.length + needsAdult.length;

  bool get isEmpty => auto.isEmpty && needsAdult.isEmpty;
}

/// Plans the move from [current], what the child sees now, towards [fresh],
/// the replica's present state of the same board.
///
/// A cell occupied in [current] keeps its tile id or becomes empty, and no
/// tile id shown in [current] turns up in another cell: those cases are
/// reported in [SnapshotPlan.needsAdult] and left untouched. A relocated
/// tile stays where it is shown and its new cell stays empty. A tile that
/// lands in a cell occupied by another is reported once, as replaced.
///
/// Both lists are in row-major order. The plan's board is [fresh]'s while
/// the grid keeps its size, so a rename arrives with the next swap. A resize
/// re-lays out every cell, so it is held back: the plan keeps [current]'s
/// board, and `next.board != fresh.board` then means an adult has to accept
/// it even when both lists are empty. Reconciling the plan's `next` against
/// [fresh] again yields no auto changes and the same needsAdult changes.
SnapshotPlan reconcileSnapshot(BoardSnapshot current, BoardSnapshot fresh) {
  final shownAt = <String, (int, int)>{
    for (final entry in current.cells.entries) entry.value.id: entry.key,
  };
  final freshIds = <String>{for (final tile in fresh.cells.values) tile.id};
  final cells = <(int, int)>{
    ...current.cells.keys,
    ...fresh.cells.keys,
  }.toList()..sort(_rowMajor);

  final next = Map<(int, int), TileFacts>.of(current.cells);
  final auto = <SnapshotChange>[];
  final needsAdult = <SnapshotChange>[];

  for (final cell in cells) {
    final (row, col) = cell;
    final before = current.cells[cell];
    final after = fresh.cells[cell];
    if (before == null) {
      // The cell came from the union of both maps, so fresh fills it.
      final arriving = after!;
      final shown = shownAt[arriving.id];
      if (shown == null) {
        auto.add(SnapshotChange(ChangeKind.added, row, col, after: arriving));
        next[cell] = arriving;
      } else {
        needsAdult.add(
          SnapshotChange(
            ChangeKind.relocated,
            row,
            col,
            before: current.cells[shown],
            after: arriving,
          ),
        );
      }
    } else if (after == null) {
      // A tile that only moved away stays put until an adult accepts the
      // move, which is reported at the cell it moved into.
      if (!freshIds.contains(before.id)) {
        auto.add(SnapshotChange(ChangeKind.removed, row, col, before: before));
        next.remove(cell);
      }
    } else if (after.id == before.id) {
      if (after != before) {
        auto.add(
          SnapshotChange(
            ChangeKind.updated,
            row,
            col,
            before: before,
            after: after,
          ),
        );
        next[cell] = after;
      }
    } else {
      needsAdult.add(
        SnapshotChange(
          ChangeKind.replaced,
          row,
          col,
          before: before,
          after: after,
        ),
      );
    }
  }

  final sameGrid =
      current.board.rows == fresh.board.rows &&
      current.board.cols == fresh.board.cols;
  return SnapshotPlan(
    next: BoardSnapshot(
      sameGrid ? fresh.board : current.board,
      Map.unmodifiable(next),
    ),
    auto: List.unmodifiable(auto),
    needsAdult: List.unmodifiable(needsAdult),
  );
}

int _rowMajor((int, int) a, (int, int) b) {
  final byRow = a.$1.compareTo(b.$1);
  return byRow != 0 ? byRow : a.$2.compareTo(b.$2);
}

/// What the child is doing with the talker right now.
class TalkerActivity {
  const TalkerActivity({
    required this.stripEmpty,
    required this.speaking,
    required this.sinceLastTouch,
  });

  /// The sentence strip holds no tiles.
  final bool stripEmpty;

  /// Speech is playing.
  final bool speaking;

  /// Time since a finger last touched the board.
  final Duration sinceLastTouch;
}

/// Whether the held snapshot may swap now: the strip is empty, nothing is
/// being spoken, and the board has been untouched for at least [quiet].
bool isSafePoint(
  TalkerActivity activity, {
  Duration quiet = const Duration(seconds: 2),
}) =>
    activity.stripEmpty &&
    !activity.speaking &&
    activity.sinceLastTouch >= quiet;
