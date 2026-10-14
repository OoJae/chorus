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
import '../printing/snapshot_kind.dart' as _ijgkrnn1;

/// A board as one member's device saw it, kept so it can be printed or
/// opened from a link. Server-only and not synced.
abstract class SharedSnapshot
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  SharedSnapshot._({
    this.id,
    required this.token,
    required this.circleSpace,
    required this.boardJson,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    _ijgkrnn1.SnapshotKind? kind,
  }) : kind = kind ?? _ijgkrnn1.SnapshotKind.print;

  factory SharedSnapshot({
    int? id,
    required String token,
    required _is.UuidValue circleSpace,
    required String boardJson,
    required _is.UuidValue createdBy,
    required DateTime createdAt,
    required DateTime expiresAt,
    _ijgkrnn1.SnapshotKind? kind,
  }) = _SharedSnapshotImpl;

  factory SharedSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return SharedSnapshot(
      id: jsonSerialization['id'] as int?,
      token: jsonSerialization['token'] as String,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      boardJson: jsonSerialization['boardJson'] as String,
      createdBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['createdBy'],
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      kind: jsonSerialization['kind'] == null
          ? null
          : _ijgkrnn1.SnapshotKind.fromJson(
              (jsonSerialization['kind'] as String),
            ),
    );
  }

  static final t = SharedSnapshotTable();

  static const db = SharedSnapshotRepository._();

  @override
  int? id;

  /// Unguessable; the only key to the printable page.
  String token;

  _is.UuidValue circleSpace;

  /// The board and its tiles as JSON, built by the client from its replica.
  String boardJson;

  _is.UuidValue createdBy;

  DateTime createdAt;

  /// Withdrawing a link sets this to the moment it was withdrawn.
  DateTime expiresAt;

  /// Rows from before view-only pages are paper copies.
  _ijgkrnn1.SnapshotKind kind;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [SharedSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SharedSnapshot copyWith({
    int? id,
    String? token,
    _is.UuidValue? circleSpace,
    String? boardJson,
    _is.UuidValue? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    _ijgkrnn1.SnapshotKind? kind,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SharedSnapshot',
      if (id != null) 'id': id,
      'token': token,
      'circleSpace': circleSpace.toJson(),
      'boardJson': boardJson,
      'createdBy': createdBy.toJson(),
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      'kind': kind.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SharedSnapshotInclude include() {
    return SharedSnapshotInclude._();
  }

  static SharedSnapshotIncludeList includeList({
    _is.WhereExpressionBuilder<SharedSnapshotTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SharedSnapshotTable>? orderBy,
    _is.OrderByListBuilder<SharedSnapshotTable>? orderByList,
    SharedSnapshotInclude? include,
  }) {
    return SharedSnapshotIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SharedSnapshot.t),
      orderByList: orderByList?.call(SharedSnapshot.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SharedSnapshotImpl extends SharedSnapshot {
  _SharedSnapshotImpl({
    int? id,
    required String token,
    required _is.UuidValue circleSpace,
    required String boardJson,
    required _is.UuidValue createdBy,
    required DateTime createdAt,
    required DateTime expiresAt,
    _ijgkrnn1.SnapshotKind? kind,
  }) : super._(
         id: id,
         token: token,
         circleSpace: circleSpace,
         boardJson: boardJson,
         createdBy: createdBy,
         createdAt: createdAt,
         expiresAt: expiresAt,
         kind: kind,
       );

  /// Returns a shallow copy of this [SharedSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SharedSnapshot copyWith({
    Object? id = _Undefined,
    String? token,
    _is.UuidValue? circleSpace,
    String? boardJson,
    _is.UuidValue? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    _ijgkrnn1.SnapshotKind? kind,
  }) {
    return SharedSnapshot(
      id: id is int? ? id : this.id,
      token: token ?? this.token,
      circleSpace: circleSpace ?? this.circleSpace,
      boardJson: boardJson ?? this.boardJson,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      kind: kind ?? this.kind,
    );
  }
}

class SharedSnapshotUpdateTable extends _is.UpdateTable<SharedSnapshotTable> {
  SharedSnapshotUpdateTable(super.table);

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

  _is.ColumnValue<String, String> boardJson(String value) => _is.ColumnValue(
    table.boardJson,
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

  _is.ColumnValue<_ijgkrnn1.SnapshotKind, _ijgkrnn1.SnapshotKind> kind(
    _ijgkrnn1.SnapshotKind value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );
}

class SharedSnapshotTable extends _is.Table<int?> {
  SharedSnapshotTable({super.tableRelation})
    : super(tableName: 'shared_snapshot') {
    updateTable = SharedSnapshotUpdateTable(this);
    token = _is.ColumnString(
      'token',
      this,
    );
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    boardJson = _is.ColumnString(
      'boardJson',
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
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
  }

  late final SharedSnapshotUpdateTable updateTable;

  /// Unguessable; the only key to the printable page.
  late final _is.ColumnString token;

  late final _is.ColumnUuid circleSpace;

  /// The board and its tiles as JSON, built by the client from its replica.
  late final _is.ColumnString boardJson;

  late final _is.ColumnUuid createdBy;

  late final _is.ColumnDateTime createdAt;

  /// Withdrawing a link sets this to the moment it was withdrawn.
  late final _is.ColumnDateTime expiresAt;

  /// Rows from before view-only pages are paper copies.
  late final _is.ColumnEnum<_ijgkrnn1.SnapshotKind> kind;

  @override
  List<_is.Column> get columns => [
    id,
    token,
    circleSpace,
    boardJson,
    createdBy,
    createdAt,
    expiresAt,
    kind,
  ];
}

class SharedSnapshotInclude extends _is.IncludeObject {
  SharedSnapshotInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => SharedSnapshot.t;
}

class SharedSnapshotIncludeList extends _is.IncludeList {
  SharedSnapshotIncludeList._({
    _is.WhereExpressionBuilder<SharedSnapshotTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SharedSnapshot.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => SharedSnapshot.t;
}

class SharedSnapshotRepository {
  const SharedSnapshotRepository._();

  /// Returns a list of [SharedSnapshot]s matching the given query parameters.
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
  Future<List<SharedSnapshot>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SharedSnapshotTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SharedSnapshotTable>? orderBy,
    _is.OrderByListBuilder<SharedSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SharedSnapshot>(
      where: where?.call(SharedSnapshot.t),
      orderBy: orderBy?.call(SharedSnapshot.t),
      orderByList: orderByList?.call(SharedSnapshot.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SharedSnapshot] matching the given query parameters.
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
  Future<SharedSnapshot?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SharedSnapshotTable>? where,
    int? offset,
    _is.OrderByBuilder<SharedSnapshotTable>? orderBy,
    _is.OrderByListBuilder<SharedSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SharedSnapshot>(
      where: where?.call(SharedSnapshot.t),
      orderBy: orderBy?.call(SharedSnapshot.t),
      orderByList: orderByList?.call(SharedSnapshot.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SharedSnapshot] by its [id] or null if no such row exists.
  Future<SharedSnapshot?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SharedSnapshot>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SharedSnapshot]s in the list and returns the inserted rows.
  ///
  /// The returned [SharedSnapshot]s will have their `id` fields set.
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
  Future<List<SharedSnapshot>> insert(
    _is.DatabaseSession session,
    List<SharedSnapshot> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SharedSnapshot>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SharedSnapshot] and returns the inserted row.
  ///
  /// The returned [SharedSnapshot] will have its `id` field set.
  Future<SharedSnapshot> insertRow(
    _is.DatabaseSession session,
    SharedSnapshot row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SharedSnapshot>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [SharedSnapshot]s in the list and returns the resulting rows.
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
  /// The returned [SharedSnapshot]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SharedSnapshot>> upsert(
    _is.DatabaseSession session,
    List<SharedSnapshot> rows, {
    required _is.ColumnSelections<SharedSnapshotTable> conflictColumns,
    _is.ColumnSelections<SharedSnapshotTable>? updateColumns,
    _is.WhereExpressionBuilder<SharedSnapshotTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SharedSnapshot>(
      rows,
      conflictColumns: conflictColumns(SharedSnapshot.t),
      updateColumns: updateColumns?.call(SharedSnapshot.t),
      updateWhere: updateWhere?.call(SharedSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SharedSnapshot] and returns the resulting row.
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
  /// The returned [SharedSnapshot] will have its `id` field set.
  Future<SharedSnapshot?> upsertRow(
    _is.DatabaseSession session,
    SharedSnapshot row, {
    required _is.ColumnSelections<SharedSnapshotTable> conflictColumns,
    _is.ColumnSelections<SharedSnapshotTable>? updateColumns,
    _is.WhereExpressionBuilder<SharedSnapshotTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SharedSnapshot>(
      row,
      conflictColumns: conflictColumns(SharedSnapshot.t),
      updateColumns: updateColumns?.call(SharedSnapshot.t),
      updateWhere: updateWhere?.call(SharedSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates all [SharedSnapshot]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SharedSnapshot>> update(
    _is.DatabaseSession session,
    List<SharedSnapshot> rows, {
    _is.ColumnSelections<SharedSnapshotTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SharedSnapshot>(
      rows,
      columns: columns?.call(SharedSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SharedSnapshot]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SharedSnapshot> updateRow(
    _is.DatabaseSession session,
    SharedSnapshot row, {
    _is.ColumnSelections<SharedSnapshotTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SharedSnapshot>(
      row,
      columns: columns?.call(SharedSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SharedSnapshot] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SharedSnapshot?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SharedSnapshotUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SharedSnapshot>(
      id,
      columnValues: columnValues(SharedSnapshot.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SharedSnapshot]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SharedSnapshot>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SharedSnapshotUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SharedSnapshotTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SharedSnapshotTable>? orderBy,
    _is.OrderByListBuilder<SharedSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SharedSnapshot>(
      columnValues: columnValues(SharedSnapshot.t.updateTable),
      where: where(SharedSnapshot.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SharedSnapshot.t),
      orderByList: orderByList?.call(SharedSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SharedSnapshot]s in the list and returns the deleted rows.
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
  Future<List<SharedSnapshot>> delete(
    _is.DatabaseSession session,
    List<SharedSnapshot> rows, {
    _is.OrderByBuilder<SharedSnapshotTable>? orderBy,
    _is.OrderByListBuilder<SharedSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SharedSnapshot>(
      rows,
      orderBy: orderBy?.call(SharedSnapshot.t),
      orderByList: orderByList?.call(SharedSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SharedSnapshot].
  Future<SharedSnapshot> deleteRow(
    _is.DatabaseSession session,
    SharedSnapshot row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SharedSnapshot>(
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
  Future<List<SharedSnapshot>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SharedSnapshotTable> where,
    _is.OrderByBuilder<SharedSnapshotTable>? orderBy,
    _is.OrderByListBuilder<SharedSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SharedSnapshot>(
      where: where(SharedSnapshot.t),
      orderBy: orderBy?.call(SharedSnapshot.t),
      orderByList: orderByList?.call(SharedSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SharedSnapshotTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SharedSnapshot>(
      where: where?.call(SharedSnapshot.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SharedSnapshot] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SharedSnapshotTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SharedSnapshot>(
      where: where(SharedSnapshot.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
