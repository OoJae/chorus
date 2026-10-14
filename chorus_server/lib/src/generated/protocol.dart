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
import 'package:chorus_server/src/generated/circles/circle_info.dart'
    as _iun4jhfl;
import 'package:chorus_server/src/generated/wordlog/word_use_entry.dart'
    as _i1jjj2rd;
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart'
    as _izehhkf5;
import 'boards/board.dart' as _i3lcnjeo;
import 'boards/tile.dart' as _ihyl55zs;
import 'boards/tile_edit.dart' as _ignkl5py;
import 'circles/circle.dart' as _ihms22h2;
import 'circles/circle_exception.dart' as _i4ewpqfy;
import 'circles/circle_failure.dart' as _igjnv98g;
import 'circles/circle_info.dart' as _i5j3z7cn;
import 'circles/circle_role.dart' as _il0wc3z7;
import 'circles/invitation.dart' as _ib6idedo;
import 'circles/member_info.dart' as _i5nn4t9p;
import 'circles/membership.dart' as _i5ll2qlc;
import 'circles/server_info.dart' as _iqe7186e;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'live/live_event.dart' as _ixdzvre4;
import 'live/live_kind.dart' as _il8wtxvt;
import 'media/media_kind.dart' as _i8mjpd0r;
import 'media/media_object.dart' as _i87lco0i;
import 'media/upload_ticket.dart' as _illp1jkh;
import 'printing/shared_snapshot.dart' as _if9s8td9;
import 'printing/snapshot_kind.dart' as _iergzj3e;
import 'sharing/view_only_link.dart' as _iveyennw;
import 'suggest/ai_usage.dart' as _inv1atzh;
import 'suggest/suggest_exception.dart' as _iw5bueja;
import 'suggest/suggest_failure.dart' as _iv4peolp;
import 'suggest/word_suggestion.dart' as _ifctwajg;
import 'summary/week_report.dart' as _iaf8iewd;
import 'summary/weekly_summary.dart' as _ikaxfpae;
import 'summary/word_tally.dart' as _i6roonjc;
import 'voice/circle_voice.dart' as _iyiv61tv;
import 'voice/voice_setting.dart' as _iex30usi;
import 'wordlog/word_log_exception.dart' as _i163yf92;
import 'wordlog/word_log_failure.dart' as _i352cmsp;
import 'wordlog/word_log_setting.dart' as _i8exouxb;
import 'wordlog/word_log_status.dart' as _i5lyi3mq;
import 'wordlog/word_use_entry.dart' as _in1k2ibs;
import 'wordlog/word_use_record.dart' as _iqz5pl6l;
export 'boards/board.dart';
export 'boards/tile.dart';
export 'boards/tile_edit.dart';
export 'circles/circle.dart';
export 'circles/circle_exception.dart';
export 'circles/circle_failure.dart';
export 'circles/circle_info.dart';
export 'circles/circle_role.dart';
export 'circles/invitation.dart';
export 'circles/member_info.dart';
export 'circles/membership.dart';
export 'circles/server_info.dart';
export 'greetings/greeting.dart';
export 'live/live_event.dart';
export 'live/live_kind.dart';
export 'media/media_kind.dart';
export 'media/media_object.dart';
export 'media/upload_ticket.dart';
export 'printing/shared_snapshot.dart';
export 'printing/snapshot_kind.dart';
export 'sharing/view_only_link.dart';
export 'suggest/ai_usage.dart';
export 'suggest/suggest_exception.dart';
export 'suggest/suggest_failure.dart';
export 'suggest/word_suggestion.dart';
export 'summary/week_report.dart';
export 'summary/weekly_summary.dart';
export 'summary/word_tally.dart';
export 'voice/circle_voice.dart';
export 'voice/voice_setting.dart';
export 'wordlog/word_log_exception.dart';
export 'wordlog/word_log_failure.dart';
export 'wordlog/word_log_setting.dart';
export 'wordlog/word_log_status.dart';
export 'wordlog/word_use_entry.dart';
export 'wordlog/word_use_record.dart';
export 'sync_tables.dart';

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'ai_usage',
      dartName: 'AiUsage',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'circleSpace',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'day',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'calls',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'ai_usage_circle_day_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'day',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'board',
      dartName: 'Board',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'spaceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'circleId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'rows',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'cols',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'isHome',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'archivedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'board_fk_0',
          columns: ['spaceId'],
          referenceTable: 'offline_sync_spaces',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'board_circle_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
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
    _isp.TableDefinition(
      name: 'circle',
      dartName: 'Circle',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'spaceUuid',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'childName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'circle_space_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'spaceUuid',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'circle_voice',
      dartName: 'CircleVoice',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'circleSpace',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'voiceName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'rate',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'pitch',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'changedBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'changedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'circle_voice_circle_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'invitation',
      dartName: 'Invitation',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'code',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'circleSpace',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'role',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:CircleRole',
        ),
        _isp.ColumnDefinition(
          name: 'createdBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'acceptedBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'invitation_code_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'code',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'media_object',
      dartName: 'MediaObject',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'circleSpace',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'sha256',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:MediaKind',
        ),
        _isp.ColumnDefinition(
          name: 'path',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'bytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'verifiedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'media_object_circle_hash_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sha256',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'membership',
      dartName: 'Membership',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'circleSpace',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'role',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:CircleRole',
        ),
        _isp.ColumnDefinition(
          name: 'displayName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'joinedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'membership_circle_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'membership_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'shared_snapshot',
      dartName: 'SharedSnapshot',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'token',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'circleSpace',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'boardJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'expiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SnapshotKind',
          columnDefault: '\'print\'',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'shared_snapshot_token_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'token',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'tile',
      dartName: 'Tile',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'spaceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'circleId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'boardId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'cellKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'label',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'speech',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'colorKey',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'imageHash',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'audioHash',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'linkBoardId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'noLog',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'archivedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'createdByName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'tile_fk_0',
          columns: ['spaceId'],
          referenceTable: 'offline_sync_spaces',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'tile_fk_1',
          columns: ['boardId'],
          referenceTable: 'board',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
          deferrable: _isp.DeferrableConstraint.initiallyDeferred,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'tile__spaceId__cellKey__unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'spaceId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'cellKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'tile_circle_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
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
    _isp.TableDefinition(
      name: 'tile_edit',
      dartName: 'TileEdit',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'spaceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'circleId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'tileId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'prop',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'oldValue',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'newValue',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'baseEditId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'reason',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'actorId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'actorName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'editedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'tile_edit_fk_0',
          columns: ['spaceId'],
          referenceTable: 'offline_sync_spaces',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'tile_edit_circle_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'tile_edit_tile_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'tileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
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
    _isp.TableDefinition(
      name: 'weekly_summary',
      dartName: 'WeeklySummary',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'circleSpace',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'weekStart',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'report',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'protocol:WeekReport',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'weekly_summary_circle_week_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'weekStart',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'word_log_setting',
      dartName: 'WordLogSetting',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'circleSpace',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'enabled',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'changedBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'changedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'word_log_setting_circle_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'word_use',
      dartName: 'WordUseRecord',
      schema: 'public',
      module: 'chorus',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'circleSpace',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'tileId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'boardId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'spokenAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'receivedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'word_use_circle_spoken_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'spokenAt',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'tileId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._iais.Protocol.targetTableDefinitions,
    ..._izehhkf5.Protocol.targetTableDefinitions,
    ..._iacs.Protocol.targetTableDefinitions,
    ..._isp.Protocol.targetTableDefinitions,
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
      } on _is.DeserializationClassNameNotFoundException catch (_) {
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
    if (t == _ihms22h2.Circle) {
      return _ihms22h2.Circle.fromJson(data) as T;
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
    if (t == _ib6idedo.Invitation) {
      return _ib6idedo.Invitation.fromJson(data) as T;
    }
    if (t == _i5nn4t9p.MemberInfo) {
      return _i5nn4t9p.MemberInfo.fromJson(data) as T;
    }
    if (t == _i5ll2qlc.Membership) {
      return _i5ll2qlc.Membership.fromJson(data) as T;
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
    if (t == _i87lco0i.MediaObject) {
      return _i87lco0i.MediaObject.fromJson(data) as T;
    }
    if (t == _illp1jkh.UploadTicket) {
      return _illp1jkh.UploadTicket.fromJson(data) as T;
    }
    if (t == _if9s8td9.SharedSnapshot) {
      return _if9s8td9.SharedSnapshot.fromJson(data) as T;
    }
    if (t == _iergzj3e.SnapshotKind) {
      return _iergzj3e.SnapshotKind.fromJson(data) as T;
    }
    if (t == _iveyennw.ViewOnlyLink) {
      return _iveyennw.ViewOnlyLink.fromJson(data) as T;
    }
    if (t == _inv1atzh.AiUsage) {
      return _inv1atzh.AiUsage.fromJson(data) as T;
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
    if (t == _ikaxfpae.WeeklySummary) {
      return _ikaxfpae.WeeklySummary.fromJson(data) as T;
    }
    if (t == _i6roonjc.WordTally) {
      return _i6roonjc.WordTally.fromJson(data) as T;
    }
    if (t == _iyiv61tv.CircleVoice) {
      return _iyiv61tv.CircleVoice.fromJson(data) as T;
    }
    if (t == _iex30usi.VoiceSetting) {
      return _iex30usi.VoiceSetting.fromJson(data) as T;
    }
    if (t == _i163yf92.WordLogException) {
      return _i163yf92.WordLogException.fromJson(data) as T;
    }
    if (t == _i352cmsp.WordLogFailure) {
      return _i352cmsp.WordLogFailure.fromJson(data) as T;
    }
    if (t == _i8exouxb.WordLogSetting) {
      return _i8exouxb.WordLogSetting.fromJson(data) as T;
    }
    if (t == _i5lyi3mq.WordLogStatus) {
      return _i5lyi3mq.WordLogStatus.fromJson(data) as T;
    }
    if (t == _in1k2ibs.WordUseEntry) {
      return _in1k2ibs.WordUseEntry.fromJson(data) as T;
    }
    if (t == _iqz5pl6l.WordUseRecord) {
      return _iqz5pl6l.WordUseRecord.fromJson(data) as T;
    }
    if (t == _is.getType<_i3lcnjeo.Board?>()) {
      return (data != null ? _i3lcnjeo.Board.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ihyl55zs.Tile?>()) {
      return (data != null ? _ihyl55zs.Tile.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ignkl5py.TileEdit?>()) {
      return (data != null ? _ignkl5py.TileEdit.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ihms22h2.Circle?>()) {
      return (data != null ? _ihms22h2.Circle.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i4ewpqfy.CircleException?>()) {
      return (data != null ? _i4ewpqfy.CircleException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_igjnv98g.CircleFailure?>()) {
      return (data != null ? _igjnv98g.CircleFailure.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5j3z7cn.CircleInfo?>()) {
      return (data != null ? _i5j3z7cn.CircleInfo.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_il0wc3z7.CircleRole?>()) {
      return (data != null ? _il0wc3z7.CircleRole.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ib6idedo.Invitation?>()) {
      return (data != null ? _ib6idedo.Invitation.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i5nn4t9p.MemberInfo?>()) {
      return (data != null ? _i5nn4t9p.MemberInfo.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i5ll2qlc.Membership?>()) {
      return (data != null ? _i5ll2qlc.Membership.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iqe7186e.ServerInfo?>()) {
      return (data != null ? _iqe7186e.ServerInfo.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ixdzvre4.LiveEvent?>()) {
      return (data != null ? _ixdzvre4.LiveEvent.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_il8wtxvt.LiveKind?>()) {
      return (data != null ? _il8wtxvt.LiveKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i8mjpd0r.MediaKind?>()) {
      return (data != null ? _i8mjpd0r.MediaKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i87lco0i.MediaObject?>()) {
      return (data != null ? _i87lco0i.MediaObject.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_illp1jkh.UploadTicket?>()) {
      return (data != null ? _illp1jkh.UploadTicket.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_if9s8td9.SharedSnapshot?>()) {
      return (data != null ? _if9s8td9.SharedSnapshot.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iergzj3e.SnapshotKind?>()) {
      return (data != null ? _iergzj3e.SnapshotKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iveyennw.ViewOnlyLink?>()) {
      return (data != null ? _iveyennw.ViewOnlyLink.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_inv1atzh.AiUsage?>()) {
      return (data != null ? _inv1atzh.AiUsage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iw5bueja.SuggestException?>()) {
      return (data != null ? _iw5bueja.SuggestException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iv4peolp.SuggestFailure?>()) {
      return (data != null ? _iv4peolp.SuggestFailure.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ifctwajg.WordSuggestion?>()) {
      return (data != null ? _ifctwajg.WordSuggestion.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iaf8iewd.WeekReport?>()) {
      return (data != null ? _iaf8iewd.WeekReport.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ikaxfpae.WeeklySummary?>()) {
      return (data != null ? _ikaxfpae.WeeklySummary.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i6roonjc.WordTally?>()) {
      return (data != null ? _i6roonjc.WordTally.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iyiv61tv.CircleVoice?>()) {
      return (data != null ? _iyiv61tv.CircleVoice.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iex30usi.VoiceSetting?>()) {
      return (data != null ? _iex30usi.VoiceSetting.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i163yf92.WordLogException?>()) {
      return (data != null ? _i163yf92.WordLogException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i352cmsp.WordLogFailure?>()) {
      return (data != null ? _i352cmsp.WordLogFailure.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i8exouxb.WordLogSetting?>()) {
      return (data != null ? _i8exouxb.WordLogSetting.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5lyi3mq.WordLogStatus?>()) {
      return (data != null ? _i5lyi3mq.WordLogStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_in1k2ibs.WordUseEntry?>()) {
      return (data != null ? _in1k2ibs.WordUseEntry.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iqz5pl6l.WordUseRecord?>()) {
      return (data != null ? _iqz5pl6l.WordUseRecord.fromJson(data) : null)
          as T;
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
    if (t == List<_iun4jhfl.CircleInfo>) {
      return (data as List)
              .map((e) => deserialize<_iun4jhfl.CircleInfo>(e))
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
    if (t == List<_i1jjj2rd.WordUseEntry>) {
      return (data as List)
              .map((e) => deserialize<_i1jjj2rd.WordUseEntry>(e))
              .toList()
          as T;
    }
    try {
      return _iais.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _izehhkf5.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacs.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _isp.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i3lcnjeo.Board => 'Board',
      _ihyl55zs.Tile => 'Tile',
      _ignkl5py.TileEdit => 'TileEdit',
      _ihms22h2.Circle => 'Circle',
      _i4ewpqfy.CircleException => 'CircleException',
      _igjnv98g.CircleFailure => 'CircleFailure',
      _i5j3z7cn.CircleInfo => 'CircleInfo',
      _il0wc3z7.CircleRole => 'CircleRole',
      _ib6idedo.Invitation => 'Invitation',
      _i5nn4t9p.MemberInfo => 'MemberInfo',
      _i5ll2qlc.Membership => 'Membership',
      _iqe7186e.ServerInfo => 'ServerInfo',
      _izw8z7ou.Greeting => 'Greeting',
      _ixdzvre4.LiveEvent => 'LiveEvent',
      _il8wtxvt.LiveKind => 'LiveKind',
      _i8mjpd0r.MediaKind => 'MediaKind',
      _i87lco0i.MediaObject => 'MediaObject',
      _illp1jkh.UploadTicket => 'UploadTicket',
      _if9s8td9.SharedSnapshot => 'SharedSnapshot',
      _iergzj3e.SnapshotKind => 'SnapshotKind',
      _iveyennw.ViewOnlyLink => 'ViewOnlyLink',
      _inv1atzh.AiUsage => 'AiUsage',
      _iw5bueja.SuggestException => 'SuggestException',
      _iv4peolp.SuggestFailure => 'SuggestFailure',
      _ifctwajg.WordSuggestion => 'WordSuggestion',
      _iaf8iewd.WeekReport => 'WeekReport',
      _ikaxfpae.WeeklySummary => 'WeeklySummary',
      _i6roonjc.WordTally => 'WordTally',
      _iyiv61tv.CircleVoice => 'CircleVoice',
      _iex30usi.VoiceSetting => 'VoiceSetting',
      _i163yf92.WordLogException => 'WordLogException',
      _i352cmsp.WordLogFailure => 'WordLogFailure',
      _i8exouxb.WordLogSetting => 'WordLogSetting',
      _i5lyi3mq.WordLogStatus => 'WordLogStatus',
      _in1k2ibs.WordUseEntry => 'WordUseEntry',
      _iqz5pl6l.WordUseRecord => 'WordUseRecord',
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
      case _ihms22h2.Circle():
        return 'Circle';
      case _i4ewpqfy.CircleException():
        return 'CircleException';
      case _igjnv98g.CircleFailure():
        return 'CircleFailure';
      case _i5j3z7cn.CircleInfo():
        return 'CircleInfo';
      case _il0wc3z7.CircleRole():
        return 'CircleRole';
      case _ib6idedo.Invitation():
        return 'Invitation';
      case _i5nn4t9p.MemberInfo():
        return 'MemberInfo';
      case _i5ll2qlc.Membership():
        return 'Membership';
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
      case _i87lco0i.MediaObject():
        return 'MediaObject';
      case _illp1jkh.UploadTicket():
        return 'UploadTicket';
      case _if9s8td9.SharedSnapshot():
        return 'SharedSnapshot';
      case _iergzj3e.SnapshotKind():
        return 'SnapshotKind';
      case _iveyennw.ViewOnlyLink():
        return 'ViewOnlyLink';
      case _inv1atzh.AiUsage():
        return 'AiUsage';
      case _iw5bueja.SuggestException():
        return 'SuggestException';
      case _iv4peolp.SuggestFailure():
        return 'SuggestFailure';
      case _ifctwajg.WordSuggestion():
        return 'WordSuggestion';
      case _iaf8iewd.WeekReport():
        return 'WeekReport';
      case _ikaxfpae.WeeklySummary():
        return 'WeeklySummary';
      case _i6roonjc.WordTally():
        return 'WordTally';
      case _iyiv61tv.CircleVoice():
        return 'CircleVoice';
      case _iex30usi.VoiceSetting():
        return 'VoiceSetting';
      case _i163yf92.WordLogException():
        return 'WordLogException';
      case _i352cmsp.WordLogFailure():
        return 'WordLogFailure';
      case _i8exouxb.WordLogSetting():
        return 'WordLogSetting';
      case _i5lyi3mq.WordLogStatus():
        return 'WordLogStatus';
      case _in1k2ibs.WordUseEntry():
        return 'WordUseEntry';
      case _iqz5pl6l.WordUseRecord():
        return 'WordUseRecord';
    }
    className = _iais.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _izehhkf5.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_offline_sync.$className';
    }
    className = _iacs.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
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
    if (dataClassName == 'Circle') {
      return deserialize<_ihms22h2.Circle>(data['data']);
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
    if (dataClassName == 'Invitation') {
      return deserialize<_ib6idedo.Invitation>(data['data']);
    }
    if (dataClassName == 'MemberInfo') {
      return deserialize<_i5nn4t9p.MemberInfo>(data['data']);
    }
    if (dataClassName == 'Membership') {
      return deserialize<_i5ll2qlc.Membership>(data['data']);
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
    if (dataClassName == 'MediaObject') {
      return deserialize<_i87lco0i.MediaObject>(data['data']);
    }
    if (dataClassName == 'UploadTicket') {
      return deserialize<_illp1jkh.UploadTicket>(data['data']);
    }
    if (dataClassName == 'SharedSnapshot') {
      return deserialize<_if9s8td9.SharedSnapshot>(data['data']);
    }
    if (dataClassName == 'SnapshotKind') {
      return deserialize<_iergzj3e.SnapshotKind>(data['data']);
    }
    if (dataClassName == 'ViewOnlyLink') {
      return deserialize<_iveyennw.ViewOnlyLink>(data['data']);
    }
    if (dataClassName == 'AiUsage') {
      return deserialize<_inv1atzh.AiUsage>(data['data']);
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
    if (dataClassName == 'WeeklySummary') {
      return deserialize<_ikaxfpae.WeeklySummary>(data['data']);
    }
    if (dataClassName == 'WordTally') {
      return deserialize<_i6roonjc.WordTally>(data['data']);
    }
    if (dataClassName == 'CircleVoice') {
      return deserialize<_iyiv61tv.CircleVoice>(data['data']);
    }
    if (dataClassName == 'VoiceSetting') {
      return deserialize<_iex30usi.VoiceSetting>(data['data']);
    }
    if (dataClassName == 'WordLogException') {
      return deserialize<_i163yf92.WordLogException>(data['data']);
    }
    if (dataClassName == 'WordLogFailure') {
      return deserialize<_i352cmsp.WordLogFailure>(data['data']);
    }
    if (dataClassName == 'WordLogSetting') {
      return deserialize<_i8exouxb.WordLogSetting>(data['data']);
    }
    if (dataClassName == 'WordLogStatus') {
      return deserialize<_i5lyi3mq.WordLogStatus>(data['data']);
    }
    if (dataClassName == 'WordUseEntry') {
      return deserialize<_in1k2ibs.WordUseEntry>(data['data']);
    }
    if (dataClassName == 'WordUseRecord') {
      return deserialize<_iqz5pl6l.WordUseRecord>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iais.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_offline_sync.')) {
      data['className'] = dataClassName.substring(23);
      return _izehhkf5.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacs.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iais.Protocol().registerHostProtocol('chorus', this);
    _izehhkf5.Protocol().registerHostProtocol('chorus', this);
    _iacs.Protocol().registerHostProtocol('chorus', this);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _iais.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _izehhkf5.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _iacs.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _isp.Protocol().getTableForType(t);
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
      case _ihms22h2.Circle:
        return _ihms22h2.Circle.t;
      case _ib6idedo.Invitation:
        return _ib6idedo.Invitation.t;
      case _i5ll2qlc.Membership:
        return _i5ll2qlc.Membership.t;
      case _i87lco0i.MediaObject:
        return _i87lco0i.MediaObject.t;
      case _if9s8td9.SharedSnapshot:
        return _if9s8td9.SharedSnapshot.t;
      case _inv1atzh.AiUsage:
        return _inv1atzh.AiUsage.t;
      case _ikaxfpae.WeeklySummary:
        return _ikaxfpae.WeeklySummary.t;
      case _iyiv61tv.CircleVoice:
        return _iyiv61tv.CircleVoice.t;
      case _i8exouxb.WordLogSetting:
        return _i8exouxb.WordLogSetting.t;
      case _iqz5pl6l.WordUseRecord:
        return _iqz5pl6l.WordUseRecord.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
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
      return _iais.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _izehhkf5.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacs.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
