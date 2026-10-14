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

/// Whether an adult has hidden a word from the child's board for now.
/// Server-only, so the frozen synced tables stay as they are. A tile with
/// no row is shown. Hiding never moves a word: its cell stays taken.
abstract class TileSetting
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  TileSetting._({
    this.id,
    required this.circleSpace,
    required this.tileId,
    required this.hidden,
    required this.changedBy,
    required this.changedAt,
  });

  factory TileSetting({
    int? id,
    required _is.UuidValue circleSpace,
    required _is.UuidValue tileId,
    required bool hidden,
    required _is.UuidValue changedBy,
    required DateTime changedAt,
  }) = _TileSettingImpl;

  factory TileSetting.fromJson(Map<String, dynamic> jsonSerialization) {
    return TileSetting(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      tileId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['tileId']),
      hidden: _is.BoolJsonExtension.fromJson(jsonSerialization['hidden']),
      changedBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['changedBy'],
      ),
      changedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['changedAt'],
      ),
    );
  }

  static final t = TileSettingTable();

  static const db = TileSettingRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  _is.UuidValue tileId;

  bool hidden;

  /// The adult who last hid or showed the word, and when.
  _is.UuidValue changedBy;

  DateTime changedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TileSetting]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TileSetting copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    _is.UuidValue? tileId,
    bool? hidden,
    _is.UuidValue? changedBy,
    DateTime? changedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TileSetting',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'tileId': tileId.toJson(),
      'hidden': hidden,
      'changedBy': changedBy.toJson(),
      'changedAt': changedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TileSettingInclude include() {
    return TileSettingInclude._();
  }

  static TileSettingIncludeList includeList({
    _is.WhereExpressionBuilder<TileSettingTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TileSettingTable>? orderBy,
    _is.OrderByListBuilder<TileSettingTable>? orderByList,
    TileSettingInclude? include,
  }) {
    return TileSettingIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TileSetting.t),
      orderByList: orderByList?.call(TileSetting.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TileSettingImpl extends TileSetting {
  _TileSettingImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required _is.UuidValue tileId,
    required bool hidden,
    required _is.UuidValue changedBy,
    required DateTime changedAt,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         tileId: tileId,
         hidden: hidden,
         changedBy: changedBy,
         changedAt: changedAt,
       );

  /// Returns a shallow copy of this [TileSetting]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TileSetting copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    _is.UuidValue? tileId,
    bool? hidden,
    _is.UuidValue? changedBy,
    DateTime? changedAt,
  }) {
    return TileSetting(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      tileId: tileId ?? this.tileId,
      hidden: hidden ?? this.hidden,
      changedBy: changedBy ?? this.changedBy,
      changedAt: changedAt ?? this.changedAt,
    );
  }
}

class TileSettingUpdateTable extends _is.UpdateTable<TileSettingTable> {
  TileSettingUpdateTable(super.table);

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

  _is.ColumnValue<bool, bool> hidden(bool value) => _is.ColumnValue(
    table.hidden,
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

class TileSettingTable extends _is.Table<int?> {
  TileSettingTable({super.tableRelation}) : super(tableName: 'tile_setting') {
    updateTable = TileSettingUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    tileId = _is.ColumnUuid(
      'tileId',
      this,
    );
    hidden = _is.ColumnBool(
      'hidden',
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

  late final TileSettingUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  late final _is.ColumnUuid tileId;

  late final _is.ColumnBool hidden;

  /// The adult who last hid or showed the word, and when.
  late final _is.ColumnUuid changedBy;

  late final _is.ColumnDateTime changedAt;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    tileId,
    hidden,
    changedBy,
    changedAt,
  ];
}

class TileSettingInclude extends _is.IncludeObject {
  TileSettingInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => TileSetting.t;
}

class TileSettingIncludeList extends _is.IncludeList {
  TileSettingIncludeList._({
    _is.WhereExpressionBuilder<TileSettingTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TileSetting.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TileSetting.t;
}

class TileSettingRepository {
  const TileSettingRepository._();

  /// Returns a list of [TileSetting]s matching the given query parameters.
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
  Future<List<TileSetting>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TileSettingTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TileSettingTable>? orderBy,
    _is.OrderByListBuilder<TileSettingTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TileSetting>(
      where: where?.call(TileSetting.t),
      orderBy: orderBy?.call(TileSetting.t),
      orderByList: orderByList?.call(TileSetting.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TileSetting] matching the given query parameters.
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
  Future<TileSetting?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TileSettingTable>? where,
    int? offset,
    _is.OrderByBuilder<TileSettingTable>? orderBy,
    _is.OrderByListBuilder<TileSettingTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TileSetting>(
      where: where?.call(TileSetting.t),
      orderBy: orderBy?.call(TileSetting.t),
      orderByList: orderByList?.call(TileSetting.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TileSetting] by its [id] or null if no such row exists.
  Future<TileSetting?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TileSetting>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TileSetting]s in the list and returns the inserted rows.
  ///
  /// The returned [TileSetting]s will have their `id` fields set.
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
  Future<List<TileSetting>> insert(
    _is.DatabaseSession session,
    List<TileSetting> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TileSetting>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TileSetting] and returns the inserted row.
  ///
  /// The returned [TileSetting] will have its `id` field set.
  Future<TileSetting> insertRow(
    _is.DatabaseSession session,
    TileSetting row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TileSetting>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [TileSetting]s in the list and returns the resulting rows.
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
  /// The returned [TileSetting]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TileSetting>> upsert(
    _is.DatabaseSession session,
    List<TileSetting> rows, {
    required _is.ColumnSelections<TileSettingTable> conflictColumns,
    _is.ColumnSelections<TileSettingTable>? updateColumns,
    _is.WhereExpressionBuilder<TileSettingTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TileSetting>(
      rows,
      conflictColumns: conflictColumns(TileSetting.t),
      updateColumns: updateColumns?.call(TileSetting.t),
      updateWhere: updateWhere?.call(TileSetting.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TileSetting] and returns the resulting row.
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
  /// The returned [TileSetting] will have its `id` field set.
  Future<TileSetting?> upsertRow(
    _is.DatabaseSession session,
    TileSetting row, {
    required _is.ColumnSelections<TileSettingTable> conflictColumns,
    _is.ColumnSelections<TileSettingTable>? updateColumns,
    _is.WhereExpressionBuilder<TileSettingTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TileSetting>(
      row,
      conflictColumns: conflictColumns(TileSetting.t),
      updateColumns: updateColumns?.call(TileSetting.t),
      updateWhere: updateWhere?.call(TileSetting.t),
      transaction: transaction,
    );
  }

  /// Updates all [TileSetting]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TileSetting>> update(
    _is.DatabaseSession session,
    List<TileSetting> rows, {
    _is.ColumnSelections<TileSettingTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TileSetting>(
      rows,
      columns: columns?.call(TileSetting.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TileSetting]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TileSetting> updateRow(
    _is.DatabaseSession session,
    TileSetting row, {
    _is.ColumnSelections<TileSettingTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TileSetting>(
      row,
      columns: columns?.call(TileSetting.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TileSetting] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TileSetting?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TileSettingUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TileSetting>(
      id,
      columnValues: columnValues(TileSetting.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TileSetting]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TileSetting>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TileSettingUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<TileSettingTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TileSettingTable>? orderBy,
    _is.OrderByListBuilder<TileSettingTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TileSetting>(
      columnValues: columnValues(TileSetting.t.updateTable),
      where: where(TileSetting.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TileSetting.t),
      orderByList: orderByList?.call(TileSetting.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TileSetting]s in the list and returns the deleted rows.
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
  Future<List<TileSetting>> delete(
    _is.DatabaseSession session,
    List<TileSetting> rows, {
    _is.OrderByBuilder<TileSettingTable>? orderBy,
    _is.OrderByListBuilder<TileSettingTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TileSetting>(
      rows,
      orderBy: orderBy?.call(TileSetting.t),
      orderByList: orderByList?.call(TileSetting.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TileSetting].
  Future<TileSetting> deleteRow(
    _is.DatabaseSession session,
    TileSetting row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TileSetting>(
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
  Future<List<TileSetting>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TileSettingTable> where,
    _is.OrderByBuilder<TileSettingTable>? orderBy,
    _is.OrderByListBuilder<TileSettingTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TileSetting>(
      where: where(TileSetting.t),
      orderBy: orderBy?.call(TileSetting.t),
      orderByList: orderByList?.call(TileSetting.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TileSettingTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TileSetting>(
      where: where?.call(TileSetting.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TileSetting] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TileSettingTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TileSetting>(
      where: where(TileSetting.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
