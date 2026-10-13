/// The three forms a tile's `cellKey` can take, and the only functions that
/// may build one.
///
/// The key is a single unique string per circle. The sync engine resolves two
/// claims on the same key by suffixing the loser, so position conflicts show
/// up as a changed key and nothing else: no event fires.
library;

/// Suffix the sync engine appends to the loser of a unique-key collision.
const String conflictMarker = '__conflict__';

/// Prefix of the key of a tile that has no cell.
const String trayPrefix = 'tray:';

/// Markers only the sync engine may write into a unique column.
const List<String> _reservedMarkers = [conflictMarker, '__hidden__', '__park__'];

/// Canonical non-negative integer: no sign, no leading zeros.
final RegExp _index = RegExp(r'^(0|[1-9][0-9]*)$');

/// A parsed `cellKey`.
sealed class CellKey {
  const CellKey();

  /// Parses a raw key exactly as read from a row. Never throws: anything
  /// that is not one of the three known forms becomes an [UnknownCell].
  static CellKey parse(String raw) {
    if (raw.contains('__hidden__') || raw.contains('__park__')) {
      return UnknownCell(raw);
    }
    final at = raw.indexOf(conflictMarker);
    if (at >= 0) {
      final wanted = _parsePlaced(raw.substring(0, at));
      final loser = raw.substring(at + conflictMarker.length);
      if (wanted == null || loser.isEmpty || loser.contains(conflictMarker)) {
        return UnknownCell(raw);
      }
      return ContestedCell(wanted.boardId, wanted.row, wanted.col, loser);
    }
    if (raw.startsWith(trayPrefix)) {
      final tileId = raw.substring(trayPrefix.length);
      if (tileId.isEmpty || tileId.contains(':')) return UnknownCell(raw);
      return TrayCell(tileId);
    }
    return _parsePlaced(raw) ?? UnknownCell(raw);
  }
}

/// `<boardId>:<row>:<col>`, or null when [s] is not exactly that.
PlacedCell? _parsePlaced(String s) {
  if (s.startsWith(trayPrefix)) return null;
  final parts = s.split(':');
  if (parts.length != 3 || parts[0].isEmpty) return null;
  if (!_index.hasMatch(parts[1]) || !_index.hasMatch(parts[2])) return null;
  final row = int.tryParse(parts[1]);
  final col = int.tryParse(parts[2]);
  if (row == null || col == null) return null;
  return PlacedCell(parts[0], row, col);
}

/// A tile on a board cell: `<boardId>:<row>:<col>`.
final class PlacedCell extends CellKey {
  const PlacedCell(this.boardId, this.row, this.col);

  final String boardId;
  final int row;
  final int col;

  /// The raw key. Throws [ArgumentError] if the fields cannot form one.
  String format() => placedKey(boardId, row, col);

  @override
  bool operator ==(Object other) =>
      other is PlacedCell &&
      other.boardId == boardId &&
      other.row == row &&
      other.col == col;

  @override
  int get hashCode => Object.hash(boardId, row, col);

  @override
  String toString() => 'PlacedCell($boardId, $row, $col)';
}

/// A tile that lost a collision for a cell:
/// `<boardId>:<row>:<col>__conflict__<rowId>`.
///
/// Only the sync engine writes this form, so there is deliberately no way to
/// format one. The app moves such a tile by writing a placed or tray key.
final class ContestedCell extends CellKey {
  const ContestedCell(this.boardId, this.row, this.col, this.loserRowId);

  final String boardId;
  final int row;
  final int col;

  /// The row id the engine appended; identifies the losing row.
  final String loserRowId;

  /// The cell this tile asked for and did not get.
  PlacedCell get wanted => PlacedCell(boardId, row, col);

  @override
  bool operator ==(Object other) =>
      other is ContestedCell &&
      other.boardId == boardId &&
      other.row == row &&
      other.col == col &&
      other.loserRowId == loserRowId;

  @override
  int get hashCode => Object.hash(boardId, row, col, loserRowId);

  @override
  String toString() => 'ContestedCell($boardId, $row, $col, loser $loserRowId)';
}

/// A tile with no cell: `tray:<tileId>`. The tile id keeps the key unique.
final class TrayCell extends CellKey {
  const TrayCell(this.tileId);

  final String tileId;

  /// The raw key. Throws [ArgumentError] if [tileId] cannot form one.
  String format() => trayKey(tileId);

  @override
  bool operator ==(Object other) => other is TrayCell && other.tileId == tileId;

  @override
  int get hashCode => Object.hash(TrayCell, tileId);

  @override
  String toString() => 'TrayCell($tileId)';
}

/// A key in none of the known forms. Kept verbatim so the tile can still be
/// shown to an adult and given a home.
final class UnknownCell extends CellKey {
  const UnknownCell(this.raw);

  final String raw;

  @override
  bool operator ==(Object other) => other is UnknownCell && other.raw == raw;

  @override
  int get hashCode => Object.hash(UnknownCell, raw);

  @override
  String toString() => 'UnknownCell("$raw")';
}

/// The key of a cell on a board.
///
/// Throws [ArgumentError] if the result would not parse back to the same
/// [PlacedCell]: an empty board id, a colon or reserved marker in it, or a
/// negative row or column.
String placedKey(String boardId, int row, int col) {
  final key = assertAuthorable('$boardId:$row:$col');
  if (CellKey.parse(key) != PlacedCell(boardId, row, col)) {
    throw ArgumentError.value(key, 'cellKey', 'Not a valid placed key');
  }
  return key;
}

/// The key of a tile that has no cell.
///
/// Throws [ArgumentError] if [tileId] is empty or contains a colon or a
/// reserved marker.
String trayKey(String tileId) {
  final key = assertAuthorable('$trayPrefix$tileId');
  if (CellKey.parse(key) != TrayCell(tileId)) {
    throw ArgumentError.value(key, 'cellKey', 'Not a valid tray key');
  }
  return key;
}

/// Returns [value], or throws [ArgumentError] if it contains a marker
/// reserved for the sync engine. Call it on anything the app is about to
/// write into a unique column.
String assertAuthorable(String value) {
  for (final marker in _reservedMarkers) {
    if (value.contains(marker)) {
      throw ArgumentError.value(
          value, 'value', 'Contains the reserved engine marker $marker');
    }
  }
  return value;
}
