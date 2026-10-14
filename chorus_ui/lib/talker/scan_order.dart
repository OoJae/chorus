/// Row then word scanning over a board, as pure logic: where the highlight
/// goes next, and what a switch press selects.
library;

/// Whether the highlight is on a whole row or on one word in it.
enum ScanPhase { rows, cells }

/// Where the highlight is.
class ScanPosition {
  const ScanPosition(this.phase, this.row, [this.col]);

  final ScanPhase phase;

  /// The board row highlighted, or the row of the highlighted word.
  final int row;

  /// The highlighted word's column; null while a row is highlighted.
  final int? col;

  @override
  bool operator ==(Object other) =>
      other is ScanPosition &&
      other.phase == phase &&
      other.row == row &&
      other.col == col;

  @override
  int get hashCode => Object.hash(phase, row, col);

  @override
  String toString() => col == null ? 'row $row' : 'cell ($row, $col)';
}

/// What a switch press did: moved into a row, or chose a word.
class ScanSelection {
  const ScanSelection({required this.next, this.chosen});

  final ScanPosition next;

  /// The word chosen, as (row, column); null when the press opened a row.
  final (int, int)? chosen;
}

/// The words of a board that scanning visits, by row: only rows with a
/// word in them, and only cells holding a word, in reading order.
class ScanOrder {
  ScanOrder(Iterable<(int, int)> occupied) : _rows = _group(occupied);

  final List<(int, List<int>)> _rows;

  static List<(int, List<int>)> _group(Iterable<(int, int)> occupied) {
    final byRow = <int, Set<int>>{};
    for (final (row, col) in occupied) {
      (byRow[row] ??= <int>{}).add(col);
    }
    final rows = byRow.keys.toList()..sort();
    return [for (final row in rows) (row, byRow[row]!.toList()..sort())];
  }

  /// True when there is nothing to scan.
  bool get isEmpty => _rows.isEmpty;

  /// The rows scanning visits, top first.
  List<int> get rows => [for (final (row, _) in _rows) row];

  /// The highlight's first place: the first row with a word; null for an
  /// empty board.
  ScanPosition? get start =>
      isEmpty ? null : ScanPosition(ScanPhase.rows, _rows.first.$1);

  int _rowIndex(int row) => _rows.indexWhere((entry) => entry.$1 == row);

  /// Where the highlight moves from [at]: the next row (after the last, the
  /// first again), or the next word in the row. After a row's last word it
  /// goes back to row scanning, on the row after this one.
  ScanPosition? next(ScanPosition at) {
    if (isEmpty) return null;
    var index = _rowIndex(at.row);
    if (index < 0) return start;
    if (at.phase == ScanPhase.rows) {
      index = (index + 1) % _rows.length;
      return ScanPosition(ScanPhase.rows, _rows[index].$1);
    }
    final cols = _rows[index].$2;
    final at0 = cols.indexOf(at.col ?? -1);
    if (at0 >= 0 && at0 + 1 < cols.length) {
      return ScanPosition(ScanPhase.cells, at.row, cols[at0 + 1]);
    }
    index = (index + 1) % _rows.length;
    return ScanPosition(ScanPhase.rows, _rows[index].$1);
  }

  /// What a select press at [at] does: on a row, highlights its first
  /// word; on a word, chooses it, and scanning starts again from the top.
  ScanSelection? select(ScanPosition at) {
    if (isEmpty) return null;
    final index = _rowIndex(at.row);
    if (index < 0) return ScanSelection(next: start!);
    if (at.phase == ScanPhase.rows) {
      return ScanSelection(
        next: ScanPosition(ScanPhase.cells, at.row, _rows[index].$2.first),
      );
    }
    final col = at.col;
    if (col == null || !_rows[index].$2.contains(col)) {
      return ScanSelection(next: start!);
    }
    return ScanSelection(next: start!, chosen: (at.row, col));
  }

  /// [at] if it is still on the board after a change to it, else the
  /// nearest place that is: the same row if it still has words, otherwise
  /// the start.
  ScanPosition? keep(ScanPosition? at) {
    if (at == null || isEmpty) return start;
    final index = _rowIndex(at.row);
    if (index < 0) return start;
    if (at.phase == ScanPhase.rows) return at;
    if (_rows[index].$2.contains(at.col)) return at;
    return ScanPosition(ScanPhase.rows, at.row);
  }
}
