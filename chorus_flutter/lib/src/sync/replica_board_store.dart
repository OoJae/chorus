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
import 'package:chorus_ui/contracts_boards.dart';
import 'package:chorus_ui/contracts_copies.dart' show TrayWordAdder;
import 'package:chorus_ui/contracts_media.dart';
import 'package:flutter/foundation.dart';
import 'package:serverpod_database/serverpod_database.dart';

import '../activity/activity_undo_store.dart';
import 'adapters.dart';
import 'edit_log_store.dart';
import 'replica_service.dart';

/// Values of `TileEdit.reason` this store writes.
abstract final class EditReason {
  static const add = 'add';
  static const edit = 'edit';
  static const resolve = 'resolve';
  static const archive = 'archive';
  static const restore = restoreReason;
}

/// The [BoardStore] of one circle on this device. Boards are added,
/// renamed, archived and imported through it too ([BoardManager]).
class ReplicaBoardStore extends BoardStore
    with EditLogStore, ActivityUndoStore
    implements TileMediaWriter, BoardManager, TrayWordAdder {
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
  @override
  final UuidValue circleId;

  @override
  ReplicaService get editLogReplica => _replica;

  @override
  final CircleRole role;

  @override
  final String childName;

  @override
  final String myName;

  List<BoardFacts> _boards = const [];
  List<TileFacts> _tiles = const [];
  bool _disposed = false;
  bool _hasLoaded = false;

  /// False until the first read of this device has finished. Until then an
  /// empty [boards] means "not read yet", not "no board".
  bool get hasLoaded => _hasLoaded;

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
  @override
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
    final editsChanged = await reloadEdits();
    if (_disposed) return;

    boardRows.sort((a, b) => _byAge(a.createdAt, a.id!, b.createdAt, b.id!));
    tileRows.sort((a, b) => _byAge(a.createdAt, a.id!, b.createdAt, b.id!));
    final boards = [for (final row in boardRows) boardFacts(row)];
    final tiles = [for (final row in tileRows) tileFacts(row)];
    final first = !_hasLoaded;
    _hasLoaded = true;
    if (listEquals(boards, _boards) && listEquals(tiles, _tiles)) {
      if (first || editsChanged) notifyListeners();
      return;
    }

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

  /// A new word in [boardId]'s "Needs a home": a tray key, never a cell,
  /// so an adult chooses where it goes. Used by "Put back" in a board copy.
  @override
  Future<String> addToTray({
    required String boardId,
    required String label,
    String? speech,
    String? colorKey,
    String? imageHash,
  }) async {
    _requireEditor();
    final text = _requireLabel(label);
    final board = uuidOf(boardId);
    final id = UuidValue.fromString(const Uuid().v7());
    final waiting = trayKey(idOf(id));
    await _replica.write(circleId, (tx) async {
      final at = _now().toUtc();
      final spoken = _blankToNull(speech);
      final colour = _blankToNull(colorKey);
      final picture = _blankToNull(imageHash);
      await Tile.db.insertRow(
        _replica.session,
        Tile(
          id: id,
          circleId: circleId,
          boardId: board,
          cellKey: waiting,
          label: text,
          speech: spoken,
          colorKey: colour,
          imageHash: picture,
          noLog: false,
          createdBy: _replica.userId,
          createdByName: myName,
          createdAt: at,
        ),
        transaction: tx,
      );
      await _log(tx, id, EditReason.add, at, [
        ('label', null, text),
        ('cellKey', null, waiting),
        if (spoken != null) ('speech', null, spoken),
        if (colour != null) ('colorKey', null, colour),
        if (picture != null) ('imageHash', null, picture),
      ], isNewTile: true);
    });
    await refresh();
    return idOf(id);
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
  }) => updateTileAs(
    tileId,
    label: label,
    speech: speech,
    colorKey: colorKey,
    reason: EditReason.edit,
  );

  /// [updateTile] with the [reason] to record in the edit log, so a restore
  /// takes the same write path as any other edit.
  @override
  Future<void> updateTileAs(
    String tileId, {
    String? label,
    String? speech,
    String? colorKey,
    required String reason,
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
        await _log(tx, id, reason, at, changes);
      });
    } on _NothingToWrite {
      return;
    }
    await refresh();
  }

  /// Sets or clears a tile's picture and recording. A null argument leaves
  /// that property alone; an empty one clears it. Never changes the cell.
  @override
  Future<void> setTileMedia(
    String tileId, {
    String? imageHash,
    String? audioHash,
  }) async {
    _requireEditor();
    final id = uuidOf(tileId);
    try {
      await _replica.write(circleId, (tx) async {
        final tile = await _requireTile(tx, id);
        final changes = <(String, String?, String?)>[
          if (imageHash != null && _blankToNull(imageHash) != tile.imageHash)
            ('imageHash', tile.imageHash, _blankToNull(imageHash)),
          if (audioHash != null && _blankToNull(audioHash) != tile.audioHash)
            ('audioHash', tile.audioHash, _blankToNull(audioHash)),
        ];
        if (changes.isEmpty) throw const _NothingToWrite();
        final changed = {for (final change in changes) change.$1};

        // Only the columns that changed are named, as in updateTile.
        final at = _now().toUtc();
        final next = Tile(
          id: tile.id,
          circleId: tile.circleId,
          boardId: tile.boardId,
          cellKey: tile.cellKey,
          label: tile.label,
          speech: tile.speech,
          colorKey: tile.colorKey,
          imageHash: changed.contains('imageHash')
              ? _blankToNull(imageHash)
              : tile.imageHash,
          audioHash: changed.contains('audioHash')
              ? _blankToNull(audioHash)
              : tile.audioHash,
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
            if (changed.contains('imageHash')) t.imageHash,
            if (changed.contains('audioHash')) t.audioHash,
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

  // ---- Boards ------------------------------------------------------------

  /// A new board is a plain synced row in the circle's space, the size of
  /// the starter board, never the home board.
  @override
  Future<String> addBoard(String name) async {
    _requireEditor();
    final tidy = _requireBoardName(name);
    final id = UuidValue.fromString(const Uuid().v7());
    await _replica.write(
      circleId,
      (tx) => _insertBoard(tx, id, tidy, _now().toUtc()),
    );
    await refresh();
    return idOf(id);
  }

  /// Names only the name column, so a rename on one device and an archive
  /// on another both survive the merge.
  @override
  Future<void> renameBoard(String boardId, String name) async {
    _requireEditor();
    final tidy = _requireBoardName(name);
    final id = _boardUuid(boardId);
    try {
      await _replica.write(circleId, (tx) async {
        final board = await Board.db.findFirstRow(
          _replica.session,
          where: (t) => t.id.equals(id) & t.circleId.equals(circleId),
          transaction: tx,
        );
        if (board == null || board.archivedAt != null) {
          throw ArgumentError.value(boardId, 'boardId', 'No such board');
        }
        if (board.name == tidy) throw const _NothingToWrite();
        await Board.db.updateRow(
          _replica.session,
          board.copyWith(name: tidy),
          columns: (t) => [t.name],
          transaction: tx,
        );
      });
    } on _NothingToWrite {
      return;
    }
    await refresh();
  }

  /// Sets the board's `archivedAt`, and archives each of its words as
  /// [archiveTile] does (flag and tray key in one update, one edit-log
  /// row each), all in one transaction. Nothing is deleted.
  @override
  Future<void> archiveBoard(String boardId) async {
    _requireEditor();
    final id = _boardUuid(boardId);
    await _replica.write(circleId, (tx) async {
      final rows = await Board.db.find(
        _replica.session,
        where: (t) => t.circleId.equals(circleId),
        transaction: tx,
      );
      final board = rows.where((row) => idOf(row.id!) == idOf(id)).firstOrNull;
      if (board == null) {
        throw ArgumentError.value(boardId, 'boardId', 'No such board');
      }
      // Read inside the transaction: a board archived on this device a
      // moment ago counts, so the last board in use always stays.
      final problem = archiveProblem(
        boardFacts(board),
        rows.map(boardFacts),
      );
      if (problem != null) throw StateError(problem);

      final at = _now().toUtc();
      await Board.db.updateRow(
        _replica.session,
        board.copyWith(archivedAt: at),
        columns: (t) => [t.archivedAt],
        transaction: tx,
      );
      final words = await Tile.db.find(
        _replica.session,
        where: (t) => t.circleId.equals(circleId) & t.boardId.equals(id),
        transaction: tx,
      );
      for (final tile in words) {
        if (tile.archivedAt != null) continue;
        final tileId = tile.id!;
        final waiting = trayKey(idOf(tileId));
        final hadCell = CellKey.parse(tile.cellKey) != TrayCell(idOf(tileId));
        await Tile.db.updateRow(
          _replica.session,
          tile.copyWith(archivedAt: at, cellKey: waiting),
          columns: (t) => [t.archivedAt, if (hadCell) t.cellKey],
          transaction: tx,
        );
        await _log(tx, tileId, EditReason.archive, at, [
          ('archivedAt', null, at.toIso8601String()),
          if (hadCell) ('cellKey', loggedKey(tile.cellKey), waiting),
        ]);
      }
    });
    await refresh();
  }

  /// One transaction: the board, then each word that fits in the cell it
  /// had in the file, keyed with [placedKey] and logged as an added word.
  /// The board is new, so every cell is free.
  @override
  Future<BoardImport> importBoard(ObfBoard board) async {
    _requireEditor();
    final (:fitted, :leftOver) = obfPlacements(
      board,
      rows: starterRows,
      cols: starterCols,
    );
    final id = UuidValue.fromString(const Uuid().v7());
    final boardKey = idOf(id);
    await _replica.write(circleId, (tx) async {
      final rows = await Board.db.find(
        _replica.session,
        where: (t) => t.circleId.equals(circleId),
        transaction: tx,
      );
      final at = _now().toUtc();
      await _insertBoard(
        tx,
        id,
        importedBoardName(board.name, rows.map(boardFacts)),
        at,
      );
      if (fitted.isEmpty) return;
      final tiles = <Tile>[];
      final edits = <TileEdit>[];
      for (final word in fitted) {
        final tileId = UuidValue.fromString(const Uuid().v7());
        final cellKey = placedKey(boardKey, word.row, word.col);
        final speech = _blankToNull(word.speech);
        final colour = _blankToNull(word.colorKey);
        tiles.add(
          Tile(
            id: tileId,
            circleId: circleId,
            boardId: id,
            cellKey: cellKey,
            label: word.label,
            speech: speech,
            colorKey: colour,
            noLog: false,
            createdBy: _replica.userId,
            createdByName: myName,
            createdAt: at,
          ),
        );
        // As addTile logs a new word: no earlier edits to point at.
        for (final (prop, value) in [
          ('label', word.label),
          ('cellKey', cellKey),
          if (speech != null) ('speech', speech),
          if (colour != null) ('colorKey', colour),
        ]) {
          edits.add(
            TileEdit(
              circleId: circleId,
              tileId: tileId,
              prop: prop,
              newValue: value,
              reason: EditReason.add,
              actorId: _replica.userId,
              actorName: myName,
              editedAt: at,
            ),
          );
        }
      }
      await Tile.db.insert(_replica.session, tiles, transaction: tx);
      await TileEdit.db.insert(_replica.session, edits, transaction: tx);
    });
    await refresh();
    return BoardImport(boardId: boardKey, leftOut: leftOver);
  }

  Future<void> _insertBoard(
    Transaction tx,
    UuidValue id,
    String name,
    DateTime at,
  ) => Board.db.insertRow(
    _replica.session,
    Board(
      id: id,
      circleId: circleId,
      name: name,
      rows: starterRows,
      cols: starterCols,
      isHome: false,
      createdAt: at,
    ),
    transaction: tx,
  );

  /// [name] tidied, or [ArgumentError] with the reason in words.
  static String _requireBoardName(String name) {
    final problem = boardNameProblem(name);
    if (problem != null) throw ArgumentError.value(name, 'name', problem);
    return tidyBoardName(name);
  }

  /// A board id as the replica keys it; [ArgumentError] for one that is
  /// not a UUID, which no board of this circle can have.
  static UuidValue _boardUuid(String boardId) {
    try {
      return UuidValue.withFormatValidation(boardId.toLowerCase());
    } on FormatException {
      throw ArgumentError.value(boardId, 'boardId', 'No such board');
    }
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
