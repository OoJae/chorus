/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:chorus_server/src/generated/protocol.dart' as _iq1qvsxu;
import 'package:serverpod/serverpod.dart' as _is;
import '../boards/board.dart' as _iuigseqj;

/// A tile: one word on a board.
///
/// Synced. Never hard-deleted. A tile is bound to one cell for life: it may
/// go from the tray into an empty cell, or from the board to the tray, never
/// from one cell to another.
abstract class Tile
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  Tile._({
    this.id,
    this.spaceId,
    required this.circleId,
    required this.boardId,
    this.board,
    required this.cellKey,
    required this.label,
    this.speech,
    this.colorKey,
    this.imageHash,
    this.audioHash,
    this.linkBoardId,
    required this.noLog,
    this.archivedAt,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
  });

  factory Tile({
    _is.UuidValue? id,
    int? spaceId,
    required _is.UuidValue circleId,
    required _is.UuidValue boardId,
    _iuigseqj.Board? board,
    required String cellKey,
    required String label,
    String? speech,
    String? colorKey,
    String? imageHash,
    String? audioHash,
    _is.UuidValue? linkBoardId,
    required bool noLog,
    DateTime? archivedAt,
    required _is.UuidValue createdBy,
    required String createdByName,
    required DateTime createdAt,
  }) = _TileImpl;

  factory Tile.fromJson(Map<String, dynamic> jsonSerialization) {
    return Tile(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      spaceId: jsonSerialization['spaceId'] as int?,
      circleId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleId'],
      ),
      boardId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['boardId'],
      ),
      board: jsonSerialization['board'] == null
          ? null
          : _iq1qvsxu.Protocol().deserialize<_iuigseqj.Board>(
              jsonSerialization['board'],
            ),
      cellKey: jsonSerialization['cellKey'] as String,
      label: jsonSerialization['label'] as String,
      speech: jsonSerialization['speech'] as String?,
      colorKey: jsonSerialization['colorKey'] as String?,
      imageHash: jsonSerialization['imageHash'] as String?,
      audioHash: jsonSerialization['audioHash'] as String?,
      linkBoardId: jsonSerialization['linkBoardId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['linkBoardId'],
            ),
      noLog: _is.BoolJsonExtension.fromJson(jsonSerialization['noLog']),
      archivedAt: jsonSerialization['archivedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['archivedAt']),
      createdBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['createdBy'],
      ),
      createdByName: jsonSerialization['createdByName'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = TileTable();

  static const db = TileRepository._();

  @override
  _is.UuidValue? id;

  /// The space owning this row. Maintained by the sync engine.
  int? spaceId;

  _is.UuidValue circleId;

  _is.UuidValue boardId;

  _iuigseqj.Board? board;

  /// The only place a tile's position lives. Three forms:
  /// `<boardId>:<row>:<col>` (on the board), `tray:<tileId>` (unplaced or
  /// archived, written by the app), and `<boardId>:<row>:<col>__conflict__<id>`
  /// (written only by the sync engine to the loser of an offline collision).
  /// The unique index is what turns two offline claims on one cell into a
  /// visible "needs a home" item instead of a silent overwrite.
  String cellKey;

  String label;

  /// What is spoken; the label is spoken when this is null.
  String? speech;

  /// Part-of-speech colour key, e.g. `verb`.
  String? colorKey;

  /// Content hashes of the picture and the recorded voice. The files travel
  /// by direct upload; only the hash is synced.
  String? imageHash;

  String? audioHash;

  _is.UuidValue? linkBoardId;

  /// When true, taps on this tile are never logged, even if logging is on.
  bool noLog;

  DateTime? archivedAt;

  _is.UuidValue createdBy;

  String createdByName;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [Tile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Tile copyWith({
    _is.UuidValue? id,
    int? spaceId,
    _is.UuidValue? circleId,
    _is.UuidValue? boardId,
    _iuigseqj.Board? board,
    String? cellKey,
    String? label,
    String? speech,
    String? colorKey,
    String? imageHash,
    String? audioHash,
    _is.UuidValue? linkBoardId,
    bool? noLog,
    DateTime? archivedAt,
    _is.UuidValue? createdBy,
    String? createdByName,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Tile',
      if (id != null) 'id': id?.toJson(),
      if (spaceId != null) 'spaceId': spaceId,
      'circleId': circleId.toJson(),
      'boardId': boardId.toJson(),
      if (board != null) 'board': board?.toJson(),
      'cellKey': cellKey,
      'label': label,
      if (speech != null) 'speech': speech,
      if (colorKey != null) 'colorKey': colorKey,
      if (imageHash != null) 'imageHash': imageHash,
      if (audioHash != null) 'audioHash': audioHash,
      if (linkBoardId != null) 'linkBoardId': linkBoardId?.toJson(),
      'noLog': noLog,
      if (archivedAt != null) 'archivedAt': archivedAt?.toJson(),
      'createdBy': createdBy.toJson(),
      'createdByName': createdByName,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Tile',
      if (id != null) 'id': id?.toJson(),
      if (spaceId != null) 'spaceId': spaceId,
      'circleId': circleId.toJson(),
      'boardId': boardId.toJson(),
      if (board != null) 'board': board?.toJsonForProtocol(),
      'cellKey': cellKey,
      'label': label,
      if (speech != null) 'speech': speech,
      if (colorKey != null) 'colorKey': colorKey,
      if (imageHash != null) 'imageHash': imageHash,
      if (audioHash != null) 'audioHash': audioHash,
      if (linkBoardId != null) 'linkBoardId': linkBoardId?.toJson(),
      'noLog': noLog,
      if (archivedAt != null) 'archivedAt': archivedAt?.toJson(),
      'createdBy': createdBy.toJson(),
      'createdByName': createdByName,
      'createdAt': createdAt.toJson(),
    };
  }

  static TileInclude include({_iuigseqj.BoardInclude? board}) {
    return TileInclude._(board: board);
  }

  static TileIncludeList includeList({
    _is.WhereExpressionBuilder<TileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TileTable>? orderBy,
    _is.OrderByListBuilder<TileTable>? orderByList,
    TileInclude? include,
  }) {
    return TileIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Tile.t),
      orderByList: orderByList?.call(Tile.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TileImpl extends Tile {
  _TileImpl({
    _is.UuidValue? id,
    int? spaceId,
    required _is.UuidValue circleId,
    required _is.UuidValue boardId,
    _iuigseqj.Board? board,
    required String cellKey,
    required String label,
    String? speech,
    String? colorKey,
    String? imageHash,
    String? audioHash,
    _is.UuidValue? linkBoardId,
    required bool noLog,
    DateTime? archivedAt,
    required _is.UuidValue createdBy,
    required String createdByName,
    required DateTime createdAt,
  }) : super._(
         id: id,
         spaceId: spaceId,
         circleId: circleId,
         boardId: boardId,
         board: board,
         cellKey: cellKey,
         label: label,
         speech: speech,
         colorKey: colorKey,
         imageHash: imageHash,
         audioHash: audioHash,
         linkBoardId: linkBoardId,
         noLog: noLog,
         archivedAt: archivedAt,
         createdBy: createdBy,
         createdByName: createdByName,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Tile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Tile copyWith({
    Object? id = _Undefined,
    Object? spaceId = _Undefined,
    _is.UuidValue? circleId,
    _is.UuidValue? boardId,
    Object? board = _Undefined,
    String? cellKey,
    String? label,
    Object? speech = _Undefined,
    Object? colorKey = _Undefined,
    Object? imageHash = _Undefined,
    Object? audioHash = _Undefined,
    Object? linkBoardId = _Undefined,
    bool? noLog,
    Object? archivedAt = _Undefined,
    _is.UuidValue? createdBy,
    String? createdByName,
    DateTime? createdAt,
  }) {
    return Tile(
      id: id is _is.UuidValue? ? id : this.id,
      spaceId: spaceId is int? ? spaceId : this.spaceId,
      circleId: circleId ?? this.circleId,
      boardId: boardId ?? this.boardId,
      board: board is _iuigseqj.Board? ? board : this.board?.copyWith(),
      cellKey: cellKey ?? this.cellKey,
      label: label ?? this.label,
      speech: speech is String? ? speech : this.speech,
      colorKey: colorKey is String? ? colorKey : this.colorKey,
      imageHash: imageHash is String? ? imageHash : this.imageHash,
      audioHash: audioHash is String? ? audioHash : this.audioHash,
      linkBoardId: linkBoardId is _is.UuidValue?
          ? linkBoardId
          : this.linkBoardId,
      noLog: noLog ?? this.noLog,
      archivedAt: archivedAt is DateTime? ? archivedAt : this.archivedAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TileUpdateTable extends _is.UpdateTable<TileTable> {
  TileUpdateTable(super.table);

  _is.ColumnValue<int, int> spaceId(int? value) => _is.ColumnValue(
    table.spaceId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.circleId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> boardId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.boardId,
        value,
      );

  _is.ColumnValue<String, String> cellKey(String value) => _is.ColumnValue(
    table.cellKey,
    value,
  );

  _is.ColumnValue<String, String> label(String value) => _is.ColumnValue(
    table.label,
    value,
  );

  _is.ColumnValue<String, String> speech(String? value) => _is.ColumnValue(
    table.speech,
    value,
  );

  _is.ColumnValue<String, String> colorKey(String? value) => _is.ColumnValue(
    table.colorKey,
    value,
  );

  _is.ColumnValue<String, String> imageHash(String? value) => _is.ColumnValue(
    table.imageHash,
    value,
  );

  _is.ColumnValue<String, String> audioHash(String? value) => _is.ColumnValue(
    table.audioHash,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> linkBoardId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.linkBoardId,
    value,
  );

  _is.ColumnValue<bool, bool> noLog(bool value) => _is.ColumnValue(
    table.noLog,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> archivedAt(DateTime? value) =>
      _is.ColumnValue(
        table.archivedAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> createdBy(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.createdBy,
    value,
  );

  _is.ColumnValue<String, String> createdByName(String value) =>
      _is.ColumnValue(
        table.createdByName,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class TileTable extends _is.Table<_is.UuidValue?> {
  TileTable({super.tableRelation}) : super(tableName: 'tile') {
    updateTable = TileUpdateTable(this);
    spaceId = _is.ColumnInt(
      'spaceId',
      this,
    );
    circleId = _is.ColumnUuid(
      'circleId',
      this,
    );
    boardId = _is.ColumnUuid(
      'boardId',
      this,
    );
    cellKey = _is.ColumnString(
      'cellKey',
      this,
    );
    label = _is.ColumnString(
      'label',
      this,
    );
    speech = _is.ColumnString(
      'speech',
      this,
    );
    colorKey = _is.ColumnString(
      'colorKey',
      this,
    );
    imageHash = _is.ColumnString(
      'imageHash',
      this,
    );
    audioHash = _is.ColumnString(
      'audioHash',
      this,
    );
    linkBoardId = _is.ColumnUuid(
      'linkBoardId',
      this,
    );
    noLog = _is.ColumnBool(
      'noLog',
      this,
    );
    archivedAt = _is.ColumnDateTime(
      'archivedAt',
      this,
    );
    createdBy = _is.ColumnUuid(
      'createdBy',
      this,
    );
    createdByName = _is.ColumnString(
      'createdByName',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final TileUpdateTable updateTable;

  /// The space owning this row. Maintained by the sync engine.
  late final _is.ColumnInt spaceId;

  late final _is.ColumnUuid circleId;

  late final _is.ColumnUuid boardId;

  _iuigseqj.BoardTable? _board;

  /// The only place a tile's position lives. Three forms:
  /// `<boardId>:<row>:<col>` (on the board), `tray:<tileId>` (unplaced or
  /// archived, written by the app), and `<boardId>:<row>:<col>__conflict__<id>`
  /// (written only by the sync engine to the loser of an offline collision).
  /// The unique index is what turns two offline claims on one cell into a
  /// visible "needs a home" item instead of a silent overwrite.
  late final _is.ColumnString cellKey;

  late final _is.ColumnString label;

  /// What is spoken; the label is spoken when this is null.
  late final _is.ColumnString speech;

  /// Part-of-speech colour key, e.g. `verb`.
  late final _is.ColumnString colorKey;

  /// Content hashes of the picture and the recorded voice. The files travel
  /// by direct upload; only the hash is synced.
  late final _is.ColumnString imageHash;

  late final _is.ColumnString audioHash;

  late final _is.ColumnUuid linkBoardId;

  /// When true, taps on this tile are never logged, even if logging is on.
  late final _is.ColumnBool noLog;

  late final _is.ColumnDateTime archivedAt;

  late final _is.ColumnUuid createdBy;

  late final _is.ColumnString createdByName;

  late final _is.ColumnDateTime createdAt;

  _iuigseqj.BoardTable get board {
    if (_board != null) return _board!;
    _board = _is.createRelationTable(
      relationFieldName: 'board',
      field: Tile.t.boardId,
      foreignField: _iuigseqj.Board.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iuigseqj.BoardTable(tableRelation: foreignTableRelation),
    );
    return _board!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    spaceId,
    circleId,
    boardId,
    cellKey,
    label,
    speech,
    colorKey,
    imageHash,
    audioHash,
    linkBoardId,
    noLog,
    archivedAt,
    createdBy,
    createdByName,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'board') {
      return board;
    }
    return null;
  }
}

class TileInclude extends _is.IncludeObject {
  TileInclude._({_iuigseqj.BoardInclude? board}) {
    _board = board;
  }

  _iuigseqj.BoardInclude? _board;

  @override
  Map<String, _is.Include?> get includes => {'board': _board};

  @override
  _is.Table<_is.UuidValue?> get table => Tile.t;
}

class TileIncludeList extends _is.IncludeList {
  TileIncludeList._({
    _is.WhereExpressionBuilder<TileTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Tile.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => Tile.t;
}

class TileRepository {
  const TileRepository._();

  final attachRow = const TileAttachRowRepository._();

  /// Returns a list of [Tile]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Tile>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TileTable>? orderBy,
    _is.OrderByListBuilder<TileTable>? orderByList,
    _is.Transaction? transaction,
    TileInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Tile>(
      where: where?.call(Tile.t),
      orderBy: orderBy?.call(Tile.t),
      orderByList: orderByList?.call(Tile.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Tile] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Tile?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TileTable>? where,
    int? offset,
    _is.OrderByBuilder<TileTable>? orderBy,
    _is.OrderByListBuilder<TileTable>? orderByList,
    _is.Transaction? transaction,
    TileInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Tile>(
      where: where?.call(Tile.t),
      orderBy: orderBy?.call(Tile.t),
      orderByList: orderByList?.call(Tile.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Tile] by its [id] or null if no such row exists.
  Future<Tile?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    TileInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Tile>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Tile]s in the list and returns the inserted rows.
  ///
  /// The returned [Tile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Tile>> insert(
    _is.DatabaseSession session,
    List<Tile> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Tile>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Tile] and returns the inserted row.
  ///
  /// The returned [Tile] will have its `id` field set.
  Future<Tile> insertRow(
    _is.DatabaseSession session,
    Tile row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Tile>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Tile]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [Tile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Tile>> upsert(
    _is.DatabaseSession session,
    List<Tile> rows, {
    required _is.ColumnSelections<TileTable> conflictColumns,
    _is.ColumnSelections<TileTable>? updateColumns,
    _is.WhereExpressionBuilder<TileTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Tile>(
      rows,
      conflictColumns: conflictColumns(Tile.t),
      updateColumns: updateColumns?.call(Tile.t),
      updateWhere: updateWhere?.call(Tile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Tile] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [Tile] will have its `id` field set.
  Future<Tile?> upsertRow(
    _is.DatabaseSession session,
    Tile row, {
    required _is.ColumnSelections<TileTable> conflictColumns,
    _is.ColumnSelections<TileTable>? updateColumns,
    _is.WhereExpressionBuilder<TileTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Tile>(
      row,
      conflictColumns: conflictColumns(Tile.t),
      updateColumns: updateColumns?.call(Tile.t),
      updateWhere: updateWhere?.call(Tile.t),
      transaction: transaction,
    );
  }

  /// Updates all [Tile]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Tile>> update(
    _is.DatabaseSession session,
    List<Tile> rows, {
    _is.ColumnSelections<TileTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Tile>(
      rows,
      columns: columns?.call(Tile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Tile]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Tile> updateRow(
    _is.DatabaseSession session,
    Tile row, {
    _is.ColumnSelections<TileTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Tile>(
      row,
      columns: columns?.call(Tile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Tile] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Tile?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<TileUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Tile>(
      id,
      columnValues: columnValues(Tile.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Tile]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Tile>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TileUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<TileTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TileTable>? orderBy,
    _is.OrderByListBuilder<TileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Tile>(
      columnValues: columnValues(Tile.t.updateTable),
      where: where(Tile.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Tile.t),
      orderByList: orderByList?.call(Tile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Tile]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Tile>> delete(
    _is.DatabaseSession session,
    List<Tile> rows, {
    _is.OrderByBuilder<TileTable>? orderBy,
    _is.OrderByListBuilder<TileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Tile>(
      rows,
      orderBy: orderBy?.call(Tile.t),
      orderByList: orderByList?.call(Tile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Tile].
  Future<Tile> deleteRow(
    _is.DatabaseSession session,
    Tile row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Tile>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Tile>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TileTable> where,
    _is.OrderByBuilder<TileTable>? orderBy,
    _is.OrderByListBuilder<TileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Tile>(
      where: where(Tile.t),
      orderBy: orderBy?.call(Tile.t),
      orderByList: orderByList?.call(Tile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TileTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Tile>(
      where: where?.call(Tile.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Tile] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TileTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Tile>(
      where: where(Tile.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class TileAttachRowRepository {
  const TileAttachRowRepository._();

  /// Creates a relation between the given [Tile] and [Board]
  /// by setting the [Tile]'s foreign key `boardId` to refer to the [Board].
  Future<void> board(
    _is.DatabaseSession session,
    Tile tile,
    _iuigseqj.Board board, {
    _is.Transaction? transaction,
  }) async {
    if (tile.id == null) {
      throw ArgumentError.notNull('tile.id');
    }
    if (board.id == null) {
      throw ArgumentError.notNull('board.id');
    }

    var $tile = tile.copyWith(boardId: board.id);
    await session.db.updateRow<Tile>(
      $tile,
      columns: [Tile.t.boardId],
      transaction: transaction,
    );
  }
}
