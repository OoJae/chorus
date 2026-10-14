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

/// A circle's second (home) language, e.g. Yoruba. Server-only. A circle
/// with no row has none.
abstract class CircleLanguage
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  CircleLanguage._({
    this.id,
    required this.circleSpace,
    required this.languageCode,
    required this.languageName,
    required this.changedBy,
    required this.changedAt,
  });

  factory CircleLanguage({
    int? id,
    required _is.UuidValue circleSpace,
    required String languageCode,
    required String languageName,
    required _is.UuidValue changedBy,
    required DateTime changedAt,
  }) = _CircleLanguageImpl;

  factory CircleLanguage.fromJson(Map<String, dynamic> jsonSerialization) {
    return CircleLanguage(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      languageCode: jsonSerialization['languageCode'] as String,
      languageName: jsonSerialization['languageName'] as String,
      changedBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['changedBy'],
      ),
      changedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['changedAt'],
      ),
    );
  }

  static final t = CircleLanguageTable();

  static const db = CircleLanguageRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  /// A BCP 47 language code, e.g. `yo`, `es`, `fr`.
  String languageCode;

  /// The language's name as the adults wrote it, e.g. "Yoruba".
  String languageName;

  _is.UuidValue changedBy;

  DateTime changedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [CircleLanguage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CircleLanguage copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    String? languageCode,
    String? languageName,
    _is.UuidValue? changedBy,
    DateTime? changedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CircleLanguage',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'languageCode': languageCode,
      'languageName': languageName,
      'changedBy': changedBy.toJson(),
      'changedAt': changedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static CircleLanguageInclude include() {
    return CircleLanguageInclude._();
  }

  static CircleLanguageIncludeList includeList({
    _is.WhereExpressionBuilder<CircleLanguageTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CircleLanguageTable>? orderBy,
    _is.OrderByListBuilder<CircleLanguageTable>? orderByList,
    CircleLanguageInclude? include,
  }) {
    return CircleLanguageIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CircleLanguage.t),
      orderByList: orderByList?.call(CircleLanguage.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CircleLanguageImpl extends CircleLanguage {
  _CircleLanguageImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required String languageCode,
    required String languageName,
    required _is.UuidValue changedBy,
    required DateTime changedAt,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         languageCode: languageCode,
         languageName: languageName,
         changedBy: changedBy,
         changedAt: changedAt,
       );

  /// Returns a shallow copy of this [CircleLanguage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CircleLanguage copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    String? languageCode,
    String? languageName,
    _is.UuidValue? changedBy,
    DateTime? changedAt,
  }) {
    return CircleLanguage(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      languageCode: languageCode ?? this.languageCode,
      languageName: languageName ?? this.languageName,
      changedBy: changedBy ?? this.changedBy,
      changedAt: changedAt ?? this.changedAt,
    );
  }
}

class CircleLanguageUpdateTable extends _is.UpdateTable<CircleLanguageTable> {
  CircleLanguageUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleSpace(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.circleSpace,
    value,
  );

  _is.ColumnValue<String, String> languageCode(String value) => _is.ColumnValue(
    table.languageCode,
    value,
  );

  _is.ColumnValue<String, String> languageName(String value) => _is.ColumnValue(
    table.languageName,
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

class CircleLanguageTable extends _is.Table<int?> {
  CircleLanguageTable({super.tableRelation})
    : super(tableName: 'circle_language') {
    updateTable = CircleLanguageUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    languageCode = _is.ColumnString(
      'languageCode',
      this,
    );
    languageName = _is.ColumnString(
      'languageName',
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

  late final CircleLanguageUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  /// A BCP 47 language code, e.g. `yo`, `es`, `fr`.
  late final _is.ColumnString languageCode;

  /// The language's name as the adults wrote it, e.g. "Yoruba".
  late final _is.ColumnString languageName;

  late final _is.ColumnUuid changedBy;

  late final _is.ColumnDateTime changedAt;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    languageCode,
    languageName,
    changedBy,
    changedAt,
  ];
}

class CircleLanguageInclude extends _is.IncludeObject {
  CircleLanguageInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => CircleLanguage.t;
}

class CircleLanguageIncludeList extends _is.IncludeList {
  CircleLanguageIncludeList._({
    _is.WhereExpressionBuilder<CircleLanguageTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(CircleLanguage.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => CircleLanguage.t;
}

class CircleLanguageRepository {
  const CircleLanguageRepository._();

  /// Returns a list of [CircleLanguage]s matching the given query parameters.
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
  Future<List<CircleLanguage>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CircleLanguageTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CircleLanguageTable>? orderBy,
    _is.OrderByListBuilder<CircleLanguageTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<CircleLanguage>(
      where: where?.call(CircleLanguage.t),
      orderBy: orderBy?.call(CircleLanguage.t),
      orderByList: orderByList?.call(CircleLanguage.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [CircleLanguage] matching the given query parameters.
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
  Future<CircleLanguage?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CircleLanguageTable>? where,
    int? offset,
    _is.OrderByBuilder<CircleLanguageTable>? orderBy,
    _is.OrderByListBuilder<CircleLanguageTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<CircleLanguage>(
      where: where?.call(CircleLanguage.t),
      orderBy: orderBy?.call(CircleLanguage.t),
      orderByList: orderByList?.call(CircleLanguage.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [CircleLanguage] by its [id] or null if no such row exists.
  Future<CircleLanguage?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<CircleLanguage>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [CircleLanguage]s in the list and returns the inserted rows.
  ///
  /// The returned [CircleLanguage]s will have their `id` fields set.
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
  Future<List<CircleLanguage>> insert(
    _is.DatabaseSession session,
    List<CircleLanguage> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<CircleLanguage>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [CircleLanguage] and returns the inserted row.
  ///
  /// The returned [CircleLanguage] will have its `id` field set.
  Future<CircleLanguage> insertRow(
    _is.DatabaseSession session,
    CircleLanguage row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<CircleLanguage>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [CircleLanguage]s in the list and returns the resulting rows.
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
  /// The returned [CircleLanguage]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CircleLanguage>> upsert(
    _is.DatabaseSession session,
    List<CircleLanguage> rows, {
    required _is.ColumnSelections<CircleLanguageTable> conflictColumns,
    _is.ColumnSelections<CircleLanguageTable>? updateColumns,
    _is.WhereExpressionBuilder<CircleLanguageTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<CircleLanguage>(
      rows,
      conflictColumns: conflictColumns(CircleLanguage.t),
      updateColumns: updateColumns?.call(CircleLanguage.t),
      updateWhere: updateWhere?.call(CircleLanguage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [CircleLanguage] and returns the resulting row.
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
  /// The returned [CircleLanguage] will have its `id` field set.
  Future<CircleLanguage?> upsertRow(
    _is.DatabaseSession session,
    CircleLanguage row, {
    required _is.ColumnSelections<CircleLanguageTable> conflictColumns,
    _is.ColumnSelections<CircleLanguageTable>? updateColumns,
    _is.WhereExpressionBuilder<CircleLanguageTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<CircleLanguage>(
      row,
      conflictColumns: conflictColumns(CircleLanguage.t),
      updateColumns: updateColumns?.call(CircleLanguage.t),
      updateWhere: updateWhere?.call(CircleLanguage.t),
      transaction: transaction,
    );
  }

  /// Updates all [CircleLanguage]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CircleLanguage>> update(
    _is.DatabaseSession session,
    List<CircleLanguage> rows, {
    _is.ColumnSelections<CircleLanguageTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<CircleLanguage>(
      rows,
      columns: columns?.call(CircleLanguage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [CircleLanguage]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<CircleLanguage> updateRow(
    _is.DatabaseSession session,
    CircleLanguage row, {
    _is.ColumnSelections<CircleLanguageTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<CircleLanguage>(
      row,
      columns: columns?.call(CircleLanguage.t),
      transaction: transaction,
    );
  }

  /// Updates a single [CircleLanguage] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<CircleLanguage?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<CircleLanguageUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<CircleLanguage>(
      id,
      columnValues: columnValues(CircleLanguage.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [CircleLanguage]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CircleLanguage>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<CircleLanguageUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<CircleLanguageTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CircleLanguageTable>? orderBy,
    _is.OrderByListBuilder<CircleLanguageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<CircleLanguage>(
      columnValues: columnValues(CircleLanguage.t.updateTable),
      where: where(CircleLanguage.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CircleLanguage.t),
      orderByList: orderByList?.call(CircleLanguage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [CircleLanguage]s in the list and returns the deleted rows.
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
  Future<List<CircleLanguage>> delete(
    _is.DatabaseSession session,
    List<CircleLanguage> rows, {
    _is.OrderByBuilder<CircleLanguageTable>? orderBy,
    _is.OrderByListBuilder<CircleLanguageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<CircleLanguage>(
      rows,
      orderBy: orderBy?.call(CircleLanguage.t),
      orderByList: orderByList?.call(CircleLanguage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [CircleLanguage].
  Future<CircleLanguage> deleteRow(
    _is.DatabaseSession session,
    CircleLanguage row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<CircleLanguage>(
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
  Future<List<CircleLanguage>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CircleLanguageTable> where,
    _is.OrderByBuilder<CircleLanguageTable>? orderBy,
    _is.OrderByListBuilder<CircleLanguageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<CircleLanguage>(
      where: where(CircleLanguage.t),
      orderBy: orderBy?.call(CircleLanguage.t),
      orderByList: orderByList?.call(CircleLanguage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CircleLanguageTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<CircleLanguage>(
      where: where?.call(CircleLanguage.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [CircleLanguage] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CircleLanguageTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<CircleLanguage>(
      where: where(CircleLanguage.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
