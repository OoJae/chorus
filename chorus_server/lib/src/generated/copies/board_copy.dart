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
import 'package:chorus_server/src/generated/protocol.dart' as _iq1qvsxu;
import 'package:serverpod/serverpod.dart' as _is;
import '../copies/board_copy_word.dart' as _ivdpg0kb;

/// A named copy of a board, such as "Before the school trip": its words as
/// the server held them when the copy was taken. Server-only and not
/// synced; taking or deleting one never changes the board.
abstract class BoardCopy
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  BoardCopy._({
    this.id,
    required this.circleSpace,
    required this.boardId,
    required this.boardName,
    required this.rows,
    required this.cols,
    required this.name,
    required this.takenBy,
    required this.takenByName,
    required this.takenAt,
    required this.words,
  });

  factory BoardCopy({
    int? id,
    required _is.UuidValue circleSpace,
    required _is.UuidValue boardId,
    required String boardName,
    required int rows,
    required int cols,
    required String name,
    required _is.UuidValue takenBy,
    required String takenByName,
    required DateTime takenAt,
    required List<_ivdpg0kb.BoardCopyWord> words,
  }) = _BoardCopyImpl;

  factory BoardCopy.fromJson(Map<String, dynamic> jsonSerialization) {
    return BoardCopy(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      boardId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['boardId'],
      ),
      boardName: jsonSerialization['boardName'] as String,
      rows: jsonSerialization['rows'] as int,
      cols: jsonSerialization['cols'] as int,
      name: jsonSerialization['name'] as String,
      takenBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['takenBy'],
      ),
      takenByName: jsonSerialization['takenByName'] as String,
      takenAt: _is.DateTimeJsonExtension.fromJson(jsonSerialization['takenAt']),
      words: _iq1qvsxu.Protocol().deserialize<List<_ivdpg0kb.BoardCopyWord>>(
        jsonSerialization['words'],
      ),
    );
  }

  static final t = BoardCopyTable();

  static const db = BoardCopyRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  _is.UuidValue boardId;

  /// The board's name and size when the copy was taken.
  String boardName;

  int rows;

  int cols;

  String name;

  _is.UuidValue takenBy;

  String takenByName;

  DateTime takenAt;

  /// The placed words, kept as JSON.
  List<_ivdpg0kb.BoardCopyWord> words;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [BoardCopy]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BoardCopy copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    _is.UuidValue? boardId,
    String? boardName,
    int? rows,
    int? cols,
    String? name,
    _is.UuidValue? takenBy,
    String? takenByName,
    DateTime? takenAt,
    List<_ivdpg0kb.BoardCopyWord>? words,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BoardCopy',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'boardId': boardId.toJson(),
      'boardName': boardName,
      'rows': rows,
      'cols': cols,
      'name': name,
      'takenBy': takenBy.toJson(),
      'takenByName': takenByName,
      'takenAt': takenAt.toJson(),
      'words': words.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static BoardCopyInclude include() {
    return BoardCopyInclude._();
  }

  static BoardCopyIncludeList includeList({
    _is.WhereExpressionBuilder<BoardCopyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BoardCopyTable>? orderBy,
    _is.OrderByListBuilder<BoardCopyTable>? orderByList,
    BoardCopyInclude? include,
  }) {
    return BoardCopyIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BoardCopy.t),
      orderByList: orderByList?.call(BoardCopy.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BoardCopyImpl extends BoardCopy {
  _BoardCopyImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required _is.UuidValue boardId,
    required String boardName,
    required int rows,
    required int cols,
    required String name,
    required _is.UuidValue takenBy,
    required String takenByName,
    required DateTime takenAt,
    required List<_ivdpg0kb.BoardCopyWord> words,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         boardId: boardId,
         boardName: boardName,
         rows: rows,
         cols: cols,
         name: name,
         takenBy: takenBy,
         takenByName: takenByName,
         takenAt: takenAt,
         words: words,
       );

  /// Returns a shallow copy of this [BoardCopy]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BoardCopy copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    _is.UuidValue? boardId,
    String? boardName,
    int? rows,
    int? cols,
    String? name,
    _is.UuidValue? takenBy,
    String? takenByName,
    DateTime? takenAt,
    List<_ivdpg0kb.BoardCopyWord>? words,
  }) {
    return BoardCopy(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      boardId: boardId ?? this.boardId,
      boardName: boardName ?? this.boardName,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      name: name ?? this.name,
      takenBy: takenBy ?? this.takenBy,
      takenByName: takenByName ?? this.takenByName,
      takenAt: takenAt ?? this.takenAt,
      words: words ?? this.words.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class BoardCopyUpdateTable extends _is.UpdateTable<BoardCopyTable> {
  BoardCopyUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleSpace(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.circleSpace,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> boardId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.boardId,
        value,
      );

  _is.ColumnValue<String, String> boardName(String value) => _is.ColumnValue(
    table.boardName,
    value,
  );

  _is.ColumnValue<int, int> rows(int value) => _is.ColumnValue(
    table.rows,
    value,
  );

  _is.ColumnValue<int, int> cols(int value) => _is.ColumnValue(
    table.cols,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> takenBy(_is.UuidValue value) =>
      _is.ColumnValue(
        table.takenBy,
        value,
      );

  _is.ColumnValue<String, String> takenByName(String value) => _is.ColumnValue(
    table.takenByName,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> takenAt(DateTime value) =>
      _is.ColumnValue(
        table.takenAt,
        value,
      );

  _is.ColumnValue<List<_ivdpg0kb.BoardCopyWord>, List<_ivdpg0kb.BoardCopyWord>>
  words(List<_ivdpg0kb.BoardCopyWord> value) => _is.ColumnValue(
    table.words,
    value,
  );
}

class BoardCopyTable extends _is.Table<int?> {
  BoardCopyTable({super.tableRelation}) : super(tableName: 'board_copy') {
    updateTable = BoardCopyUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    boardId = _is.ColumnUuid(
      'boardId',
      this,
    );
    boardName = _is.ColumnString(
      'boardName',
      this,
    );
    rows = _is.ColumnInt(
      'rows',
      this,
    );
    cols = _is.ColumnInt(
      'cols',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    takenBy = _is.ColumnUuid(
      'takenBy',
      this,
    );
    takenByName = _is.ColumnString(
      'takenByName',
      this,
    );
    takenAt = _is.ColumnDateTime(
      'takenAt',
      this,
    );
    words = _is.ColumnSerializable<List<_ivdpg0kb.BoardCopyWord>>(
      'words',
      this,
    );
  }

  late final BoardCopyUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  late final _is.ColumnUuid boardId;

  /// The board's name and size when the copy was taken.
  late final _is.ColumnString boardName;

  late final _is.ColumnInt rows;

  late final _is.ColumnInt cols;

  late final _is.ColumnString name;

  late final _is.ColumnUuid takenBy;

  late final _is.ColumnString takenByName;

  late final _is.ColumnDateTime takenAt;

  /// The placed words, kept as JSON.
  late final _is.ColumnSerializable<List<_ivdpg0kb.BoardCopyWord>> words;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    boardId,
    boardName,
    rows,
    cols,
    name,
    takenBy,
    takenByName,
    takenAt,
    words,
  ];
}

class BoardCopyInclude extends _is.IncludeObject {
  BoardCopyInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => BoardCopy.t;
}

class BoardCopyIncludeList extends _is.IncludeList {
  BoardCopyIncludeList._({
    _is.WhereExpressionBuilder<BoardCopyTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BoardCopy.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => BoardCopy.t;
}

class BoardCopyRepository {
  const BoardCopyRepository._();

  /// Returns a list of [BoardCopy]s matching the given query parameters.
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
  Future<List<BoardCopy>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BoardCopyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BoardCopyTable>? orderBy,
    _is.OrderByListBuilder<BoardCopyTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<BoardCopy>(
      where: where?.call(BoardCopy.t),
      orderBy: orderBy?.call(BoardCopy.t),
      orderByList: orderByList?.call(BoardCopy.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [BoardCopy] matching the given query parameters.
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
  Future<BoardCopy?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BoardCopyTable>? where,
    int? offset,
    _is.OrderByBuilder<BoardCopyTable>? orderBy,
    _is.OrderByListBuilder<BoardCopyTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<BoardCopy>(
      where: where?.call(BoardCopy.t),
      orderBy: orderBy?.call(BoardCopy.t),
      orderByList: orderByList?.call(BoardCopy.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [BoardCopy] by its [id] or null if no such row exists.
  Future<BoardCopy?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<BoardCopy>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [BoardCopy]s in the list and returns the inserted rows.
  ///
  /// The returned [BoardCopy]s will have their `id` fields set.
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
  Future<List<BoardCopy>> insert(
    _is.DatabaseSession session,
    List<BoardCopy> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<BoardCopy>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [BoardCopy] and returns the inserted row.
  ///
  /// The returned [BoardCopy] will have its `id` field set.
  Future<BoardCopy> insertRow(
    _is.DatabaseSession session,
    BoardCopy row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<BoardCopy>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [BoardCopy]s in the list and returns the resulting rows.
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
  /// The returned [BoardCopy]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BoardCopy>> upsert(
    _is.DatabaseSession session,
    List<BoardCopy> rows, {
    required _is.ColumnSelections<BoardCopyTable> conflictColumns,
    _is.ColumnSelections<BoardCopyTable>? updateColumns,
    _is.WhereExpressionBuilder<BoardCopyTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<BoardCopy>(
      rows,
      conflictColumns: conflictColumns(BoardCopy.t),
      updateColumns: updateColumns?.call(BoardCopy.t),
      updateWhere: updateWhere?.call(BoardCopy.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [BoardCopy] and returns the resulting row.
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
  /// The returned [BoardCopy] will have its `id` field set.
  Future<BoardCopy?> upsertRow(
    _is.DatabaseSession session,
    BoardCopy row, {
    required _is.ColumnSelections<BoardCopyTable> conflictColumns,
    _is.ColumnSelections<BoardCopyTable>? updateColumns,
    _is.WhereExpressionBuilder<BoardCopyTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<BoardCopy>(
      row,
      conflictColumns: conflictColumns(BoardCopy.t),
      updateColumns: updateColumns?.call(BoardCopy.t),
      updateWhere: updateWhere?.call(BoardCopy.t),
      transaction: transaction,
    );
  }

  /// Updates all [BoardCopy]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BoardCopy>> update(
    _is.DatabaseSession session,
    List<BoardCopy> rows, {
    _is.ColumnSelections<BoardCopyTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<BoardCopy>(
      rows,
      columns: columns?.call(BoardCopy.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [BoardCopy]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BoardCopy> updateRow(
    _is.DatabaseSession session,
    BoardCopy row, {
    _is.ColumnSelections<BoardCopyTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<BoardCopy>(
      row,
      columns: columns?.call(BoardCopy.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BoardCopy] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<BoardCopy?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<BoardCopyUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<BoardCopy>(
      id,
      columnValues: columnValues(BoardCopy.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [BoardCopy]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BoardCopy>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<BoardCopyUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<BoardCopyTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BoardCopyTable>? orderBy,
    _is.OrderByListBuilder<BoardCopyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<BoardCopy>(
      columnValues: columnValues(BoardCopy.t.updateTable),
      where: where(BoardCopy.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BoardCopy.t),
      orderByList: orderByList?.call(BoardCopy.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [BoardCopy]s in the list and returns the deleted rows.
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
  Future<List<BoardCopy>> delete(
    _is.DatabaseSession session,
    List<BoardCopy> rows, {
    _is.OrderByBuilder<BoardCopyTable>? orderBy,
    _is.OrderByListBuilder<BoardCopyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<BoardCopy>(
      rows,
      orderBy: orderBy?.call(BoardCopy.t),
      orderByList: orderByList?.call(BoardCopy.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [BoardCopy].
  Future<BoardCopy> deleteRow(
    _is.DatabaseSession session,
    BoardCopy row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BoardCopy>(
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
  Future<List<BoardCopy>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BoardCopyTable> where,
    _is.OrderByBuilder<BoardCopyTable>? orderBy,
    _is.OrderByListBuilder<BoardCopyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<BoardCopy>(
      where: where(BoardCopy.t),
      orderBy: orderBy?.call(BoardCopy.t),
      orderByList: orderByList?.call(BoardCopy.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BoardCopyTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<BoardCopy>(
      where: where?.call(BoardCopy.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [BoardCopy] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BoardCopyTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<BoardCopy>(
      where: where(BoardCopy.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
