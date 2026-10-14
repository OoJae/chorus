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

/// A word an adult pinned for the week, with a one-line modelling tip.
/// Server-only and not synced; at most three per circle and week.
abstract class FocusWord
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  FocusWord._({
    this.id,
    required this.circleSpace,
    required this.tileId,
    required this.tip,
    required this.weekStart,
    required this.pinnedBy,
    required this.pinnedAt,
  });

  factory FocusWord({
    int? id,
    required _is.UuidValue circleSpace,
    required _is.UuidValue tileId,
    required String tip,
    required DateTime weekStart,
    required _is.UuidValue pinnedBy,
    required DateTime pinnedAt,
  }) = _FocusWordImpl;

  factory FocusWord.fromJson(Map<String, dynamic> jsonSerialization) {
    return FocusWord(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      tileId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['tileId']),
      tip: jsonSerialization['tip'] as String,
      weekStart: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['weekStart'],
      ),
      pinnedBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['pinnedBy'],
      ),
      pinnedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['pinnedAt'],
      ),
    );
  }

  static final t = FocusWordTable();

  static const db = FocusWordRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  _is.UuidValue tileId;

  /// "At bath time: 'more bubbles?'". May be empty.
  String tip;

  /// Monday 00:00 UTC of the week it is pinned for.
  DateTime weekStart;

  _is.UuidValue pinnedBy;

  DateTime pinnedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [FocusWord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  FocusWord copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    _is.UuidValue? tileId,
    String? tip,
    DateTime? weekStart,
    _is.UuidValue? pinnedBy,
    DateTime? pinnedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FocusWord',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'tileId': tileId.toJson(),
      'tip': tip,
      'weekStart': weekStart.toJson(),
      'pinnedBy': pinnedBy.toJson(),
      'pinnedAt': pinnedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static FocusWordInclude include() {
    return FocusWordInclude._();
  }

  static FocusWordIncludeList includeList({
    _is.WhereExpressionBuilder<FocusWordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FocusWordTable>? orderBy,
    _is.OrderByListBuilder<FocusWordTable>? orderByList,
    FocusWordInclude? include,
  }) {
    return FocusWordIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FocusWord.t),
      orderByList: orderByList?.call(FocusWord.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FocusWordImpl extends FocusWord {
  _FocusWordImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required _is.UuidValue tileId,
    required String tip,
    required DateTime weekStart,
    required _is.UuidValue pinnedBy,
    required DateTime pinnedAt,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         tileId: tileId,
         tip: tip,
         weekStart: weekStart,
         pinnedBy: pinnedBy,
         pinnedAt: pinnedAt,
       );

  /// Returns a shallow copy of this [FocusWord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  FocusWord copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    _is.UuidValue? tileId,
    String? tip,
    DateTime? weekStart,
    _is.UuidValue? pinnedBy,
    DateTime? pinnedAt,
  }) {
    return FocusWord(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      tileId: tileId ?? this.tileId,
      tip: tip ?? this.tip,
      weekStart: weekStart ?? this.weekStart,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      pinnedAt: pinnedAt ?? this.pinnedAt,
    );
  }
}

class FocusWordUpdateTable extends _is.UpdateTable<FocusWordTable> {
  FocusWordUpdateTable(super.table);

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

  _is.ColumnValue<String, String> tip(String value) => _is.ColumnValue(
    table.tip,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> weekStart(DateTime value) =>
      _is.ColumnValue(
        table.weekStart,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> pinnedBy(_is.UuidValue value) =>
      _is.ColumnValue(
        table.pinnedBy,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> pinnedAt(DateTime value) =>
      _is.ColumnValue(
        table.pinnedAt,
        value,
      );
}

class FocusWordTable extends _is.Table<int?> {
  FocusWordTable({super.tableRelation}) : super(tableName: 'focus_word') {
    updateTable = FocusWordUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    tileId = _is.ColumnUuid(
      'tileId',
      this,
    );
    tip = _is.ColumnString(
      'tip',
      this,
    );
    weekStart = _is.ColumnDateTime(
      'weekStart',
      this,
    );
    pinnedBy = _is.ColumnUuid(
      'pinnedBy',
      this,
    );
    pinnedAt = _is.ColumnDateTime(
      'pinnedAt',
      this,
    );
  }

  late final FocusWordUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  late final _is.ColumnUuid tileId;

  /// "At bath time: 'more bubbles?'". May be empty.
  late final _is.ColumnString tip;

  /// Monday 00:00 UTC of the week it is pinned for.
  late final _is.ColumnDateTime weekStart;

  late final _is.ColumnUuid pinnedBy;

  late final _is.ColumnDateTime pinnedAt;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    tileId,
    tip,
    weekStart,
    pinnedBy,
    pinnedAt,
  ];
}

class FocusWordInclude extends _is.IncludeObject {
  FocusWordInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => FocusWord.t;
}

class FocusWordIncludeList extends _is.IncludeList {
  FocusWordIncludeList._({
    _is.WhereExpressionBuilder<FocusWordTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(FocusWord.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => FocusWord.t;
}

class FocusWordRepository {
  const FocusWordRepository._();

  /// Returns a list of [FocusWord]s matching the given query parameters.
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
  Future<List<FocusWord>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FocusWordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FocusWordTable>? orderBy,
    _is.OrderByListBuilder<FocusWordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<FocusWord>(
      where: where?.call(FocusWord.t),
      orderBy: orderBy?.call(FocusWord.t),
      orderByList: orderByList?.call(FocusWord.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [FocusWord] matching the given query parameters.
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
  Future<FocusWord?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FocusWordTable>? where,
    int? offset,
    _is.OrderByBuilder<FocusWordTable>? orderBy,
    _is.OrderByListBuilder<FocusWordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<FocusWord>(
      where: where?.call(FocusWord.t),
      orderBy: orderBy?.call(FocusWord.t),
      orderByList: orderByList?.call(FocusWord.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [FocusWord] by its [id] or null if no such row exists.
  Future<FocusWord?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<FocusWord>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [FocusWord]s in the list and returns the inserted rows.
  ///
  /// The returned [FocusWord]s will have their `id` fields set.
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
  Future<List<FocusWord>> insert(
    _is.DatabaseSession session,
    List<FocusWord> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<FocusWord>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [FocusWord] and returns the inserted row.
  ///
  /// The returned [FocusWord] will have its `id` field set.
  Future<FocusWord> insertRow(
    _is.DatabaseSession session,
    FocusWord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<FocusWord>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [FocusWord]s in the list and returns the resulting rows.
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
  /// The returned [FocusWord]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FocusWord>> upsert(
    _is.DatabaseSession session,
    List<FocusWord> rows, {
    required _is.ColumnSelections<FocusWordTable> conflictColumns,
    _is.ColumnSelections<FocusWordTable>? updateColumns,
    _is.WhereExpressionBuilder<FocusWordTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<FocusWord>(
      rows,
      conflictColumns: conflictColumns(FocusWord.t),
      updateColumns: updateColumns?.call(FocusWord.t),
      updateWhere: updateWhere?.call(FocusWord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [FocusWord] and returns the resulting row.
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
  /// The returned [FocusWord] will have its `id` field set.
  Future<FocusWord?> upsertRow(
    _is.DatabaseSession session,
    FocusWord row, {
    required _is.ColumnSelections<FocusWordTable> conflictColumns,
    _is.ColumnSelections<FocusWordTable>? updateColumns,
    _is.WhereExpressionBuilder<FocusWordTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<FocusWord>(
      row,
      conflictColumns: conflictColumns(FocusWord.t),
      updateColumns: updateColumns?.call(FocusWord.t),
      updateWhere: updateWhere?.call(FocusWord.t),
      transaction: transaction,
    );
  }

  /// Updates all [FocusWord]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FocusWord>> update(
    _is.DatabaseSession session,
    List<FocusWord> rows, {
    _is.ColumnSelections<FocusWordTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<FocusWord>(
      rows,
      columns: columns?.call(FocusWord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [FocusWord]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<FocusWord> updateRow(
    _is.DatabaseSession session,
    FocusWord row, {
    _is.ColumnSelections<FocusWordTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<FocusWord>(
      row,
      columns: columns?.call(FocusWord.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FocusWord] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<FocusWord?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<FocusWordUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<FocusWord>(
      id,
      columnValues: columnValues(FocusWord.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [FocusWord]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FocusWord>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<FocusWordUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<FocusWordTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FocusWordTable>? orderBy,
    _is.OrderByListBuilder<FocusWordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<FocusWord>(
      columnValues: columnValues(FocusWord.t.updateTable),
      where: where(FocusWord.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FocusWord.t),
      orderByList: orderByList?.call(FocusWord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [FocusWord]s in the list and returns the deleted rows.
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
  Future<List<FocusWord>> delete(
    _is.DatabaseSession session,
    List<FocusWord> rows, {
    _is.OrderByBuilder<FocusWordTable>? orderBy,
    _is.OrderByListBuilder<FocusWordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<FocusWord>(
      rows,
      orderBy: orderBy?.call(FocusWord.t),
      orderByList: orderByList?.call(FocusWord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [FocusWord].
  Future<FocusWord> deleteRow(
    _is.DatabaseSession session,
    FocusWord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<FocusWord>(
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
  Future<List<FocusWord>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FocusWordTable> where,
    _is.OrderByBuilder<FocusWordTable>? orderBy,
    _is.OrderByListBuilder<FocusWordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<FocusWord>(
      where: where(FocusWord.t),
      orderBy: orderBy?.call(FocusWord.t),
      orderByList: orderByList?.call(FocusWord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FocusWordTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<FocusWord>(
      where: where?.call(FocusWord.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [FocusWord] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FocusWordTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<FocusWord>(
      where: where(FocusWord.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
