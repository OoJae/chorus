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
import '../circles/circle_role.dart' as _ihm6sz5o;

/// An adult's place in a circle. Server-only; the source of truth for who
/// may invite or remove people. Kept in step with the sync space's own
/// read-write / read-only grants.
abstract class Membership
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Membership._({
    this.id,
    required this.circleSpace,
    required this.userId,
    required this.role,
    required this.displayName,
    required this.joinedAt,
  });

  factory Membership({
    int? id,
    required _is.UuidValue circleSpace,
    required _is.UuidValue userId,
    required _ihm6sz5o.CircleRole role,
    required String displayName,
    required DateTime joinedAt,
  }) = _MembershipImpl;

  factory Membership.fromJson(Map<String, dynamic> jsonSerialization) {
    return Membership(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      userId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      role: _ihm6sz5o.CircleRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
      displayName: jsonSerialization['displayName'] as String,
      joinedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
    );
  }

  static final t = MembershipTable();

  static const db = MembershipRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  _is.UuidValue userId;

  _ihm6sz5o.CircleRole role;

  String displayName;

  DateTime joinedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Membership]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Membership copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    _is.UuidValue? userId,
    _ihm6sz5o.CircleRole? role,
    String? displayName,
    DateTime? joinedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Membership',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'userId': userId.toJson(),
      'role': role.toJson(),
      'displayName': displayName,
      'joinedAt': joinedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static MembershipInclude include() {
    return MembershipInclude._();
  }

  static MembershipIncludeList includeList({
    _is.WhereExpressionBuilder<MembershipTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MembershipTable>? orderBy,
    _is.OrderByListBuilder<MembershipTable>? orderByList,
    MembershipInclude? include,
  }) {
    return MembershipIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Membership.t),
      orderByList: orderByList?.call(Membership.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MembershipImpl extends Membership {
  _MembershipImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required _is.UuidValue userId,
    required _ihm6sz5o.CircleRole role,
    required String displayName,
    required DateTime joinedAt,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         userId: userId,
         role: role,
         displayName: displayName,
         joinedAt: joinedAt,
       );

  /// Returns a shallow copy of this [Membership]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Membership copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    _is.UuidValue? userId,
    _ihm6sz5o.CircleRole? role,
    String? displayName,
    DateTime? joinedAt,
  }) {
    return Membership(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class MembershipUpdateTable extends _is.UpdateTable<MembershipTable> {
  MembershipUpdateTable(super.table);

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

  _is.ColumnValue<_ihm6sz5o.CircleRole, _ihm6sz5o.CircleRole> role(
    _ihm6sz5o.CircleRole value,
  ) => _is.ColumnValue(
    table.role,
    value,
  );

  _is.ColumnValue<String, String> displayName(String value) => _is.ColumnValue(
    table.displayName,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> joinedAt(DateTime value) =>
      _is.ColumnValue(
        table.joinedAt,
        value,
      );
}

class MembershipTable extends _is.Table<int?> {
  MembershipTable({super.tableRelation}) : super(tableName: 'membership') {
    updateTable = MembershipUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    userId = _is.ColumnUuid(
      'userId',
      this,
    );
    role = _is.ColumnEnum(
      'role',
      this,
      _is.EnumSerialization.byName,
    );
    displayName = _is.ColumnString(
      'displayName',
      this,
    );
    joinedAt = _is.ColumnDateTime(
      'joinedAt',
      this,
    );
  }

  late final MembershipUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  late final _is.ColumnUuid userId;

  late final _is.ColumnEnum<_ihm6sz5o.CircleRole> role;

  late final _is.ColumnString displayName;

  late final _is.ColumnDateTime joinedAt;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    userId,
    role,
    displayName,
    joinedAt,
  ];
}

class MembershipInclude extends _is.IncludeObject {
  MembershipInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Membership.t;
}

class MembershipIncludeList extends _is.IncludeList {
  MembershipIncludeList._({
    _is.WhereExpressionBuilder<MembershipTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Membership.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Membership.t;
}

class MembershipRepository {
  const MembershipRepository._();

  /// Returns a list of [Membership]s matching the given query parameters.
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
  Future<List<Membership>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MembershipTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MembershipTable>? orderBy,
    _is.OrderByListBuilder<MembershipTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Membership>(
      where: where?.call(Membership.t),
      orderBy: orderBy?.call(Membership.t),
      orderByList: orderByList?.call(Membership.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Membership] matching the given query parameters.
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
  Future<Membership?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MembershipTable>? where,
    int? offset,
    _is.OrderByBuilder<MembershipTable>? orderBy,
    _is.OrderByListBuilder<MembershipTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Membership>(
      where: where?.call(Membership.t),
      orderBy: orderBy?.call(Membership.t),
      orderByList: orderByList?.call(Membership.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Membership] by its [id] or null if no such row exists.
  Future<Membership?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Membership>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Membership]s in the list and returns the inserted rows.
  ///
  /// The returned [Membership]s will have their `id` fields set.
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
  Future<List<Membership>> insert(
    _is.DatabaseSession session,
    List<Membership> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Membership>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Membership] and returns the inserted row.
  ///
  /// The returned [Membership] will have its `id` field set.
  Future<Membership> insertRow(
    _is.DatabaseSession session,
    Membership row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Membership>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Membership]s in the list and returns the resulting rows.
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
  /// The returned [Membership]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Membership>> upsert(
    _is.DatabaseSession session,
    List<Membership> rows, {
    required _is.ColumnSelections<MembershipTable> conflictColumns,
    _is.ColumnSelections<MembershipTable>? updateColumns,
    _is.WhereExpressionBuilder<MembershipTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Membership>(
      rows,
      conflictColumns: conflictColumns(Membership.t),
      updateColumns: updateColumns?.call(Membership.t),
      updateWhere: updateWhere?.call(Membership.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Membership] and returns the resulting row.
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
  /// The returned [Membership] will have its `id` field set.
  Future<Membership?> upsertRow(
    _is.DatabaseSession session,
    Membership row, {
    required _is.ColumnSelections<MembershipTable> conflictColumns,
    _is.ColumnSelections<MembershipTable>? updateColumns,
    _is.WhereExpressionBuilder<MembershipTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Membership>(
      row,
      conflictColumns: conflictColumns(Membership.t),
      updateColumns: updateColumns?.call(Membership.t),
      updateWhere: updateWhere?.call(Membership.t),
      transaction: transaction,
    );
  }

  /// Updates all [Membership]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Membership>> update(
    _is.DatabaseSession session,
    List<Membership> rows, {
    _is.ColumnSelections<MembershipTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Membership>(
      rows,
      columns: columns?.call(Membership.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Membership]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Membership> updateRow(
    _is.DatabaseSession session,
    Membership row, {
    _is.ColumnSelections<MembershipTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Membership>(
      row,
      columns: columns?.call(Membership.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Membership] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Membership?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<MembershipUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Membership>(
      id,
      columnValues: columnValues(Membership.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Membership]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Membership>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MembershipUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<MembershipTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MembershipTable>? orderBy,
    _is.OrderByListBuilder<MembershipTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Membership>(
      columnValues: columnValues(Membership.t.updateTable),
      where: where(Membership.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Membership.t),
      orderByList: orderByList?.call(Membership.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Membership]s in the list and returns the deleted rows.
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
  Future<List<Membership>> delete(
    _is.DatabaseSession session,
    List<Membership> rows, {
    _is.OrderByBuilder<MembershipTable>? orderBy,
    _is.OrderByListBuilder<MembershipTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Membership>(
      rows,
      orderBy: orderBy?.call(Membership.t),
      orderByList: orderByList?.call(Membership.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Membership].
  Future<Membership> deleteRow(
    _is.DatabaseSession session,
    Membership row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Membership>(
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
  Future<List<Membership>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MembershipTable> where,
    _is.OrderByBuilder<MembershipTable>? orderBy,
    _is.OrderByListBuilder<MembershipTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Membership>(
      where: where(Membership.t),
      orderBy: orderBy?.call(Membership.t),
      orderByList: orderByList?.call(Membership.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MembershipTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Membership>(
      where: where?.call(Membership.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Membership] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MembershipTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Membership>(
      where: where(Membership.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
