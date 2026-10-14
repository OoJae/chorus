/// "What changed": the circle's history in plain lines, built from the
/// synced tiles and their edit log alone.
///
/// Nothing here writes. [activityOf] reads what every device already holds;
/// [undoPlanOf] says what writing the old value back would do, so the app
/// can do it through its normal store path.
library;

import 'cell_key.dart';
import 'edit_facts.dart';
import 'facts.dart';

/// `reason` of an edit that undoes an earlier one from the feed.
const String undoReason = 'undo';

/// What one line of the feed reports.
enum ActivityKind {
  /// A new word was made (on the board or waiting for a home).
  added,

  /// The word's label changed.
  renamed,

  /// What the word says changed.
  spoken,

  /// The word's colour changed.
  colour,

  /// The word got a new picture or lost one.
  picture,

  /// The word got a recorded voice or lost one.
  voice,

  /// A waiting word was given a spot on the board.
  placed,

  /// The word was put away (archived).
  putAway,

  /// A put-away word was brought back.
  broughtBack,

  /// A word tapped on the view-only page by a sitter. Not from the edit
  /// log: the server reports these.
  sitterTap,
}

/// One line of the feed.
class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.kind,
    required this.tileId,
    required this.label,
    required this.actorId,
    required this.actorName,
    required this.at,
    this.prop,
    this.oldValue,
    this.newValue,
    this.reason = '',
    this.oldCellKey,
  });

  /// The edit's id, or `added:<tileId>` for a new word.
  final String id;
  final ActivityKind kind;
  final String tileId;

  /// The word's label now, or as it was for a word no longer here.
  final String label;
  final String actorId;
  final String actorName;
  final DateTime at;

  /// The edited property, null for [ActivityKind.added].
  final String? prop;
  final String? oldValue;
  final String? newValue;

  /// The edit's reason, e.g. `edit`, [undoReason].
  final String reason;

  /// For [ActivityKind.putAway]: the cell the word held before, if it had
  /// one.
  final String? oldCellKey;

  @override
  bool operator ==(Object other) =>
      other is ActivityEntry &&
      other.id == id &&
      other.kind == kind &&
      other.label == label &&
      other.at == at &&
      other.newValue == newValue;

  @override
  int get hashCode => Object.hash(id, kind, label, at, newValue);

  @override
  String toString() => 'ActivityEntry(${kind.name} "$label" by $actorName)';
}

/// Every change in the circle, newest first.
///
/// A new word is one line (its first edits, reason `add`, are folded into
/// it), however many properties it was made with. Putting a word away is
/// one line, its freed cell kept on the entry so undo can offer it back.
/// Seeded starter words, which log no `add` edit, are left out: nobody
/// added them by hand.
List<ActivityEntry> activityOf(
  Iterable<TileFacts> tiles,
  Iterable<EditFacts> edits,
) {
  final tileById = {for (final tile in tiles) tile.id: tile};
  // A word added by hand or imported logs its first values as `add` edits;
  // a seeded starter word logs none.
  final addedByHand = {
    for (final edit in edits)
      if (edit.reason == 'add') edit.tileId,
  };
  final entries = <ActivityEntry>[];
  for (final tile in tiles) {
    final at = tile.createdAt;
    if (at == null || !addedByHand.contains(tile.id)) continue;
    entries.add(
      ActivityEntry(
        id: 'added:${tile.id}',
        kind: ActivityKind.added,
        tileId: tile.id,
        label: tile.label,
        actorId: tile.createdBy,
        actorName: tile.createdByName,
        at: at,
      ),
    );
  }
  // The cell a put-away word freed is logged as a separate cellKey edit at
  // the same instant, by the same adult.
  final freedCell = <(String, DateTime), String?>{};
  for (final edit in edits) {
    if (edit.prop == 'cellKey' &&
        edit.reason != 'add' &&
        edit.newValue != null &&
        CellKey.parse(edit.newValue!) is TrayCell) {
      freedCell[(edit.tileId, edit.editedAt)] = edit.oldValue;
    }
  }
  for (final edit in edits) {
    if (edit.reason == 'add' || edit.reason == 'seed') continue;
    final tile = tileById[edit.tileId];
    if (tile == null) continue;
    final kind = _kindOf(edit);
    if (kind == null) continue;
    entries.add(
      ActivityEntry(
        id: edit.id,
        kind: kind,
        tileId: edit.tileId,
        label: tile.label,
        actorId: edit.actorId,
        actorName: edit.actorName,
        at: edit.editedAt,
        prop: edit.prop,
        oldValue: edit.oldValue,
        newValue: edit.newValue,
        reason: edit.reason,
        oldCellKey: kind == ActivityKind.putAway
            ? freedCell[(edit.tileId, edit.editedAt)]
            : null,
      ),
    );
  }
  entries.sort((a, b) {
    final byTime = b.at.compareTo(a.at);
    return byTime != 0 ? byTime : b.id.compareTo(a.id);
  });
  return entries;
}

ActivityKind? _kindOf(EditFacts edit) => switch (edit.prop) {
  'label' => ActivityKind.renamed,
  'speech' => ActivityKind.spoken,
  'colorKey' => ActivityKind.colour,
  'imageHash' => ActivityKind.picture,
  'audioHash' => ActivityKind.voice,
  'archivedAt' =>
    edit.newValue == null ? ActivityKind.broughtBack : ActivityKind.putAway,
  // Only a word given a spot from the tray: the cell that putting a word
  // away frees is part of its putAway line, and bringing one back is part
  // of its broughtBack line.
  'cellKey' when edit.reason == 'resolve' => ActivityKind.placed,
  _ => null,
};

/// How many entries are newer than [since]. All of them when [since] is
/// null: nothing has been looked at on this device yet.
int changesSince(List<ActivityEntry> entries, DateTime? since) => since == null
    ? entries.length
    : entries.where((entry) => entry.at.isAfter(since)).length;

/// What undoing an entry writes.
sealed class UndoPlan {
  const UndoPlan();
}

/// Writes [value] back to [prop] (an empty value clears it).
class UndoSetValue extends UndoPlan {
  const UndoSetValue(this.prop, this.value);
  final String prop;
  final String value;

  @override
  bool operator ==(Object other) =>
      other is UndoSetValue && other.prop == prop && other.value == value;

  @override
  int get hashCode => Object.hash(prop, value);
}

/// Puts the word away: archived, restorable.
class UndoPutAway extends UndoPlan {
  const UndoPutAway();

  @override
  bool operator ==(Object other) => other is UndoPutAway;

  @override
  int get hashCode => 0;
}

/// Brings the word back into [cell] if it is still empty, and into the tray
/// otherwise. Never moves a placed word.
class UndoBringBack extends UndoPlan {
  const UndoBringBack(this.cell);

  /// The cell it held, or null for a word that had none.
  final PlacedCell? cell;

  @override
  bool operator ==(Object other) =>
      other is UndoBringBack && other.cell == cell;

  @override
  int get hashCode => cell.hashCode;
}

/// What undoing [entry] would write, or null when it cannot be undone: the
/// word changed again since, is gone, or the change is one that undoing
/// would move a placed word for.
UndoPlan? undoPlanOf(ActivityEntry entry, Iterable<TileFacts> tiles) {
  final tile = tiles.where((t) => t.id == entry.tileId).firstOrNull;
  if (tile == null) return null;
  String now(String? value) => value ?? '';
  switch (entry.kind) {
    case ActivityKind.added:
    case ActivityKind.broughtBack:
      return tile.archived ? null : const UndoPutAway();
    case ActivityKind.putAway:
      if (!tile.archived) return null;
      final old = entry.oldCellKey;
      final cell = old == null ? null : CellKey.parse(old);
      return UndoBringBack(cell is PlacedCell ? cell : null);
    case ActivityKind.renamed:
      if (tile.label != now(entry.newValue)) return null;
      final old = now(entry.oldValue);
      return old.isEmpty ? null : UndoSetValue('label', old);
    case ActivityKind.spoken:
      if (now(tile.speech) != now(entry.newValue)) return null;
      return UndoSetValue('speech', now(entry.oldValue));
    case ActivityKind.colour:
      if (now(tile.colorKey) != now(entry.newValue)) return null;
      return UndoSetValue('colorKey', now(entry.oldValue));
    case ActivityKind.picture:
    case ActivityKind.voice:
    case ActivityKind.placed:
    case ActivityKind.sitterTap:
      return null;
  }
}
