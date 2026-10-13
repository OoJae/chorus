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

/// One child's circle: the adults who share one set of boards.
/// Server-only. The boards themselves live in the circle's sync space.
abstract class Circle implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Circle._({
    this.id,
    required this.spaceUuid,
    required this.childName,
    required this.createdBy,
    required this.createdAt,
  });

  factory Circle({
    int? id,
    required _is.UuidValue spaceUuid,
    required String childName,
    required _is.UuidValue createdBy,
    required DateTime createdAt,
  }) = _CircleImpl;

  factory Circle.fromJson(Map<String, dynamic> jsonSerialization) {
    return Circle(
      id: jsonSerialization['id'] as int?,
      spaceUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['spaceUuid'],
      ),
      childName: jsonSerialization['childName'] as String,
      createdBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['createdBy'],
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = CircleTable();

  static const db = CircleRepository._();

  @override
  int? id;

  /// UUID of the circle's shared sync space. Also the circle's public id.
  _is.UuidValue spaceUuid;

  String childName;

  _is.UuidValue createdBy;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Circle]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Circle copyWith({
    int? id,
    _is.UuidValue? spaceUuid,
    String? childName,
    _is.UuidValue? createdBy,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Circle',
      if (id != null) 'id': id,
      'spaceUuid': spaceUuid.toJson(),
      'childName': childName,
      'createdBy': createdBy.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static CircleInclude include() {
    return CircleInclude._();
  }

  static CircleIncludeList includeList({
    _is.WhereExpressionBuilder<CircleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CircleTable>? orderBy,
    _is.OrderByListBuilder<CircleTable>? orderByList,
    CircleInclude? include,
  }) {
    return CircleIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Circle.t),
      orderByList: orderByList?.call(Circle.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CircleImpl extends Circle {
  _CircleImpl({
    int? id,
    required _is.UuidValue spaceUuid,
    required String childName,
    required _is.UuidValue createdBy,
    required DateTime createdAt,
  }) : super._(
         id: id,
         spaceUuid: spaceUuid,
         childName: childName,
         createdBy: createdBy,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Circle]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Circle copyWith({
    Object? id = _Undefined,
    _is.UuidValue? spaceUuid,
    String? childName,
    _is.UuidValue? createdBy,
    DateTime? createdAt,
  }) {
    return Circle(
      id: id is int? ? id : this.id,
      spaceUuid: spaceUuid ?? this.spaceUuid,
      childName: childName ?? this.childName,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CircleUpdateTable extends _is.UpdateTable<CircleTable> {
  CircleUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> spaceUuid(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.spaceUuid,
    value,
  );

  _is.ColumnValue<String, String> childName(String value) => _is.ColumnValue(
    table.childName,
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
}

class CircleTable extends _is.Table<int?> {
  CircleTable({super.tableRelation}) : super(tableName: 'circle') {
    updateTable = CircleUpdateTable(this);
    spaceUuid = _is.ColumnUuid(
      'spaceUuid',
      this,
    );
    childName = _is.ColumnString(
      'childName',
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
  }

  late final CircleUpdateTable updateTable;

  /// UUID of the circle's shared sync space. Also the circle's public id.
  late final _is.ColumnUuid spaceUuid;

  late final _is.ColumnString childName;

  late final _is.ColumnUuid createdBy;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    spaceUuid,
    childName,
    createdBy,
    createdAt,
  ];
}

class CircleInclude extends _is.IncludeObject {
  CircleInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Circle.t;
}

class CircleIncludeList extends _is.IncludeList {
  CircleIncludeList._({
    _is.WhereExpressionBuilder<CircleTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Circle.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Circle.t;
}

class CircleRepository {
  const CircleRepository._();

  /// Returns a list of [Circle]s matching the given query parameters.
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
  Future<List<Circle>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CircleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CircleTable>? orderBy,
    _is.OrderByListBuilder<CircleTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Circle>(
      where: where?.call(Circle.t),
      orderBy: orderBy?.call(Circle.t),
      orderByList: orderByList?.call(Circle.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Circle] matching the given query parameters.
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
  Future<Circle?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CircleTable>? where,
    int? offset,
    _is.OrderByBuilder<CircleTable>? orderBy,
    _is.OrderByListBuilder<CircleTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Circle>(
      where: where?.call(Circle.t),
      orderBy: orderBy?.call(Circle.t),
      orderByList: orderByList?.call(Circle.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Circle] by its [id] or null if no such row exists.
  Future<Circle?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Circle>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Circle]s in the list and returns the inserted rows.
  ///
  /// The returned [Circle]s will have their `id` fields set.
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
  Future<List<Circle>> insert(
    _is.DatabaseSession session,
    List<Circle> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Circle>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Circle] and returns the inserted row.
  ///
  /// The returned [Circle] will have its `id` field set.
  Future<Circle> insertRow(
    _is.DatabaseSession session,
    Circle row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Circle>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Circle]s in the list and returns the resulting rows.
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
  /// The returned [Circle]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Circle>> upsert(
    _is.DatabaseSession session,
    List<Circle> rows, {
    required _is.ColumnSelections<CircleTable> conflictColumns,
    _is.ColumnSelections<CircleTable>? updateColumns,
    _is.WhereExpressionBuilder<CircleTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Circle>(
      rows,
      conflictColumns: conflictColumns(Circle.t),
      updateColumns: updateColumns?.call(Circle.t),
      updateWhere: updateWhere?.call(Circle.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Circle] and returns the resulting row.
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
  /// The returned [Circle] will have its `id` field set.
  Future<Circle?> upsertRow(
    _is.DatabaseSession session,
    Circle row, {
    required _is.ColumnSelections<CircleTable> conflictColumns,
    _is.ColumnSelections<CircleTable>? updateColumns,
    _is.WhereExpressionBuilder<CircleTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Circle>(
      row,
      conflictColumns: conflictColumns(Circle.t),
      updateColumns: updateColumns?.call(Circle.t),
      updateWhere: updateWhere?.call(Circle.t),
      transaction: transaction,
    );
  }

  /// Updates all [Circle]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Circle>> update(
    _is.DatabaseSession session,
    List<Circle> rows, {
    _is.ColumnSelections<CircleTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Circle>(
      rows,
      columns: columns?.call(Circle.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Circle]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Circle> updateRow(
    _is.DatabaseSession session,
    Circle row, {
    _is.ColumnSelections<CircleTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Circle>(
      row,
      columns: columns?.call(Circle.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Circle] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Circle?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<CircleUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Circle>(
      id,
      columnValues: columnValues(Circle.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Circle]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Circle>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<CircleUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<CircleTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CircleTable>? orderBy,
    _is.OrderByListBuilder<CircleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Circle>(
      columnValues: columnValues(Circle.t.updateTable),
      where: where(Circle.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Circle.t),
      orderByList: orderByList?.call(Circle.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Circle]s in the list and returns the deleted rows.
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
  Future<List<Circle>> delete(
    _is.DatabaseSession session,
    List<Circle> rows, {
    _is.OrderByBuilder<CircleTable>? orderBy,
    _is.OrderByListBuilder<CircleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Circle>(
      rows,
      orderBy: orderBy?.call(Circle.t),
      orderByList: orderByList?.call(Circle.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Circle].
  Future<Circle> deleteRow(
    _is.DatabaseSession session,
    Circle row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Circle>(
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
  Future<List<Circle>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CircleTable> where,
    _is.OrderByBuilder<CircleTable>? orderBy,
    _is.OrderByListBuilder<CircleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Circle>(
      where: where(Circle.t),
      orderBy: orderBy?.call(Circle.t),
      orderByList: orderByList?.call(Circle.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CircleTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Circle>(
      where: where?.call(Circle.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Circle] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CircleTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Circle>(
      where: where(Circle.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
