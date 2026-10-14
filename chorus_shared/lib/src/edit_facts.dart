/// One row of the edit log as a plain value, free of generated classes.
library;

/// `reason` of an edit that puts an overwritten value back.
const String restoreReason = 'restore';

/// One change to one property of a tile.
///
/// The log is append-only: an edit is never changed after it is written, so
/// two edits with the same [id] are the same edit.
class EditFacts {
  const EditFacts({
    required this.id,
    required this.tileId,
    required this.prop,
    this.oldValue,
    this.newValue,
    this.baseEditId,
    required this.reason,
    required this.actorId,
    required this.actorName,
    required this.editedAt,
  });

  /// Edit UUID, lowercase.
  final String id;

  /// UUID of the tile that was changed.
  final String tileId;

  /// Name of the changed property, e.g. `label`.
  final String prop;

  /// What the author's device held before the change.
  final String? oldValue;
  final String? newValue;

  /// The newest edit of this tile and property the author could see, or
  /// null when there was none.
  final String? baseEditId;

  /// Why the edit happened, e.g. `edit`, `add`, [restoreReason].
  final String reason;

  /// UUID of the adult who made the change.
  final String actorId;
  final String actorName;

  /// The author's own clock. Used for display and to order ties, never to
  /// decide which edit won.
  final DateTime editedAt;

  @override
  bool operator ==(Object other) =>
      other is EditFacts &&
      other.id == id &&
      other.tileId == tileId &&
      other.prop == prop &&
      other.oldValue == oldValue &&
      other.newValue == newValue &&
      other.baseEditId == baseEditId &&
      other.reason == reason &&
      other.actorId == actorId &&
      other.actorName == actorName &&
      other.editedAt == editedAt;

  @override
  int get hashCode => Object.hash(
    id,
    tileId,
    prop,
    oldValue,
    newValue,
    baseEditId,
    reason,
    actorId,
    actorName,
    editedAt,
  );

  @override
  String toString() =>
      'EditFacts($id, $prop of $tileId: "$oldValue" -> "$newValue", $reason)';
}
