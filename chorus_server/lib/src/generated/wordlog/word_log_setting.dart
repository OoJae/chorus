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

/// Whether a circle keeps a word log. Server-only. A circle with no row has
/// never turned it on: the log is off until a guardian says otherwise.
abstract class WordLogSetting
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WordLogSetting._({
    this.id,
    required this.circleSpace,
    required this.enabled,
    required this.changedBy,
    required this.changedAt,
  });

  factory WordLogSetting({
    int? id,
    required _is.UuidValue circleSpace,
    required bool enabled,
    required _is.UuidValue changedBy,
    required DateTime changedAt,
  }) = _WordLogSettingImpl;

  factory WordLogSetting.fromJson(Map<String, dynamic> jsonSerialization) {
    return WordLogSetting(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      enabled: _is.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      changedBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['changedBy'],
      ),
      changedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['changedAt'],
      ),
    );
  }

  static final t = WordLogSettingTable();

  static const db = WordLogSettingRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  bool enabled;

  /// The guardian who last turned it on or off or deleted the log, and
  /// when. The log takes no word spoken before then.
  _is.UuidValue changedBy;

  DateTime changedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WordLogSetting]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WordLogSetting copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    bool? enabled,
    _is.UuidValue? changedBy,
    DateTime? changedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WordLogSetting',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'enabled': enabled,
      'changedBy': changedBy.toJson(),
      'changedAt': changedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static WordLogSettingInclude include() {
    return WordLogSettingInclude._();
  }

  static WordLogSettingIncludeList includeList({
    _is.WhereExpressionBuilder<WordLogSettingTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WordLogSettingTable>? orderBy,
    _is.OrderByListBuilder<WordLogSettingTable>? orderByList,
    WordLogSettingInclude? include,
  }) {
    return WordLogSettingIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WordLogSetting.t),
      orderByList: orderByList?.call(WordLogSetting.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WordLogSettingImpl extends WordLogSetting {
  _WordLogSettingImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required bool enabled,
    required _is.UuidValue changedBy,
    required DateTime changedAt,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         enabled: enabled,
         changedBy: changedBy,
         changedAt: changedAt,
       );

  /// Returns a shallow copy of this [WordLogSetting]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WordLogSetting copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    bool? enabled,
    _is.UuidValue? changedBy,
    DateTime? changedAt,
  }) {
    return WordLogSetting(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      enabled: enabled ?? this.enabled,
      changedBy: changedBy ?? this.changedBy,
      changedAt: changedAt ?? this.changedAt,
    );
  }
}

class WordLogSettingUpdateTable extends _is.UpdateTable<WordLogSettingTable> {
  WordLogSettingUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleSpace(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.circleSpace,
    value,
  );

  _is.ColumnValue<bool, bool> enabled(bool value) => _is.ColumnValue(
    table.enabled,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> changedBy(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.changedBy,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> changedAt(DateTime value) =>
      _is.ColumnValue(
        table.changedAt,
        value,
      );
}

class WordLogSettingTable extends _is.Table<int?> {
  WordLogSettingTable({super.tableRelation})
    : super(tableName: 'word_log_setting') {
    updateTable = WordLogSettingUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    enabled = _is.ColumnBool(
      'enabled',
      this,
    );
    changedBy = _is.ColumnUuid(
      'changedBy',
      this,
    );
    changedAt = _is.ColumnDateTime(
      'changedAt',
      this,
    );
  }

  late final WordLogSettingUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  late final _is.ColumnBool enabled;

  /// The guardian who last turned it on or off or deleted the log, and
  /// when. The log takes no word spoken before then.
  late final _is.ColumnUuid changedBy;

  late final _is.ColumnDateTime changedAt;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    enabled,
    changedBy,
    changedAt,
  ];
}

class WordLogSettingInclude extends _is.IncludeObject {
  WordLogSettingInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WordLogSetting.t;
}

class WordLogSettingIncludeList extends _is.IncludeList {
  WordLogSettingIncludeList._({
    _is.WhereExpressionBuilder<WordLogSettingTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WordLogSetting.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WordLogSetting.t;
}

class WordLogSettingRepository {
  const WordLogSettingRepository._();

  /// Returns a list of [WordLogSetting]s matching the given query parameters.
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
  Future<List<WordLogSetting>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WordLogSettingTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WordLogSettingTable>? orderBy,
    _is.OrderByListBuilder<WordLogSettingTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WordLogSetting>(
      where: where?.call(WordLogSetting.t),
      orderBy: orderBy?.call(WordLogSetting.t),
      orderByList: orderByList?.call(WordLogSetting.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WordLogSetting] matching the given query parameters.
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
  Future<WordLogSetting?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WordLogSettingTable>? where,
    int? offset,
    _is.OrderByBuilder<WordLogSettingTable>? orderBy,
    _is.OrderByListBuilder<WordLogSettingTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WordLogSetting>(
      where: where?.call(WordLogSetting.t),
      orderBy: orderBy?.call(WordLogSetting.t),
      orderByList: orderByList?.call(WordLogSetting.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WordLogSetting] by its [id] or null if no such row exists.
  Future<WordLogSetting?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WordLogSetting>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WordLogSetting]s in the list and returns the inserted rows.
  ///
  /// The returned [WordLogSetting]s will have their `id` fields set.
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
  Future<List<WordLogSetting>> insert(
    _is.DatabaseSession session,
    List<WordLogSetting> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WordLogSetting>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WordLogSetting] and returns the inserted row.
  ///
  /// The returned [WordLogSetting] will have its `id` field set.
  Future<WordLogSetting> insertRow(
    _is.DatabaseSession session,
    WordLogSetting row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WordLogSetting>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WordLogSetting]s in the list and returns the resulting rows.
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
  /// The returned [WordLogSetting]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WordLogSetting>> upsert(
    _is.DatabaseSession session,
    List<WordLogSetting> rows, {
    required _is.ColumnSelections<WordLogSettingTable> conflictColumns,
    _is.ColumnSelections<WordLogSettingTable>? updateColumns,
    _is.WhereExpressionBuilder<WordLogSettingTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WordLogSetting>(
      rows,
      conflictColumns: conflictColumns(WordLogSetting.t),
      updateColumns: updateColumns?.call(WordLogSetting.t),
      updateWhere: updateWhere?.call(WordLogSetting.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WordLogSetting] and returns the resulting row.
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
  /// The returned [WordLogSetting] will have its `id` field set.
  Future<WordLogSetting?> upsertRow(
    _is.DatabaseSession session,
    WordLogSetting row, {
    required _is.ColumnSelections<WordLogSettingTable> conflictColumns,
    _is.ColumnSelections<WordLogSettingTable>? updateColumns,
    _is.WhereExpressionBuilder<WordLogSettingTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WordLogSetting>(
      row,
      conflictColumns: conflictColumns(WordLogSetting.t),
      updateColumns: updateColumns?.call(WordLogSetting.t),
      updateWhere: updateWhere?.call(WordLogSetting.t),
      transaction: transaction,
    );
  }

  /// Updates all [WordLogSetting]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WordLogSetting>> update(
    _is.DatabaseSession session,
    List<WordLogSetting> rows, {
    _is.ColumnSelections<WordLogSettingTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WordLogSetting>(
      rows,
      columns: columns?.call(WordLogSetting.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WordLogSetting]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WordLogSetting> updateRow(
    _is.DatabaseSession session,
    WordLogSetting row, {
    _is.ColumnSelections<WordLogSettingTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WordLogSetting>(
      row,
      columns: columns?.call(WordLogSetting.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WordLogSetting] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WordLogSetting?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WordLogSettingUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WordLogSetting>(
      id,
      columnValues: columnValues(WordLogSetting.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WordLogSetting]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WordLogSetting>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WordLogSettingUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<WordLogSettingTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WordLogSettingTable>? orderBy,
    _is.OrderByListBuilder<WordLogSettingTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WordLogSetting>(
      columnValues: columnValues(WordLogSetting.t.updateTable),
      where: where(WordLogSetting.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WordLogSetting.t),
      orderByList: orderByList?.call(WordLogSetting.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WordLogSetting]s in the list and returns the deleted rows.
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
  Future<List<WordLogSetting>> delete(
    _is.DatabaseSession session,
    List<WordLogSetting> rows, {
    _is.OrderByBuilder<WordLogSettingTable>? orderBy,
    _is.OrderByListBuilder<WordLogSettingTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WordLogSetting>(
      rows,
      orderBy: orderBy?.call(WordLogSetting.t),
      orderByList: orderByList?.call(WordLogSetting.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WordLogSetting].
  Future<WordLogSetting> deleteRow(
    _is.DatabaseSession session,
    WordLogSetting row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WordLogSetting>(
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
  Future<List<WordLogSetting>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WordLogSettingTable> where,
    _is.OrderByBuilder<WordLogSettingTable>? orderBy,
    _is.OrderByListBuilder<WordLogSettingTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WordLogSetting>(
      where: where(WordLogSetting.t),
      orderBy: orderBy?.call(WordLogSetting.t),
      orderByList: orderByList?.call(WordLogSetting.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WordLogSettingTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WordLogSetting>(
      where: where?.call(WordLogSetting.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WordLogSetting] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WordLogSettingTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WordLogSetting>(
      where: where(WordLogSetting.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
