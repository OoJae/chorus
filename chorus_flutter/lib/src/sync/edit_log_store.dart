/// The edit log of one circle, read from the local replica, and the way to
/// put a replaced edit back.
///
/// A mixin rather than a class of its own so that the board store is also
/// the edit log: the screens ask one object for tiles and edits, and one
/// notification covers both.
library;

import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_edits.dart';
import 'package:flutter/foundation.dart';

import 'adapters.dart';
import 'replica_service.dart';

/// An edit-log row as the shared rules see it. The row must have an id,
/// which every row read from the replica does.
EditFacts editFacts(api.TileEdit row) => EditFacts(
  id: idOf(row.id!),
  tileId: idOf(row.tileId),
  prop: row.prop,
  oldValue: row.oldValue,
  newValue: row.newValue,
  baseEditId: row.baseEditId == null ? null : idOf(row.baseEditId!),
  reason: row.reason,
  actorId: idOf(row.actorId),
  actorName: row.actorName,
  editedAt: row.editedAt,
);

/// Makes a replica-backed [BoardStore] an [EditLog].
///
/// The store supplies the three members below and calls [reloadEdits]
/// wherever it re-reads its tiles. This mixin never writes: [restore] goes
/// through [updateTileAs], so a restored value takes the same path as any
/// other edit (one transaction in the circle's space, narrowed columns, an
/// edit-log row).
mixin EditLogStore on BoardStore implements EditLog {
  /// The replica the edits are read from.
  @protected
  ReplicaService get editLogReplica;

  /// UUID of the circle's sync space; every edit row of the circle carries
  /// it.
  api.UuidValue get circleId;

  /// `updateTile` with the reason to record in the edit log.
  @protected
  Future<void> updateTileAs(
    String tileId, {
    String? label,
    String? speech,
    String? colorKey,
    required String reason,
  });

  List<EditFacts> _edits = const [];

  @override
  List<EditFacts> get edits => _edits;

  /// Re-reads the circle's edit rows. Completes with whether they differ
  /// from what was held, so the caller knows to notify. Never throws: a
  /// failed read leaves the held edits as they are.
  @protected
  Future<bool> reloadEdits() async {
    final List<api.TileEdit> rows;
    try {
      // Reads span every circle the user is in, so the query filters on the
      // circle id carried by each row.
      rows = await editLogReplica.read(
        (session) => api.TileEdit.db.find(
          session,
          where: (t) => t.circleId.equals(circleId),
        ),
      );
    } catch (error) {
      // Typically the replica closing under a late re-read.
      debugPrint('Chorus: edit log re-read failed: $error');
      return false;
    }
    // Oldest first, ties broken by id, so the list keeps a stable order.
    rows.sort((a, b) {
      final byTime = a.editedAt.compareTo(b.editedAt);
      return byTime != 0 ? byTime : a.id!.uuid.compareTo(b.id!.uuid);
    });
    final edits = [for (final row in rows) editFacts(row)];
    if (listEquals(edits, _edits)) return false;
    _edits = List.unmodifiable(edits);
    return true;
  }

  /// Writes the lost value back with reason [restoreReason].
  ///
  /// A lost edit that cleared the speech or the colour clears it again. If
  /// the tile already holds the lost value nothing is written. Throws
  /// [UnsupportedError] for a property outside [restorableProps] and
  /// whatever [updateTileAs] throws (a partner, a tile that is gone).
  @override
  Future<void> restore(Overwrite overwrite) {
    final lost = overwrite.lost;
    final value = lost.newValue ?? '';
    return switch (lost.prop) {
      'label' => updateTileAs(lost.tileId, label: value, reason: restoreReason),
      'speech' => updateTileAs(
        lost.tileId,
        speech: value,
        reason: restoreReason,
      ),
      'colorKey' => updateTileAs(
        lost.tileId,
        colorKey: value,
        reason: restoreReason,
      ),
      _ => throw UnsupportedError(
        'A replaced "${lost.prop}" cannot be restored.',
      ),
    };
  }
}
