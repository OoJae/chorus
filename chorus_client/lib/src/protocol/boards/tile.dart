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
import 'package:chorus_client/src/protocol/protocol.dart' as _iuvo7w6p;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:serverpod_database/serverpod_database.dart' as _isd;
import '../boards/board.dart' as _iuigseqj;

/// A tile: one word on a board.
///
/// Synced. Never hard-deleted. A tile is bound to one cell for life: it may
/// go from the tray into an empty cell, or from the board to the tray, never
/// from one cell to another.
abstract class Tile
    implements _isd.TableRow<_isc.UuidValue?>, _isc.ProtocolSerialization {
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
    _isc.UuidValue? id,
    int? spaceId,
    required _isc.UuidValue circleId,
    required _isc.UuidValue boardId,
    _iuigseqj.Board? board,
    required String cellKey,
    required String label,
    String? speech,
    String? colorKey,
    String? imageHash,
    String? audioHash,
    _isc.UuidValue? linkBoardId,
    required bool noLog,
    DateTime? archivedAt,
    required _isc.UuidValue createdBy,
    required String createdByName,
    required DateTime createdAt,
  }) = _TileImpl;

  factory Tile.fromJson(Map<String, dynamic> jsonSerialization) {
    return Tile(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      spaceId: jsonSerialization['spaceId'] as int?,
      circleId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleId'],
      ),
      boardId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['boardId'],
      ),
      board: jsonSerialization['board'] == null
          ? null
          : _iuvo7w6p.Protocol().deserialize<_iuigseqj.Board>(
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
          : _isc.UuidValueJsonExtension.fromJson(
              jsonSerialization['linkBoardId'],
            ),
      noLog: _isc.BoolJsonExtension.fromJson(jsonSerialization['noLog']),
      archivedAt: jsonSerialization['archivedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['archivedAt'],
            ),
      createdBy: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['createdBy'],
      ),
      createdByName: jsonSerialization['createdByName'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = TileTable();

  static const db = TileRepository._();

  @override
  _isc.UuidValue? id;

  /// The space owning this row. Maintained by the sync engine.
  int? spaceId;

  _isc.UuidValue circleId;

  _isc.UuidValue boardId;

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

  _isc.UuidValue? linkBoardId;

  /// When true, taps on this tile are never logged, even if logging is on.
  bool noLog;

  DateTime? archivedAt;

  _isc.UuidValue createdBy;

  String createdByName;

  DateTime createdAt;

  @override
  _isd.Table<_isc.UuidValue?> get table => t;

  /// Returns a shallow copy of this [Tile]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Tile copyWith({
    _isc.UuidValue? id,
    int? spaceId,
    _isc.UuidValue? circleId,
    _isc.UuidValue? boardId,
    _iuigseqj.Board? board,
    String? cellKey,
    String? label,
    String? speech,
    String? colorKey,
    String? imageHash,
    String? audioHash,
    _isc.UuidValue? linkBoardId,
    bool? noLog,
    DateTime? archivedAt,
    _isc.UuidValue? createdBy,
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
    _isd.WhereExpressionBuilder<TileTable>? where,
    int? limit,
    int? offset,
    _isd.OrderByBuilder<TileTable>? orderBy,
    _isd.OrderByListBuilder<TileTable>? orderByList,
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
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TileImpl extends Tile {
  _TileImpl({
    _isc.UuidValue? id,
    int? spaceId,
    required _isc.UuidValue circleId,
    required _isc.UuidValue boardId,
    _iuigseqj.Board? board,
    required String cellKey,
    required String label,
    String? speech,
    String? colorKey,
    String? imageHash,
    String? audioHash,
    _isc.UuidValue? linkBoardId,
    required bool noLog,
    DateTime? archivedAt,
    required _isc.UuidValue createdBy,
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
  @_isc.useResult
  @override
  Tile copyWith({
    Object? id = _Undefined,
    Object? spaceId = _Undefined,
    _isc.UuidValue? circleId,
    _isc.UuidValue? boardId,
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
    _isc.UuidValue? createdBy,
    String? createdByName,
    DateTime? createdAt,
  }) {
    return Tile(
      id: id is _isc.UuidValue? ? id : this.id,
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
      linkBoardId: linkBoardId is _isc.UuidValue?
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

class TileUpdateTable extends _isd.UpdateTable<TileTable> {
  TileUpdateTable(super.table);

  _isd.ColumnValue<int, int> spaceId(int? value) => _isd.ColumnValue(
    table.spaceId,
    value,
  );

  _isd.ColumnValue<_isc.UuidValue, _isc.UuidValue> circleId(
    _isc.UuidValue value,
  ) => _isd.ColumnValue(
    table.circleId,
    value,
  );

  _isd.ColumnValue<_isc.UuidValue, _isc.UuidValue> boardId(
    _isc.UuidValue value,
  ) => _isd.ColumnValue(
    table.boardId,
    value,
  );

  _isd.ColumnValue<String, String> cellKey(String value) => _isd.ColumnValue(
    table.cellKey,
    value,
  );

  _isd.ColumnValue<String, String> label(String value) => _isd.ColumnValue(
    table.label,
    value,
  );

  _isd.ColumnValue<String, String> speech(String? value) => _isd.ColumnValue(
    table.speech,
    value,
  );

  _isd.ColumnValue<String, String> colorKey(String? value) => _isd.ColumnValue(
    table.colorKey,
    value,
  );

  _isd.ColumnValue<String, String> imageHash(String? value) => _isd.ColumnValue(
    table.imageHash,
    value,
  );

  _isd.ColumnValue<String, String> audioHash(String? value) => _isd.ColumnValue(
    table.audioHash,
    value,
  );

  _isd.ColumnValue<_isc.UuidValue, _isc.UuidValue> linkBoardId(
    _isc.UuidValue? value,
  ) => _isd.ColumnValue(
    table.linkBoardId,
    value,
  );

  _isd.ColumnValue<bool, bool> noLog(bool value) => _isd.ColumnValue(
    table.noLog,
    value,
  );

  _isd.ColumnValue<DateTime, DateTime> archivedAt(DateTime? value) =>
      _isd.ColumnValue(
        table.archivedAt,
        value,
      );

  _isd.ColumnValue<_isc.UuidValue, _isc.UuidValue> createdBy(
    _isc.UuidValue value,
  ) => _isd.ColumnValue(
    table.createdBy,
    value,
  );

  _isd.ColumnValue<String, String> createdByName(String value) =>
      _isd.ColumnValue(
        table.createdByName,
        value,
      );

  _isd.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _isd.ColumnValue(
        table.createdAt,
        value,
      );
}

class TileTable extends _isd.Table<_isc.UuidValue?> {
  TileTable({super.tableRelation}) : super(tableName: 'tile') {
    updateTable = TileUpdateTable(this);
    spaceId = _isd.ColumnInt(
      'spaceId',
      this,
    );
    circleId = _isd.ColumnUuid(
      'circleId',
      this,
    );
    boardId = _isd.ColumnUuid(
      'boardId',
      this,
    );
    cellKey = _isd.ColumnString(
      'cellKey',
      this,
    );
    label = _isd.ColumnString(
      'label',
      this,
    );
    speech = _isd.ColumnString(
      'speech',
      this,
    );
    colorKey = _isd.ColumnString(
      'colorKey',
      this,
    );
    imageHash = _isd.ColumnString(
      'imageHash',
      this,
    );
    audioHash = _isd.ColumnString(
      'audioHash',
      this,
    );
    linkBoardId = _isd.ColumnUuid(
      'linkBoardId',
      this,
    );
    noLog = _isd.ColumnBool(
      'noLog',
      this,
    );
    archivedAt = _isd.ColumnDateTime(
      'archivedAt',
      this,
    );
    createdBy = _isd.ColumnUuid(
      'createdBy',
      this,
    );
    createdByName = _isd.ColumnString(
      'createdByName',
      this,
    );
    createdAt = _isd.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final TileUpdateTable updateTable;

  /// The space owning this row. Maintained by the sync engine.
  late final _isd.ColumnInt spaceId;

  late final _isd.ColumnUuid circleId;

  late final _isd.ColumnUuid boardId;

  _iuigseqj.BoardTable? _board;

  /// The only place a tile's position lives. Three forms:
  /// `<boardId>:<row>:<col>` (on the board), `tray:<tileId>` (unplaced or
  /// archived, written by the app), and `<boardId>:<row>:<col>__conflict__<id>`
  /// (written only by the sync engine to the loser of an offline collision).
  /// The unique index is what turns two offline claims on one cell into a
  /// visible "needs a home" item instead of a silent overwrite.
  late final _isd.ColumnString cellKey;

  late final _isd.ColumnString label;

  /// What is spoken; the label is spoken when this is null.
  late final _isd.ColumnString speech;

  /// Part-of-speech colour key, e.g. `verb`.
  late final _isd.ColumnString colorKey;

  /// Content hashes of the picture and the recorded voice. The files travel
  /// by direct upload; only the hash is synced.
  late final _isd.ColumnString imageHash;

  late final _isd.ColumnString audioHash;

  late final _isd.ColumnUuid linkBoardId;

  /// When true, taps on this tile are never logged, even if logging is on.
  late final _isd.ColumnBool noLog;

  late final _isd.ColumnDateTime archivedAt;

  late final _isd.ColumnUuid createdBy;

  late final _isd.ColumnString createdByName;

  late final _isd.ColumnDateTime createdAt;

  _iuigseqj.BoardTable get board {
    if (_board != null) return _board!;
    _board = _isd.createRelationTable(
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
  List<_isd.Column> get columns => [
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
  _isd.Table? getRelationTable(String relationField) {
    if (relationField == 'board') {
      return board;
    }
    return null;
  }
}

class TileInclude extends _isd.IncludeObject {
  TileInclude._({_iuigseqj.BoardInclude? board}) {
    _board = board;
  }

  _iuigseqj.BoardInclude? _board;

  @override
  Map<String, _isd.Include?> get includes => {'board': _board};

  @override
  _isd.Table<_isc.UuidValue?> get table => Tile.t;
}

class TileIncludeList extends _isd.IncludeList {
  TileIncludeList._({
    _isd.WhereExpressionBuilder<TileTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Tile.t);
  }

  @override
  Map<String, _isd.Include?> get includes => include?.includes ?? {};

  @override
  _isd.Table<_isc.UuidValue?> get table => Tile.t;
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
    _isd.DatabaseSession session, {
    _isd.WhereExpressionBuilder<TileTable>? where,
    int? limit,
    int? offset,
    _isd.OrderByBuilder<TileTable>? orderBy,
    _isd.OrderByListBuilder<TileTable>? orderByList,
    _isd.Transaction? transaction,
    TileInclude? include,
    _isd.LockMode? lockMode,
    _isd.LockBehavior? lockBehavior,
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
    _isd.DatabaseSession session, {
    _isd.WhereExpressionBuilder<TileTable>? where,
    int? offset,
    _isd.OrderByBuilder<TileTable>? orderBy,
    _isd.OrderByListBuilder<TileTable>? orderByList,
    _isd.Transaction? transaction,
    TileInclude? include,
    _isd.LockMode? lockMode,
    _isd.LockBehavior? lockBehavior,
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
    _isd.DatabaseSession session,
    _isc.UuidValue id, {
    _isd.Transaction? transaction,
    TileInclude? include,
    _isd.LockMode? lockMode,
    _isd.LockBehavior? lockBehavior,
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
    _isd.DatabaseSession session,
    List<Tile> rows, {
    _isd.Transaction? transaction,
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
    _isd.DatabaseSession session,
    Tile row, {
    _isd.Transaction? transaction,
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
    _isd.DatabaseSession session,
    List<Tile> rows, {
    required _isd.ColumnSelections<TileTable> conflictColumns,
    _isd.ColumnSelections<TileTable>? updateColumns,
    _isd.WhereExpressionBuilder<TileTable>? updateWhere,
    _isd.Transaction? transaction,
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
    _isd.DatabaseSession session,
    Tile row, {
    required _isd.ColumnSelections<TileTable> conflictColumns,
    _isd.ColumnSelections<TileTable>? updateColumns,
    _isd.WhereExpressionBuilder<TileTable>? updateWhere,
    _isd.Transaction? transaction,
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
    _isd.DatabaseSession session,
    List<Tile> rows, {
    _isd.ColumnSelections<TileTable>? columns,
    _isd.Transaction? transaction,
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
    _isd.DatabaseSession session,
    Tile row, {
    _isd.ColumnSelections<TileTable>? columns,
    _isd.Transaction? transaction,
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
    _isd.DatabaseSession session,
    _isc.UuidValue id, {
    required _isd.ColumnValueListBuilder<TileUpdateTable> columnValues,
    _isd.Transaction? transaction,
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
    _isd.DatabaseSession session, {
    required _isd.ColumnValueListBuilder<TileUpdateTable> columnValues,
    required _isd.WhereExpressionBuilder<TileTable> where,
    int? limit,
    int? offset,
    _isd.OrderByBuilder<TileTable>? orderBy,
    _isd.OrderByListBuilder<TileTable>? orderByList,
    _isd.Transaction? transaction,
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
    _isd.DatabaseSession session,
    List<Tile> rows, {
    _isd.OrderByBuilder<TileTable>? orderBy,
    _isd.OrderByListBuilder<TileTable>? orderByList,
    _isd.Transaction? transaction,
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
    _isd.DatabaseSession session,
    Tile row, {
    _isd.Transaction? transaction,
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
    _isd.DatabaseSession session, {
    required _isd.WhereExpressionBuilder<TileTable> where,
    _isd.OrderByBuilder<TileTable>? orderBy,
    _isd.OrderByListBuilder<TileTable>? orderByList,
    _isd.Transaction? transaction,
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
    _isd.DatabaseSession session, {
    _isd.WhereExpressionBuilder<TileTable>? where,
    int? limit,
    _isd.Transaction? transaction,
  }) async {
    return session.db.count<Tile>(
      where: where?.call(Tile.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Tile] rows matching the [where] expression.
  Future<void> lockRows(
    _isd.DatabaseSession session, {
    required _isd.WhereExpressionBuilder<TileTable> where,
    required _isd.LockMode lockMode,
    required _isd.Transaction transaction,
    _isd.LockBehavior lockBehavior = _isd.LockBehavior.wait,
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
    _isd.DatabaseSession session,
    Tile tile,
    _iuigseqj.Board board, {
    _isd.Transaction? transaction,
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
