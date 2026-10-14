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

/// One of a circle's quick phrases: a whole sentence the child's board
/// says at once, such as "I need a break". Server-only and not synced; a
/// circle with no rows uses the defaults in `defaultQuickPhrases`.
abstract class QuickPhrase
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  QuickPhrase._({
    this.id,
    required this.circleSpace,
    required this.position,
    required this.text,
  });

  factory QuickPhrase({
    int? id,
    required _is.UuidValue circleSpace,
    required int position,
    required String text,
  }) = _QuickPhraseImpl;

  factory QuickPhrase.fromJson(Map<String, dynamic> jsonSerialization) {
    return QuickPhrase(
      id: jsonSerialization['id'] as int?,
      circleSpace: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['circleSpace'],
      ),
      position: jsonSerialization['position'] as int,
      text: jsonSerialization['text'] as String,
    );
  }

  static final t = QuickPhraseTable();

  static const db = QuickPhraseRepository._();

  @override
  int? id;

  _is.UuidValue circleSpace;

  /// Its place in the list, from 0.
  int position;

  String text;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [QuickPhrase]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  QuickPhrase copyWith({
    int? id,
    _is.UuidValue? circleSpace,
    int? position,
    String? text,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'QuickPhrase',
      if (id != null) 'id': id,
      'circleSpace': circleSpace.toJson(),
      'position': position,
      'text': text,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static QuickPhraseInclude include() {
    return QuickPhraseInclude._();
  }

  static QuickPhraseIncludeList includeList({
    _is.WhereExpressionBuilder<QuickPhraseTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<QuickPhraseTable>? orderBy,
    _is.OrderByListBuilder<QuickPhraseTable>? orderByList,
    QuickPhraseInclude? include,
  }) {
    return QuickPhraseIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(QuickPhrase.t),
      orderByList: orderByList?.call(QuickPhrase.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _QuickPhraseImpl extends QuickPhrase {
  _QuickPhraseImpl({
    int? id,
    required _is.UuidValue circleSpace,
    required int position,
    required String text,
  }) : super._(
         id: id,
         circleSpace: circleSpace,
         position: position,
         text: text,
       );

  /// Returns a shallow copy of this [QuickPhrase]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  QuickPhrase copyWith({
    Object? id = _Undefined,
    _is.UuidValue? circleSpace,
    int? position,
    String? text,
  }) {
    return QuickPhrase(
      id: id is int? ? id : this.id,
      circleSpace: circleSpace ?? this.circleSpace,
      position: position ?? this.position,
      text: text ?? this.text,
    );
  }
}

class QuickPhraseUpdateTable extends _is.UpdateTable<QuickPhraseTable> {
  QuickPhraseUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> circleSpace(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.circleSpace,
    value,
  );

  _is.ColumnValue<int, int> position(int value) => _is.ColumnValue(
    table.position,
    value,
  );

  _is.ColumnValue<String, String> text(String value) => _is.ColumnValue(
    table.text,
    value,
  );
}

class QuickPhraseTable extends _is.Table<int?> {
  QuickPhraseTable({super.tableRelation}) : super(tableName: 'quick_phrase') {
    updateTable = QuickPhraseUpdateTable(this);
    circleSpace = _is.ColumnUuid(
      'circleSpace',
      this,
    );
    position = _is.ColumnInt(
      'position',
      this,
    );
    text = _is.ColumnString(
      'text',
      this,
    );
  }

  late final QuickPhraseUpdateTable updateTable;

  late final _is.ColumnUuid circleSpace;

  /// Its place in the list, from 0.
  late final _is.ColumnInt position;

  late final _is.ColumnString text;

  @override
  List<_is.Column> get columns => [
    id,
    circleSpace,
    position,
    text,
  ];
}

class QuickPhraseInclude extends _is.IncludeObject {
  QuickPhraseInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => QuickPhrase.t;
}

class QuickPhraseIncludeList extends _is.IncludeList {
  QuickPhraseIncludeList._({
    _is.WhereExpressionBuilder<QuickPhraseTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(QuickPhrase.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => QuickPhrase.t;
}

class QuickPhraseRepository {
  const QuickPhraseRepository._();

  /// Returns a list of [QuickPhrase]s matching the given query parameters.
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
  Future<List<QuickPhrase>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<QuickPhraseTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<QuickPhraseTable>? orderBy,
    _is.OrderByListBuilder<QuickPhraseTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<QuickPhrase>(
      where: where?.call(QuickPhrase.t),
      orderBy: orderBy?.call(QuickPhrase.t),
      orderByList: orderByList?.call(QuickPhrase.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [QuickPhrase] matching the given query parameters.
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
  Future<QuickPhrase?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<QuickPhraseTable>? where,
    int? offset,
    _is.OrderByBuilder<QuickPhraseTable>? orderBy,
    _is.OrderByListBuilder<QuickPhraseTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<QuickPhrase>(
      where: where?.call(QuickPhrase.t),
      orderBy: orderBy?.call(QuickPhrase.t),
      orderByList: orderByList?.call(QuickPhrase.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [QuickPhrase] by its [id] or null if no such row exists.
  Future<QuickPhrase?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<QuickPhrase>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [QuickPhrase]s in the list and returns the inserted rows.
  ///
  /// The returned [QuickPhrase]s will have their `id` fields set.
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
  Future<List<QuickPhrase>> insert(
    _is.DatabaseSession session,
    List<QuickPhrase> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<QuickPhrase>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [QuickPhrase] and returns the inserted row.
  ///
  /// The returned [QuickPhrase] will have its `id` field set.
  Future<QuickPhrase> insertRow(
    _is.DatabaseSession session,
    QuickPhrase row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<QuickPhrase>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [QuickPhrase]s in the list and returns the resulting rows.
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
  /// The returned [QuickPhrase]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<QuickPhrase>> upsert(
    _is.DatabaseSession session,
    List<QuickPhrase> rows, {
    required _is.ColumnSelections<QuickPhraseTable> conflictColumns,
    _is.ColumnSelections<QuickPhraseTable>? updateColumns,
    _is.WhereExpressionBuilder<QuickPhraseTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<QuickPhrase>(
      rows,
      conflictColumns: conflictColumns(QuickPhrase.t),
      updateColumns: updateColumns?.call(QuickPhrase.t),
      updateWhere: updateWhere?.call(QuickPhrase.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [QuickPhrase] and returns the resulting row.
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
  /// The returned [QuickPhrase] will have its `id` field set.
  Future<QuickPhrase?> upsertRow(
    _is.DatabaseSession session,
    QuickPhrase row, {
    required _is.ColumnSelections<QuickPhraseTable> conflictColumns,
    _is.ColumnSelections<QuickPhraseTable>? updateColumns,
    _is.WhereExpressionBuilder<QuickPhraseTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<QuickPhrase>(
      row,
      conflictColumns: conflictColumns(QuickPhrase.t),
      updateColumns: updateColumns?.call(QuickPhrase.t),
      updateWhere: updateWhere?.call(QuickPhrase.t),
      transaction: transaction,
    );
  }

  /// Updates all [QuickPhrase]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<QuickPhrase>> update(
    _is.DatabaseSession session,
    List<QuickPhrase> rows, {
    _is.ColumnSelections<QuickPhraseTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<QuickPhrase>(
      rows,
      columns: columns?.call(QuickPhrase.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [QuickPhrase]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<QuickPhrase> updateRow(
    _is.DatabaseSession session,
    QuickPhrase row, {
    _is.ColumnSelections<QuickPhraseTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<QuickPhrase>(
      row,
      columns: columns?.call(QuickPhrase.t),
      transaction: transaction,
    );
  }

  /// Updates a single [QuickPhrase] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<QuickPhrase?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<QuickPhraseUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<QuickPhrase>(
      id,
      columnValues: columnValues(QuickPhrase.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [QuickPhrase]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<QuickPhrase>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<QuickPhraseUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<QuickPhraseTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<QuickPhraseTable>? orderBy,
    _is.OrderByListBuilder<QuickPhraseTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<QuickPhrase>(
      columnValues: columnValues(QuickPhrase.t.updateTable),
      where: where(QuickPhrase.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(QuickPhrase.t),
      orderByList: orderByList?.call(QuickPhrase.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [QuickPhrase]s in the list and returns the deleted rows.
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
  Future<List<QuickPhrase>> delete(
    _is.DatabaseSession session,
    List<QuickPhrase> rows, {
    _is.OrderByBuilder<QuickPhraseTable>? orderBy,
    _is.OrderByListBuilder<QuickPhraseTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<QuickPhrase>(
      rows,
      orderBy: orderBy?.call(QuickPhrase.t),
      orderByList: orderByList?.call(QuickPhrase.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [QuickPhrase].
  Future<QuickPhrase> deleteRow(
    _is.DatabaseSession session,
    QuickPhrase row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<QuickPhrase>(
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
  Future<List<QuickPhrase>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<QuickPhraseTable> where,
    _is.OrderByBuilder<QuickPhraseTable>? orderBy,
    _is.OrderByListBuilder<QuickPhraseTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<QuickPhrase>(
      where: where(QuickPhrase.t),
      orderBy: orderBy?.call(QuickPhrase.t),
      orderByList: orderByList?.call(QuickPhrase.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<QuickPhraseTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<QuickPhrase>(
      where: where?.call(QuickPhrase.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [QuickPhrase] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<QuickPhraseTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<QuickPhrase>(
      where: where(QuickPhrase.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
