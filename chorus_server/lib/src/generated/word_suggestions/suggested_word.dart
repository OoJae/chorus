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

/// A word someone in the circle suggested for the board. Server-only, not
/// synced: nothing reaches the board until an editor adds it there.
abstract class SuggestedWord
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  SuggestedWord._({
    this.id,
    required this.circleSpace,
    required this.label,
    this.speech,
    this.colorKey,
    required this.suggestedBy,
    required this.suggestedByName,
    required this.source,
    required this.createdAt,
    this.resolvedAt,
    this.resolution,
    this.resolvedBy,
  });

  factory SuggestedWord({
    int? id,
    required _is.UuidValue circleSpace,
    required String label,
    String? speech,
    String? colorKey,
    required _is.UuidValue suggestedBy,
    required String suggestedByName,
    required String source,
    required DateTime createdAt,
    DateTime? resolvedAt,
    String? resolution,
    _is.UuidValue? resolvedBy,
  }) = _SuggestedWordImpl;

  factory SuggestedWord.fromJson(Map<String, dynamic> jsonSerialization) {
    return SuggestedWord(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      label: jsonSerialization['label'] as String,
      speech: jsonSerialization['speech'] as String?,
      colorKey: jsonSerialization['colorKey'] as String?,
      suggestedBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['suggestedBy'],
      ),
      suggestedByName: jsonSerialization['suggestedByName'] as String,
      source: jsonSerialization['source'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      resolvedAt: jsonSerialization['resolvedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['resolvedAt']),
      resolution: jsonSerialization['resolution'] as String?,
      resolvedBy: jsonSerialization['resolvedBy'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['resolvedBy'],
            ),
    );
  }

  static final t = SuggestedWordTable();

  static const db = SuggestedWordRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  String label;

  String? speech;

  String? colorKey;

  _is.UuidValue suggestedBy;

  String suggestedByName;

  /// `person` (a read-only member) or `photo` (a photo suggestion).
  String source;

  DateTime createdAt;

  /// When an editor answered it, and how: `added` or `declined`.
  DateTime? resolvedAt;

  String? resolution;

  _is.UuidValue? resolvedBy;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [SuggestedWord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SuggestedWord copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    String? label,
    String? speech,
    String? colorKey,
    _is.UuidValue? suggestedBy,
    String? suggestedByName,
    String? source,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolution,
    _is.UuidValue? resolvedBy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SuggestedWord',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'label': label,
      if (speech != null) 'speech': speech,
      if (colorKey != null) 'colorKey': colorKey,
      'suggestedBy': suggestedBy.toJson(),
      'suggestedByName': suggestedByName,
      'source': source,
      'createdAt': createdAt.toJson(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
      if (resolution != null) 'resolution': resolution,
      if (resolvedBy != null) 'resolvedBy': resolvedBy?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SuggestedWordInclude include() {
    return SuggestedWordInclude._();
  }

  static SuggestedWordIncludeList includeList({
    _is.WhereExpressionBuilder<SuggestedWordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SuggestedWordTable>? orderBy,
    _is.OrderByListBuilder<SuggestedWordTable>? orderByList,
    SuggestedWordInclude? include,
  }) {
    return SuggestedWordIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SuggestedWord.t),
      orderByList: orderByList?.call(SuggestedWord.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SuggestedWordImpl extends SuggestedWord {
  _SuggestedWordImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required String label,
    String? speech,
    String? colorKey,
    required _is.UuidValue suggestedBy,
    required String suggestedByName,
    required String source,
    required DateTime createdAt,
    DateTime? resolvedAt,
    String? resolution,
    _is.UuidValue? resolvedBy,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         label: label,
         speech: speech,
         colorKey: colorKey,
         suggestedBy: suggestedBy,
         suggestedByName: suggestedByName,
         source: source,
         createdAt: createdAt,
         resolvedAt: resolvedAt,
         resolution: resolution,
         resolvedBy: resolvedBy,
       );

  /// Returns a shallow copy of this [SuggestedWord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SuggestedWord copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    String? label,
    Object? speech = _Undefined,
    Object? colorKey = _Undefined,
    _is.UuidValue? suggestedBy,
    String? suggestedByName,
    String? source,
    DateTime? createdAt,
    Object? resolvedAt = _Undefined,
    Object? resolution = _Undefined,
    Object? resolvedBy = _Undefined,
  }) {
    return SuggestedWord(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      label: label ?? this.label,
      speech: speech is String? ? speech : this.speech,
      colorKey: colorKey is String? ? colorKey : this.colorKey,
      suggestedBy: suggestedBy ?? this.suggestedBy,
      suggestedByName: suggestedByName ?? this.suggestedByName,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt is DateTime? ? resolvedAt : this.resolvedAt,
      resolution: resolution is String? ? resolution : this.resolution,
      resolvedBy: resolvedBy is _is.UuidValue? ? resolvedBy : this.resolvedBy,
    );
  }
}

class SuggestedWordUpdateTable extends _is.UpdateTable<SuggestedWordTable> {
  SuggestedWordUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleSpace(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.circleSpace,
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

  _is.ColumnValue<String, String> colorKey(String? value) => _is.ColumnValue(
    table.colorKey,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> suggestedBy(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.suggestedBy,
    value,
  );

  _is.ColumnValue<String, String> suggestedByName(String value) =>
      _is.ColumnValue(
        table.suggestedByName,
        value,
      );

  _is.ColumnValue<String, String> source(String value) => _is.ColumnValue(
    table.source,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> resolvedAt(DateTime? value) =>
      _is.ColumnValue(
        table.resolvedAt,
        value,
      );

  _is.ColumnValue<String, String> resolution(String? value) => _is.ColumnValue(
    table.resolution,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> resolvedBy(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.resolvedBy,
    value,
  );
}

class SuggestedWordTable extends _is.Table<int?> {
  SuggestedWordTable({super.tableRelation})
    : super(tableName: 'word_suggestion') {
    updateTable = SuggestedWordUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
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
    colorKey = _is.ColumnString(
      'colorKey',
      this,
    );
    suggestedBy = _is.ColumnUuid(
      'suggestedBy',
      this,
    );
    suggestedByName = _is.ColumnString(
      'suggestedByName',
      this,
    );
    source = _is.ColumnString(
      'source',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    resolvedAt = _is.ColumnDateTime(
      'resolvedAt',
      this,
    );
    resolution = _is.ColumnString(
      'resolution',
      this,
    );
    resolvedBy = _is.ColumnUuid(
      'resolvedBy',
      this,
    );
  }

  late final SuggestedWordUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  late final _is.ColumnString label;

  late final _is.ColumnString speech;

  late final _is.ColumnString colorKey;

  late final _is.ColumnUuid suggestedBy;

  late final _is.ColumnString suggestedByName;

  /// `person` (a read-only member) or `photo` (a photo suggestion).
  late final _is.ColumnString source;

  late final _is.ColumnDateTime createdAt;

  /// When an editor answered it, and how: `added` or `declined`.
  late final _is.ColumnDateTime resolvedAt;

  late final _is.ColumnString resolution;

  late final _is.ColumnUuid resolvedBy;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    label,
    speech,
    colorKey,
    suggestedBy,
    suggestedByName,
    source,
    createdAt,
    resolvedAt,
    resolution,
    resolvedBy,
  ];
}

class SuggestedWordInclude extends _is.IncludeObject {
  SuggestedWordInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => SuggestedWord.t;
}

class SuggestedWordIncludeList extends _is.IncludeList {
  SuggestedWordIncludeList._({
    _is.WhereExpressionBuilder<SuggestedWordTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SuggestedWord.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => SuggestedWord.t;
}

class SuggestedWordRepository {
  const SuggestedWordRepository._();

  /// Returns a list of [SuggestedWord]s matching the given query parameters.
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
  Future<List<SuggestedWord>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SuggestedWordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SuggestedWordTable>? orderBy,
    _is.OrderByListBuilder<SuggestedWordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SuggestedWord>(
      where: where?.call(SuggestedWord.t),
      orderBy: orderBy?.call(SuggestedWord.t),
      orderByList: orderByList?.call(SuggestedWord.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SuggestedWord] matching the given query parameters.
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
  Future<SuggestedWord?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SuggestedWordTable>? where,
    int? offset,
    _is.OrderByBuilder<SuggestedWordTable>? orderBy,
    _is.OrderByListBuilder<SuggestedWordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SuggestedWord>(
      where: where?.call(SuggestedWord.t),
      orderBy: orderBy?.call(SuggestedWord.t),
      orderByList: orderByList?.call(SuggestedWord.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SuggestedWord] by its [id] or null if no such row exists.
  Future<SuggestedWord?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SuggestedWord>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SuggestedWord]s in the list and returns the inserted rows.
  ///
  /// The returned [SuggestedWord]s will have their `id` fields set.
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
  Future<List<SuggestedWord>> insert(
    _is.DatabaseSession session,
    List<SuggestedWord> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SuggestedWord>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SuggestedWord] and returns the inserted row.
  ///
  /// The returned [SuggestedWord] will have its `id` field set.
  Future<SuggestedWord> insertRow(
    _is.DatabaseSession session,
    SuggestedWord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SuggestedWord>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [SuggestedWord]s in the list and returns the resulting rows.
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
  /// The returned [SuggestedWord]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SuggestedWord>> upsert(
    _is.DatabaseSession session,
    List<SuggestedWord> rows, {
    required _is.ColumnSelections<SuggestedWordTable> conflictColumns,
    _is.ColumnSelections<SuggestedWordTable>? updateColumns,
    _is.WhereExpressionBuilder<SuggestedWordTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SuggestedWord>(
      rows,
      conflictColumns: conflictColumns(SuggestedWord.t),
      updateColumns: updateColumns?.call(SuggestedWord.t),
      updateWhere: updateWhere?.call(SuggestedWord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SuggestedWord] and returns the resulting row.
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
  /// The returned [SuggestedWord] will have its `id` field set.
  Future<SuggestedWord?> upsertRow(
    _is.DatabaseSession session,
    SuggestedWord row, {
    required _is.ColumnSelections<SuggestedWordTable> conflictColumns,
    _is.ColumnSelections<SuggestedWordTable>? updateColumns,
    _is.WhereExpressionBuilder<SuggestedWordTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SuggestedWord>(
      row,
      conflictColumns: conflictColumns(SuggestedWord.t),
      updateColumns: updateColumns?.call(SuggestedWord.t),
      updateWhere: updateWhere?.call(SuggestedWord.t),
      transaction: transaction,
    );
  }

  /// Updates all [SuggestedWord]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SuggestedWord>> update(
    _is.DatabaseSession session,
    List<SuggestedWord> rows, {
    _is.ColumnSelections<SuggestedWordTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SuggestedWord>(
      rows,
      columns: columns?.call(SuggestedWord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SuggestedWord]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SuggestedWord> updateRow(
    _is.DatabaseSession session,
    SuggestedWord row, {
    _is.ColumnSelections<SuggestedWordTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SuggestedWord>(
      row,
      columns: columns?.call(SuggestedWord.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SuggestedWord] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SuggestedWord?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SuggestedWordUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SuggestedWord>(
      id,
      columnValues: columnValues(SuggestedWord.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SuggestedWord]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SuggestedWord>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SuggestedWordUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SuggestedWordTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SuggestedWordTable>? orderBy,
    _is.OrderByListBuilder<SuggestedWordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SuggestedWord>(
      columnValues: columnValues(SuggestedWord.t.updateTable),
      where: where(SuggestedWord.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SuggestedWord.t),
      orderByList: orderByList?.call(SuggestedWord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SuggestedWord]s in the list and returns the deleted rows.
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
  Future<List<SuggestedWord>> delete(
    _is.DatabaseSession session,
    List<SuggestedWord> rows, {
    _is.OrderByBuilder<SuggestedWordTable>? orderBy,
    _is.OrderByListBuilder<SuggestedWordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SuggestedWord>(
      rows,
      orderBy: orderBy?.call(SuggestedWord.t),
      orderByList: orderByList?.call(SuggestedWord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SuggestedWord].
  Future<SuggestedWord> deleteRow(
    _is.DatabaseSession session,
    SuggestedWord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SuggestedWord>(
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
  Future<List<SuggestedWord>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SuggestedWordTable> where,
    _is.OrderByBuilder<SuggestedWordTable>? orderBy,
    _is.OrderByListBuilder<SuggestedWordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SuggestedWord>(
      where: where(SuggestedWord.t),
      orderBy: orderBy?.call(SuggestedWord.t),
      orderByList: orderByList?.call(SuggestedWord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SuggestedWordTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SuggestedWord>(
      where: where?.call(SuggestedWord.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SuggestedWord] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SuggestedWordTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SuggestedWord>(
      where: where(SuggestedWord.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
