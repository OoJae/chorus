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

/// Ideas the model gave for one photo, kept for a day so asking again costs
/// nothing. Server-only; holds words, never the photo.
abstract class PhotoIdeaCache
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  PhotoIdeaCache._({
    this.id,
    required this.circleSpace,
    required this.imageSha256,
    required this.locale,
    required this.ideasJson,
    required this.createdAt,
  });

  factory PhotoIdeaCache({
    int? id,
    required _is.UuidValue circleSpace,
    required String imageSha256,
    required String locale,
    required String ideasJson,
    required DateTime createdAt,
  }) = _PhotoIdeaCacheImpl;

  factory PhotoIdeaCache.fromJson(Map<String, dynamic> jsonSerialization) {
    return PhotoIdeaCache(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      imageSha256: jsonSerialization['imageSha256'] as String,
      locale: jsonSerialization['locale'] as String,
      ideasJson: jsonSerialization['ideasJson'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = PhotoIdeaCacheTable();

  static const db = PhotoIdeaCacheRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  String imageSha256;

  String locale;

  /// The ideas as a JSON list of WordSuggestion objects.
  String ideasJson;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [PhotoIdeaCache]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PhotoIdeaCache copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    String? imageSha256,
    String? locale,
    String? ideasJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PhotoIdeaCache',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'imageSha256': imageSha256,
      'locale': locale,
      'ideasJson': ideasJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PhotoIdeaCacheInclude include() {
    return PhotoIdeaCacheInclude._();
  }

  static PhotoIdeaCacheIncludeList includeList({
    _is.WhereExpressionBuilder<PhotoIdeaCacheTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PhotoIdeaCacheTable>? orderBy,
    _is.OrderByListBuilder<PhotoIdeaCacheTable>? orderByList,
    PhotoIdeaCacheInclude? include,
  }) {
    return PhotoIdeaCacheIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PhotoIdeaCache.t),
      orderByList: orderByList?.call(PhotoIdeaCache.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PhotoIdeaCacheImpl extends PhotoIdeaCache {
  _PhotoIdeaCacheImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required String imageSha256,
    required String locale,
    required String ideasJson,
    required DateTime createdAt,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         imageSha256: imageSha256,
         locale: locale,
         ideasJson: ideasJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PhotoIdeaCache]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PhotoIdeaCache copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    String? imageSha256,
    String? locale,
    String? ideasJson,
    DateTime? createdAt,
  }) {
    return PhotoIdeaCache(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      imageSha256: imageSha256 ?? this.imageSha256,
      locale: locale ?? this.locale,
      ideasJson: ideasJson ?? this.ideasJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PhotoIdeaCacheUpdateTable extends _is.UpdateTable<PhotoIdeaCacheTable> {
  PhotoIdeaCacheUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleSpace(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.circleSpace,
    value,
  );

  _is.ColumnValue<String, String> imageSha256(String value) => _is.ColumnValue(
    table.imageSha256,
    value,
  );

  _is.ColumnValue<String, String> locale(String value) => _is.ColumnValue(
    table.locale,
    value,
  );

  _is.ColumnValue<String, String> ideasJson(String value) => _is.ColumnValue(
    table.ideasJson,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class PhotoIdeaCacheTable extends _is.Table<int?> {
  PhotoIdeaCacheTable({super.tableRelation})
    : super(tableName: 'photo_idea_cache') {
    updateTable = PhotoIdeaCacheUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    imageSha256 = _is.ColumnString(
      'imageSha256',
      this,
    );
    locale = _is.ColumnString(
      'locale',
      this,
    );
    ideasJson = _is.ColumnString(
      'ideasJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final PhotoIdeaCacheUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  late final _is.ColumnString imageSha256;

  late final _is.ColumnString locale;

  /// The ideas as a JSON list of WordSuggestion objects.
  late final _is.ColumnString ideasJson;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    imageSha256,
    locale,
    ideasJson,
    createdAt,
  ];
}

class PhotoIdeaCacheInclude extends _is.IncludeObject {
  PhotoIdeaCacheInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => PhotoIdeaCache.t;
}

class PhotoIdeaCacheIncludeList extends _is.IncludeList {
  PhotoIdeaCacheIncludeList._({
    _is.WhereExpressionBuilder<PhotoIdeaCacheTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PhotoIdeaCache.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => PhotoIdeaCache.t;
}

class PhotoIdeaCacheRepository {
  const PhotoIdeaCacheRepository._();

  /// Returns a list of [PhotoIdeaCache]s matching the given query parameters.
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
  Future<List<PhotoIdeaCache>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PhotoIdeaCacheTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PhotoIdeaCacheTable>? orderBy,
    _is.OrderByListBuilder<PhotoIdeaCacheTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PhotoIdeaCache>(
      where: where?.call(PhotoIdeaCache.t),
      orderBy: orderBy?.call(PhotoIdeaCache.t),
      orderByList: orderByList?.call(PhotoIdeaCache.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PhotoIdeaCache] matching the given query parameters.
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
  Future<PhotoIdeaCache?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PhotoIdeaCacheTable>? where,
    int? offset,
    _is.OrderByBuilder<PhotoIdeaCacheTable>? orderBy,
    _is.OrderByListBuilder<PhotoIdeaCacheTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PhotoIdeaCache>(
      where: where?.call(PhotoIdeaCache.t),
      orderBy: orderBy?.call(PhotoIdeaCache.t),
      orderByList: orderByList?.call(PhotoIdeaCache.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PhotoIdeaCache] by its [id] or null if no such row exists.
  Future<PhotoIdeaCache?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PhotoIdeaCache>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PhotoIdeaCache]s in the list and returns the inserted rows.
  ///
  /// The returned [PhotoIdeaCache]s will have their `id` fields set.
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
  Future<List<PhotoIdeaCache>> insert(
    _is.DatabaseSession session,
    List<PhotoIdeaCache> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PhotoIdeaCache>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PhotoIdeaCache] and returns the inserted row.
  ///
  /// The returned [PhotoIdeaCache] will have its `id` field set.
  Future<PhotoIdeaCache> insertRow(
    _is.DatabaseSession session,
    PhotoIdeaCache row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PhotoIdeaCache>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PhotoIdeaCache]s in the list and returns the resulting rows.
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
  /// The returned [PhotoIdeaCache]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PhotoIdeaCache>> upsert(
    _is.DatabaseSession session,
    List<PhotoIdeaCache> rows, {
    required _is.ColumnSelections<PhotoIdeaCacheTable> conflictColumns,
    _is.ColumnSelections<PhotoIdeaCacheTable>? updateColumns,
    _is.WhereExpressionBuilder<PhotoIdeaCacheTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PhotoIdeaCache>(
      rows,
      conflictColumns: conflictColumns(PhotoIdeaCache.t),
      updateColumns: updateColumns?.call(PhotoIdeaCache.t),
      updateWhere: updateWhere?.call(PhotoIdeaCache.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PhotoIdeaCache] and returns the resulting row.
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
  /// The returned [PhotoIdeaCache] will have its `id` field set.
  Future<PhotoIdeaCache?> upsertRow(
    _is.DatabaseSession session,
    PhotoIdeaCache row, {
    required _is.ColumnSelections<PhotoIdeaCacheTable> conflictColumns,
    _is.ColumnSelections<PhotoIdeaCacheTable>? updateColumns,
    _is.WhereExpressionBuilder<PhotoIdeaCacheTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PhotoIdeaCache>(
      row,
      conflictColumns: conflictColumns(PhotoIdeaCache.t),
      updateColumns: updateColumns?.call(PhotoIdeaCache.t),
      updateWhere: updateWhere?.call(PhotoIdeaCache.t),
      transaction: transaction,
    );
  }

  /// Updates all [PhotoIdeaCache]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PhotoIdeaCache>> update(
    _is.DatabaseSession session,
    List<PhotoIdeaCache> rows, {
    _is.ColumnSelections<PhotoIdeaCacheTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PhotoIdeaCache>(
      rows,
      columns: columns?.call(PhotoIdeaCache.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PhotoIdeaCache]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PhotoIdeaCache> updateRow(
    _is.DatabaseSession session,
    PhotoIdeaCache row, {
    _is.ColumnSelections<PhotoIdeaCacheTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PhotoIdeaCache>(
      row,
      columns: columns?.call(PhotoIdeaCache.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PhotoIdeaCache] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PhotoIdeaCache?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PhotoIdeaCacheUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PhotoIdeaCache>(
      id,
      columnValues: columnValues(PhotoIdeaCache.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PhotoIdeaCache]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PhotoIdeaCache>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PhotoIdeaCacheUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PhotoIdeaCacheTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PhotoIdeaCacheTable>? orderBy,
    _is.OrderByListBuilder<PhotoIdeaCacheTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PhotoIdeaCache>(
      columnValues: columnValues(PhotoIdeaCache.t.updateTable),
      where: where(PhotoIdeaCache.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PhotoIdeaCache.t),
      orderByList: orderByList?.call(PhotoIdeaCache.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PhotoIdeaCache]s in the list and returns the deleted rows.
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
  Future<List<PhotoIdeaCache>> delete(
    _is.DatabaseSession session,
    List<PhotoIdeaCache> rows, {
    _is.OrderByBuilder<PhotoIdeaCacheTable>? orderBy,
    _is.OrderByListBuilder<PhotoIdeaCacheTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PhotoIdeaCache>(
      rows,
      orderBy: orderBy?.call(PhotoIdeaCache.t),
      orderByList: orderByList?.call(PhotoIdeaCache.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PhotoIdeaCache].
  Future<PhotoIdeaCache> deleteRow(
    _is.DatabaseSession session,
    PhotoIdeaCache row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PhotoIdeaCache>(
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
  Future<List<PhotoIdeaCache>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PhotoIdeaCacheTable> where,
    _is.OrderByBuilder<PhotoIdeaCacheTable>? orderBy,
    _is.OrderByListBuilder<PhotoIdeaCacheTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PhotoIdeaCache>(
      where: where(PhotoIdeaCache.t),
      orderBy: orderBy?.call(PhotoIdeaCache.t),
      orderByList: orderByList?.call(PhotoIdeaCache.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PhotoIdeaCacheTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PhotoIdeaCache>(
      where: where?.call(PhotoIdeaCache.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PhotoIdeaCache] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PhotoIdeaCacheTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PhotoIdeaCache>(
      where: where(PhotoIdeaCache.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
