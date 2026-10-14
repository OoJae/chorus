/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:chorus_client/src/protocol/circles/circle_info.dart'
    as _icfd3qx2;
import 'package:chorus_client/src/protocol/trust/device_status.dart'
    as _ilm3njl8;
import 'package:chorus_client/src/protocol/wordlog/word_use_entry.dart'
    as _iyisc6zi;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:serverpod_database/serverpod_database.dart' as _isd;
import 'package:serverpod_offline_sync_client/serverpod_offline_sync_client.dart'
    as _ipulbpi2;
import 'boards/board.dart' as _i3lcnjeo;
import 'boards/tile.dart' as _ihyl55zs;
import 'boards/tile_edit.dart' as _ignkl5py;
import 'circles/circle_exception.dart' as _i4ewpqfy;
import 'circles/circle_failure.dart' as _igjnv98g;
import 'circles/circle_info.dart' as _i5j3z7cn;
import 'circles/circle_role.dart' as _il0wc3z7;
import 'circles/member_info.dart' as _i5nn4t9p;
import 'circles/server_info.dart' as _iqe7186e;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'live/live_event.dart' as _ixdzvre4;
import 'live/live_kind.dart' as _il8wtxvt;
import 'media/media_kind.dart' as _i8mjpd0r;
import 'media/upload_ticket.dart' as _illp1jkh;
import 'practice/practice_exception.dart' as _ilvwtkyp;
import 'practice/practice_failure.dart' as _iv6qijxa;
import 'practice/practice_word.dart' as _iu9klhki;
import 'sharing/view_only_link.dart' as _iveyennw;
import 'suggest/suggest_exception.dart' as _iw5bueja;
import 'suggest/suggest_failure.dart' as _iv4peolp;
import 'suggest/word_suggestion.dart' as _ifctwajg;
import 'summary/week_report.dart' as _iaf8iewd;
import 'summary/word_tally.dart' as _i6roonjc;
import 'trust/device_status.dart' as _i1bd2zm2;
import 'wordlog/word_log_exception.dart' as _i163yf92;
import 'wordlog/word_log_failure.dart' as _i352cmsp;
import 'wordlog/word_log_status.dart' as _i5lyi3mq;
import 'wordlog/word_use_entry.dart' as _in1k2ibs;
export 'boards/board.dart';
export 'boards/tile.dart';
export 'boards/tile_edit.dart';
export 'circles/circle_exception.dart';
export 'circles/circle_failure.dart';
export 'circles/circle_info.dart';
export 'circles/circle_role.dart';
export 'circles/member_info.dart';
export 'circles/server_info.dart';
export 'greetings/greeting.dart';
export 'live/live_event.dart';
export 'live/live_kind.dart';
export 'media/media_kind.dart';
export 'media/upload_ticket.dart';
export 'practice/practice_exception.dart';
export 'practice/practice_failure.dart';
export 'practice/practice_word.dart';
export 'sharing/view_only_link.dart';
export 'suggest/suggest_exception.dart';
export 'suggest/suggest_failure.dart';
export 'suggest/word_suggestion.dart';
export 'summary/week_report.dart';
export 'summary/word_tally.dart';
export 'trust/device_status.dart';
export 'wordlog/word_log_exception.dart';
export 'wordlog/word_log_failure.dart';
export 'wordlog/word_log_status.dart';
export 'wordlog/word_use_entry.dart';
export 'client.dart';
export 'sync_tables.dart';

class Protocol extends _isd.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static List<_isd.TableDefinition> get targetTableDefinitions => [
    _isd.TableDefinition(
      name: 'board',
      dartName: 'Board',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isd.ColumnDefinition(
          name: 'id',
          columnType: _isd.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isd.ColumnDefinition(
          name: 'spaceId',
          columnType: _isd.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isd.ColumnDefinition(
          name: 'circleId',
          columnType: _isd.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isd.ColumnDefinition(
          name: 'name',
          columnType: _isd.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isd.ColumnDefinition(
          name: 'rows',
          columnType: _isd.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isd.ColumnDefinition(
          name: 'cols',
          columnType: _isd.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isd.ColumnDefinition(
          name: 'isHome',
          columnType: _isd.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isd.ColumnDefinition(
          name: 'archivedAt',
          columnType: _isd.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isd.ColumnDefinition(
          name: 'createdAt',
          columnType: _isd.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isd.ForeignKeyDefinition(
          constraintName: 'board_fk_0',
          columns: ['spaceId'],
          referenceTable: 'offline_sync_spaces',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isd.ForeignKeyAction.noAction,
          onDelete: _isd.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isd.IndexDefinition(
          indexName: 'board_circle_idx',
          tableSpace: null,
          elements: [
            _isd.IndexElementDefinition(
              type: _isd.IndexElementDefinitionType.column,
              definition: 'circleId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isd.TableDefinition(
      name: 'tile',
      dartName: 'Tile',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isd.ColumnDefinition(
          name: 'id',
          columnType: _isd.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isd.ColumnDefinition(
          name: 'spaceId',
          columnType: _isd.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isd.ColumnDefinition(
          name: 'circleId',
          columnType: _isd.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isd.ColumnDefinition(
          name: 'boardId',
          columnType: _isd.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isd.ColumnDefinition(
          name: 'cellKey',
          columnType: _isd.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isd.ColumnDefinition(
          name: 'label',
          columnType: _isd.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isd.ColumnDefinition(
          name: 'speech',
          columnType: _isd.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isd.ColumnDefinition(
          name: 'colorKey',
          columnType: _isd.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isd.ColumnDefinition(
          name: 'imageHash',
          columnType: _isd.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isd.ColumnDefinition(
          name: 'audioHash',
          columnType: _isd.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isd.ColumnDefinition(
          name: 'linkBoardId',
          columnType: _isd.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isd.ColumnDefinition(
          name: 'noLog',
          columnType: _isd.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isd.ColumnDefinition(
          name: 'archivedAt',
          columnType: _isd.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isd.ColumnDefinition(
          name: 'createdBy',
          columnType: _isd.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isd.ColumnDefinition(
          name: 'createdByName',
          columnType: _isd.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isd.ColumnDefinition(
          name: 'createdAt',
          columnType: _isd.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isd.ForeignKeyDefinition(
          constraintName: 'tile_fk_0',
          columns: ['spaceId'],
          referenceTable: 'offline_sync_spaces',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isd.ForeignKeyAction.noAction,
          onDelete: _isd.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isd.ForeignKeyDefinition(
          constraintName: 'tile_fk_1',
          columns: ['boardId'],
          referenceTable: 'board',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isd.ForeignKeyAction.noAction,
          onDelete: _isd.ForeignKeyAction.noAction,
          matchType: null,
          deferrable: _isd.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isd.IndexDefinition(
          indexName: 'tile__spaceId__cellKey__unique_idx',
          tableSpace: null,
          elements: [
            _isd.IndexElementDefinition(
              type: _isd.IndexElementDefinitionType.column,
              definition: 'spaceId',
            ),
            _isd.IndexElementDefinition(
              type: _isd.IndexElementDefinitionType.column,
              definition: 'cellKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isd.IndexDefinition(
          indexName: 'tile_circle_idx',
          tableSpace: null,
          elements: [
            _isd.IndexElementDefinition(
              type: _isd.IndexElementDefinitionType.column,
              definition: 'circleId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isd.TableDefinition(
      name: 'tile_edit',
      dartName: 'TileEdit',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isd.ColumnDefinition(
          name: 'id',
          columnType: _isd.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isd.ColumnDefinition(
          name: 'spaceId',
          columnType: _isd.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isd.ColumnDefinition(
          name: 'circleId',
          columnType: _isd.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isd.ColumnDefinition(
          name: 'tileId',
          columnType: _isd.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isd.ColumnDefinition(
          name: 'prop',
          columnType: _isd.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isd.ColumnDefinition(
          name: 'oldValue',
          columnType: _isd.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isd.ColumnDefinition(
          name: 'newValue',
          columnType: _isd.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isd.ColumnDefinition(
          name: 'baseEditId',
          columnType: _isd.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isd.ColumnDefinition(
          name: 'reason',
          columnType: _isd.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isd.ColumnDefinition(
          name: 'actorId',
          columnType: _isd.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isd.ColumnDefinition(
          name: 'actorName',
          columnType: _isd.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isd.ColumnDefinition(
          name: 'editedAt',
          columnType: _isd.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isd.ForeignKeyDefinition(
          constraintName: 'tile_edit_fk_0',
          columns: ['spaceId'],
          referenceTable: 'offline_sync_spaces',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isd.ForeignKeyAction.noAction,
          onDelete: _isd.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isd.IndexDefinition(
          indexName: 'tile_edit_circle_idx',
          tableSpace: null,
          elements: [
            _isd.IndexElementDefinition(
              type: _isd.IndexElementDefinitionType.column,
              definition: 'circleId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isd.IndexDefinition(
          indexName: 'tile_edit_tile_idx',
          tableSpace: null,
          elements: [
            _isd.IndexElementDefinition(
              type: _isd.IndexElementDefinitionType.column,
              definition: 'tileId',
            ),
            _isd.IndexElementDefinition(
              type: _isd.IndexElementDefinitionType.column,
              definition: 'prop',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._iaic.Protocol() is _isd.DatabaseSerializationManager
        ? (_iaic.Protocol() as _isd.DatabaseSerializationManager)
              .getTargetTableDefinitions()
        : [],
    ..._ipulbpi2.Protocol() is _isd.DatabaseSerializationManager
        ? (_ipulbpi2.Protocol() as _isd.DatabaseSerializationManager)
              .getTargetTableDefinitions()
        : [],
    ..._iacc.Protocol() is _isd.DatabaseSerializationManager
        ? (_iacc.Protocol() as _isd.DatabaseSerializationManager)
              .getTargetTableDefinitions()
        : [],
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i3lcnjeo.Board) {
      return _i3lcnjeo.Board.fromJson(data) as T;
    }
    if (t == _ihyl55zs.Tile) {
      return _ihyl55zs.Tile.fromJson(data) as T;
    }
    if (t == _ignkl5py.TileEdit) {
      return _ignkl5py.TileEdit.fromJson(data) as T;
    }
    if (t == _i4ewpqfy.CircleException) {
      return _i4ewpqfy.CircleException.fromJson(data) as T;
    }
    if (t == _igjnv98g.CircleFailure) {
      return _igjnv98g.CircleFailure.fromJson(data) as T;
    }
    if (t == _i5j3z7cn.CircleInfo) {
      return _i5j3z7cn.CircleInfo.fromJson(data) as T;
    }
    if (t == _il0wc3z7.CircleRole) {
      return _il0wc3z7.CircleRole.fromJson(data) as T;
    }
    if (t == _i5nn4t9p.MemberInfo) {
      return _i5nn4t9p.MemberInfo.fromJson(data) as T;
    }
    if (t == _iqe7186e.ServerInfo) {
      return _iqe7186e.ServerInfo.fromJson(data) as T;
    }
    if (t == _izw8z7ou.Greeting) {
      return _izw8z7ou.Greeting.fromJson(data) as T;
    }
    if (t == _ixdzvre4.LiveEvent) {
      return _ixdzvre4.LiveEvent.fromJson(data) as T;
    }
    if (t == _il8wtxvt.LiveKind) {
      return _il8wtxvt.LiveKind.fromJson(data) as T;
    }
    if (t == _i8mjpd0r.MediaKind) {
      return _i8mjpd0r.MediaKind.fromJson(data) as T;
    }
    if (t == _illp1jkh.UploadTicket) {
      return _illp1jkh.UploadTicket.fromJson(data) as T;
    }
    if (t == _ilvwtkyp.PracticeException) {
      return _ilvwtkyp.PracticeException.fromJson(data) as T;
    }
    if (t == _iv6qijxa.PracticeFailure) {
      return _iv6qijxa.PracticeFailure.fromJson(data) as T;
    }
    if (t == _iu9klhki.PracticeWord) {
      return _iu9klhki.PracticeWord.fromJson(data) as T;
    }
    if (t == _iveyennw.ViewOnlyLink) {
      return _iveyennw.ViewOnlyLink.fromJson(data) as T;
    }
    if (t == _iw5bueja.SuggestException) {
      return _iw5bueja.SuggestException.fromJson(data) as T;
    }
    if (t == _iv4peolp.SuggestFailure) {
      return _iv4peolp.SuggestFailure.fromJson(data) as T;
    }
    if (t == _ifctwajg.WordSuggestion) {
      return _ifctwajg.WordSuggestion.fromJson(data) as T;
    }
    if (t == _iaf8iewd.WeekReport) {
      return _iaf8iewd.WeekReport.fromJson(data) as T;
    }
    if (t == _i6roonjc.WordTally) {
      return _i6roonjc.WordTally.fromJson(data) as T;
    }
    if (t == _i1bd2zm2.DeviceStatus) {
      return _i1bd2zm2.DeviceStatus.fromJson(data) as T;
    }
    if (t == _i163yf92.WordLogException) {
      return _i163yf92.WordLogException.fromJson(data) as T;
    }
    if (t == _i352cmsp.WordLogFailure) {
      return _i352cmsp.WordLogFailure.fromJson(data) as T;
    }
    if (t == _i5lyi3mq.WordLogStatus) {
      return _i5lyi3mq.WordLogStatus.fromJson(data) as T;
    }
    if (t == _in1k2ibs.WordUseEntry) {
      return _in1k2ibs.WordUseEntry.fromJson(data) as T;
    }
    if (t == _isc.getType<_i3lcnjeo.Board?>()) {
      return (data != null ? _i3lcnjeo.Board.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ihyl55zs.Tile?>()) {
      return (data != null ? _ihyl55zs.Tile.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ignkl5py.TileEdit?>()) {
      return (data != null ? _ignkl5py.TileEdit.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i4ewpqfy.CircleException?>()) {
      return (data != null ? _i4ewpqfy.CircleException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_igjnv98g.CircleFailure?>()) {
      return (data != null ? _igjnv98g.CircleFailure.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i5j3z7cn.CircleInfo?>()) {
      return (data != null ? _i5j3z7cn.CircleInfo.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_il0wc3z7.CircleRole?>()) {
      return (data != null ? _il0wc3z7.CircleRole.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i5nn4t9p.MemberInfo?>()) {
      return (data != null ? _i5nn4t9p.MemberInfo.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iqe7186e.ServerInfo?>()) {
      return (data != null ? _iqe7186e.ServerInfo.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ixdzvre4.LiveEvent?>()) {
      return (data != null ? _ixdzvre4.LiveEvent.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_il8wtxvt.LiveKind?>()) {
      return (data != null ? _il8wtxvt.LiveKind.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i8mjpd0r.MediaKind?>()) {
      return (data != null ? _i8mjpd0r.MediaKind.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_illp1jkh.UploadTicket?>()) {
      return (data != null ? _illp1jkh.UploadTicket.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ilvwtkyp.PracticeException?>()) {
      return (data != null ? _ilvwtkyp.PracticeException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iv6qijxa.PracticeFailure?>()) {
      return (data != null ? _iv6qijxa.PracticeFailure.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iu9klhki.PracticeWord?>()) {
      return (data != null ? _iu9klhki.PracticeWord.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iveyennw.ViewOnlyLink?>()) {
      return (data != null ? _iveyennw.ViewOnlyLink.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iw5bueja.SuggestException?>()) {
      return (data != null ? _iw5bueja.SuggestException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iv4peolp.SuggestFailure?>()) {
      return (data != null ? _iv4peolp.SuggestFailure.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ifctwajg.WordSuggestion?>()) {
      return (data != null ? _ifctwajg.WordSuggestion.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iaf8iewd.WeekReport?>()) {
      return (data != null ? _iaf8iewd.WeekReport.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i6roonjc.WordTally?>()) {
      return (data != null ? _i6roonjc.WordTally.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i1bd2zm2.DeviceStatus?>()) {
      return (data != null ? _i1bd2zm2.DeviceStatus.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i163yf92.WordLogException?>()) {
      return (data != null ? _i163yf92.WordLogException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i352cmsp.WordLogFailure?>()) {
      return (data != null ? _i352cmsp.WordLogFailure.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i5lyi3mq.WordLogStatus?>()) {
      return (data != null ? _i5lyi3mq.WordLogStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_in1k2ibs.WordUseEntry?>()) {
      return (data != null ? _in1k2ibs.WordUseEntry.fromJson(data) : null) as T;
    }
    if (t == List<_i5nn4t9p.MemberInfo>) {
      return (data as List)
              .map((e) => deserialize<_i5nn4t9p.MemberInfo>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i6roonjc.WordTally>) {
      return (data as List)
              .map((e) => deserialize<_i6roonjc.WordTally>(e))
              .toList()
          as T;
    }
    if (t == List<_icfd3qx2.CircleInfo>) {
      return (data as List)
              .map((e) => deserialize<_icfd3qx2.CircleInfo>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_ilm3njl8.DeviceStatus>) {
      return (data as List)
              .map((e) => deserialize<_ilm3njl8.DeviceStatus>(e))
              .toList()
          as T;
    }
    if (t == List<_iyisc6zi.WordUseEntry>) {
      return (data as List)
              .map((e) => deserialize<_iyisc6zi.WordUseEntry>(e))
              .toList()
          as T;
    }
    try {
      return _iaic.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _ipulbpi2.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacc.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i3lcnjeo.Board => 'Board',
      _ihyl55zs.Tile => 'Tile',
      _ignkl5py.TileEdit => 'TileEdit',
      _i4ewpqfy.CircleException => 'CircleException',
      _igjnv98g.CircleFailure => 'CircleFailure',
      _i5j3z7cn.CircleInfo => 'CircleInfo',
      _il0wc3z7.CircleRole => 'CircleRole',
      _i5nn4t9p.MemberInfo => 'MemberInfo',
      _iqe7186e.ServerInfo => 'ServerInfo',
      _izw8z7ou.Greeting => 'Greeting',
      _ixdzvre4.LiveEvent => 'LiveEvent',
      _il8wtxvt.LiveKind => 'LiveKind',
      _i8mjpd0r.MediaKind => 'MediaKind',
      _illp1jkh.UploadTicket => 'UploadTicket',
      _ilvwtkyp.PracticeException => 'PracticeException',
      _iv6qijxa.PracticeFailure => 'PracticeFailure',
      _iu9klhki.PracticeWord => 'PracticeWord',
      _iveyennw.ViewOnlyLink => 'ViewOnlyLink',
      _iw5bueja.SuggestException => 'SuggestException',
      _iv4peolp.SuggestFailure => 'SuggestFailure',
      _ifctwajg.WordSuggestion => 'WordSuggestion',
      _iaf8iewd.WeekReport => 'WeekReport',
      _i6roonjc.WordTally => 'WordTally',
      _i1bd2zm2.DeviceStatus => 'DeviceStatus',
      _i163yf92.WordLogException => 'WordLogException',
      _i352cmsp.WordLogFailure => 'WordLogFailure',
      _i5lyi3mq.WordLogStatus => 'WordLogStatus',
      _in1k2ibs.WordUseEntry => 'WordUseEntry',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('chorus.', '');
    }

    switch (data) {
      case _i3lcnjeo.Board():
        return 'Board';
      case _ihyl55zs.Tile():
        return 'Tile';
      case _ignkl5py.TileEdit():
        return 'TileEdit';
      case _i4ewpqfy.CircleException():
        return 'CircleException';
      case _igjnv98g.CircleFailure():
        return 'CircleFailure';
      case _i5j3z7cn.CircleInfo():
        return 'CircleInfo';
      case _il0wc3z7.CircleRole():
        return 'CircleRole';
      case _i5nn4t9p.MemberInfo():
        return 'MemberInfo';
      case _iqe7186e.ServerInfo():
        return 'ServerInfo';
      case _izw8z7ou.Greeting():
        return 'Greeting';
      case _ixdzvre4.LiveEvent():
        return 'LiveEvent';
      case _il8wtxvt.LiveKind():
        return 'LiveKind';
      case _i8mjpd0r.MediaKind():
        return 'MediaKind';
      case _illp1jkh.UploadTicket():
        return 'UploadTicket';
      case _ilvwtkyp.PracticeException():
        return 'PracticeException';
      case _iv6qijxa.PracticeFailure():
        return 'PracticeFailure';
      case _iu9klhki.PracticeWord():
        return 'PracticeWord';
      case _iveyennw.ViewOnlyLink():
        return 'ViewOnlyLink';
      case _iw5bueja.SuggestException():
        return 'SuggestException';
      case _iv4peolp.SuggestFailure():
        return 'SuggestFailure';
      case _ifctwajg.WordSuggestion():
        return 'WordSuggestion';
      case _iaf8iewd.WeekReport():
        return 'WeekReport';
      case _i6roonjc.WordTally():
        return 'WordTally';
      case _i1bd2zm2.DeviceStatus():
        return 'DeviceStatus';
      case _i163yf92.WordLogException():
        return 'WordLogException';
      case _i352cmsp.WordLogFailure():
        return 'WordLogFailure';
      case _i5lyi3mq.WordLogStatus():
        return 'WordLogStatus';
      case _in1k2ibs.WordUseEntry():
        return 'WordUseEntry';
    }
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _ipulbpi2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_offline_sync.$className';
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Board') {
      return deserialize<_i3lcnjeo.Board>(data['data']);
    }
    if (dataClassName == 'Tile') {
      return deserialize<_ihyl55zs.Tile>(data['data']);
    }
    if (dataClassName == 'TileEdit') {
      return deserialize<_ignkl5py.TileEdit>(data['data']);
    }
    if (dataClassName == 'CircleException') {
      return deserialize<_i4ewpqfy.CircleException>(data['data']);
    }
    if (dataClassName == 'CircleFailure') {
      return deserialize<_igjnv98g.CircleFailure>(data['data']);
    }
    if (dataClassName == 'CircleInfo') {
      return deserialize<_i5j3z7cn.CircleInfo>(data['data']);
    }
    if (dataClassName == 'CircleRole') {
      return deserialize<_il0wc3z7.CircleRole>(data['data']);
    }
    if (dataClassName == 'MemberInfo') {
      return deserialize<_i5nn4t9p.MemberInfo>(data['data']);
    }
    if (dataClassName == 'ServerInfo') {
      return deserialize<_iqe7186e.ServerInfo>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_izw8z7ou.Greeting>(data['data']);
    }
    if (dataClassName == 'LiveEvent') {
      return deserialize<_ixdzvre4.LiveEvent>(data['data']);
    }
    if (dataClassName == 'LiveKind') {
      return deserialize<_il8wtxvt.LiveKind>(data['data']);
    }
    if (dataClassName == 'MediaKind') {
      return deserialize<_i8mjpd0r.MediaKind>(data['data']);
    }
    if (dataClassName == 'UploadTicket') {
      return deserialize<_illp1jkh.UploadTicket>(data['data']);
    }
    if (dataClassName == 'PracticeException') {
      return deserialize<_ilvwtkyp.PracticeException>(data['data']);
    }
    if (dataClassName == 'PracticeFailure') {
      return deserialize<_iv6qijxa.PracticeFailure>(data['data']);
    }
    if (dataClassName == 'PracticeWord') {
      return deserialize<_iu9klhki.PracticeWord>(data['data']);
    }
    if (dataClassName == 'ViewOnlyLink') {
      return deserialize<_iveyennw.ViewOnlyLink>(data['data']);
    }
    if (dataClassName == 'SuggestException') {
      return deserialize<_iw5bueja.SuggestException>(data['data']);
    }
    if (dataClassName == 'SuggestFailure') {
      return deserialize<_iv4peolp.SuggestFailure>(data['data']);
    }
    if (dataClassName == 'WordSuggestion') {
      return deserialize<_ifctwajg.WordSuggestion>(data['data']);
    }
    if (dataClassName == 'WeekReport') {
      return deserialize<_iaf8iewd.WeekReport>(data['data']);
    }
    if (dataClassName == 'WordTally') {
      return deserialize<_i6roonjc.WordTally>(data['data']);
    }
    if (dataClassName == 'DeviceStatus') {
      return deserialize<_i1bd2zm2.DeviceStatus>(data['data']);
    }
    if (dataClassName == 'WordLogException') {
      return deserialize<_i163yf92.WordLogException>(data['data']);
    }
    if (dataClassName == 'WordLogFailure') {
      return deserialize<_i352cmsp.WordLogFailure>(data['data']);
    }
    if (dataClassName == 'WordLogStatus') {
      return deserialize<_i5lyi3mq.WordLogStatus>(data['data']);
    }
    if (dataClassName == 'WordUseEntry') {
      return deserialize<_in1k2ibs.WordUseEntry>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iaic.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_offline_sync.')) {
      data['className'] = dataClassName.substring(23);
      return _ipulbpi2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacc.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iaic.Protocol().registerHostProtocol('chorus', this);
    _ipulbpi2.Protocol().registerHostProtocol('chorus', this);
    _iacc.Protocol().registerHostProtocol('chorus', this);
  }

  @override
  _isd.Table? getTableForType(Type t) {
    {
      var protocol = _iaic.Protocol();
      var table = protocol is _isd.DatabaseSerializationManager
          ? (protocol as _isd.DatabaseSerializationManager).getTableForType(t)
          : null;
      if (table != null) {
        return table;
      }
    }
    {
      var protocol = _ipulbpi2.Protocol();
      var table = protocol is _isd.DatabaseSerializationManager
          ? (protocol as _isd.DatabaseSerializationManager).getTableForType(t)
          : null;
      if (table != null) {
        return table;
      }
    }
    {
      var protocol = _iacc.Protocol();
      var table = protocol is _isd.DatabaseSerializationManager
          ? (protocol as _isd.DatabaseSerializationManager).getTableForType(t)
          : null;
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i3lcnjeo.Board:
        return _i3lcnjeo.Board.t;
      case _ihyl55zs.Tile:
        return _ihyl55zs.Tile.t;
      case _ignkl5py.TileEdit:
        return _ignkl5py.TileEdit.t;
    }
    return null;
  }

  @override
  List<_isd.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'chorus';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _ipulbpi2.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
