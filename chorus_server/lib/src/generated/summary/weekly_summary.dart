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
import '../summary/week_report.dart' as _idaibkhp;

/// A finished week of a circle's word log, worked out ahead by the weekly
/// job. Server-only. Removed with the word log, and whenever a late word
/// changes a week it describes.
abstract class WeeklySummary
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WeeklySummary._({
    this.id,
    required this.circleSpace,
    required this.weekStart,
    required this.report,
  });

  factory WeeklySummary({
    int? id,
    required _is.UuidValue circleSpace,
    required DateTime weekStart,
    required _idaibkhp.WeekReport report,
  }) = _WeeklySummaryImpl;

  factory WeeklySummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return WeeklySummary(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      weekStart: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['weekStart'],
      ),
      report: _iq1qvsxu.Protocol().deserialize<_idaibkhp.WeekReport>(
        jsonSerialization['report'],
      ),
    );
  }

  static final t = WeeklySummaryTable();

  static const db = WeeklySummaryRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  DateTime weekStart;

  _idaibkhp.WeekReport report;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WeeklySummary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WeeklySummary copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    DateTime? weekStart,
    _idaibkhp.WeekReport? report,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WeeklySummary',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'weekStart': weekStart.toJson(),
      'report': report.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static WeeklySummaryInclude include() {
    return WeeklySummaryInclude._();
  }

  static WeeklySummaryIncludeList includeList({
    _is.WhereExpressionBuilder<WeeklySummaryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WeeklySummaryTable>? orderBy,
    _is.OrderByListBuilder<WeeklySummaryTable>? orderByList,
    WeeklySummaryInclude? include,
  }) {
    return WeeklySummaryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WeeklySummary.t),
      orderByList: orderByList?.call(WeeklySummary.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WeeklySummaryImpl extends WeeklySummary {
  _WeeklySummaryImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required DateTime weekStart,
    required _idaibkhp.WeekReport report,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         weekStart: weekStart,
         report: report,
       );

  /// Returns a shallow copy of this [WeeklySummary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WeeklySummary copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    DateTime? weekStart,
    _idaibkhp.WeekReport? report,
  }) {
    return WeeklySummary(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      weekStart: weekStart ?? this.weekStart,
      report: report ?? this.report.copyWith(),
    );
  }
}

class WeeklySummaryUpdateTable extends _is.UpdateTable<WeeklySummaryTable> {
  WeeklySummaryUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleSpace(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.circleSpace,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> weekStart(DateTime value) =>
      _is.ColumnValue(
        table.weekStart,
        value,
      );

  _is.ColumnValue<_idaibkhp.WeekReport, _idaibkhp.WeekReport> report(
    _idaibkhp.WeekReport value,
  ) => _is.ColumnValue(
    table.report,
    value,
  );
}

class WeeklySummaryTable extends _is.Table<int?> {
  WeeklySummaryTable({super.tableRelation})
    : super(tableName: 'weekly_summary') {
    updateTable = WeeklySummaryUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    weekStart = _is.ColumnDateTime(
      'weekStart',
      this,
    );
    report = _is.ColumnSerializable<_idaibkhp.WeekReport>(
      'report',
      this,
    );
  }

  late final WeeklySummaryUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  late final _is.ColumnDateTime weekStart;

  late final _is.ColumnSerializable<_idaibkhp.WeekReport> report;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    weekStart,
    report,
  ];
}

class WeeklySummaryInclude extends _is.IncludeObject {
  WeeklySummaryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WeeklySummary.t;
}

class WeeklySummaryIncludeList extends _is.IncludeList {
  WeeklySummaryIncludeList._({
    _is.WhereExpressionBuilder<WeeklySummaryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WeeklySummary.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WeeklySummary.t;
}

class WeeklySummaryRepository {
  const WeeklySummaryRepository._();

  /// Returns a list of [WeeklySummary]s matching the given query parameters.
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
  Future<List<WeeklySummary>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WeeklySummaryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WeeklySummaryTable>? orderBy,
    _is.OrderByListBuilder<WeeklySummaryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WeeklySummary>(
      where: where?.call(WeeklySummary.t),
      orderBy: orderBy?.call(WeeklySummary.t),
      orderByList: orderByList?.call(WeeklySummary.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WeeklySummary] matching the given query parameters.
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
  Future<WeeklySummary?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WeeklySummaryTable>? where,
    int? offset,
    _is.OrderByBuilder<WeeklySummaryTable>? orderBy,
    _is.OrderByListBuilder<WeeklySummaryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WeeklySummary>(
      where: where?.call(WeeklySummary.t),
      orderBy: orderBy?.call(WeeklySummary.t),
      orderByList: orderByList?.call(WeeklySummary.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WeeklySummary] by its [id] or null if no such row exists.
  Future<WeeklySummary?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WeeklySummary>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WeeklySummary]s in the list and returns the inserted rows.
  ///
  /// The returned [WeeklySummary]s will have their `id` fields set.
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
  Future<List<WeeklySummary>> insert(
    _is.DatabaseSession session,
    List<WeeklySummary> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WeeklySummary>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WeeklySummary] and returns the inserted row.
  ///
  /// The returned [WeeklySummary] will have its `id` field set.
  Future<WeeklySummary> insertRow(
    _is.DatabaseSession session,
    WeeklySummary row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WeeklySummary>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WeeklySummary]s in the list and returns the resulting rows.
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
  /// The returned [WeeklySummary]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WeeklySummary>> upsert(
    _is.DatabaseSession session,
    List<WeeklySummary> rows, {
    required _is.ColumnSelections<WeeklySummaryTable> conflictColumns,
    _is.ColumnSelections<WeeklySummaryTable>? updateColumns,
    _is.WhereExpressionBuilder<WeeklySummaryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WeeklySummary>(
      rows,
      conflictColumns: conflictColumns(WeeklySummary.t),
      updateColumns: updateColumns?.call(WeeklySummary.t),
      updateWhere: updateWhere?.call(WeeklySummary.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WeeklySummary] and returns the resulting row.
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
  /// The returned [WeeklySummary] will have its `id` field set.
  Future<WeeklySummary?> upsertRow(
    _is.DatabaseSession session,
    WeeklySummary row, {
    required _is.ColumnSelections<WeeklySummaryTable> conflictColumns,
    _is.ColumnSelections<WeeklySummaryTable>? updateColumns,
    _is.WhereExpressionBuilder<WeeklySummaryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WeeklySummary>(
      row,
      conflictColumns: conflictColumns(WeeklySummary.t),
      updateColumns: updateColumns?.call(WeeklySummary.t),
      updateWhere: updateWhere?.call(WeeklySummary.t),
      transaction: transaction,
    );
  }

  /// Updates all [WeeklySummary]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WeeklySummary>> update(
    _is.DatabaseSession session,
    List<WeeklySummary> rows, {
    _is.ColumnSelections<WeeklySummaryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WeeklySummary>(
      rows,
      columns: columns?.call(WeeklySummary.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WeeklySummary]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WeeklySummary> updateRow(
    _is.DatabaseSession session,
    WeeklySummary row, {
    _is.ColumnSelections<WeeklySummaryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WeeklySummary>(
      row,
      columns: columns?.call(WeeklySummary.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WeeklySummary] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WeeklySummary?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WeeklySummaryUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WeeklySummary>(
      id,
      columnValues: columnValues(WeeklySummary.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WeeklySummary]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WeeklySummary>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WeeklySummaryUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<WeeklySummaryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WeeklySummaryTable>? orderBy,
    _is.OrderByListBuilder<WeeklySummaryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WeeklySummary>(
      columnValues: columnValues(WeeklySummary.t.updateTable),
      where: where(WeeklySummary.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WeeklySummary.t),
      orderByList: orderByList?.call(WeeklySummary.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WeeklySummary]s in the list and returns the deleted rows.
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
  Future<List<WeeklySummary>> delete(
    _is.DatabaseSession session,
    List<WeeklySummary> rows, {
    _is.OrderByBuilder<WeeklySummaryTable>? orderBy,
    _is.OrderByListBuilder<WeeklySummaryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WeeklySummary>(
      rows,
      orderBy: orderBy?.call(WeeklySummary.t),
      orderByList: orderByList?.call(WeeklySummary.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WeeklySummary].
  Future<WeeklySummary> deleteRow(
    _is.DatabaseSession session,
    WeeklySummary row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WeeklySummary>(
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
  Future<List<WeeklySummary>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WeeklySummaryTable> where,
    _is.OrderByBuilder<WeeklySummaryTable>? orderBy,
    _is.OrderByListBuilder<WeeklySummaryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WeeklySummary>(
      where: where(WeeklySummary.t),
      orderBy: orderBy?.call(WeeklySummary.t),
      orderByList: orderByList?.call(WeeklySummary.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WeeklySummaryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WeeklySummary>(
      where: where?.call(WeeklySummary.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WeeklySummary] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WeeklySummaryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WeeklySummary>(
      where: where(WeeklySummary.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
