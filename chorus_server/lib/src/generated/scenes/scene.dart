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

/// A picture scene of a circle: a family photo with spots that speak.
/// Server-only and not synced; devices keep their own copy for use with no
/// connection.
abstract class Scene implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Scene._({
    this.id,
    required this.circleSpace,
    required this.name,
    required this.imageHash,
    required this.createdBy,
    required this.createdAt,
    this.archivedAt,
  });

  factory Scene({
    int? id,
    required _is.UuidValue circleSpace,
    required String name,
    required String imageHash,
    required _is.UuidValue createdBy,
    required DateTime createdAt,
    DateTime? archivedAt,
  }) = _SceneImpl;

  factory Scene.fromJson(Map<String, dynamic> jsonSerialization) {
    return Scene(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      name: jsonSerialization['name'] as String,
      imageHash: jsonSerialization['imageHash'] as String,
      createdBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['createdBy'],
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      archivedAt: jsonSerialization['archivedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['archivedAt']),
    );
  }

  static final t = SceneTable();

  static const db = SceneRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  String name;

  /// Lowercase hex SHA-256 of the photo, uploaded like a tile's picture.
  String imageHash;

  _is.UuidValue createdBy;

  DateTime createdAt;

  /// Set when an adult archives the scene; it is then left out of lists.
  DateTime? archivedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Scene]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Scene copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    String? name,
    String? imageHash,
    _is.UuidValue? createdBy,
    DateTime? createdAt,
    DateTime? archivedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Scene',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'name': name,
      'imageHash': imageHash,
      'createdBy': createdBy.toJson(),
      'createdAt': createdAt.toJson(),
      if (archivedAt != null) 'archivedAt': archivedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SceneInclude include() {
    return SceneInclude._();
  }

  static SceneIncludeList includeList({
    _is.WhereExpressionBuilder<SceneTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SceneTable>? orderBy,
    _is.OrderByListBuilder<SceneTable>? orderByList,
    SceneInclude? include,
  }) {
    return SceneIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Scene.t),
      orderByList: orderByList?.call(Scene.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SceneImpl extends Scene {
  _SceneImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required String name,
    required String imageHash,
    required _is.UuidValue createdBy,
    required DateTime createdAt,
    DateTime? archivedAt,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         name: name,
         imageHash: imageHash,
         createdBy: createdBy,
         createdAt: createdAt,
         archivedAt: archivedAt,
       );

  /// Returns a shallow copy of this [Scene]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Scene copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    String? name,
    String? imageHash,
    _is.UuidValue? createdBy,
    DateTime? createdAt,
    Object? archivedAt = _Undefined,
  }) {
    return Scene(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      name: name ?? this.name,
      imageHash: imageHash ?? this.imageHash,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt is DateTime? ? archivedAt : this.archivedAt,
    );
  }
}

class SceneUpdateTable extends _is.UpdateTable<SceneTable> {
  SceneUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleSpace(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.circleSpace,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> imageHash(String value) => _is.ColumnValue(
    table.imageHash,
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

  _is.ColumnValue<DateTime, DateTime> archivedAt(DateTime? value) =>
      _is.ColumnValue(
        table.archivedAt,
        value,
      );
}

class SceneTable extends _is.Table<int?> {
  SceneTable({super.tableRelation}) : super(tableName: 'scene') {
    updateTable = SceneUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    imageHash = _is.ColumnString(
      'imageHash',
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
    archivedAt = _is.ColumnDateTime(
      'archivedAt',
      this,
    );
  }

  late final SceneUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  late final _is.ColumnString name;

  /// Lowercase hex SHA-256 of the photo, uploaded like a tile's picture.
  late final _is.ColumnString imageHash;

  late final _is.ColumnUuid createdBy;

  late final _is.ColumnDateTime createdAt;

  /// Set when an adult archives the scene; it is then left out of lists.
  late final _is.ColumnDateTime archivedAt;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    name,
    imageHash,
    createdBy,
    createdAt,
    archivedAt,
  ];
}

class SceneInclude extends _is.IncludeObject {
  SceneInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Scene.t;
}

class SceneIncludeList extends _is.IncludeList {
  SceneIncludeList._({
    _is.WhereExpressionBuilder<SceneTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Scene.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Scene.t;
}

class SceneRepository {
  const SceneRepository._();

  /// Returns a list of [Scene]s matching the given query parameters.
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
  Future<List<Scene>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SceneTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SceneTable>? orderBy,
    _is.OrderByListBuilder<SceneTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Scene>(
      where: where?.call(Scene.t),
      orderBy: orderBy?.call(Scene.t),
      orderByList: orderByList?.call(Scene.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Scene] matching the given query parameters.
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
  Future<Scene?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SceneTable>? where,
    int? offset,
    _is.OrderByBuilder<SceneTable>? orderBy,
    _is.OrderByListBuilder<SceneTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Scene>(
      where: where?.call(Scene.t),
      orderBy: orderBy?.call(Scene.t),
      orderByList: orderByList?.call(Scene.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Scene] by its [id] or null if no such row exists.
  Future<Scene?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Scene>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Scene]s in the list and returns the inserted rows.
  ///
  /// The returned [Scene]s will have their `id` fields set.
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
  Future<List<Scene>> insert(
    _is.DatabaseSession session,
    List<Scene> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Scene>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Scene] and returns the inserted row.
  ///
  /// The returned [Scene] will have its `id` field set.
  Future<Scene> insertRow(
    _is.DatabaseSession session,
    Scene row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Scene>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Scene]s in the list and returns the resulting rows.
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
  /// The returned [Scene]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Scene>> upsert(
    _is.DatabaseSession session,
    List<Scene> rows, {
    required _is.ColumnSelections<SceneTable> conflictColumns,
    _is.ColumnSelections<SceneTable>? updateColumns,
    _is.WhereExpressionBuilder<SceneTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Scene>(
      rows,
      conflictColumns: conflictColumns(Scene.t),
      updateColumns: updateColumns?.call(Scene.t),
      updateWhere: updateWhere?.call(Scene.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Scene] and returns the resulting row.
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
  /// The returned [Scene] will have its `id` field set.
  Future<Scene?> upsertRow(
    _is.DatabaseSession session,
    Scene row, {
    required _is.ColumnSelections<SceneTable> conflictColumns,
    _is.ColumnSelections<SceneTable>? updateColumns,
    _is.WhereExpressionBuilder<SceneTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Scene>(
      row,
      conflictColumns: conflictColumns(Scene.t),
      updateColumns: updateColumns?.call(Scene.t),
      updateWhere: updateWhere?.call(Scene.t),
      transaction: transaction,
    );
  }

  /// Updates all [Scene]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Scene>> update(
    _is.DatabaseSession session,
    List<Scene> rows, {
    _is.ColumnSelections<SceneTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Scene>(
      rows,
      columns: columns?.call(Scene.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Scene]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Scene> updateRow(
    _is.DatabaseSession session,
    Scene row, {
    _is.ColumnSelections<SceneTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Scene>(
      row,
      columns: columns?.call(Scene.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Scene] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Scene?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SceneUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Scene>(
      id,
      columnValues: columnValues(Scene.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Scene]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Scene>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SceneUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SceneTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SceneTable>? orderBy,
    _is.OrderByListBuilder<SceneTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Scene>(
      columnValues: columnValues(Scene.t.updateTable),
      where: where(Scene.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Scene.t),
      orderByList: orderByList?.call(Scene.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Scene]s in the list and returns the deleted rows.
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
  Future<List<Scene>> delete(
    _is.DatabaseSession session,
    List<Scene> rows, {
    _is.OrderByBuilder<SceneTable>? orderBy,
    _is.OrderByListBuilder<SceneTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Scene>(
      rows,
      orderBy: orderBy?.call(Scene.t),
      orderByList: orderByList?.call(Scene.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Scene].
  Future<Scene> deleteRow(
    _is.DatabaseSession session,
    Scene row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Scene>(
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
  Future<List<Scene>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SceneTable> where,
    _is.OrderByBuilder<SceneTable>? orderBy,
    _is.OrderByListBuilder<SceneTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Scene>(
      where: where(Scene.t),
      orderBy: orderBy?.call(Scene.t),
      orderByList: orderByList?.call(Scene.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SceneTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Scene>(
      where: where?.call(Scene.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Scene] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SceneTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Scene>(
      where: where(Scene.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
