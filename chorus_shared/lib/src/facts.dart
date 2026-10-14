/// Plain value types shared by the app, the server and the tests.
///
/// These deliberately do not depend on generated Serverpod classes: thin
/// adapters map generated rows to these types, so the rules in this package
/// can be unit-tested with nothing but the Dart SDK.
library;

/// A board: a fixed grid of cells that tiles are placed on.
class BoardFacts {
  const BoardFacts({
    required this.id,
    required this.name,
    required this.rows,
    required this.cols,
    this.isHome = false,
    this.archived = false,
  });

  /// Board UUID, lowercase.
  final String id;
  final String name;
  final int rows;
  final int cols;
  final bool isHome;
  final bool archived;

  bool contains(int row, int col) =>
      row >= 0 && col >= 0 && row < rows && col < cols;

  @override
  bool operator ==(Object other) =>
      other is BoardFacts &&
      other.id == id &&
      other.name == name &&
      other.rows == rows &&
      other.cols == cols &&
      other.isHome == isHome &&
      other.archived == archived;

  @override
  int get hashCode => Object.hash(id, name, rows, cols, isHome, archived);

  @override
  String toString() => 'BoardFacts($id, "$name", ${rows}x$cols)';
}

/// A tile: one word on a board.
///
/// [cellKey] is the raw value stored in the synced row. It is the only place
/// a tile's position lives; parse it with `CellKey.parse`.
class TileFacts {
  const TileFacts({
    required this.id,
    required this.boardId,
    required this.cellKey,
    required this.label,
    this.speech,
    this.imageHash,
    this.audioHash,
    this.colorKey,
    this.archived = false,
    this.createdBy = '',
    this.createdByName = '',
    this.createdAt,
  });

  /// Tile UUID, lowercase.
  final String id;

  /// UUID of the board this tile belongs to.
  final String boardId;

  /// Raw cell key exactly as read from the row.
  final String cellKey;

  final String label;

  /// What is spoken; falls back to [label] when null.
  final String? speech;
  final String? imageHash;
  final String? audioHash;

  /// Part-of-speech colour key, e.g. `verb`, `pronoun`.
  final String? colorKey;
  final bool archived;

  /// UUID of the adult who created the tile.
  final String createdBy;
  final String createdByName;
  final DateTime? createdAt;

  String get spokenText =>
      (speech == null || speech!.isEmpty) ? label : speech!;

  TileFacts copyWith({
    String? cellKey,
    String? label,
    String? speech,
    String? imageHash,
    String? audioHash,
    String? colorKey,
    bool? archived,
  }) => TileFacts(
    id: id,
    boardId: boardId,
    cellKey: cellKey ?? this.cellKey,
    label: label ?? this.label,
    speech: speech ?? this.speech,
    imageHash: imageHash ?? this.imageHash,
    audioHash: audioHash ?? this.audioHash,
    colorKey: colorKey ?? this.colorKey,
    archived: archived ?? this.archived,
    createdBy: createdBy,
    createdByName: createdByName,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is TileFacts &&
      other.id == id &&
      other.boardId == boardId &&
      other.cellKey == cellKey &&
      other.label == label &&
      other.speech == speech &&
      other.imageHash == imageHash &&
      other.audioHash == audioHash &&
      other.colorKey == colorKey &&
      other.archived == archived &&
      other.createdBy == createdBy &&
      other.createdByName == createdByName &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    boardId,
    cellKey,
    label,
    speech,
    imageHash,
    audioHash,
    colorKey,
    archived,
    createdBy,
    createdByName,
    createdAt,
  );

  @override
  String toString() => 'TileFacts($id, "$label", $cellKey)';
}
