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

/// One change to one property of a tile. Append-only and synced.
///
/// Same-property edits from two offline devices merge as last-writer-wins,
/// silently. This log is what makes the overwritten value visible and
/// restorable.
abstract class TileEdit
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  TileEdit._({
    this.id,
    this.spaceId,
    required this.circleId,
    required this.tileId,
    required this.prop,
    this.oldValue,
    this.newValue,
    this.baseEditId,
    required this.reason,
    required this.actorId,
    required this.actorName,
    required this.editedAt,
  });

  factory TileEdit({
    _is.UuidValue? id,
    int? spaceId,
    required _is.UuidValue circleId,
    required _is.UuidValue tileId,
    required String prop,
    String? oldValue,
    String? newValue,
    _is.UuidValue? baseEditId,
    required String reason,
    required _is.UuidValue actorId,
    required String actorName,
    required DateTime editedAt,
  }) = _TileEditImpl;

  factory TileEdit.fromJson(Map<String, dynamic> jsonSerialization) {
    return TileEdit(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      spaceId: jsonSerialization['spaceId'] as int?,
      circleId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleId'],
      ),
      tileId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['tileId']),
      prop: jsonSerialization['prop'] as String,
      oldValue: jsonSerialization['oldValue'] as String?,
      newValue: jsonSerialization['newValue'] as String?,
      baseEditId: jsonSerialization['baseEditId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['baseEditId'],
            ),
      reason: jsonSerialization['reason'] as String,
      actorId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['actorId'],
      ),
      actorName: jsonSerialization['actorName'] as String,
      editedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['editedAt'],
      ),
    );
  }

  static final t = TileEditTable();

  static const db = TileEditRepository._();

  @override
  _is.UuidValue? id;

  /// The space owning this row. Maintained by the sync engine.
  int? spaceId;

  _is.UuidValue circleId;

  _is.UuidValue tileId;

  /// Name of the changed property, e.g. `label`.
  String prop;

  String? oldValue;

  String? newValue;

  /// The newest edit of this tile and property the author could see.
  _is.UuidValue? baseEditId;

  /// Why the edit happened, e.g. `edit`, `resolve`, `restore`, `seed`.
  String reason;

  _is.UuidValue actorId;

  String actorName;

  DateTime editedAt;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [TileEdit]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TileEdit copyWith({
    _is.UuidValue? id,
    int? spaceId,
    _is.UuidValue? circleId,
    _is.UuidValue? tileId,
    String? prop,
    String? oldValue,
    String? newValue,
    _is.UuidValue? baseEditId,
    String? reason,
    _is.UuidValue? actorId,
    String? actorName,
    DateTime? editedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TileEdit',
      if (id != null) 'id': id?.toJson(),
      if (spaceId != null) 'spaceId': spaceId,
      'circleId': circleId.toJson(),
      'tileId': tileId.toJson(),
      'prop': prop,
      if (oldValue != null) 'oldValue': oldValue,
      if (newValue != null) 'newValue': newValue,
      if (baseEditId != null) 'baseEditId': baseEditId?.toJson(),
      'reason': reason,
      'actorId': actorId.toJson(),
      'actorName': actorName,
      'editedAt': editedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TileEdit',
      if (id != null) 'id': id?.toJson(),
      if (spaceId != null) 'spaceId': spaceId,
      'circleId': circleId.toJson(),
      'tileId': tileId.toJson(),
      'prop': prop,
      if (oldValue != null) 'oldValue': oldValue,
      if (newValue != null) 'newValue': newValue,
      if (baseEditId != null) 'baseEditId': baseEditId?.toJson(),
      'reason': reason,
      'actorId': actorId.toJson(),
      'actorName': actorName,
      'editedAt': editedAt.toJson(),
    };
  }

  static TileEditInclude include() {
    return TileEditInclude._();
  }

  static TileEditIncludeList includeList({
    _is.WhereExpressionBuilder<TileEditTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TileEditTable>? orderBy,
    _is.OrderByListBuilder<TileEditTable>? orderByList,
    TileEditInclude? include,
  }) {
    return TileEditIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TileEdit.t),
      orderByList: orderByList?.call(TileEdit.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TileEditImpl extends TileEdit {
  _TileEditImpl({
    _is.UuidValue? id,
    int? spaceId,
    required _is.UuidValue circleId,
    required _is.UuidValue tileId,
    required String prop,
    String? oldValue,
    String? newValue,
    _is.UuidValue? baseEditId,
    required String reason,
    required _is.UuidValue actorId,
    required String actorName,
    required DateTime editedAt,
  }) : super._(
         id: id,
         spaceId: spaceId,
         circleId: circleId,
         tileId: tileId,
         prop: prop,
         oldValue: oldValue,
         newValue: newValue,
         baseEditId: baseEditId,
         reason: reason,
         actorId: actorId,
         actorName: actorName,
         editedAt: editedAt,
       );

  /// Returns a shallow copy of this [TileEdit]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TileEdit copyWith({
    Object? id = _Undefined,
    Object? spaceId = _Undefined,
    _is.UuidValue? circleId,
    _is.UuidValue? tileId,
    String? prop,
    Object? oldValue = _Undefined,
    Object? newValue = _Undefined,
    Object? baseEditId = _Undefined,
    String? reason,
    _is.UuidValue? actorId,
    String? actorName,
    DateTime? editedAt,
  }) {
    return TileEdit(
      id: id is _is.UuidValue? ? id : this.id,
      spaceId: spaceId is int? ? spaceId : this.spaceId,
      circleId: circleId ?? this.circleId,
      tileId: tileId ?? this.tileId,
      prop: prop ?? this.prop,
      oldValue: oldValue is String? ? oldValue : this.oldValue,
      newValue: newValue is String? ? newValue : this.newValue,
      baseEditId: baseEditId is _is.UuidValue? ? baseEditId : this.baseEditId,
      reason: reason ?? this.reason,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}

class TileEditUpdateTable extends _is.UpdateTable<TileEditTable> {
  TileEditUpdateTable(super.table);

  _is.ColumnValue<int, int> spaceId(int? value) => _is.ColumnValue(
    table.spaceId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.circleId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> tileId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.tileId,
        value,
      );

  _is.ColumnValue<String, String> prop(String value) => _is.ColumnValue(
    table.prop,
    value,
  );

  _is.ColumnValue<String, String> oldValue(String? value) => _is.ColumnValue(
    table.oldValue,
    value,
  );

  _is.ColumnValue<String, String> newValue(String? value) => _is.ColumnValue(
    table.newValue,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> baseEditId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.baseEditId,
    value,
  );

  _is.ColumnValue<String, String> reason(String value) => _is.ColumnValue(
    table.reason,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> actorId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.actorId,
        value,
      );

  _is.ColumnValue<String, String> actorName(String value) => _is.ColumnValue(
    table.actorName,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> editedAt(DateTime value) =>
      _is.ColumnValue(
        table.editedAt,
        value,
      );
}

class TileEditTable extends _is.Table<_is.UuidValue?> {
  TileEditTable({super.tableRelation}) : super(tableName: 'tile_edit') {
    updateTable = TileEditUpdateTable(this);
    spaceId = _is.ColumnInt(
      'spaceId',
      this,
    );
    circleId = _is.ColumnUuid(
      'circleId',
      this,
    );
    tileId = _is.ColumnUuid(
      'tileId',
      this,
    );
    prop = _is.ColumnString(
      'prop',
      this,
    );
    oldValue = _is.ColumnString(
      'oldValue',
      this,
    );
    newValue = _is.ColumnString(
      'newValue',
      this,
    );
    baseEditId = _is.ColumnUuid(
      'baseEditId',
      this,
    );
    reason = _is.ColumnString(
      'reason',
      this,
    );
    actorId = _is.ColumnUuid(
      'actorId',
      this,
    );
    actorName = _is.ColumnString(
      'actorName',
      this,
    );
    editedAt = _is.ColumnDateTime(
      'editedAt',
      this,
    );
  }

  late final TileEditUpdateTable updateTable;

  /// The space owning this row. Maintained by the sync engine.
  late final _is.ColumnInt spaceId;

  late final _is.ColumnUuid circleId;

  late final _is.ColumnUuid tileId;

  /// Name of the changed property, e.g. `label`.
  late final _is.ColumnString prop;

  late final _is.ColumnString oldValue;

  late final _is.ColumnString newValue;

  /// The newest edit of this tile and property the author could see.
  late final _is.ColumnUuid baseEditId;

  /// Why the edit happened, e.g. `edit`, `resolve`, `restore`, `seed`.
  late final _is.ColumnString reason;

  late final _is.ColumnUuid actorId;

  late final _is.ColumnString actorName;

  late final _is.ColumnDateTime editedAt;

  @override
  List<_is.Column> get columns => [
    id,
    spaceId,
    circleId,
    tileId,
    prop,
    oldValue,
    newValue,
    baseEditId,
    reason,
    actorId,
    actorName,
    editedAt,
  ];
}

class TileEditInclude extends _is.IncludeObject {
  TileEditInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => TileEdit.t;
}

class TileEditIncludeList extends _is.IncludeList {
  TileEditIncludeList._({
    _is.WhereExpressionBuilder<TileEditTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TileEdit.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => TileEdit.t;
}

class TileEditRepository {
  const TileEditRepository._();

  /// Returns a list of [TileEdit]s matching the given query parameters.
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
  Future<List<TileEdit>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TileEditTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TileEditTable>? orderBy,
    _is.OrderByListBuilder<TileEditTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TileEdit>(
      where: where?.call(TileEdit.t),
      orderBy: orderBy?.call(TileEdit.t),
      orderByList: orderByList?.call(TileEdit.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TileEdit] matching the given query parameters.
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
  Future<TileEdit?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TileEditTable>? where,
    int? offset,
    _is.OrderByBuilder<TileEditTable>? orderBy,
    _is.OrderByListBuilder<TileEditTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TileEdit>(
      where: where?.call(TileEdit.t),
      orderBy: orderBy?.call(TileEdit.t),
      orderByList: orderByList?.call(TileEdit.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TileEdit] by its [id] or null if no such row exists.
  Future<TileEdit?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TileEdit>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TileEdit]s in the list and returns the inserted rows.
  ///
  /// The returned [TileEdit]s will have their `id` fields set.
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
  Future<List<TileEdit>> insert(
    _is.DatabaseSession session,
    List<TileEdit> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TileEdit>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TileEdit] and returns the inserted row.
  ///
  /// The returned [TileEdit] will have its `id` field set.
  Future<TileEdit> insertRow(
    _is.DatabaseSession session,
    TileEdit row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TileEdit>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [TileEdit]s in the list and returns the resulting rows.
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
  /// The returned [TileEdit]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TileEdit>> upsert(
    _is.DatabaseSession session,
    List<TileEdit> rows, {
    required _is.ColumnSelections<TileEditTable> conflictColumns,
    _is.ColumnSelections<TileEditTable>? updateColumns,
    _is.WhereExpressionBuilder<TileEditTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TileEdit>(
      rows,
      conflictColumns: conflictColumns(TileEdit.t),
      updateColumns: updateColumns?.call(TileEdit.t),
      updateWhere: updateWhere?.call(TileEdit.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TileEdit] and returns the resulting row.
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
  /// The returned [TileEdit] will have its `id` field set.
  Future<TileEdit?> upsertRow(
    _is.DatabaseSession session,
    TileEdit row, {
    required _is.ColumnSelections<TileEditTable> conflictColumns,
    _is.ColumnSelections<TileEditTable>? updateColumns,
    _is.WhereExpressionBuilder<TileEditTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TileEdit>(
      row,
      conflictColumns: conflictColumns(TileEdit.t),
      updateColumns: updateColumns?.call(TileEdit.t),
      updateWhere: updateWhere?.call(TileEdit.t),
      transaction: transaction,
    );
  }

  /// Updates all [TileEdit]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TileEdit>> update(
    _is.DatabaseSession session,
    List<TileEdit> rows, {
    _is.ColumnSelections<TileEditTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TileEdit>(
      rows,
      columns: columns?.call(TileEdit.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TileEdit]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TileEdit> updateRow(
    _is.DatabaseSession session,
    TileEdit row, {
    _is.ColumnSelections<TileEditTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TileEdit>(
      row,
      columns: columns?.call(TileEdit.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TileEdit] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TileEdit?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<TileEditUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TileEdit>(
      id,
      columnValues: columnValues(TileEdit.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TileEdit]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TileEdit>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TileEditUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<TileEditTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TileEditTable>? orderBy,
    _is.OrderByListBuilder<TileEditTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TileEdit>(
      columnValues: columnValues(TileEdit.t.updateTable),
      where: where(TileEdit.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TileEdit.t),
      orderByList: orderByList?.call(TileEdit.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TileEdit]s in the list and returns the deleted rows.
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
  Future<List<TileEdit>> delete(
    _is.DatabaseSession session,
    List<TileEdit> rows, {
    _is.OrderByBuilder<TileEditTable>? orderBy,
    _is.OrderByListBuilder<TileEditTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TileEdit>(
      rows,
      orderBy: orderBy?.call(TileEdit.t),
      orderByList: orderByList?.call(TileEdit.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TileEdit].
  Future<TileEdit> deleteRow(
    _is.DatabaseSession session,
    TileEdit row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TileEdit>(
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
  Future<List<TileEdit>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TileEditTable> where,
    _is.OrderByBuilder<TileEditTable>? orderBy,
    _is.OrderByListBuilder<TileEditTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TileEdit>(
      where: where(TileEdit.t),
      orderBy: orderBy?.call(TileEdit.t),
      orderByList: orderByList?.call(TileEdit.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TileEditTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TileEdit>(
      where: where?.call(TileEdit.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TileEdit] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TileEditTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TileEdit>(
      where: where(TileEdit.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
