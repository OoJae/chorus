/// Undo from "What changed", written to the local replica the same way as
/// every other edit: one transaction in the circle's space, narrowed
/// columns, an edit-log row per changed property, reason `undo`.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart' hide CircleRole;
import 'package:chorus_ui/contracts_activity.dart';
import 'package:serverpod_database/serverpod_database.dart';

import '../sync/adapters.dart';
import '../sync/edit_log_store.dart';

/// Makes a replica-backed store an [ActivityUndo].
///
/// A changed value goes back through `updateTileAs`, as Restore does.
/// Putting a word away and bringing it back are written here, because the
/// store's own archive records reason `archive`, and nothing else brings an
/// archived word back. Bringing one back never moves a placed word: it
/// takes its old cell only while that cell is empty, and otherwise waits in
/// the tray.
mixin ActivityUndoStore on EditLogStore implements ActivityUndo {
  /// Re-reads the replica; the store already has one.
  Future<void> refresh();

  @override
  Future<UndoOutcome> undo(ActivityEntry entry) async {
    if (!role.canEdit) {
      throw StateError('A read-only member cannot undo.');
    }
    final plan = undoPlanOf(entry, tiles);
    if (plan == null) throw StateError('There is nothing to undo.');
    switch (plan) {
      case UndoSetValue(:final prop, :final value):
        await updateTileAs(
          entry.tileId,
          label: prop == 'label' ? value : null,
          speech: prop == 'speech' ? value : null,
          colorKey: prop == 'colorKey' ? value : null,
          reason: undoReason,
        );
        return UndoOutcome.done;
      case UndoPutAway():
        await _putAway(entry.tileId);
        return UndoOutcome.done;
      case UndoBringBack(:final cell):
        return _bringBack(entry.tileId, cell);
    }
  }

  Future<void> _putAway(String tileId) async {
    final id = uuidOf(tileId);
    final waiting = trayKey(idOf(id));
    await editLogReplica.write(circleId, (tx) async {
      final tile = await _tile(tx, id);
      if (tile.archivedAt != null) return;
      final at = DateTime.now().toUtc();
      final hadCell = CellKey.parse(tile.cellKey) != TrayCell(idOf(id));
      await Tile.db.updateRow(
        editLogReplica.session,
        tile.copyWith(archivedAt: at, cellKey: waiting),
        columns: (t) => [t.archivedAt, if (hadCell) t.cellKey],
        transaction: tx,
      );
      await _log(tx, id, at, [
        ('archivedAt', null, at.toIso8601String()),
        if (hadCell) ('cellKey', loggedKey(tile.cellKey), waiting),
      ]);
    });
    await refresh();
  }

  Future<UndoOutcome> _bringBack(String tileId, PlacedCell? cell) async {
    final id = uuidOf(tileId);
    Future<bool> write({required bool tryCell}) =>
        editLogReplica.write(circleId, (tx) async {
          final tile = await _tile(tx, id);
          if (tile.archivedAt == null) return true;
          final at = DateTime.now().toUtc();
          final key = tryCell && cell != null ? await _freeKey(tx, cell) : null;
          final next = key ?? tile.cellKey;
          await Tile.db.updateRow(
            editLogReplica.session,
            tile.copyWith(archivedAt: null, cellKey: next),
            columns: (t) => [t.archivedAt, if (key != null) t.cellKey],
            transaction: tx,
          );
          await _log(tx, id, at, [
            ('archivedAt', tile.archivedAt!.toIso8601String(), null),
            if (key != null) ('cellKey', loggedKey(tile.cellKey), key),
          ]);
          return key != null;
        });
    bool placed;
    try {
      placed = await write(tryCell: true);
    } on DatabaseUniqueViolationException {
      // The cell is held by a row no query shows. The transaction rolled
      // back; bring the word back into the tray instead.
      placed = await write(tryCell: false);
    }
    await refresh();
    return placed || cell == null ? UndoOutcome.done : UndoOutcome.waiting;
  }

  /// The placed key of [cell] when it is an empty cell of a live board of
  /// this circle; null otherwise.
  Future<String?> _freeKey(Transaction tx, PlacedCell cell) async {
    final board = await Board.db.findFirstRow(
      editLogReplica.session,
      where: (t) =>
          t.id.equals(uuidOf(cell.boardId)) & t.circleId.equals(circleId),
      transaction: tx,
    );
    if (board == null ||
        board.archivedAt != null ||
        cell.row >= board.rows ||
        cell.col >= board.cols) {
      return null;
    }
    final key = placedKey(cell.boardId, cell.row, cell.col);
    final holder = await Tile.db.findFirstRow(
      editLogReplica.session,
      where: (t) => t.circleId.equals(circleId) & t.cellKey.equals(key),
      transaction: tx,
    );
    return holder == null ? key : null;
  }

  Future<Tile> _tile(Transaction tx, UuidValue id) async {
    final tile = await Tile.db.findFirstRow(
      editLogReplica.session,
      where: (t) => t.id.equals(id) & t.circleId.equals(circleId),
      transaction: tx,
    );
    if (tile == null) throw StateError('No such word in this circle: $id');
    return tile;
  }

  /// One edit-log row per (property, old, new), each pointing at the newest
  /// earlier edit of the same property, as the store's own writes do.
  Future<void> _log(
    Transaction tx,
    UuidValue tileId,
    DateTime at,
    List<(String, String?, String?)> changes,
  ) async {
    final session = editLogReplica.session;
    for (final (prop, oldValue, newValue) in changes) {
      final base = await TileEdit.db.findFirstRow(
        session,
        where: (t) =>
            t.circleId.equals(circleId) &
            t.tileId.equals(tileId) &
            t.prop.equals(prop),
        orderBy: (t) => t.editedAt.desc(),
        transaction: tx,
      );
      await TileEdit.db.insertRow(
        session,
        TileEdit(
          circleId: circleId,
          tileId: tileId,
          prop: prop,
          oldValue: oldValue,
          newValue: newValue,
          baseEditId: base?.id,
          reason: undoReason,
          actorId: editLogReplica.userId,
          actorName: myName,
          editedAt: at,
        ),
        transaction: tx,
      );
    }
  }
}
