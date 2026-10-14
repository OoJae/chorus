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

/// When one device of one member last synced a circle. Server-only; holds
/// no words. Written by the app's heartbeat after a successful sync.
abstract class DeviceSeen
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DeviceSeen._({
    this.id,
    required this.circleSpace,
    required this.userId,
    required this.userName,
    required this.deviceId,
    required this.deviceLabel,
    required this.lastSyncAt,
    required this.lastSeenAt,
  });

  factory DeviceSeen({
    int? id,
    required _is.UuidValue circleSpace,
    required _is.UuidValue userId,
    required String userName,
    required String deviceId,
    required String deviceLabel,
    required DateTime lastSyncAt,
    required DateTime lastSeenAt,
  }) = _DeviceSeenImpl;

  factory DeviceSeen.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeviceSeen(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      userName: jsonSerialization['userName'] as String,
      deviceId: jsonSerialization['deviceId'] as String,
      deviceLabel: jsonSerialization['deviceLabel'] as String,
      lastSyncAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSyncAt'],
      ),
      lastSeenAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenAt'],
      ),
    );
  }

  static final t = DeviceSeenTable();

  static const db = DeviceSeenRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  _is.UuidValue userId;

  /// The member's name in the circle when the device last checked in.
  String userName;

  /// A random id the device keeps for itself.
  String deviceId;

  /// What the device is, in plain words: "Android phone", "Web browser".
  String deviceLabel;

  /// When the device last finished a sync, by its own report.
  DateTime lastSyncAt;

  /// When the server last heard from the device.
  DateTime lastSeenAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DeviceSeen]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DeviceSeen copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    _is.UuidValue? userId,
    String? userName,
    String? deviceId,
    String? deviceLabel,
    DateTime? lastSyncAt,
    DateTime? lastSeenAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceSeen',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'userId': userId.toJson(),
      'userName': userName,
      'deviceId': deviceId,
      'deviceLabel': deviceLabel,
      'lastSyncAt': lastSyncAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static DeviceSeenInclude include() {
    return DeviceSeenInclude._();
  }

  static DeviceSeenIncludeList includeList({
    _is.WhereExpressionBuilder<DeviceSeenTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeviceSeenTable>? orderBy,
    _is.OrderByListBuilder<DeviceSeenTable>? orderByList,
    DeviceSeenInclude? include,
  }) {
    return DeviceSeenIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DeviceSeen.t),
      orderByList: orderByList?.call(DeviceSeen.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeviceSeenImpl extends DeviceSeen {
  _DeviceSeenImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required _is.UuidValue userId,
    required String userName,
    required String deviceId,
    required String deviceLabel,
    required DateTime lastSyncAt,
    required DateTime lastSeenAt,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         userId: userId,
         userName: userName,
         deviceId: deviceId,
         deviceLabel: deviceLabel,
         lastSyncAt: lastSyncAt,
         lastSeenAt: lastSeenAt,
       );

  /// Returns a shallow copy of this [DeviceSeen]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DeviceSeen copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    _is.UuidValue? userId,
    String? userName,
    String? deviceId,
    String? deviceLabel,
    DateTime? lastSyncAt,
    DateTime? lastSeenAt,
  }) {
    return DeviceSeen(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      deviceId: deviceId ?? this.deviceId,
      deviceLabel: deviceLabel ?? this.deviceLabel,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}

class DeviceSeenUpdateTable extends _is.UpdateTable<DeviceSeenTable> {
  DeviceSeenUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleSpace(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.circleSpace,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userId,
        value,
      );

  _is.ColumnValue<String, String> userName(String value) => _is.ColumnValue(
    table.userName,
    value,
  );

  _is.ColumnValue<String, String> deviceId(String value) => _is.ColumnValue(
    table.deviceId,
    value,
  );

  _is.ColumnValue<String, String> deviceLabel(String value) => _is.ColumnValue(
    table.deviceLabel,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> lastSyncAt(DateTime value) =>
      _is.ColumnValue(
        table.lastSyncAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> lastSeenAt(DateTime value) =>
      _is.ColumnValue(
        table.lastSeenAt,
        value,
      );
}

class DeviceSeenTable extends _is.Table<int?> {
  DeviceSeenTable({super.tableRelation}) : super(tableName: 'device_seen') {
    updateTable = DeviceSeenUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
    userName = _is.ColumnString(
      'userName',
      this,
    );
    deviceId = _is.ColumnString(
      'deviceId',
      this,
    );
    deviceLabel = _is.ColumnString(
      'deviceLabel',
      this,
    );
    lastSyncAt = _is.ColumnDateTime(
      'lastSyncAt',
      this,
    );
    lastSeenAt = _is.ColumnDateTime(
      'lastSeenAt',
      this,
    );
  }

  late final DeviceSeenUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  late final _is.ColumnUuid userId;

  /// The member's name in the circle when the device last checked in.
  late final _is.ColumnString userName;

  /// A random id the device keeps for itself.
  late final _is.ColumnString deviceId;

  /// What the device is, in plain words: "Android phone", "Web browser".
  late final _is.ColumnString deviceLabel;

  /// When the device last finished a sync, by its own report.
  late final _is.ColumnDateTime lastSyncAt;

  /// When the server last heard from the device.
  late final _is.ColumnDateTime lastSeenAt;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    userId,
    userName,
    deviceId,
    deviceLabel,
    lastSyncAt,
    lastSeenAt,
  ];
}

class DeviceSeenInclude extends _is.IncludeObject {
  DeviceSeenInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DeviceSeen.t;
}

class DeviceSeenIncludeList extends _is.IncludeList {
  DeviceSeenIncludeList._({
    _is.WhereExpressionBuilder<DeviceSeenTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DeviceSeen.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DeviceSeen.t;
}

class DeviceSeenRepository {
  const DeviceSeenRepository._();

  /// Returns a list of [DeviceSeen]s matching the given query parameters.
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
  Future<List<DeviceSeen>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeviceSeenTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeviceSeenTable>? orderBy,
    _is.OrderByListBuilder<DeviceSeenTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DeviceSeen>(
      where: where?.call(DeviceSeen.t),
      orderBy: orderBy?.call(DeviceSeen.t),
      orderByList: orderByList?.call(DeviceSeen.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DeviceSeen] matching the given query parameters.
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
  Future<DeviceSeen?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeviceSeenTable>? where,
    int? offset,
    _is.OrderByBuilder<DeviceSeenTable>? orderBy,
    _is.OrderByListBuilder<DeviceSeenTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DeviceSeen>(
      where: where?.call(DeviceSeen.t),
      orderBy: orderBy?.call(DeviceSeen.t),
      orderByList: orderByList?.call(DeviceSeen.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DeviceSeen] by its [id] or null if no such row exists.
  Future<DeviceSeen?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DeviceSeen>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DeviceSeen]s in the list and returns the inserted rows.
  ///
  /// The returned [DeviceSeen]s will have their `id` fields set.
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
  Future<List<DeviceSeen>> insert(
    _is.DatabaseSession session,
    List<DeviceSeen> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DeviceSeen>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DeviceSeen] and returns the inserted row.
  ///
  /// The returned [DeviceSeen] will have its `id` field set.
  Future<DeviceSeen> insertRow(
    _is.DatabaseSession session,
    DeviceSeen row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DeviceSeen>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DeviceSeen]s in the list and returns the resulting rows.
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
  /// The returned [DeviceSeen]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DeviceSeen>> upsert(
    _is.DatabaseSession session,
    List<DeviceSeen> rows, {
    required _is.ColumnSelections<DeviceSeenTable> conflictColumns,
    _is.ColumnSelections<DeviceSeenTable>? updateColumns,
    _is.WhereExpressionBuilder<DeviceSeenTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DeviceSeen>(
      rows,
      conflictColumns: conflictColumns(DeviceSeen.t),
      updateColumns: updateColumns?.call(DeviceSeen.t),
      updateWhere: updateWhere?.call(DeviceSeen.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DeviceSeen] and returns the resulting row.
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
  /// The returned [DeviceSeen] will have its `id` field set.
  Future<DeviceSeen?> upsertRow(
    _is.DatabaseSession session,
    DeviceSeen row, {
    required _is.ColumnSelections<DeviceSeenTable> conflictColumns,
    _is.ColumnSelections<DeviceSeenTable>? updateColumns,
    _is.WhereExpressionBuilder<DeviceSeenTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DeviceSeen>(
      row,
      conflictColumns: conflictColumns(DeviceSeen.t),
      updateColumns: updateColumns?.call(DeviceSeen.t),
      updateWhere: updateWhere?.call(DeviceSeen.t),
      transaction: transaction,
    );
  }

  /// Updates all [DeviceSeen]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DeviceSeen>> update(
    _is.DatabaseSession session,
    List<DeviceSeen> rows, {
    _is.ColumnSelections<DeviceSeenTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DeviceSeen>(
      rows,
      columns: columns?.call(DeviceSeen.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DeviceSeen]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DeviceSeen> updateRow(
    _is.DatabaseSession session,
    DeviceSeen row, {
    _is.ColumnSelections<DeviceSeenTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DeviceSeen>(
      row,
      columns: columns?.call(DeviceSeen.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DeviceSeen] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DeviceSeen?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DeviceSeenUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DeviceSeen>(
      id,
      columnValues: columnValues(DeviceSeen.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DeviceSeen]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DeviceSeen>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DeviceSeenUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DeviceSeenTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeviceSeenTable>? orderBy,
    _is.OrderByListBuilder<DeviceSeenTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DeviceSeen>(
      columnValues: columnValues(DeviceSeen.t.updateTable),
      where: where(DeviceSeen.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DeviceSeen.t),
      orderByList: orderByList?.call(DeviceSeen.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DeviceSeen]s in the list and returns the deleted rows.
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
  Future<List<DeviceSeen>> delete(
    _is.DatabaseSession session,
    List<DeviceSeen> rows, {
    _is.OrderByBuilder<DeviceSeenTable>? orderBy,
    _is.OrderByListBuilder<DeviceSeenTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DeviceSeen>(
      rows,
      orderBy: orderBy?.call(DeviceSeen.t),
      orderByList: orderByList?.call(DeviceSeen.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DeviceSeen].
  Future<DeviceSeen> deleteRow(
    _is.DatabaseSession session,
    DeviceSeen row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DeviceSeen>(
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
  Future<List<DeviceSeen>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DeviceSeenTable> where,
    _is.OrderByBuilder<DeviceSeenTable>? orderBy,
    _is.OrderByListBuilder<DeviceSeenTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DeviceSeen>(
      where: where(DeviceSeen.t),
      orderBy: orderBy?.call(DeviceSeen.t),
      orderByList: orderByList?.call(DeviceSeen.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeviceSeenTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DeviceSeen>(
      where: where?.call(DeviceSeen.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DeviceSeen] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DeviceSeenTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DeviceSeen>(
      where: where(DeviceSeen.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
