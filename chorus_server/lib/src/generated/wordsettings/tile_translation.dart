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

/// A word's label, and optionally what is spoken, in a circle's second
/// language. Server-only.
abstract class TileTranslation
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  TileTranslation._({
    this.id,
    required this.circleSpace,
    required this.tileId,
    required this.languageCode,
    required this.label,
    this.speech,
    required this.changedBy,
    required this.changedAt,
  });

  factory TileTranslation({
    int? id,
    required _is.UuidValue circleSpace,
    required _is.UuidValue tileId,
    required String languageCode,
    required String label,
    String? speech,
    required _is.UuidValue changedBy,
    required DateTime changedAt,
  }) = _TileTranslationImpl;

  factory TileTranslation.fromJson(Map<String, dynamic> jsonSerialization) {
    return TileTranslation(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      tileId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['tileId']),
      languageCode: jsonSerialization['languageCode'] as String,
      label: jsonSerialization['label'] as String,
      speech: jsonSerialization['speech'] as String?,
      changedBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['changedBy'],
      ),
      changedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['changedAt'],
      ),
    );
  }

  static final t = TileTranslationTable();

  static const db = TileTranslationRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  _is.UuidValue tileId;

  String languageCode;

  String label;

  String? speech;

  _is.UuidValue changedBy;

  DateTime changedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TileTranslation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TileTranslation copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    _is.UuidValue? tileId,
    String? languageCode,
    String? label,
    String? speech,
    _is.UuidValue? changedBy,
    DateTime? changedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TileTranslation',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'tileId': tileId.toJson(),
      'languageCode': languageCode,
      'label': label,
      if (speech != null) 'speech': speech,
      'changedBy': changedBy.toJson(),
      'changedAt': changedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TileTranslationInclude include() {
    return TileTranslationInclude._();
  }

  static TileTranslationIncludeList includeList({
    _is.WhereExpressionBuilder<TileTranslationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TileTranslationTable>? orderBy,
    _is.OrderByListBuilder<TileTranslationTable>? orderByList,
    TileTranslationInclude? include,
  }) {
    return TileTranslationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TileTranslation.t),
      orderByList: orderByList?.call(TileTranslation.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TileTranslationImpl extends TileTranslation {
  _TileTranslationImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required _is.UuidValue tileId,
    required String languageCode,
    required String label,
    String? speech,
    required _is.UuidValue changedBy,
    required DateTime changedAt,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         tileId: tileId,
         languageCode: languageCode,
         label: label,
         speech: speech,
         changedBy: changedBy,
         changedAt: changedAt,
       );

  /// Returns a shallow copy of this [TileTranslation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TileTranslation copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    _is.UuidValue? tileId,
    String? languageCode,
    String? label,
    Object? speech = _Undefined,
    _is.UuidValue? changedBy,
    DateTime? changedAt,
  }) {
    return TileTranslation(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      tileId: tileId ?? this.tileId,
      languageCode: languageCode ?? this.languageCode,
      label: label ?? this.label,
      speech: speech is String? ? speech : this.speech,
      changedBy: changedBy ?? this.changedBy,
      changedAt: changedAt ?? this.changedAt,
    );
  }
}

class TileTranslationUpdateTable extends _is.UpdateTable<TileTranslationTable> {
  TileTranslationUpdateTable(super.table);

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

  _is.ColumnValue<String, String> languageCode(String value) => _is.ColumnValue(
    table.languageCode,
    value,
  );

  _is.ColumnValue<String, String> label(String value) => _is.ColumnValue(
    table.label,
    value,
  );

  _is.ColumnValue<String, String> speech(String? value) => _is.ColumnValue(
    table.speech,
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

class TileTranslationTable extends _is.Table<int?> {
  TileTranslationTable({super.tableRelation})
    : super(tableName: 'tile_translation') {
    updateTable = TileTranslationUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    tileId = _is.ColumnUuid(
      'tileId',
      this,
    );
    languageCode = _is.ColumnString(
      'languageCode',
      this,
    );
    label = _is.ColumnString(
      'label',
      this,
    );
    speech = _is.ColumnString(
      'speech',
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

  late final TileTranslationUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  late final _is.ColumnUuid tileId;

  late final _is.ColumnString languageCode;

  late final _is.ColumnString label;

  late final _is.ColumnString speech;

  late final _is.ColumnUuid changedBy;

  late final _is.ColumnDateTime changedAt;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    tileId,
    languageCode,
    label,
    speech,
    changedBy,
    changedAt,
  ];
}

class TileTranslationInclude extends _is.IncludeObject {
  TileTranslationInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => TileTranslation.t;
}

class TileTranslationIncludeList extends _is.IncludeList {
  TileTranslationIncludeList._({
    _is.WhereExpressionBuilder<TileTranslationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TileTranslation.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TileTranslation.t;
}

class TileTranslationRepository {
  const TileTranslationRepository._();

  /// Returns a list of [TileTranslation]s matching the given query parameters.
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
  Future<List<TileTranslation>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TileTranslationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TileTranslationTable>? orderBy,
    _is.OrderByListBuilder<TileTranslationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TileTranslation>(
      where: where?.call(TileTranslation.t),
      orderBy: orderBy?.call(TileTranslation.t),
      orderByList: orderByList?.call(TileTranslation.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TileTranslation] matching the given query parameters.
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
  Future<TileTranslation?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TileTranslationTable>? where,
    int? offset,
    _is.OrderByBuilder<TileTranslationTable>? orderBy,
    _is.OrderByListBuilder<TileTranslationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TileTranslation>(
      where: where?.call(TileTranslation.t),
      orderBy: orderBy?.call(TileTranslation.t),
      orderByList: orderByList?.call(TileTranslation.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TileTranslation] by its [id] or null if no such row exists.
  Future<TileTranslation?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TileTranslation>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TileTranslation]s in the list and returns the inserted rows.
  ///
  /// The returned [TileTranslation]s will have their `id` fields set.
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
  Future<List<TileTranslation>> insert(
    _is.DatabaseSession session,
    List<TileTranslation> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TileTranslation>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TileTranslation] and returns the inserted row.
  ///
  /// The returned [TileTranslation] will have its `id` field set.
  Future<TileTranslation> insertRow(
    _is.DatabaseSession session,
    TileTranslation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TileTranslation>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [TileTranslation]s in the list and returns the resulting rows.
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
  /// The returned [TileTranslation]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TileTranslation>> upsert(
    _is.DatabaseSession session,
    List<TileTranslation> rows, {
    required _is.ColumnSelections<TileTranslationTable> conflictColumns,
    _is.ColumnSelections<TileTranslationTable>? updateColumns,
    _is.WhereExpressionBuilder<TileTranslationTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TileTranslation>(
      rows,
      conflictColumns: conflictColumns(TileTranslation.t),
      updateColumns: updateColumns?.call(TileTranslation.t),
      updateWhere: updateWhere?.call(TileTranslation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TileTranslation] and returns the resulting row.
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
  /// The returned [TileTranslation] will have its `id` field set.
  Future<TileTranslation?> upsertRow(
    _is.DatabaseSession session,
    TileTranslation row, {
    required _is.ColumnSelections<TileTranslationTable> conflictColumns,
    _is.ColumnSelections<TileTranslationTable>? updateColumns,
    _is.WhereExpressionBuilder<TileTranslationTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TileTranslation>(
      row,
      conflictColumns: conflictColumns(TileTranslation.t),
      updateColumns: updateColumns?.call(TileTranslation.t),
      updateWhere: updateWhere?.call(TileTranslation.t),
      transaction: transaction,
    );
  }

  /// Updates all [TileTranslation]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TileTranslation>> update(
    _is.DatabaseSession session,
    List<TileTranslation> rows, {
    _is.ColumnSelections<TileTranslationTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TileTranslation>(
      rows,
      columns: columns?.call(TileTranslation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TileTranslation]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TileTranslation> updateRow(
    _is.DatabaseSession session,
    TileTranslation row, {
    _is.ColumnSelections<TileTranslationTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TileTranslation>(
      row,
      columns: columns?.call(TileTranslation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TileTranslation] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TileTranslation?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TileTranslationUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TileTranslation>(
      id,
      columnValues: columnValues(TileTranslation.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TileTranslation]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TileTranslation>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TileTranslationUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<TileTranslationTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TileTranslationTable>? orderBy,
    _is.OrderByListBuilder<TileTranslationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TileTranslation>(
      columnValues: columnValues(TileTranslation.t.updateTable),
      where: where(TileTranslation.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TileTranslation.t),
      orderByList: orderByList?.call(TileTranslation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TileTranslation]s in the list and returns the deleted rows.
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
  Future<List<TileTranslation>> delete(
    _is.DatabaseSession session,
    List<TileTranslation> rows, {
    _is.OrderByBuilder<TileTranslationTable>? orderBy,
    _is.OrderByListBuilder<TileTranslationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TileTranslation>(
      rows,
      orderBy: orderBy?.call(TileTranslation.t),
      orderByList: orderByList?.call(TileTranslation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TileTranslation].
  Future<TileTranslation> deleteRow(
    _is.DatabaseSession session,
    TileTranslation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TileTranslation>(
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
  Future<List<TileTranslation>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TileTranslationTable> where,
    _is.OrderByBuilder<TileTranslationTable>? orderBy,
    _is.OrderByListBuilder<TileTranslationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TileTranslation>(
      where: where(TileTranslation.t),
      orderBy: orderBy?.call(TileTranslation.t),
      orderByList: orderByList?.call(TileTranslation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TileTranslationTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TileTranslation>(
      where: where?.call(TileTranslation.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TileTranslation] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TileTranslationTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TileTranslation>(
      where: where(TileTranslation.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
