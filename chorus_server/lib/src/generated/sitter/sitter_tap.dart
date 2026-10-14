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

/// A word a sitter tapped on the view-only page, reported back to the
/// circle. Kept only while the circle's word log is on, and never more
/// than the word and the time. Server-only and not synced.
abstract class SitterTap
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  SitterTap._({
    this.id,
    required this.circleSpace,
    required this.label,
    required this.tappedAt,
  });

  factory SitterTap({
    int? id,
    required _is.UuidValue circleSpace,
    required String label,
    required DateTime tappedAt,
  }) = _SitterTapImpl;

  factory SitterTap.fromJson(Map<String, dynamic> jsonSerialization) {
    return SitterTap(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      label: jsonSerialization['label'] as String,
      tappedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['tappedAt'],
      ),
    );
  }

  static final t = SitterTapTable();

  static const db = SitterTapRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  String label;

  DateTime tappedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [SitterTap]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SitterTap copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    String? label,
    DateTime? tappedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SitterTap',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'label': label,
      'tappedAt': tappedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SitterTapInclude include() {
    return SitterTapInclude._();
  }

  static SitterTapIncludeList includeList({
    _is.WhereExpressionBuilder<SitterTapTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SitterTapTable>? orderBy,
    _is.OrderByListBuilder<SitterTapTable>? orderByList,
    SitterTapInclude? include,
  }) {
    return SitterTapIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SitterTap.t),
      orderByList: orderByList?.call(SitterTap.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SitterTapImpl extends SitterTap {
  _SitterTapImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required String label,
    required DateTime tappedAt,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         label: label,
         tappedAt: tappedAt,
       );

  /// Returns a shallow copy of this [SitterTap]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SitterTap copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    String? label,
    DateTime? tappedAt,
  }) {
    return SitterTap(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      label: label ?? this.label,
      tappedAt: tappedAt ?? this.tappedAt,
    );
  }
}

class SitterTapUpdateTable extends _is.UpdateTable<SitterTapTable> {
  SitterTapUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleSpace(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.circleSpace,
    value,
  );

  _is.ColumnValue<String, String> label(String value) => _is.ColumnValue(
    table.label,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> tappedAt(DateTime value) =>
      _is.ColumnValue(
        table.tappedAt,
        value,
      );
}

class SitterTapTable extends _is.Table<int?> {
  SitterTapTable({super.tableRelation}) : super(tableName: 'sitter_tap') {
    updateTable = SitterTapUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    label = _is.ColumnString(
      'label',
      this,
    );
    tappedAt = _is.ColumnDateTime(
      'tappedAt',
      this,
    );
  }

  late final SitterTapUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  late final _is.ColumnString label;

  late final _is.ColumnDateTime tappedAt;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    label,
    tappedAt,
  ];
}

class SitterTapInclude extends _is.IncludeObject {
  SitterTapInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => SitterTap.t;
}

class SitterTapIncludeList extends _is.IncludeList {
  SitterTapIncludeList._({
    _is.WhereExpressionBuilder<SitterTapTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SitterTap.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => SitterTap.t;
}

class SitterTapRepository {
  const SitterTapRepository._();

  /// Returns a list of [SitterTap]s matching the given query parameters.
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
  Future<List<SitterTap>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SitterTapTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SitterTapTable>? orderBy,
    _is.OrderByListBuilder<SitterTapTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SitterTap>(
      where: where?.call(SitterTap.t),
      orderBy: orderBy?.call(SitterTap.t),
      orderByList: orderByList?.call(SitterTap.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SitterTap] matching the given query parameters.
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
  Future<SitterTap?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SitterTapTable>? where,
    int? offset,
    _is.OrderByBuilder<SitterTapTable>? orderBy,
    _is.OrderByListBuilder<SitterTapTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SitterTap>(
      where: where?.call(SitterTap.t),
      orderBy: orderBy?.call(SitterTap.t),
      orderByList: orderByList?.call(SitterTap.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SitterTap] by its [id] or null if no such row exists.
  Future<SitterTap?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SitterTap>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SitterTap]s in the list and returns the inserted rows.
  ///
  /// The returned [SitterTap]s will have their `id` fields set.
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
  Future<List<SitterTap>> insert(
    _is.DatabaseSession session,
    List<SitterTap> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SitterTap>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SitterTap] and returns the inserted row.
  ///
  /// The returned [SitterTap] will have its `id` field set.
  Future<SitterTap> insertRow(
    _is.DatabaseSession session,
    SitterTap row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SitterTap>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [SitterTap]s in the list and returns the resulting rows.
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
  /// The returned [SitterTap]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SitterTap>> upsert(
    _is.DatabaseSession session,
    List<SitterTap> rows, {
    required _is.ColumnSelections<SitterTapTable> conflictColumns,
    _is.ColumnSelections<SitterTapTable>? updateColumns,
    _is.WhereExpressionBuilder<SitterTapTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SitterTap>(
      rows,
      conflictColumns: conflictColumns(SitterTap.t),
      updateColumns: updateColumns?.call(SitterTap.t),
      updateWhere: updateWhere?.call(SitterTap.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SitterTap] and returns the resulting row.
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
  /// The returned [SitterTap] will have its `id` field set.
  Future<SitterTap?> upsertRow(
    _is.DatabaseSession session,
    SitterTap row, {
    required _is.ColumnSelections<SitterTapTable> conflictColumns,
    _is.ColumnSelections<SitterTapTable>? updateColumns,
    _is.WhereExpressionBuilder<SitterTapTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SitterTap>(
      row,
      conflictColumns: conflictColumns(SitterTap.t),
      updateColumns: updateColumns?.call(SitterTap.t),
      updateWhere: updateWhere?.call(SitterTap.t),
      transaction: transaction,
    );
  }

  /// Updates all [SitterTap]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SitterTap>> update(
    _is.DatabaseSession session,
    List<SitterTap> rows, {
    _is.ColumnSelections<SitterTapTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SitterTap>(
      rows,
      columns: columns?.call(SitterTap.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SitterTap]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SitterTap> updateRow(
    _is.DatabaseSession session,
    SitterTap row, {
    _is.ColumnSelections<SitterTapTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SitterTap>(
      row,
      columns: columns?.call(SitterTap.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SitterTap] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SitterTap?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SitterTapUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SitterTap>(
      id,
      columnValues: columnValues(SitterTap.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SitterTap]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SitterTap>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SitterTapUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SitterTapTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SitterTapTable>? orderBy,
    _is.OrderByListBuilder<SitterTapTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SitterTap>(
      columnValues: columnValues(SitterTap.t.updateTable),
      where: where(SitterTap.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SitterTap.t),
      orderByList: orderByList?.call(SitterTap.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SitterTap]s in the list and returns the deleted rows.
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
  Future<List<SitterTap>> delete(
    _is.DatabaseSession session,
    List<SitterTap> rows, {
    _is.OrderByBuilder<SitterTapTable>? orderBy,
    _is.OrderByListBuilder<SitterTapTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SitterTap>(
      rows,
      orderBy: orderBy?.call(SitterTap.t),
      orderByList: orderByList?.call(SitterTap.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SitterTap].
  Future<SitterTap> deleteRow(
    _is.DatabaseSession session,
    SitterTap row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SitterTap>(
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
  Future<List<SitterTap>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SitterTapTable> where,
    _is.OrderByBuilder<SitterTapTable>? orderBy,
    _is.OrderByListBuilder<SitterTapTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SitterTap>(
      where: where(SitterTap.t),
      orderBy: orderBy?.call(SitterTap.t),
      orderByList: orderByList?.call(SitterTap.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SitterTapTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SitterTap>(
      where: where?.call(SitterTap.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SitterTap] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SitterTapTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SitterTap>(
      where: where(SitterTap.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
