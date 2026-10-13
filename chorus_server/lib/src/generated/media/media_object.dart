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
import '../media/media_kind.dart' as _i2bme9zf;

/// One media file of a circle, named by the SHA-256 of its bytes.
/// Server-only and not synced: tiles carry only the hash.
abstract class MediaObject
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  MediaObject._({
    this.id,
    required this.circleSpace,
    required this.sha256,
    required this.kind,
    required this.path,
    required this.bytes,
    required this.createdBy,
    this.verifiedAt,
  });

  factory MediaObject({
    int? id,
    required _is.UuidValue circleSpace,
    required String sha256,
    required _i2bme9zf.MediaKind kind,
    required String path,
    required int bytes,
    required _is.UuidValue createdBy,
    DateTime? verifiedAt,
  }) = _MediaObjectImpl;

  factory MediaObject.fromJson(Map<String, dynamic> jsonSerialization) {
    return MediaObject(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      sha256: jsonSerialization['sha256'] as String,
      kind: _i2bme9zf.MediaKind.fromJson((jsonSerialization['kind'] as String)),
      path: jsonSerialization['path'] as String,
      bytes: jsonSerialization['bytes'] as int,
      createdBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['createdBy'],
      ),
      verifiedAt: jsonSerialization['verifiedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['verifiedAt']),
    );
  }

  static final t = MediaObjectTable();

  static const db = MediaObjectRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  /// Lowercase hex SHA-256 of the file's bytes.
  String sha256;

  _i2bme9zf.MediaKind kind;

  /// Path in private storage.
  String path;

  /// Size the uploader declared, in bytes.
  int bytes;

  _is.UuidValue createdBy;

  /// Set once the stored bytes were checked against [sha256]. Until then the
  /// file is never handed out.
  DateTime? verifiedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [MediaObject]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MediaObject copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    String? sha256,
    _i2bme9zf.MediaKind? kind,
    String? path,
    int? bytes,
    _is.UuidValue? createdBy,
    DateTime? verifiedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MediaObject',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'sha256': sha256,
      'kind': kind.toJson(),
      'path': path,
      'bytes': bytes,
      'createdBy': createdBy.toJson(),
      if (verifiedAt != null) 'verifiedAt': verifiedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static MediaObjectInclude include() {
    return MediaObjectInclude._();
  }

  static MediaObjectIncludeList includeList({
    _is.WhereExpressionBuilder<MediaObjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MediaObjectTable>? orderBy,
    _is.OrderByListBuilder<MediaObjectTable>? orderByList,
    MediaObjectInclude? include,
  }) {
    return MediaObjectIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MediaObject.t),
      orderByList: orderByList?.call(MediaObject.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MediaObjectImpl extends MediaObject {
  _MediaObjectImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required String sha256,
    required _i2bme9zf.MediaKind kind,
    required String path,
    required int bytes,
    required _is.UuidValue createdBy,
    DateTime? verifiedAt,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         sha256: sha256,
         kind: kind,
         path: path,
         bytes: bytes,
         createdBy: createdBy,
         verifiedAt: verifiedAt,
       );

  /// Returns a shallow copy of this [MediaObject]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MediaObject copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    String? sha256,
    _i2bme9zf.MediaKind? kind,
    String? path,
    int? bytes,
    _is.UuidValue? createdBy,
    Object? verifiedAt = _Undefined,
  }) {
    return MediaObject(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      sha256: sha256 ?? this.sha256,
      kind: kind ?? this.kind,
      path: path ?? this.path,
      bytes: bytes ?? this.bytes,
      createdBy: createdBy ?? this.createdBy,
      verifiedAt: verifiedAt is DateTime? ? verifiedAt : this.verifiedAt,
    );
  }
}

class MediaObjectUpdateTable extends _is.UpdateTable<MediaObjectTable> {
  MediaObjectUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleSpace(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.circleSpace,
    value,
  );

  _is.ColumnValue<String, String> sha256(String value) => _is.ColumnValue(
    table.sha256,
    value,
  );

  _is.ColumnValue<_i2bme9zf.MediaKind, _i2bme9zf.MediaKind> kind(
    _i2bme9zf.MediaKind value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> path(String value) => _is.ColumnValue(
    table.path,
    value,
  );

  _is.ColumnValue<int, int> bytes(int value) => _is.ColumnValue(
    table.bytes,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> createdBy(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.createdBy,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> verifiedAt(DateTime? value) =>
      _is.ColumnValue(
        table.verifiedAt,
        value,
      );
}

class MediaObjectTable extends _is.Table<int?> {
  MediaObjectTable({super.tableRelation}) : super(tableName: 'media_object') {
    updateTable = MediaObjectUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    sha256 = _is.ColumnString(
      'sha256',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    path = _is.ColumnString(
      'path',
      this,
    );
    bytes = _is.ColumnInt(
      'bytes',
      this,
    );
    createdBy = _is.ColumnUuid(
      'createdBy',
      this,
    );
    verifiedAt = _is.ColumnDateTime(
      'verifiedAt',
      this,
    );
  }

  late final MediaObjectUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  /// Lowercase hex SHA-256 of the file's bytes.
  late final _is.ColumnString sha256;

  late final _is.ColumnEnum<_i2bme9zf.MediaKind> kind;

  /// Path in private storage.
  late final _is.ColumnString path;

  /// Size the uploader declared, in bytes.
  late final _is.ColumnInt bytes;

  late final _is.ColumnUuid createdBy;

  /// Set once the stored bytes were checked against [sha256]. Until then the
  /// file is never handed out.
  late final _is.ColumnDateTime verifiedAt;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    sha256,
    kind,
    path,
    bytes,
    createdBy,
    verifiedAt,
  ];
}

class MediaObjectInclude extends _is.IncludeObject {
  MediaObjectInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => MediaObject.t;
}

class MediaObjectIncludeList extends _is.IncludeList {
  MediaObjectIncludeList._({
    _is.WhereExpressionBuilder<MediaObjectTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MediaObject.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => MediaObject.t;
}

class MediaObjectRepository {
  const MediaObjectRepository._();

  /// Returns a list of [MediaObject]s matching the given query parameters.
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
  Future<List<MediaObject>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MediaObjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MediaObjectTable>? orderBy,
    _is.OrderByListBuilder<MediaObjectTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<MediaObject>(
      where: where?.call(MediaObject.t),
      orderBy: orderBy?.call(MediaObject.t),
      orderByList: orderByList?.call(MediaObject.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [MediaObject] matching the given query parameters.
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
  Future<MediaObject?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MediaObjectTable>? where,
    int? offset,
    _is.OrderByBuilder<MediaObjectTable>? orderBy,
    _is.OrderByListBuilder<MediaObjectTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<MediaObject>(
      where: where?.call(MediaObject.t),
      orderBy: orderBy?.call(MediaObject.t),
      orderByList: orderByList?.call(MediaObject.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [MediaObject] by its [id] or null if no such row exists.
  Future<MediaObject?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<MediaObject>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [MediaObject]s in the list and returns the inserted rows.
  ///
  /// The returned [MediaObject]s will have their `id` fields set.
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
  Future<List<MediaObject>> insert(
    _is.DatabaseSession session,
    List<MediaObject> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<MediaObject>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [MediaObject] and returns the inserted row.
  ///
  /// The returned [MediaObject] will have its `id` field set.
  Future<MediaObject> insertRow(
    _is.DatabaseSession session,
    MediaObject row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<MediaObject>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [MediaObject]s in the list and returns the resulting rows.
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
  /// The returned [MediaObject]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MediaObject>> upsert(
    _is.DatabaseSession session,
    List<MediaObject> rows, {
    required _is.ColumnSelections<MediaObjectTable> conflictColumns,
    _is.ColumnSelections<MediaObjectTable>? updateColumns,
    _is.WhereExpressionBuilder<MediaObjectTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<MediaObject>(
      rows,
      conflictColumns: conflictColumns(MediaObject.t),
      updateColumns: updateColumns?.call(MediaObject.t),
      updateWhere: updateWhere?.call(MediaObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [MediaObject] and returns the resulting row.
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
  /// The returned [MediaObject] will have its `id` field set.
  Future<MediaObject?> upsertRow(
    _is.DatabaseSession session,
    MediaObject row, {
    required _is.ColumnSelections<MediaObjectTable> conflictColumns,
    _is.ColumnSelections<MediaObjectTable>? updateColumns,
    _is.WhereExpressionBuilder<MediaObjectTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<MediaObject>(
      row,
      conflictColumns: conflictColumns(MediaObject.t),
      updateColumns: updateColumns?.call(MediaObject.t),
      updateWhere: updateWhere?.call(MediaObject.t),
      transaction: transaction,
    );
  }

  /// Updates all [MediaObject]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MediaObject>> update(
    _is.DatabaseSession session,
    List<MediaObject> rows, {
    _is.ColumnSelections<MediaObjectTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<MediaObject>(
      rows,
      columns: columns?.call(MediaObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [MediaObject]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MediaObject> updateRow(
    _is.DatabaseSession session,
    MediaObject row, {
    _is.ColumnSelections<MediaObjectTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<MediaObject>(
      row,
      columns: columns?.call(MediaObject.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MediaObject] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MediaObject?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<MediaObjectUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<MediaObject>(
      id,
      columnValues: columnValues(MediaObject.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MediaObject]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MediaObject>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MediaObjectUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<MediaObjectTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MediaObjectTable>? orderBy,
    _is.OrderByListBuilder<MediaObjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<MediaObject>(
      columnValues: columnValues(MediaObject.t.updateTable),
      where: where(MediaObject.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MediaObject.t),
      orderByList: orderByList?.call(MediaObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [MediaObject]s in the list and returns the deleted rows.
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
  Future<List<MediaObject>> delete(
    _is.DatabaseSession session,
    List<MediaObject> rows, {
    _is.OrderByBuilder<MediaObjectTable>? orderBy,
    _is.OrderByListBuilder<MediaObjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<MediaObject>(
      rows,
      orderBy: orderBy?.call(MediaObject.t),
      orderByList: orderByList?.call(MediaObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [MediaObject].
  Future<MediaObject> deleteRow(
    _is.DatabaseSession session,
    MediaObject row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MediaObject>(
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
  Future<List<MediaObject>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MediaObjectTable> where,
    _is.OrderByBuilder<MediaObjectTable>? orderBy,
    _is.OrderByListBuilder<MediaObjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<MediaObject>(
      where: where(MediaObject.t),
      orderBy: orderBy?.call(MediaObject.t),
      orderByList: orderByList?.call(MediaObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MediaObjectTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<MediaObject>(
      where: where?.call(MediaObject.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [MediaObject] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MediaObjectTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<MediaObject>(
      where: where(MediaObject.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
