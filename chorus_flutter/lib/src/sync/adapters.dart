/// Thin mappings between generated Serverpod rows and the plain types the
/// shared rules and the screens work with.
///
/// Ids cross this boundary as lowercase strings, and "archived" is derived
/// from `archivedAt`. Nothing here touches the database.
library;

import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';

/// A UUID as the shared rules expect it: lowercase.
String idOf(api.UuidValue id) => id.uuid.toLowerCase();

/// Parses an id that came out of [idOf] or the shared rules.
api.UuidValue uuidOf(String id) => api.UuidValue.fromString(id.toLowerCase());

/// The role the screens gate editing on.
CircleRole roleOf(api.CircleRole role) => switch (role) {
  api.CircleRole.guardian => CircleRole.guardian,
  api.CircleRole.therapist => CircleRole.therapist,
  api.CircleRole.teacher => CircleRole.teacher,
  api.CircleRole.partner => CircleRole.partner,
};

/// A board row as the shared rules see it. The row must have an id, which
/// every row read from the replica does.
BoardFacts boardFacts(api.Board row) => BoardFacts(
  id: idOf(row.id!),
  name: row.name,
  rows: row.rows,
  cols: row.cols,
  isHome: row.isHome,
  archived: row.archivedAt != null,
);

/// A tile row as the shared rules see it. The cell key is passed through
/// exactly as stored, including a suffix the sync engine may have added.
TileFacts tileFacts(api.Tile row) => TileFacts(
  id: idOf(row.id!),
  boardId: idOf(row.boardId),
  cellKey: row.cellKey,
  label: row.label,
  speech: row.speech,
  imageHash: row.imageHash,
  audioHash: row.audioHash,
  colorKey: row.colorKey,
  archived: row.archivedAt != null,
  createdBy: idOf(row.createdBy),
  createdByName: row.createdByName,
  createdAt: row.createdAt,
);

/// The row to insert for a starter board. [facts] carries the deterministic
/// id, so a second seed writes the same row.
api.Board starterBoardRow(
  BoardFacts facts, {
  required api.UuidValue circleId,
  required DateTime createdAt,
}) => api.Board(
  id: uuidOf(facts.id),
  circleId: circleId,
  name: facts.name,
  rows: facts.rows,
  cols: facts.cols,
  isHome: facts.isHome,
  createdAt: createdAt,
);

/// The row to insert for a starter tile.
///
/// The cell key is rebuilt from its parsed form rather than copied, so only
/// a key the app is allowed to author can reach the database. Throws
/// [ArgumentError] for a tile whose key is contested or not understood.
api.Tile starterTileRow(
  TileFacts facts, {
  required api.UuidValue circleId,
  required DateTime createdAt,
}) => api.Tile(
  id: uuidOf(facts.id),
  circleId: circleId,
  boardId: uuidOf(facts.boardId),
  cellKey: authoredKey(facts.cellKey),
  label: facts.label,
  speech: facts.speech,
  colorKey: facts.colorKey,
  noLog: false,
  createdBy: uuidOf(facts.createdBy),
  createdByName: facts.createdByName,
  createdAt: facts.createdAt ?? createdAt,
);

/// Rebuilds a placed or tray key through the only functions allowed to make
/// one. Throws [ArgumentError] for any other form.
String authoredKey(String raw) => switch (CellKey.parse(raw)) {
  PlacedCell cell => cell.format(),
  TrayCell cell => cell.format(),
  ContestedCell() || UnknownCell() => throw ArgumentError.value(
    raw,
    'cellKey',
    'Only a placed or tray key may be written',
  ),
};

/// How a key is described in the edit log: the cell or tray slot it names.
/// A contested key is logged as the cell it asked for; an unknown one as
/// null. Never the raw string, so the log cannot carry an engine suffix.
String? loggedKey(String raw) => switch (CellKey.parse(raw)) {
  PlacedCell cell => cell.format(),
  TrayCell cell => cell.format(),
  ContestedCell cell => cell.wanted.format(),
  UnknownCell() => null,
};
