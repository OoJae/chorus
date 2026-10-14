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

/// The voice the child speaks with, chosen by an adult for the whole
/// circle: every device and the view-only page use it. Server-only. A
/// circle with no row speaks with each device's default voice.
abstract class CircleVoice
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  CircleVoice._({
    this.id,
    required this.circleSpace,
    this.voiceName,
    required this.rate,
    required this.pitch,
    required this.changedBy,
    required this.changedAt,
  });

  factory CircleVoice({
    int? id,
    required _is.UuidValue circleSpace,
    String? voiceName,
    required double rate,
    required double pitch,
    required _is.UuidValue changedBy,
    required DateTime changedAt,
  }) = _CircleVoiceImpl;

  factory CircleVoice.fromJson(Map<String, dynamic> jsonSerialization) {
    return CircleVoice(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      voiceName: jsonSerialization['voiceName'] as String?,
      rate: (jsonSerialization['rate'] as num).toDouble(),
      pitch: (jsonSerialization['pitch'] as num).toDouble(),
      changedBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['changedBy'],
      ),
      changedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['changedAt'],
      ),
    );
  }

  static final t = CircleVoiceTable();

  static const db = CircleVoiceRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  /// The name the device lists the voice under; null is the device's own
  /// everyday voice. A device without a voice of this name uses its own.
  String? voiceName;

  /// Speed as a share of normal speech: 1.0 is normal, 0.9 a little slower.
  double rate;

  /// 1.0 is the voice's own pitch.
  double pitch;

  /// The adult who last changed it, and when.
  _is.UuidValue changedBy;

  DateTime changedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [CircleVoice]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CircleVoice copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    String? voiceName,
    double? rate,
    double? pitch,
    _is.UuidValue? changedBy,
    DateTime? changedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CircleVoice',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      if (voiceName != null) 'voiceName': voiceName,
      'rate': rate,
      'pitch': pitch,
      'changedBy': changedBy.toJson(),
      'changedAt': changedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static CircleVoiceInclude include() {
    return CircleVoiceInclude._();
  }

  static CircleVoiceIncludeList includeList({
    _is.WhereExpressionBuilder<CircleVoiceTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CircleVoiceTable>? orderBy,
    _is.OrderByListBuilder<CircleVoiceTable>? orderByList,
    CircleVoiceInclude? include,
  }) {
    return CircleVoiceIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CircleVoice.t),
      orderByList: orderByList?.call(CircleVoice.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CircleVoiceImpl extends CircleVoice {
  _CircleVoiceImpl({
    int? id,
    required _is.UuidValue circleSpace,
    String? voiceName,
    required double rate,
    required double pitch,
    required _is.UuidValue changedBy,
    required DateTime changedAt,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         voiceName: voiceName,
         rate: rate,
         pitch: pitch,
         changedBy: changedBy,
         changedAt: changedAt,
       );

  /// Returns a shallow copy of this [CircleVoice]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CircleVoice copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    Object? voiceName = _Undefined,
    double? rate,
    double? pitch,
    _is.UuidValue? changedBy,
    DateTime? changedAt,
  }) {
    return CircleVoice(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      voiceName: voiceName is String? ? voiceName : this.voiceName,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      changedBy: changedBy ?? this.changedBy,
      changedAt: changedAt ?? this.changedAt,
    );
  }
}

class CircleVoiceUpdateTable extends _is.UpdateTable<CircleVoiceTable> {
  CircleVoiceUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleSpace(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.circleSpace,
    value,
  );

  _is.ColumnValue<String, String> voiceName(String? value) => _is.ColumnValue(
    table.voiceName,
    value,
  );

  _is.ColumnValue<double, double> rate(double value) => _is.ColumnValue(
    table.rate,
    value,
  );

  _is.ColumnValue<double, double> pitch(double value) => _is.ColumnValue(
    table.pitch,
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

class CircleVoiceTable extends _is.Table<int?> {
  CircleVoiceTable({super.tableRelation}) : super(tableName: 'circle_voice') {
    updateTable = CircleVoiceUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    voiceName = _is.ColumnString(
      'voiceName',
      this,
    );
    rate = _is.ColumnDouble(
      'rate',
      this,
    );
    pitch = _is.ColumnDouble(
      'pitch',
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

  late final CircleVoiceUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  /// The name the device lists the voice under; null is the device's own
  /// everyday voice. A device without a voice of this name uses its own.
  late final _is.ColumnString voiceName;

  /// Speed as a share of normal speech: 1.0 is normal, 0.9 a little slower.
  late final _is.ColumnDouble rate;

  /// 1.0 is the voice's own pitch.
  late final _is.ColumnDouble pitch;

  /// The adult who last changed it, and when.
  late final _is.ColumnUuid changedBy;

  late final _is.ColumnDateTime changedAt;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    voiceName,
    rate,
    pitch,
    changedBy,
    changedAt,
  ];
}

class CircleVoiceInclude extends _is.IncludeObject {
  CircleVoiceInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => CircleVoice.t;
}

class CircleVoiceIncludeList extends _is.IncludeList {
  CircleVoiceIncludeList._({
    _is.WhereExpressionBuilder<CircleVoiceTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(CircleVoice.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => CircleVoice.t;
}

class CircleVoiceRepository {
  const CircleVoiceRepository._();

  /// Returns a list of [CircleVoice]s matching the given query parameters.
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
  Future<List<CircleVoice>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CircleVoiceTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CircleVoiceTable>? orderBy,
    _is.OrderByListBuilder<CircleVoiceTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<CircleVoice>(
      where: where?.call(CircleVoice.t),
      orderBy: orderBy?.call(CircleVoice.t),
      orderByList: orderByList?.call(CircleVoice.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [CircleVoice] matching the given query parameters.
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
  Future<CircleVoice?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CircleVoiceTable>? where,
    int? offset,
    _is.OrderByBuilder<CircleVoiceTable>? orderBy,
    _is.OrderByListBuilder<CircleVoiceTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<CircleVoice>(
      where: where?.call(CircleVoice.t),
      orderBy: orderBy?.call(CircleVoice.t),
      orderByList: orderByList?.call(CircleVoice.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [CircleVoice] by its [id] or null if no such row exists.
  Future<CircleVoice?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<CircleVoice>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [CircleVoice]s in the list and returns the inserted rows.
  ///
  /// The returned [CircleVoice]s will have their `id` fields set.
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
  Future<List<CircleVoice>> insert(
    _is.DatabaseSession session,
    List<CircleVoice> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<CircleVoice>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [CircleVoice] and returns the inserted row.
  ///
  /// The returned [CircleVoice] will have its `id` field set.
  Future<CircleVoice> insertRow(
    _is.DatabaseSession session,
    CircleVoice row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<CircleVoice>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [CircleVoice]s in the list and returns the resulting rows.
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
  /// The returned [CircleVoice]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CircleVoice>> upsert(
    _is.DatabaseSession session,
    List<CircleVoice> rows, {
    required _is.ColumnSelections<CircleVoiceTable> conflictColumns,
    _is.ColumnSelections<CircleVoiceTable>? updateColumns,
    _is.WhereExpressionBuilder<CircleVoiceTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<CircleVoice>(
      rows,
      conflictColumns: conflictColumns(CircleVoice.t),
      updateColumns: updateColumns?.call(CircleVoice.t),
      updateWhere: updateWhere?.call(CircleVoice.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [CircleVoice] and returns the resulting row.
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
  /// The returned [CircleVoice] will have its `id` field set.
  Future<CircleVoice?> upsertRow(
    _is.DatabaseSession session,
    CircleVoice row, {
    required _is.ColumnSelections<CircleVoiceTable> conflictColumns,
    _is.ColumnSelections<CircleVoiceTable>? updateColumns,
    _is.WhereExpressionBuilder<CircleVoiceTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<CircleVoice>(
      row,
      conflictColumns: conflictColumns(CircleVoice.t),
      updateColumns: updateColumns?.call(CircleVoice.t),
      updateWhere: updateWhere?.call(CircleVoice.t),
      transaction: transaction,
    );
  }

  /// Updates all [CircleVoice]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CircleVoice>> update(
    _is.DatabaseSession session,
    List<CircleVoice> rows, {
    _is.ColumnSelections<CircleVoiceTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<CircleVoice>(
      rows,
      columns: columns?.call(CircleVoice.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [CircleVoice]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<CircleVoice> updateRow(
    _is.DatabaseSession session,
    CircleVoice row, {
    _is.ColumnSelections<CircleVoiceTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<CircleVoice>(
      row,
      columns: columns?.call(CircleVoice.t),
      transaction: transaction,
    );
  }

  /// Updates a single [CircleVoice] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<CircleVoice?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<CircleVoiceUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<CircleVoice>(
      id,
      columnValues: columnValues(CircleVoice.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [CircleVoice]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CircleVoice>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<CircleVoiceUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<CircleVoiceTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CircleVoiceTable>? orderBy,
    _is.OrderByListBuilder<CircleVoiceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<CircleVoice>(
      columnValues: columnValues(CircleVoice.t.updateTable),
      where: where(CircleVoice.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CircleVoice.t),
      orderByList: orderByList?.call(CircleVoice.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [CircleVoice]s in the list and returns the deleted rows.
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
  Future<List<CircleVoice>> delete(
    _is.DatabaseSession session,
    List<CircleVoice> rows, {
    _is.OrderByBuilder<CircleVoiceTable>? orderBy,
    _is.OrderByListBuilder<CircleVoiceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<CircleVoice>(
      rows,
      orderBy: orderBy?.call(CircleVoice.t),
      orderByList: orderByList?.call(CircleVoice.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [CircleVoice].
  Future<CircleVoice> deleteRow(
    _is.DatabaseSession session,
    CircleVoice row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<CircleVoice>(
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
  Future<List<CircleVoice>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CircleVoiceTable> where,
    _is.OrderByBuilder<CircleVoiceTable>? orderBy,
    _is.OrderByListBuilder<CircleVoiceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<CircleVoice>(
      where: where(CircleVoice.t),
      orderBy: orderBy?.call(CircleVoice.t),
      orderByList: orderByList?.call(CircleVoice.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CircleVoiceTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<CircleVoice>(
      where: where?.call(CircleVoice.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [CircleVoice] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CircleVoiceTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<CircleVoice>(
      where: where(CircleVoice.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
