/// One circle's boards and tiles, read from and written to the local
/// replica.
///
/// Reads are a plain re-query after anything that may have changed the
/// replica. Writes are the only place the app touches a `cellKey`, and each
/// one follows the conflict design: placed and tray keys only, narrowed
/// updates, one transaction in the circle's shared space, an edit-log row
/// for every changed property.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart' hide CircleRole;
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:serverpod_database/serverpod_database.dart';

import 'adapters.dart';
import 'replica_service.dart';

/// Values of `TileEdit.reason` this store writes.
abstract final class EditReason {
  static const add = 'add';
  static const edit = 'edit';
  static const resolve = 'resolve';
  static const archive = 'archive';
}

/// The [BoardStore] of one circle on this device.
class ReplicaBoardStore extends BoardStore {
  /// [circleId] is the UUID of the circle's sync space; every row of the
  /// circle carries it. [revision] is listened to and each change triggers a
  /// re-read. [onDispose] lets the owner forget the store.
  ReplicaBoardStore({
    required this._replica,
    required this._revision,
    required this.circleId,
    required this.role,
    required this.childName,
    required this.myName,
    DateTime Function()? now,
    this._onDispose,
  }) : _now = now ?? DateTime.now {
    _revision.addListener(_onRevision);
    unawaited(refresh());
  }

  final ReplicaService _replica;
  final Listenable _revision;
  final DateTime Function() _now;
  final VoidCallback? _onDispose;

  /// UUID of the circle's sync space.
  final UuidValue circleId;

  @override
  final CircleRole role;

  @override
  final String childName;

  @override
  final String myName;

  List<BoardFacts> _boards = const [];
  List<TileFacts> _tiles = const [];
  bool _disposed = false;

  /// The re-read in progress, if any, and whether another is owed after it.
  Future<void>? _refreshing;
  bool _stale = false;

  @override
  List<BoardFacts> get boards => _boards;

  @override
  List<TileFacts> get tiles => _tiles;

  // ---- Reading -----------------------------------------------------------

  void _onRevision() => unawaited(refresh());

  /// Re-reads the circle's rows and notifies listeners if they differ from
  /// what is held. Completes after a read that started no earlier than this
  /// call. Never throws: a failed read leaves the held rows as they are.
  Future<void> refresh() {
    _stale = true;
    return _refreshing ??= _drain();
  }

  Future<void> _drain() async {
    try {
      while (_stale && !_disposed) {
        _stale = false;
        try {
          await _load();
        } catch (error) {
          // Typically the replica closing under a late revision bump.
          debugPrint('Chorus: board re-read failed: $error');
        }
      }
    } finally {
      _refreshing = null;
    }
  }

  Future<void> _load() async {
    // Reads span every circle the user is in, so both queries filter on the
    // circle id carried by each row.
    final (boardRows, tileRows) = await _replica.read((session) async {
      final boards = await Board.db.find(
        session,
        where: (t) => t.circleId.equals(circleId),
      );
      final tiles = await Tile.db.find(
        session,
        where: (t) => t.circleId.equals(circleId),
      );
      return (boards, tiles);
    });
    if (_disposed) return;

    boardRows.sort((a, b) => _byAge(a.createdAt, a.id!, b.createdAt, b.id!));
    tileRows.sort((a, b) => _byAge(a.createdAt, a.id!, b.createdAt, b.id!));
    final boards = [for (final row in boardRows) boardFacts(row)];
    final tiles = [for (final row in tileRows) tileFacts(row)];
    if (listEquals(boards, _boards) && listEquals(tiles, _tiles)) return;

    _boards = List.unmodifiable(boards);
    _tiles = List.unmodifiable(tiles);
    notifyListeners();
  }

  /// Oldest first, ties broken by id, so the lists keep a stable order.
  static int _byAge(DateTime a, UuidValue aId, DateTime b, UuidValue bId) {
    final byTime = a.compareTo(b);
    return byTime != 0 ? byTime : aId.uuid.compareTo(bId.uuid);
  }

  // ---- Writing -----------------------------------------------------------

  @override
  Future<bool> addTile({
    required String boardId,
    required int row,
    required int col,
    required String label,
    String? speech,
    String? colorKey,
  }) async {
    _requireEditor();
    final text = _requireLabel(label);
    final board = uuidOf(boardId);
    final id = UuidValue.fromString(const Uuid().v7());
    final wanted = placedKey(idOf(board), row, col);
    final waiting = trayKey(idOf(id));

    Future<void> insert(Transaction tx, String cellKey) async {
      final at = _now().toUtc();
      final spoken = _blankToNull(speech);
      final colour = _blankToNull(colorKey);
      await Tile.db.insertRow(
        _replica.session,
        Tile(
          id: id,
          circleId: circleId,
          boardId: board,
          cellKey: cellKey,
          label: text,
          speech: spoken,
          colorKey: colour,
          noLog: false,
          createdBy: _replica.userId,
          createdByName: myName,
          createdAt: at,
        ),
        transaction: tx,
      );
      await _log(tx, id, EditReason.add, at, [
        ('label', null, text),
        ('cellKey', null, cellKey),
        if (spoken != null) ('speech', null, spoken),
        if (colour != null) ('colorKey', null, colour),
      ], isNewTile: true);
    }

    bool placed;
    try {
      placed = await _replica.write(circleId, (tx) async {
        await _requireCell(tx, board, row, col);
        final free = await _holderOf(tx, wanted) == null;
        await insert(tx, free ? wanted : waiting);
        return free;
      });
    } on DatabaseUniqueViolationException {
      // The cell is held by a row no query shows (the engine keeps hidden
      // claims). The failed transaction rolled back; start over in the tray.
      await _replica.write(circleId, (tx) => insert(tx, waiting));
      placed = false;
    }
    await refresh();
    return placed;
  }

  @override
  Future<bool> placeTile(
    String tileId, {
    required int row,
    required int col,
  }) async {
    _requireEditor();
    final id = uuidOf(tileId);
    bool placed;
    try {
      placed = await _replica.write(circleId, (tx) async {
        final tile = await _requireTile(tx, id);
        if (tile.archivedAt != null) {
          throw StateError('An archived tile cannot be placed.');
        }
        // A tile is bound to one cell for life: only one that has no cell
        // (tray) or lost its cell (contested) may be given one.
        final from = CellKey.parse(tile.cellKey);
        if (from is! TrayCell && from is! ContestedCell) {
          throw StateError('A tile on the board cannot move to another cell.');
        }
        await _requireCell(tx, tile.boardId, row, col);
        final wanted = placedKey(idOf(tile.boardId), row, col);
        if (await _holderOf(tx, wanted) != null) {
          throw CellOccupied(idOf(tile.boardId), row, col);
        }
        final at = _now().toUtc();
        await Tile.db.updateRow(
          _replica.session,
          tile.copyWith(cellKey: wanted),
          columns: (t) => [t.cellKey],
          transaction: tx,
        );
        await _log(tx, id, EditReason.resolve, at, [
          ('cellKey', loggedKey(tile.cellKey), wanted),
        ]);
        return true;
      });
    } on CellOccupied {
      placed = false;
    } on DatabaseUniqueViolationException {
      placed = false;
    }
    await refresh();
    return placed;
  }

  /// Changes a tile's content. A null argument leaves that property alone;
  /// an empty [speech] or [colorKey] clears it. Never changes the cell.
  @override
  Future<void> updateTile(
    String tileId, {
    String? label,
    String? speech,
    String? colorKey,
  }) async {
    _requireEditor();
    final id = uuidOf(tileId);
    final text = label == null ? null : _requireLabel(label);
    try {
      await _replica.write(circleId, (tx) async {
        final tile = await _requireTile(tx, id);
        final changes = <(String, String?, String?)>[
          if (text != null && text != tile.label) ('label', tile.label, text),
          if (speech != null && _blankToNull(speech) != tile.speech)
            ('speech', tile.speech, _blankToNull(speech)),
          if (colorKey != null && _blankToNull(colorKey) != tile.colorKey)
            ('colorKey', tile.colorKey, _blankToNull(colorKey)),
        ];
        if (changes.isEmpty) throw const _NothingToWrite();
        final changed = {for (final change in changes) change.$1};

        // Only the columns that changed are named: an update that names
        // every column would turn the merge into whole-row last-writer-wins.
        final at = _now().toUtc();
        final next = Tile(
          id: tile.id,
          circleId: tile.circleId,
          boardId: tile.boardId,
          cellKey: tile.cellKey,
          label: changed.contains('label') ? text! : tile.label,
          speech: changed.contains('speech')
              ? _blankToNull(speech)
              : tile.speech,
          colorKey: changed.contains('colorKey')
              ? _blankToNull(colorKey)
              : tile.colorKey,
          imageHash: tile.imageHash,
          audioHash: tile.audioHash,
          linkBoardId: tile.linkBoardId,
          noLog: tile.noLog,
          archivedAt: tile.archivedAt,
          createdBy: tile.createdBy,
          createdByName: tile.createdByName,
          createdAt: tile.createdAt,
        );
        await Tile.db.updateRow(
          _replica.session,
          next,
          columns: (t) => [
            if (changed.contains('label')) t.label,
            if (changed.contains('speech')) t.speech,
            if (changed.contains('colorKey')) t.colorKey,
          ],
          transaction: tx,
        );
        await _log(tx, id, EditReason.edit, at, changes);
      });
    } on _NothingToWrite {
      return;
    }
    await refresh();
  }

  @override
  Future<void> archiveTile(String tileId) async {
    _requireEditor();
    final id = uuidOf(tileId);
    final waiting = trayKey(idOf(id));
    try {
      await _replica.write(circleId, (tx) async {
        final tile = await _requireTile(tx, id);
        if (tile.archivedAt != null) throw const _NothingToWrite();
        // The flag alone would leave the cell taken. Both columns go in one
        // update, so no device ever sees an archived tile holding a cell.
        final at = _now().toUtc();
        final hadCell = CellKey.parse(tile.cellKey) != TrayCell(idOf(id));
        await Tile.db.updateRow(
          _replica.session,
          tile.copyWith(archivedAt: at, cellKey: waiting),
          columns: (t) => [t.archivedAt, if (hadCell) t.cellKey],
          transaction: tx,
        );
        await _log(tx, id, EditReason.archive, at, [
          ('archivedAt', null, at.toIso8601String()),
          if (hadCell) ('cellKey', loggedKey(tile.cellKey), waiting),
        ]);
      });
    } on _NothingToWrite {
      return;
    }
    await refresh();
  }

  // ---- Helpers -----------------------------------------------------------

  /// A partner is read-only. Fails here, before the database is touched,
  /// rather than leaving it to the engine to refuse the transaction.
  void _requireEditor() {
    if (!role.canEdit) {
      throw StateError('A partner can view this board but not change it.');
    }
  }

  static String _requireLabel(String label) {
    final text = label.trim();
    if (text.isEmpty) {
      throw ArgumentError.value(label, 'label', 'A tile needs a word');
    }
    return text;
  }

  static String? _blankToNull(String? value) {
    final text = value?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  Future<Tile> _requireTile(Transaction tx, UuidValue id) async {
    final tile = await Tile.db.findFirstRow(
      _replica.session,
      where: (t) => t.id.equals(id) & t.circleId.equals(circleId),
      transaction: tx,
    );
    if (tile == null) throw StateError('No such tile in this circle: $id');
    return tile;
  }

  /// Throws unless ([row], [col]) is a cell of a live board of this circle.
  Future<void> _requireCell(
    Transaction tx,
    UuidValue boardId,
    int row,
    int col,
  ) async {
    final board = await Board.db.findFirstRow(
      _replica.session,
      where: (t) => t.id.equals(boardId) & t.circleId.equals(circleId),
      transaction: tx,
    );
    if (board == null) {
      throw ArgumentError.value(boardId, 'boardId', 'No such board');
    }
    if (board.archivedAt != null) {
      throw StateError('The board is archived.');
    }
    if (row < 0 || col < 0 || row >= board.rows || col >= board.cols) {
      throw RangeError('Cell $row:$col is outside the board.');
    }
  }

  /// The tile whose key is exactly [cellKey], if a query can see one.
  Future<Tile?> _holderOf(Transaction tx, String cellKey) =>
      Tile.db.findFirstRow(
        _replica.session,
        where: (t) => t.circleId.equals(circleId) & t.cellKey.equals(cellKey),
        transaction: tx,
      );

  /// Appends one edit-log row per (property, old, new) in [changes].
  ///
  /// Each row points at the newest earlier edit of the same property this
  /// device can see, which is what lets a later reader tell an overwrite
  /// from a follow-up. A new tile has no earlier edits to look for.
  Future<void> _log(
    Transaction tx,
    UuidValue tileId,
    String reason,
    DateTime at,
    List<(String, String?, String?)> changes, {
    bool isNewTile = false,
  }) async {
    for (final (prop, oldValue, newValue) in changes) {
      final base = isNewTile
          ? null
          : await TileEdit.db.findFirstRow(
              _replica.session,
              where: (t) =>
                  t.circleId.equals(circleId) &
                  t.tileId.equals(tileId) &
                  t.prop.equals(prop),
              orderBy: (t) => t.editedAt.desc(),
              transaction: tx,
            );
      await TileEdit.db.insertRow(
        _replica.session,
        TileEdit(
          circleId: circleId,
          tileId: tileId,
          prop: prop,
          oldValue: oldValue,
          newValue: newValue,
          baseEditId: base?.id,
          reason: reason,
          actorId: _replica.userId,
          actorName: myName,
          editedAt: at,
        ),
        transaction: tx,
      );
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _revision.removeListener(_onRevision);
    _onDispose?.call();
    super.dispose();
  }
}

/// Thrown inside a write transaction that found nothing to change, so the
/// transaction rolls back and the device does not claim to hold an unsent
/// edit.
class _NothingToWrite implements Exception {
  const _NothingToWrite();
}
