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
import 'package:serverpod/serverpod.dart' as _is;

/// One word the child spoke: which tile, on which board, and when. Never a
/// label or a sentence. Server-only and not synced.
abstract class WordUseRecord
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WordUseRecord._({
    this.id,
    required this.circleSpace,
    required this.tileId,
    required this.boardId,
    required this.spokenAt,
    required this.receivedAt,
  });

  factory WordUseRecord({
    int? id,
    required _is.UuidValue circleSpace,
    required _is.UuidValue tileId,
    required _is.UuidValue boardId,
    required DateTime spokenAt,
    required DateTime receivedAt,
  }) = _WordUseRecordImpl;

  factory WordUseRecord.fromJson(Map<String, dynamic> jsonSerialization) {
    return WordUseRecord(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      tileId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['tileId']),
      boardId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['boardId'],
      ),
      spokenAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['spokenAt'],
      ),
      receivedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['receivedAt'],
      ),
    );
  }

  static final t = WordUseRecordTable();

  static const db = WordUseRecordRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  _is.UuidValue tileId;

  _is.UuidValue boardId;

  /// When the child's device spoke it.
  DateTime spokenAt;

  /// When the server got it.
  DateTime receivedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WordUseRecord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WordUseRecord copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    _is.UuidValue? tileId,
    _is.UuidValue? boardId,
    DateTime? spokenAt,
    DateTime? receivedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WordUseRecord',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'tileId': tileId.toJson(),
      'boardId': boardId.toJson(),
      'spokenAt': spokenAt.toJson(),
      'receivedAt': receivedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static WordUseRecordInclude include() {
    return WordUseRecordInclude._();
  }

  static WordUseRecordIncludeList includeList({
    _is.WhereExpressionBuilder<WordUseRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WordUseRecordTable>? orderBy,
    _is.OrderByListBuilder<WordUseRecordTable>? orderByList,
    WordUseRecordInclude? include,
  }) {
    return WordUseRecordIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WordUseRecord.t),
      orderByList: orderByList?.call(WordUseRecord.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WordUseRecordImpl extends WordUseRecord {
  _WordUseRecordImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required _is.UuidValue tileId,
    required _is.UuidValue boardId,
    required DateTime spokenAt,
    required DateTime receivedAt,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         tileId: tileId,
         boardId: boardId,
         spokenAt: spokenAt,
         receivedAt: receivedAt,
       );

  /// Returns a shallow copy of this [WordUseRecord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WordUseRecord copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    _is.UuidValue? tileId,
    _is.UuidValue? boardId,
    DateTime? spokenAt,
    DateTime? receivedAt,
  }) {
    return WordUseRecord(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      tileId: tileId ?? this.tileId,
      boardId: boardId ?? this.boardId,
      spokenAt: spokenAt ?? this.spokenAt,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }
}

class WordUseRecordUpdateTable extends _is.UpdateTable<WordUseRecordTable> {
  WordUseRecordUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleSpace(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.circleSpace,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> tileId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.tileId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> boardId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.boardId,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> spokenAt(DateTime value) =>
      _is.ColumnValue(
        table.spokenAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> receivedAt(DateTime value) =>
      _is.ColumnValue(
        table.receivedAt,
        value,
      );
}

class WordUseRecordTable extends _is.Table<int?> {
  WordUseRecordTable({super.tableRelation}) : super(tableName: 'word_use') {
    updateTable = WordUseRecordUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    tileId = _is.ColumnUuid(
      'tileId',
      this,
    );
    boardId = _is.ColumnUuid(
      'boardId',
      this,
    );
    spokenAt = _is.ColumnDateTime(
      'spokenAt',
      this,
    );
    receivedAt = _is.ColumnDateTime(
      'receivedAt',
      this,
    );
  }

  late final WordUseRecordUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  late final _is.ColumnUuid tileId;

  late final _is.ColumnUuid boardId;

  /// When the child's device spoke it.
  late final _is.ColumnDateTime spokenAt;

  /// When the server got it.
  late final _is.ColumnDateTime receivedAt;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    tileId,
    boardId,
    spokenAt,
    receivedAt,
  ];
}

class WordUseRecordInclude extends _is.IncludeObject {
  WordUseRecordInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WordUseRecord.t;
}

class WordUseRecordIncludeList extends _is.IncludeList {
  WordUseRecordIncludeList._({
    _is.WhereExpressionBuilder<WordUseRecordTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WordUseRecord.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WordUseRecord.t;
}

class WordUseRecordRepository {
  const WordUseRecordRepository._();

  /// Returns a list of [WordUseRecord]s matching the given query parameters.
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
  Future<List<WordUseRecord>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WordUseRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WordUseRecordTable>? orderBy,
    _is.OrderByListBuilder<WordUseRecordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WordUseRecord>(
      where: where?.call(WordUseRecord.t),
      orderBy: orderBy?.call(WordUseRecord.t),
      orderByList: orderByList?.call(WordUseRecord.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WordUseRecord] matching the given query parameters.
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
  Future<WordUseRecord?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WordUseRecordTable>? where,
    int? offset,
    _is.OrderByBuilder<WordUseRecordTable>? orderBy,
    _is.OrderByListBuilder<WordUseRecordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WordUseRecord>(
      where: where?.call(WordUseRecord.t),
      orderBy: orderBy?.call(WordUseRecord.t),
      orderByList: orderByList?.call(WordUseRecord.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WordUseRecord] by its [id] or null if no such row exists.
  Future<WordUseRecord?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WordUseRecord>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WordUseRecord]s in the list and returns the inserted rows.
  ///
  /// The returned [WordUseRecord]s will have their `id` fields set.
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
  Future<List<WordUseRecord>> insert(
    _is.DatabaseSession session,
    List<WordUseRecord> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WordUseRecord>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WordUseRecord] and returns the inserted row.
  ///
  /// The returned [WordUseRecord] will have its `id` field set.
  Future<WordUseRecord> insertRow(
    _is.DatabaseSession session,
    WordUseRecord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WordUseRecord>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WordUseRecord]s in the list and returns the resulting rows.
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
  /// The returned [WordUseRecord]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WordUseRecord>> upsert(
    _is.DatabaseSession session,
    List<WordUseRecord> rows, {
    required _is.ColumnSelections<WordUseRecordTable> conflictColumns,
    _is.ColumnSelections<WordUseRecordTable>? updateColumns,
    _is.WhereExpressionBuilder<WordUseRecordTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WordUseRecord>(
      rows,
      conflictColumns: conflictColumns(WordUseRecord.t),
      updateColumns: updateColumns?.call(WordUseRecord.t),
      updateWhere: updateWhere?.call(WordUseRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WordUseRecord] and returns the resulting row.
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
  /// The returned [WordUseRecord] will have its `id` field set.
  Future<WordUseRecord?> upsertRow(
    _is.DatabaseSession session,
    WordUseRecord row, {
    required _is.ColumnSelections<WordUseRecordTable> conflictColumns,
    _is.ColumnSelections<WordUseRecordTable>? updateColumns,
    _is.WhereExpressionBuilder<WordUseRecordTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WordUseRecord>(
      row,
      conflictColumns: conflictColumns(WordUseRecord.t),
      updateColumns: updateColumns?.call(WordUseRecord.t),
      updateWhere: updateWhere?.call(WordUseRecord.t),
      transaction: transaction,
    );
  }

  /// Updates all [WordUseRecord]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WordUseRecord>> update(
    _is.DatabaseSession session,
    List<WordUseRecord> rows, {
    _is.ColumnSelections<WordUseRecordTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WordUseRecord>(
      rows,
      columns: columns?.call(WordUseRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WordUseRecord]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WordUseRecord> updateRow(
    _is.DatabaseSession session,
    WordUseRecord row, {
    _is.ColumnSelections<WordUseRecordTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WordUseRecord>(
      row,
      columns: columns?.call(WordUseRecord.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WordUseRecord] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WordUseRecord?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WordUseRecordUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WordUseRecord>(
      id,
      columnValues: columnValues(WordUseRecord.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WordUseRecord]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WordUseRecord>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WordUseRecordUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<WordUseRecordTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WordUseRecordTable>? orderBy,
    _is.OrderByListBuilder<WordUseRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WordUseRecord>(
      columnValues: columnValues(WordUseRecord.t.updateTable),
      where: where(WordUseRecord.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WordUseRecord.t),
      orderByList: orderByList?.call(WordUseRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WordUseRecord]s in the list and returns the deleted rows.
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
  Future<List<WordUseRecord>> delete(
    _is.DatabaseSession session,
    List<WordUseRecord> rows, {
    _is.OrderByBuilder<WordUseRecordTable>? orderBy,
    _is.OrderByListBuilder<WordUseRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WordUseRecord>(
      rows,
      orderBy: orderBy?.call(WordUseRecord.t),
      orderByList: orderByList?.call(WordUseRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WordUseRecord].
  Future<WordUseRecord> deleteRow(
    _is.DatabaseSession session,
    WordUseRecord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WordUseRecord>(
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
  Future<List<WordUseRecord>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WordUseRecordTable> where,
    _is.OrderByBuilder<WordUseRecordTable>? orderBy,
    _is.OrderByListBuilder<WordUseRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WordUseRecord>(
      where: where(WordUseRecord.t),
      orderBy: orderBy?.call(WordUseRecord.t),
      orderByList: orderByList?.call(WordUseRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WordUseRecordTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WordUseRecord>(
      where: where?.call(WordUseRecord.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WordUseRecord] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WordUseRecordTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WordUseRecord>(
      where: where(WordUseRecord.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
