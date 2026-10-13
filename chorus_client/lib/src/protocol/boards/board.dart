/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:serverpod_database/serverpod_database.dart' as _isd;

/// A board: a fixed grid of cells that tiles are placed on.
///
/// Synced. Never hard-deleted; archiving sets [archivedAt].
abstract class Board
    implements _isd.TableRow<_isc.UuidValue?>, _isc.ProtocolSerialization {
  Board._({
    this.id,
    this.spaceId,
    required this.circleId,
    required this.name,
    required this.rows,
    required this.cols,
    required this.isHome,
    this.archivedAt,
    required this.createdAt,
  });

  factory Board({
    _isc.UuidValue? id,
    int? spaceId,
    required _isc.UuidValue circleId,
    required String name,
    required int rows,
    required int cols,
    required bool isHome,
    DateTime? archivedAt,
    required DateTime createdAt,
  }) = _BoardImpl;

  factory Board.fromJson(Map<String, dynamic> jsonSerialization) {
    return Board(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      spaceId: jsonSerialization['spaceId'] as int?,
      circleId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleId'],
      ),
      name: jsonSerialization['name'] as String,
      rows: jsonSerialization['rows'] as int,
      cols: jsonSerialization['cols'] as int,
      isHome: _isc.BoolJsonExtension.fromJson(jsonSerialization['isHome']),
      archivedAt: jsonSerialization['archivedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['archivedAt'],
            ),
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = BoardTable();

  static const db = BoardRepository._();

  @override
  _isc.UuidValue? id;

  /// The space owning this row. Maintained by the sync engine.
  int? spaceId;

  /// The circle this board belongs to. Reads span every space a user is in
  /// and the engine's own space id comes back null, so every synced row
  /// carries this.
  _isc.UuidValue circleId;

  String name;

  int rows;

  int cols;

  bool isHome;

  DateTime? archivedAt;

  DateTime createdAt;

  @override
  _isd.Table<_isc.UuidValue?> get table => t;

  /// Returns a shallow copy of this [Board]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Board copyWith({
    _isc.UuidValue? id,
    int? spaceId,
    _isc.UuidValue? circleId,
    String? name,
    int? rows,
    int? cols,
    bool? isHome,
    DateTime? archivedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Board',
      if (id != null) 'id': id?.toJson(),
      if (spaceId != null) 'spaceId': spaceId,
      'circleId': circleId.toJson(),
      'name': name,
      'rows': rows,
      'cols': cols,
      'isHome': isHome,
      if (archivedAt != null) 'archivedAt': archivedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Board',
      if (id != null) 'id': id?.toJson(),
      if (spaceId != null) 'spaceId': spaceId,
      'circleId': circleId.toJson(),
      'name': name,
      'rows': rows,
      'cols': cols,
      'isHome': isHome,
      if (archivedAt != null) 'archivedAt': archivedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static BoardInclude include() {
    return BoardInclude._();
  }

  static BoardIncludeList includeList({
    _isd.WhereExpressionBuilder<BoardTable>? where,
    int? limit,
    int? offset,
    _isd.OrderByBuilder<BoardTable>? orderBy,
    _isd.OrderByListBuilder<BoardTable>? orderByList,
    BoardInclude? include,
  }) {
    return BoardIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Board.t),
      orderByList: orderByList?.call(Board.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BoardImpl extends Board {
  _BoardImpl({
    _isc.UuidValue? id,
    int? spaceId,
    required _isc.UuidValue circleId,
    required String name,
    required int rows,
    required int cols,
    required bool isHome,
    DateTime? archivedAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         spaceId: spaceId,
         circleId: circleId,
         name: name,
         rows: rows,
         cols: cols,
         isHome: isHome,
         archivedAt: archivedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Board]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Board copyWith({
    Object? id = _Undefined,
    Object? spaceId = _Undefined,
    _isc.UuidValue? circleId,
    String? name,
    int? rows,
    int? cols,
    bool? isHome,
    Object? archivedAt = _Undefined,
    DateTime? createdAt,
  }) {
    return Board(
      id: id is _isc.UuidValue? ? id : this.id,
      spaceId: spaceId is int? ? spaceId : this.spaceId,
      circleId: circleId ?? this.circleId,
      name: name ?? this.name,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      isHome: isHome ?? this.isHome,
      archivedAt: archivedAt is DateTime? ? archivedAt : this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BoardUpdateTable extends _isd.UpdateTable<BoardTable> {
  BoardUpdateTable(super.table);

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

  _isd.ColumnValue<String, String> name(String value) => _isd.ColumnValue(
    table.name,
    value,
  );

  _isd.ColumnValue<int, int> rows(int value) => _isd.ColumnValue(
    table.rows,
    value,
  );

  _isd.ColumnValue<int, int> cols(int value) => _isd.ColumnValue(
    table.cols,
    value,
  );

  _isd.ColumnValue<bool, bool> isHome(bool value) => _isd.ColumnValue(
    table.isHome,
    value,
  );

  _isd.ColumnValue<DateTime, DateTime> archivedAt(DateTime? value) =>
      _isd.ColumnValue(
        table.archivedAt,
        value,
      );

  _isd.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _isd.ColumnValue(
        table.createdAt,
        value,
      );
}

class BoardTable extends _isd.Table<_isc.UuidValue?> {
  BoardTable({super.tableRelation}) : super(tableName: 'board') {
    updateTable = BoardUpdateTable(this);
    spaceId = _isd.ColumnInt(
      'spaceId',
      this,
    );
    circleId = _isd.ColumnUuid(
      'circleId',
      this,
    );
    name = _isd.ColumnString(
      'name',
      this,
    );
    rows = _isd.ColumnInt(
      'rows',
      this,
    );
    cols = _isd.ColumnInt(
      'cols',
      this,
    );
    isHome = _isd.ColumnBool(
      'isHome',
      this,
    );
    archivedAt = _isd.ColumnDateTime(
      'archivedAt',
      this,
    );
    createdAt = _isd.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final BoardUpdateTable updateTable;

  /// The space owning this row. Maintained by the sync engine.
  late final _isd.ColumnInt spaceId;

  /// The circle this board belongs to. Reads span every space a user is in
  /// and the engine's own space id comes back null, so every synced row
  /// carries this.
  late final _isd.ColumnUuid circleId;

  late final _isd.ColumnString name;

  late final _isd.ColumnInt rows;

  late final _isd.ColumnInt cols;

  late final _isd.ColumnBool isHome;

  late final _isd.ColumnDateTime archivedAt;

  late final _isd.ColumnDateTime createdAt;

  @override
  List<_isd.Column> get columns => [
    id,
    spaceId,
    circleId,
    name,
    rows,
    cols,
    isHome,
    archivedAt,
    createdAt,
  ];
}

class BoardInclude extends _isd.IncludeObject {
  BoardInclude._();

  @override
  Map<String, _isd.Include?> get includes => {};

  @override
  _isd.Table<_isc.UuidValue?> get table => Board.t;
}

class BoardIncludeList extends _isd.IncludeList {
  BoardIncludeList._({
    _isd.WhereExpressionBuilder<BoardTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Board.t);
  }

  @override
  Map<String, _isd.Include?> get includes => include?.includes ?? {};

  @override
  _isd.Table<_isc.UuidValue?> get table => Board.t;
}

class BoardRepository {
  const BoardRepository._();

  /// Returns a list of [Board]s matching the given query parameters.
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
  Future<List<Board>> find(
    _isd.DatabaseSession session, {
    _isd.WhereExpressionBuilder<BoardTable>? where,
    int? limit,
    int? offset,
    _isd.OrderByBuilder<BoardTable>? orderBy,
    _isd.OrderByListBuilder<BoardTable>? orderByList,
    _isd.Transaction? transaction,
    _isd.LockMode? lockMode,
    _isd.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Board>(
      where: where?.call(Board.t),
      orderBy: orderBy?.call(Board.t),
      orderByList: orderByList?.call(Board.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Board] matching the given query parameters.
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
  Future<Board?> findFirstRow(
    _isd.DatabaseSession session, {
    _isd.WhereExpressionBuilder<BoardTable>? where,
    int? offset,
    _isd.OrderByBuilder<BoardTable>? orderBy,
    _isd.OrderByListBuilder<BoardTable>? orderByList,
    _isd.Transaction? transaction,
    _isd.LockMode? lockMode,
    _isd.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Board>(
      where: where?.call(Board.t),
      orderBy: orderBy?.call(Board.t),
      orderByList: orderByList?.call(Board.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Board] by its [id] or null if no such row exists.
  Future<Board?> findById(
    _isd.DatabaseSession session,
    _isc.UuidValue id, {
    _isd.Transaction? transaction,
    _isd.LockMode? lockMode,
    _isd.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Board>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Board]s in the list and returns the inserted rows.
  ///
  /// The returned [Board]s will have their `id` fields set.
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
  Future<List<Board>> insert(
    _isd.DatabaseSession session,
    List<Board> rows, {
    _isd.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Board>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Board] and returns the inserted row.
  ///
  /// The returned [Board] will have its `id` field set.
  Future<Board> insertRow(
    _isd.DatabaseSession session,
    Board row, {
    _isd.Transaction? transaction,
  }) async {
    return session.db.insertRow<Board>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Board]s in the list and returns the resulting rows.
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
  /// The returned [Board]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Board>> upsert(
    _isd.DatabaseSession session,
    List<Board> rows, {
    required _isd.ColumnSelections<BoardTable> conflictColumns,
    _isd.ColumnSelections<BoardTable>? updateColumns,
    _isd.WhereExpressionBuilder<BoardTable>? updateWhere,
    _isd.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Board>(
      rows,
      conflictColumns: conflictColumns(Board.t),
      updateColumns: updateColumns?.call(Board.t),
      updateWhere: updateWhere?.call(Board.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Board] and returns the resulting row.
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
  /// The returned [Board] will have its `id` field set.
  Future<Board?> upsertRow(
    _isd.DatabaseSession session,
    Board row, {
    required _isd.ColumnSelections<BoardTable> conflictColumns,
    _isd.ColumnSelections<BoardTable>? updateColumns,
    _isd.WhereExpressionBuilder<BoardTable>? updateWhere,
    _isd.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Board>(
      row,
      conflictColumns: conflictColumns(Board.t),
      updateColumns: updateColumns?.call(Board.t),
      updateWhere: updateWhere?.call(Board.t),
      transaction: transaction,
    );
  }

  /// Updates all [Board]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Board>> update(
    _isd.DatabaseSession session,
    List<Board> rows, {
    _isd.ColumnSelections<BoardTable>? columns,
    _isd.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Board>(
      rows,
      columns: columns?.call(Board.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Board]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Board> updateRow(
    _isd.DatabaseSession session,
    Board row, {
    _isd.ColumnSelections<BoardTable>? columns,
    _isd.Transaction? transaction,
  }) async {
    return session.db.updateRow<Board>(
      row,
      columns: columns?.call(Board.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Board] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Board?> updateById(
    _isd.DatabaseSession session,
    _isc.UuidValue id, {
    required _isd.ColumnValueListBuilder<BoardUpdateTable> columnValues,
    _isd.Transaction? transaction,
  }) async {
    return session.db.updateById<Board>(
      id,
      columnValues: columnValues(Board.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Board]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Board>> updateWhere(
    _isd.DatabaseSession session, {
    required _isd.ColumnValueListBuilder<BoardUpdateTable> columnValues,
    required _isd.WhereExpressionBuilder<BoardTable> where,
    int? limit,
    int? offset,
    _isd.OrderByBuilder<BoardTable>? orderBy,
    _isd.OrderByListBuilder<BoardTable>? orderByList,
    _isd.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Board>(
      columnValues: columnValues(Board.t.updateTable),
      where: where(Board.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Board.t),
      orderByList: orderByList?.call(Board.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Board]s in the list and returns the deleted rows.
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
  Future<List<Board>> delete(
    _isd.DatabaseSession session,
    List<Board> rows, {
    _isd.OrderByBuilder<BoardTable>? orderBy,
    _isd.OrderByListBuilder<BoardTable>? orderByList,
    _isd.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Board>(
      rows,
      orderBy: orderBy?.call(Board.t),
      orderByList: orderByList?.call(Board.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Board].
  Future<Board> deleteRow(
    _isd.DatabaseSession session,
    Board row, {
    _isd.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Board>(
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
  Future<List<Board>> deleteWhere(
    _isd.DatabaseSession session, {
    required _isd.WhereExpressionBuilder<BoardTable> where,
    _isd.OrderByBuilder<BoardTable>? orderBy,
    _isd.OrderByListBuilder<BoardTable>? orderByList,
    _isd.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Board>(
      where: where(Board.t),
      orderBy: orderBy?.call(Board.t),
      orderByList: orderByList?.call(Board.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _isd.DatabaseSession session, {
    _isd.WhereExpressionBuilder<BoardTable>? where,
    int? limit,
    _isd.Transaction? transaction,
  }) async {
    return session.db.count<Board>(
      where: where?.call(Board.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Board] rows matching the [where] expression.
  Future<void> lockRows(
    _isd.DatabaseSession session, {
    required _isd.WhereExpressionBuilder<BoardTable> where,
    required _isd.LockMode lockMode,
    required _isd.Transaction transaction,
    _isd.LockBehavior lockBehavior = _isd.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Board>(
      where: where(Board.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
