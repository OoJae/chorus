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
import '../progress/progress_report.dart' as _inkcg3o5;

/// A one-page progress report kept behind a token: counts only, never a
/// sentence. Server-only and not synced.
abstract class ProgressReportLink
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ProgressReportLink._({
    this.id,
    required this.token,
    required this.circleSpace,
    required this.report,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
  });

  factory ProgressReportLink({
    int? id,
    required String token,
    required _is.UuidValue circleSpace,
    required _inkcg3o5.ProgressReport report,
    required _is.UuidValue createdBy,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) = _ProgressReportLinkImpl;

  factory ProgressReportLink.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProgressReportLink(
      id: jsonSerialization['id'] as int?,
      token: jsonSerialization['token'] as String,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      report: _iq1qvsxu.Protocol().deserialize<_inkcg3o5.ProgressReport>(
        jsonSerialization['report'],
      ),
      createdBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['createdBy'],
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  static final t = ProgressReportLinkTable();

  static const db = ProgressReportLinkRepository._();

  @override
  int? id;

  /// Unguessable; the only key to the page.
  String token;

  _is.UuidValue circleSpace;

  /// The report as worked out when the link was made.
  _inkcg3o5.ProgressReport report;

  _is.UuidValue createdBy;

  DateTime createdAt;

  DateTime expiresAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ProgressReportLink]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ProgressReportLink copyWith({
    int? id,
    String? token,
    _is.UuidValue? circleSpace,
    _inkcg3o5.ProgressReport? report,
    _is.UuidValue? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProgressReportLink',
      if (id != null) 'id': id,
      'token': token,
      'circleSpace': circleSpace.toJson(),
      'report': report.toJson(),
      'createdBy': createdBy.toJson(),
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ProgressReportLinkInclude include() {
    return ProgressReportLinkInclude._();
  }

  static ProgressReportLinkIncludeList includeList({
    _is.WhereExpressionBuilder<ProgressReportLinkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProgressReportLinkTable>? orderBy,
    _is.OrderByListBuilder<ProgressReportLinkTable>? orderByList,
    ProgressReportLinkInclude? include,
  }) {
    return ProgressReportLinkIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ProgressReportLink.t),
      orderByList: orderByList?.call(ProgressReportLink.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProgressReportLinkImpl extends ProgressReportLink {
  _ProgressReportLinkImpl({
    int? id,
    required String token,
    required _is.UuidValue circleSpace,
    required _inkcg3o5.ProgressReport report,
    required _is.UuidValue createdBy,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) : super._(
         id: id,
         token: token,
         circleSpace: circleSpace,
         report: report,
         createdBy: createdBy,
         createdAt: createdAt,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [ProgressReportLink]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ProgressReportLink copyWith({
    Object? id = _Undefined,
    String? token,
    _is.UuidValue? circleSpace,
    _inkcg3o5.ProgressReport? report,
    _is.UuidValue? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return ProgressReportLink(
      id: id is int? ? id : this.id,
      token: token ?? this.token,
      circleSpace: circleSpace ?? this.circleSpace,
      report: report ?? this.report.copyWith(),
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

class ProgressReportLinkUpdateTable
    extends _is.UpdateTable<ProgressReportLinkTable> {
  ProgressReportLinkUpdateTable(super.table);

  _is.ColumnValue<String, String> token(String value) => _is.ColumnValue(
    table.token,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleSpace(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.circleSpace,
    value,
  );

  _is.ColumnValue<_inkcg3o5.ProgressReport, _inkcg3o5.ProgressReport> report(
    _inkcg3o5.ProgressReport value,
  ) => _is.ColumnValue(
    table.report,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> createdBy(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.createdBy,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );
}

class ProgressReportLinkTable extends _is.Table<int?> {
  ProgressReportLinkTable({super.tableRelation})
    : super(tableName: 'progress_report_link') {
    updateTable = ProgressReportLinkUpdateTable(this);
    token = _is.ColumnString(
      'token',
      this,
    );
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    report = _is.ColumnSerializable<_inkcg3o5.ProgressReport>(
      'report',
      this,
    );
    createdBy = _is.ColumnUuid(
      'createdBy',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
  }

  late final ProgressReportLinkUpdateTable updateTable;

  /// Unguessable; the only key to the page.
  late final _is.ColumnString token;

  late final _is.ColumnUuid circleSpace;

  /// The report as worked out when the link was made.
  late final _is.ColumnSerializable<_inkcg3o5.ProgressReport> report;

  late final _is.ColumnUuid createdBy;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime expiresAt;

  @override
  List<_is.Column> get columns => [
    id,
    token,
    circleSpace,
    report,
    createdBy,
    createdAt,
    expiresAt,
  ];
}

class ProgressReportLinkInclude extends _is.IncludeObject {
  ProgressReportLinkInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ProgressReportLink.t;
}

class ProgressReportLinkIncludeList extends _is.IncludeList {
  ProgressReportLinkIncludeList._({
    _is.WhereExpressionBuilder<ProgressReportLinkTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ProgressReportLink.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ProgressReportLink.t;
}

class ProgressReportLinkRepository {
  const ProgressReportLinkRepository._();

  /// Returns a list of [ProgressReportLink]s matching the given query parameters.
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
  Future<List<ProgressReportLink>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProgressReportLinkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProgressReportLinkTable>? orderBy,
    _is.OrderByListBuilder<ProgressReportLinkTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ProgressReportLink>(
      where: where?.call(ProgressReportLink.t),
      orderBy: orderBy?.call(ProgressReportLink.t),
      orderByList: orderByList?.call(ProgressReportLink.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ProgressReportLink] matching the given query parameters.
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
  Future<ProgressReportLink?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProgressReportLinkTable>? where,
    int? offset,
    _is.OrderByBuilder<ProgressReportLinkTable>? orderBy,
    _is.OrderByListBuilder<ProgressReportLinkTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ProgressReportLink>(
      where: where?.call(ProgressReportLink.t),
      orderBy: orderBy?.call(ProgressReportLink.t),
      orderByList: orderByList?.call(ProgressReportLink.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ProgressReportLink] by its [id] or null if no such row exists.
  Future<ProgressReportLink?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ProgressReportLink>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ProgressReportLink]s in the list and returns the inserted rows.
  ///
  /// The returned [ProgressReportLink]s will have their `id` fields set.
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
  Future<List<ProgressReportLink>> insert(
    _is.DatabaseSession session,
    List<ProgressReportLink> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ProgressReportLink>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ProgressReportLink] and returns the inserted row.
  ///
  /// The returned [ProgressReportLink] will have its `id` field set.
  Future<ProgressReportLink> insertRow(
    _is.DatabaseSession session,
    ProgressReportLink row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ProgressReportLink>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ProgressReportLink]s in the list and returns the resulting rows.
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
  /// The returned [ProgressReportLink]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProgressReportLink>> upsert(
    _is.DatabaseSession session,
    List<ProgressReportLink> rows, {
    required _is.ColumnSelections<ProgressReportLinkTable> conflictColumns,
    _is.ColumnSelections<ProgressReportLinkTable>? updateColumns,
    _is.WhereExpressionBuilder<ProgressReportLinkTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ProgressReportLink>(
      rows,
      conflictColumns: conflictColumns(ProgressReportLink.t),
      updateColumns: updateColumns?.call(ProgressReportLink.t),
      updateWhere: updateWhere?.call(ProgressReportLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ProgressReportLink] and returns the resulting row.
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
  /// The returned [ProgressReportLink] will have its `id` field set.
  Future<ProgressReportLink?> upsertRow(
    _is.DatabaseSession session,
    ProgressReportLink row, {
    required _is.ColumnSelections<ProgressReportLinkTable> conflictColumns,
    _is.ColumnSelections<ProgressReportLinkTable>? updateColumns,
    _is.WhereExpressionBuilder<ProgressReportLinkTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ProgressReportLink>(
      row,
      conflictColumns: conflictColumns(ProgressReportLink.t),
      updateColumns: updateColumns?.call(ProgressReportLink.t),
      updateWhere: updateWhere?.call(ProgressReportLink.t),
      transaction: transaction,
    );
  }

  /// Updates all [ProgressReportLink]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProgressReportLink>> update(
    _is.DatabaseSession session,
    List<ProgressReportLink> rows, {
    _is.ColumnSelections<ProgressReportLinkTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ProgressReportLink>(
      rows,
      columns: columns?.call(ProgressReportLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ProgressReportLink]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ProgressReportLink> updateRow(
    _is.DatabaseSession session,
    ProgressReportLink row, {
    _is.ColumnSelections<ProgressReportLinkTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ProgressReportLink>(
      row,
      columns: columns?.call(ProgressReportLink.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ProgressReportLink] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ProgressReportLink?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ProgressReportLinkUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ProgressReportLink>(
      id,
      columnValues: columnValues(ProgressReportLink.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ProgressReportLink]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProgressReportLink>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ProgressReportLinkUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ProgressReportLinkTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProgressReportLinkTable>? orderBy,
    _is.OrderByListBuilder<ProgressReportLinkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ProgressReportLink>(
      columnValues: columnValues(ProgressReportLink.t.updateTable),
      where: where(ProgressReportLink.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ProgressReportLink.t),
      orderByList: orderByList?.call(ProgressReportLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ProgressReportLink]s in the list and returns the deleted rows.
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
  Future<List<ProgressReportLink>> delete(
    _is.DatabaseSession session,
    List<ProgressReportLink> rows, {
    _is.OrderByBuilder<ProgressReportLinkTable>? orderBy,
    _is.OrderByListBuilder<ProgressReportLinkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ProgressReportLink>(
      rows,
      orderBy: orderBy?.call(ProgressReportLink.t),
      orderByList: orderByList?.call(ProgressReportLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ProgressReportLink].
  Future<ProgressReportLink> deleteRow(
    _is.DatabaseSession session,
    ProgressReportLink row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ProgressReportLink>(
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
  Future<List<ProgressReportLink>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProgressReportLinkTable> where,
    _is.OrderByBuilder<ProgressReportLinkTable>? orderBy,
    _is.OrderByListBuilder<ProgressReportLinkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ProgressReportLink>(
      where: where(ProgressReportLink.t),
      orderBy: orderBy?.call(ProgressReportLink.t),
      orderByList: orderByList?.call(ProgressReportLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProgressReportLinkTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ProgressReportLink>(
      where: where?.call(ProgressReportLink.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ProgressReportLink] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProgressReportLinkTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ProgressReportLink>(
      where: where(ProgressReportLink.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
