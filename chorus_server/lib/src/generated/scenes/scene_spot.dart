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

/// One spot of a scene. Positions are fractions (0 to 1) of the photo's
/// width and height. Server-only and not synced.
abstract class SceneSpot
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  SceneSpot._({
    this.id,
    required this.sceneId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
    this.speech,
    required this.position,
  });

  factory SceneSpot({
    int? id,
    required int sceneId,
    required double x,
    required double y,
    required double width,
    required double height,
    required String label,
    String? speech,
    required int position,
  }) = _SceneSpotImpl;

  factory SceneSpot.fromJson(Map<String, dynamic> jsonSerialization) {
    return SceneSpot(
      id: jsonSerialization['id'] as int?,
      sceneId: jsonSerialization['sceneId'] as int,
      x: (jsonSerialization['x'] as num).toDouble(),
      y: (jsonSerialization['y'] as num).toDouble(),
      width: (jsonSerialization['width'] as num).toDouble(),
      height: (jsonSerialization['height'] as num).toDouble(),
      label: jsonSerialization['label'] as String,
      speech: jsonSerialization['speech'] as String?,
      position: jsonSerialization['position'] as int,
    );
  }

  static final t = SceneSpotTable();

  static const db = SceneSpotRepository._();

  @override
  int? id;

  int sceneId;

  double x;

  double y;

  double width;

  double height;

  String label;

  /// What is spoken; the label is spoken when this is null.
  String? speech;

  /// Order the spots were drawn in, from 0.
  int position;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [SceneSpot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SceneSpot copyWith({
    int? id,
    int? sceneId,
    double? x,
    double? y,
    double? width,
    double? height,
    String? label,
    String? speech,
    int? position,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SceneSpot',
      if (id != null) 'id': id,
      'sceneId': sceneId,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'label': label,
      if (speech != null) 'speech': speech,
      'position': position,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SceneSpotInclude include() {
    return SceneSpotInclude._();
  }

  static SceneSpotIncludeList includeList({
    _is.WhereExpressionBuilder<SceneSpotTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SceneSpotTable>? orderBy,
    _is.OrderByListBuilder<SceneSpotTable>? orderByList,
    SceneSpotInclude? include,
  }) {
    return SceneSpotIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SceneSpot.t),
      orderByList: orderByList?.call(SceneSpot.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SceneSpotImpl extends SceneSpot {
  _SceneSpotImpl({
    int? id,
    required int sceneId,
    required double x,
    required double y,
    required double width,
    required double height,
    required String label,
    String? speech,
    required int position,
  }) : super._(
         id: id,
         sceneId: sceneId,
         x: x,
         y: y,
         width: width,
         height: height,
         label: label,
         speech: speech,
         position: position,
       );

  /// Returns a shallow copy of this [SceneSpot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SceneSpot copyWith({
    Object? id = _Undefined,
    int? sceneId,
    double? x,
    double? y,
    double? width,
    double? height,
    String? label,
    Object? speech = _Undefined,
    int? position,
  }) {
    return SceneSpot(
      id: id is int? ? id : this.id,
      sceneId: sceneId ?? this.sceneId,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      label: label ?? this.label,
      speech: speech is String? ? speech : this.speech,
      position: position ?? this.position,
    );
  }
}

class SceneSpotUpdateTable extends _is.UpdateTable<SceneSpotTable> {
  SceneSpotUpdateTable(super.table);

  _is.ColumnValue<int, int> sceneId(int value) => _is.ColumnValue(
    table.sceneId,
    value,
  );

  _is.ColumnValue<double, double> x(double value) => _is.ColumnValue(
    table.x,
    value,
  );

  _is.ColumnValue<double, double> y(double value) => _is.ColumnValue(
    table.y,
    value,
  );

  _is.ColumnValue<double, double> width(double value) => _is.ColumnValue(
    table.width,
    value,
  );

  _is.ColumnValue<double, double> height(double value) => _is.ColumnValue(
    table.height,
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

  _is.ColumnValue<int, int> position(int value) => _is.ColumnValue(
    table.position,
    value,
  );
}

class SceneSpotTable extends _is.Table<int?> {
  SceneSpotTable({super.tableRelation}) : super(tableName: 'scene_spot') {
    updateTable = SceneSpotUpdateTable(this);
    sceneId = _is.ColumnInt(
      'sceneId',
      this,
    );
    x = _is.ColumnDouble(
      'x',
      this,
    );
    y = _is.ColumnDouble(
      'y',
      this,
    );
    width = _is.ColumnDouble(
      'width',
      this,
    );
    height = _is.ColumnDouble(
      'height',
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
    position = _is.ColumnInt(
      'position',
      this,
    );
  }

  late final SceneSpotUpdateTable updateTable;

  late final _is.ColumnInt sceneId;

  late final _is.ColumnDouble x;

  late final _is.ColumnDouble y;

  late final _is.ColumnDouble width;

  late final _is.ColumnDouble height;

  late final _is.ColumnString label;

  /// What is spoken; the label is spoken when this is null.
  late final _is.ColumnString speech;

  /// Order the spots were drawn in, from 0.
  late final _is.ColumnInt position;

  @override
  List<_is.Column> get columns => [
    id,
    sceneId,
    x,
    y,
    width,
    height,
    label,
    speech,
    position,
  ];
}

class SceneSpotInclude extends _is.IncludeObject {
  SceneSpotInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => SceneSpot.t;
}

class SceneSpotIncludeList extends _is.IncludeList {
  SceneSpotIncludeList._({
    _is.WhereExpressionBuilder<SceneSpotTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SceneSpot.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => SceneSpot.t;
}

class SceneSpotRepository {
  const SceneSpotRepository._();

  /// Returns a list of [SceneSpot]s matching the given query parameters.
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
  Future<List<SceneSpot>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SceneSpotTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SceneSpotTable>? orderBy,
    _is.OrderByListBuilder<SceneSpotTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SceneSpot>(
      where: where?.call(SceneSpot.t),
      orderBy: orderBy?.call(SceneSpot.t),
      orderByList: orderByList?.call(SceneSpot.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SceneSpot] matching the given query parameters.
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
  Future<SceneSpot?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SceneSpotTable>? where,
    int? offset,
    _is.OrderByBuilder<SceneSpotTable>? orderBy,
    _is.OrderByListBuilder<SceneSpotTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SceneSpot>(
      where: where?.call(SceneSpot.t),
      orderBy: orderBy?.call(SceneSpot.t),
      orderByList: orderByList?.call(SceneSpot.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SceneSpot] by its [id] or null if no such row exists.
  Future<SceneSpot?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SceneSpot>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SceneSpot]s in the list and returns the inserted rows.
  ///
  /// The returned [SceneSpot]s will have their `id` fields set.
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
  Future<List<SceneSpot>> insert(
    _is.DatabaseSession session,
    List<SceneSpot> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SceneSpot>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SceneSpot] and returns the inserted row.
  ///
  /// The returned [SceneSpot] will have its `id` field set.
  Future<SceneSpot> insertRow(
    _is.DatabaseSession session,
    SceneSpot row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SceneSpot>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [SceneSpot]s in the list and returns the resulting rows.
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
  /// The returned [SceneSpot]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SceneSpot>> upsert(
    _is.DatabaseSession session,
    List<SceneSpot> rows, {
    required _is.ColumnSelections<SceneSpotTable> conflictColumns,
    _is.ColumnSelections<SceneSpotTable>? updateColumns,
    _is.WhereExpressionBuilder<SceneSpotTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SceneSpot>(
      rows,
      conflictColumns: conflictColumns(SceneSpot.t),
      updateColumns: updateColumns?.call(SceneSpot.t),
      updateWhere: updateWhere?.call(SceneSpot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SceneSpot] and returns the resulting row.
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
  /// The returned [SceneSpot] will have its `id` field set.
  Future<SceneSpot?> upsertRow(
    _is.DatabaseSession session,
    SceneSpot row, {
    required _is.ColumnSelections<SceneSpotTable> conflictColumns,
    _is.ColumnSelections<SceneSpotTable>? updateColumns,
    _is.WhereExpressionBuilder<SceneSpotTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SceneSpot>(
      row,
      conflictColumns: conflictColumns(SceneSpot.t),
      updateColumns: updateColumns?.call(SceneSpot.t),
      updateWhere: updateWhere?.call(SceneSpot.t),
      transaction: transaction,
    );
  }

  /// Updates all [SceneSpot]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SceneSpot>> update(
    _is.DatabaseSession session,
    List<SceneSpot> rows, {
    _is.ColumnSelections<SceneSpotTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SceneSpot>(
      rows,
      columns: columns?.call(SceneSpot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SceneSpot]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SceneSpot> updateRow(
    _is.DatabaseSession session,
    SceneSpot row, {
    _is.ColumnSelections<SceneSpotTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SceneSpot>(
      row,
      columns: columns?.call(SceneSpot.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SceneSpot] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SceneSpot?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SceneSpotUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SceneSpot>(
      id,
      columnValues: columnValues(SceneSpot.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SceneSpot]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SceneSpot>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SceneSpotUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SceneSpotTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SceneSpotTable>? orderBy,
    _is.OrderByListBuilder<SceneSpotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SceneSpot>(
      columnValues: columnValues(SceneSpot.t.updateTable),
      where: where(SceneSpot.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SceneSpot.t),
      orderByList: orderByList?.call(SceneSpot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SceneSpot]s in the list and returns the deleted rows.
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
  Future<List<SceneSpot>> delete(
    _is.DatabaseSession session,
    List<SceneSpot> rows, {
    _is.OrderByBuilder<SceneSpotTable>? orderBy,
    _is.OrderByListBuilder<SceneSpotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SceneSpot>(
      rows,
      orderBy: orderBy?.call(SceneSpot.t),
      orderByList: orderByList?.call(SceneSpot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SceneSpot].
  Future<SceneSpot> deleteRow(
    _is.DatabaseSession session,
    SceneSpot row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SceneSpot>(
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
  Future<List<SceneSpot>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SceneSpotTable> where,
    _is.OrderByBuilder<SceneSpotTable>? orderBy,
    _is.OrderByListBuilder<SceneSpotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SceneSpot>(
      where: where(SceneSpot.t),
      orderBy: orderBy?.call(SceneSpot.t),
      orderByList: orderByList?.call(SceneSpot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SceneSpotTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SceneSpot>(
      where: where?.call(SceneSpot.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SceneSpot] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SceneSpotTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SceneSpot>(
      where: where(SceneSpot.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
