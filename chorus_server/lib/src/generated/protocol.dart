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
import 'package:chorus_server/src/generated/circles/member_info.dart'
    as _isrvpywl;
import 'package:chorus_server/src/generated/copies/board_copy_info.dart'
    as _iv6nrv5r;
import 'package:chorus_server/src/generated/modelling/focus_word_info.dart'
    as _iwth5r5i;
import 'package:chorus_server/src/generated/scenes/scene_info.dart'
    as _i0srdpzw;
import 'package:chorus_server/src/generated/scenes/scene_spot_info.dart'
    as _ipw1gwuw;
import 'package:chorus_server/src/generated/sitter/sitter_tap_info.dart'
    as _iie3inqt;
import 'package:chorus_server/src/generated/suggest/word_suggestion.dart'
    as _iknl7ub9;
import 'package:chorus_server/src/generated/trust/device_status.dart'
    as _iu25h168;
import 'package:chorus_server/src/generated/word_suggestions/suggested_word_info.dart'
    as _igagi3at;
import 'package:chorus_server/src/generated/wordlog/word_use_entry.dart'
    as _i1jjj2rd;
import 'package:chorus_server/src/generated/wordsettings/word_translation.dart'
    as _iv8bzygo;
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
import 'copies/board_copy.dart' as _ijs3emu0;
import 'copies/board_copy_info.dart' as _icohyzn9;
import 'copies/board_copy_word.dart' as _i2osxjs3;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'live/live_event.dart' as _ixdzvre4;
import 'live/live_kind.dart' as _il8wtxvt;
import 'media/media_kind.dart' as _i8mjpd0r;
import 'media/media_object.dart' as _i87lco0i;
import 'media/upload_ticket.dart' as _illp1jkh;
import 'modelling/focus_nudge.dart' as _ihy8fc6y;
import 'modelling/focus_nudge_info.dart' as _id6gvdoh;
import 'modelling/focus_word.dart' as _i0v59hpr;
import 'modelling/focus_word_info.dart' as _i5dbpwlf;
import 'practice/practice_exception.dart' as _ilvwtkyp;
import 'practice/practice_failure.dart' as _iv6qijxa;
import 'practice/practice_word.dart' as _iu9klhki;
import 'printing/shared_snapshot.dart' as _if9s8td9;
import 'printing/snapshot_kind.dart' as _iergzj3e;
import 'progress/focus_report_line.dart' as _itswlrkt;
import 'progress/progress_report.dart' as _i5135299;
import 'progress/progress_report_link.dart' as _i6l0lkqz;
import 'quickphrases/quick_phrase.dart' as _i8q0qx3y;
import 'scenes/scene.dart' as _id3ymnod;
import 'scenes/scene_info.dart' as _idpmi5ts;
import 'scenes/scene_spot.dart' as _ikzlvz57;
import 'scenes/scene_spot_info.dart' as _iex9guyq;
import 'sharing/view_only_link.dart' as _iveyennw;
import 'sitter/sitter_tap.dart' as _i5yxvfrk;
import 'sitter/sitter_tap_info.dart' as _igr2wwcr;
import 'suggest/ai_usage.dart' as _inv1atzh;
import 'suggest/photo_idea_cache.dart' as _ix1g4tqw;
import 'suggest/suggest_exception.dart' as _iw5bueja;
import 'suggest/suggest_failure.dart' as _iv4peolp;
import 'suggest/word_suggestion.dart' as _ifctwajg;
import 'summary/modelled_tally.dart' as _ix06wsh7;
import 'summary/week_report.dart' as _iaf8iewd;
import 'summary/weekly_summary.dart' as _ikaxfpae;
import 'summary/word_tally.dart' as _i6roonjc;
import 'trust/device_seen.dart' as _ittyvjrh;
import 'trust/device_status.dart' as _i1bd2zm2;
import 'voice/circle_voice.dart' as _iyiv61tv;
import 'voice/voice_setting.dart' as _iex30usi;
import 'word_suggestions/suggested_word.dart' as _io8ht510;
import 'word_suggestions/suggested_word_info.dart' as _i6q1oeir;
import 'wordlog/word_log_exception.dart' as _i163yf92;
import 'wordlog/word_log_failure.dart' as _i352cmsp;
import 'wordlog/word_log_setting.dart' as _i8exouxb;
import 'wordlog/word_log_status.dart' as _i5lyi3mq;
import 'wordlog/word_use_entry.dart' as _in1k2ibs;
import 'wordlog/word_use_record.dart' as _iqz5pl6l;
import 'wordsettings/circle_language.dart' as _i1rpqem2;
import 'wordsettings/second_language.dart' as _inhgof02;
import 'wordsettings/tile_setting.dart' as _ikem9wvw;
import 'wordsettings/tile_translation.dart' as _imk02hea;
import 'wordsettings/word_settings_exception.dart' as _imidna6o;
import 'wordsettings/word_translation.dart' as _iupvr1f2;
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
export 'copies/board_copy.dart';
export 'copies/board_copy_info.dart';
export 'copies/board_copy_word.dart';
export 'greetings/greeting.dart';
export 'live/live_event.dart';
export 'live/live_kind.dart';
export 'media/media_kind.dart';
export 'media/media_object.dart';
export 'media/upload_ticket.dart';
export 'modelling/focus_nudge.dart';
export 'modelling/focus_nudge_info.dart';
export 'modelling/focus_word.dart';
export 'modelling/focus_word_info.dart';
export 'practice/practice_exception.dart';
export 'practice/practice_failure.dart';
export 'practice/practice_word.dart';
export 'printing/shared_snapshot.dart';
export 'printing/snapshot_kind.dart';
export 'progress/focus_report_line.dart';
export 'progress/progress_report.dart';
export 'progress/progress_report_link.dart';
export 'quickphrases/quick_phrase.dart';
export 'scenes/scene.dart';
export 'scenes/scene_info.dart';
export 'scenes/scene_spot.dart';
export 'scenes/scene_spot_info.dart';
export 'sharing/view_only_link.dart';
export 'sitter/sitter_tap.dart';
export 'sitter/sitter_tap_info.dart';
export 'suggest/ai_usage.dart';
export 'suggest/photo_idea_cache.dart';
export 'suggest/suggest_exception.dart';
export 'suggest/suggest_failure.dart';
export 'suggest/word_suggestion.dart';
export 'summary/modelled_tally.dart';
export 'summary/week_report.dart';
export 'summary/weekly_summary.dart';
export 'summary/word_tally.dart';
export 'trust/device_seen.dart';
export 'trust/device_status.dart';
export 'voice/circle_voice.dart';
export 'voice/voice_setting.dart';
export 'word_suggestions/suggested_word.dart';
export 'word_suggestions/suggested_word_info.dart';
export 'wordlog/word_log_exception.dart';
export 'wordlog/word_log_failure.dart';
export 'wordlog/word_log_setting.dart';
export 'wordlog/word_log_status.dart';
export 'wordlog/word_use_entry.dart';
export 'wordlog/word_use_record.dart';
export 'wordsettings/circle_language.dart';
export 'wordsettings/second_language.dart';
export 'wordsettings/tile_setting.dart';
export 'wordsettings/tile_translation.dart';
export 'wordsettings/word_settings_exception.dart';
export 'wordsettings/word_translation.dart';
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
      name: 'board_copy',
      dartName: 'BoardCopy',
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
          name: 'boardId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'boardName',
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
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'takenBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'takenByName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'takenAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'words',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<protocol:BoardCopyWord>',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'board_copy_circle_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'takenAt',
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
      name: 'circle_language',
      dartName: 'CircleLanguage',
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
          name: 'languageCode',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'languageName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
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
          indexName: 'circle_language_space_idx',
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
      name: 'device_seen',
      dartName: 'DeviceSeen',
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
          name: 'userName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'deviceId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'deviceLabel',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'lastSyncAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'lastSeenAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'device_seen_circle_user_device_idx',
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
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'deviceId',
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
      name: 'focus_nudge',
      dartName: 'FocusNudge',
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
          name: 'tileId',
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
          indexName: 'focus_nudge_circle_week_idx',
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
      name: 'focus_word',
      dartName: 'FocusWord',
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
          name: 'tip',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'weekStart',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'pinnedBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'pinnedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'focus_word_circle_week_tile_idx',
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
      name: 'photo_idea_cache',
      dartName: 'PhotoIdeaCache',
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
          name: 'imageSha256',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'locale',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'ideasJson',
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
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'photo_idea_cache_key_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'imageSha256',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'locale',
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
      name: 'progress_report_link',
      dartName: 'ProgressReportLink',
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
          name: 'report',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'protocol:ProgressReport',
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
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'progress_report_link_token_idx',
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
      name: 'quick_phrase',
      dartName: 'QuickPhrase',
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
          name: 'position',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'text',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'quick_phrase_space_position_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'position',
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
      name: 'scene',
      dartName: 'Scene',
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
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'imageHash',
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
          name: 'archivedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'scene_circle_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
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
      name: 'scene_spot',
      dartName: 'SceneSpot',
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
          name: 'sceneId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'x',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'y',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'width',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'height',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
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
          name: 'position',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'scene_spot_scene_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sceneId',
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
      name: 'sitter_tap',
      dartName: 'SitterTap',
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
          name: 'label',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'tappedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'sitter_tap_circle_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'tappedAt',
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
      name: 'tile_setting',
      dartName: 'TileSetting',
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
          name: 'hidden',
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
          indexName: 'tile_setting_space_tile_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
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
    _isp.TableDefinition(
      name: 'tile_translation',
      dartName: 'TileTranslation',
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
          name: 'languageCode',
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
          indexName: 'tile_translation_space_tile_lang_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'tileId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'languageCode',
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
      name: 'word_suggestion',
      dartName: 'SuggestedWord',
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
          name: 'suggestedBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'suggestedByName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'source',
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
        _isp.ColumnDefinition(
          name: 'resolvedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'resolution',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'resolvedBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'word_suggestion_circle_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'circleSpace',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'resolvedAt',
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
        _isp.ColumnDefinition(
          name: 'modelled',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
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
    if (t == _ijs3emu0.BoardCopy) {
      return _ijs3emu0.BoardCopy.fromJson(data) as T;
    }
    if (t == _icohyzn9.BoardCopyInfo) {
      return _icohyzn9.BoardCopyInfo.fromJson(data) as T;
    }
    if (t == _i2osxjs3.BoardCopyWord) {
      return _i2osxjs3.BoardCopyWord.fromJson(data) as T;
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
    if (t == _ihy8fc6y.FocusNudge) {
      return _ihy8fc6y.FocusNudge.fromJson(data) as T;
    }
    if (t == _id6gvdoh.FocusNudgeInfo) {
      return _id6gvdoh.FocusNudgeInfo.fromJson(data) as T;
    }
    if (t == _i0v59hpr.FocusWord) {
      return _i0v59hpr.FocusWord.fromJson(data) as T;
    }
    if (t == _i5dbpwlf.FocusWordInfo) {
      return _i5dbpwlf.FocusWordInfo.fromJson(data) as T;
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
    if (t == _if9s8td9.SharedSnapshot) {
      return _if9s8td9.SharedSnapshot.fromJson(data) as T;
    }
    if (t == _iergzj3e.SnapshotKind) {
      return _iergzj3e.SnapshotKind.fromJson(data) as T;
    }
    if (t == _itswlrkt.FocusReportLine) {
      return _itswlrkt.FocusReportLine.fromJson(data) as T;
    }
    if (t == _i5135299.ProgressReport) {
      return _i5135299.ProgressReport.fromJson(data) as T;
    }
    if (t == _i6l0lkqz.ProgressReportLink) {
      return _i6l0lkqz.ProgressReportLink.fromJson(data) as T;
    }
    if (t == _i8q0qx3y.QuickPhrase) {
      return _i8q0qx3y.QuickPhrase.fromJson(data) as T;
    }
    if (t == _id3ymnod.Scene) {
      return _id3ymnod.Scene.fromJson(data) as T;
    }
    if (t == _idpmi5ts.SceneInfo) {
      return _idpmi5ts.SceneInfo.fromJson(data) as T;
    }
    if (t == _ikzlvz57.SceneSpot) {
      return _ikzlvz57.SceneSpot.fromJson(data) as T;
    }
    if (t == _iex9guyq.SceneSpotInfo) {
      return _iex9guyq.SceneSpotInfo.fromJson(data) as T;
    }
    if (t == _iveyennw.ViewOnlyLink) {
      return _iveyennw.ViewOnlyLink.fromJson(data) as T;
    }
    if (t == _i5yxvfrk.SitterTap) {
      return _i5yxvfrk.SitterTap.fromJson(data) as T;
    }
    if (t == _igr2wwcr.SitterTapInfo) {
      return _igr2wwcr.SitterTapInfo.fromJson(data) as T;
    }
    if (t == _inv1atzh.AiUsage) {
      return _inv1atzh.AiUsage.fromJson(data) as T;
    }
    if (t == _ix1g4tqw.PhotoIdeaCache) {
      return _ix1g4tqw.PhotoIdeaCache.fromJson(data) as T;
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
    if (t == _ix06wsh7.ModelledTally) {
      return _ix06wsh7.ModelledTally.fromJson(data) as T;
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
    if (t == _ittyvjrh.DeviceSeen) {
      return _ittyvjrh.DeviceSeen.fromJson(data) as T;
    }
    if (t == _i1bd2zm2.DeviceStatus) {
      return _i1bd2zm2.DeviceStatus.fromJson(data) as T;
    }
    if (t == _iyiv61tv.CircleVoice) {
      return _iyiv61tv.CircleVoice.fromJson(data) as T;
    }
    if (t == _iex30usi.VoiceSetting) {
      return _iex30usi.VoiceSetting.fromJson(data) as T;
    }
    if (t == _io8ht510.SuggestedWord) {
      return _io8ht510.SuggestedWord.fromJson(data) as T;
    }
    if (t == _i6q1oeir.SuggestedWordInfo) {
      return _i6q1oeir.SuggestedWordInfo.fromJson(data) as T;
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
    if (t == _i1rpqem2.CircleLanguage) {
      return _i1rpqem2.CircleLanguage.fromJson(data) as T;
    }
    if (t == _inhgof02.SecondLanguage) {
      return _inhgof02.SecondLanguage.fromJson(data) as T;
    }
    if (t == _ikem9wvw.TileSetting) {
      return _ikem9wvw.TileSetting.fromJson(data) as T;
    }
    if (t == _imk02hea.TileTranslation) {
      return _imk02hea.TileTranslation.fromJson(data) as T;
    }
    if (t == _imidna6o.WordSettingsException) {
      return _imidna6o.WordSettingsException.fromJson(data) as T;
    }
    if (t == _iupvr1f2.WordTranslation) {
      return _iupvr1f2.WordTranslation.fromJson(data) as T;
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
    if (t == _is.getType<_ijs3emu0.BoardCopy?>()) {
      return (data != null ? _ijs3emu0.BoardCopy.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_icohyzn9.BoardCopyInfo?>()) {
      return (data != null ? _icohyzn9.BoardCopyInfo.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i2osxjs3.BoardCopyWord?>()) {
      return (data != null ? _i2osxjs3.BoardCopyWord.fromJson(data) : null)
          as T;
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
    if (t == _is.getType<_ihy8fc6y.FocusNudge?>()) {
      return (data != null ? _ihy8fc6y.FocusNudge.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_id6gvdoh.FocusNudgeInfo?>()) {
      return (data != null ? _id6gvdoh.FocusNudgeInfo.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i0v59hpr.FocusWord?>()) {
      return (data != null ? _i0v59hpr.FocusWord.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i5dbpwlf.FocusWordInfo?>()) {
      return (data != null ? _i5dbpwlf.FocusWordInfo.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ilvwtkyp.PracticeException?>()) {
      return (data != null ? _ilvwtkyp.PracticeException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iv6qijxa.PracticeFailure?>()) {
      return (data != null ? _iv6qijxa.PracticeFailure.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iu9klhki.PracticeWord?>()) {
      return (data != null ? _iu9klhki.PracticeWord.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_if9s8td9.SharedSnapshot?>()) {
      return (data != null ? _if9s8td9.SharedSnapshot.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iergzj3e.SnapshotKind?>()) {
      return (data != null ? _iergzj3e.SnapshotKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_itswlrkt.FocusReportLine?>()) {
      return (data != null ? _itswlrkt.FocusReportLine.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5135299.ProgressReport?>()) {
      return (data != null ? _i5135299.ProgressReport.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i6l0lkqz.ProgressReportLink?>()) {
      return (data != null ? _i6l0lkqz.ProgressReportLink.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i8q0qx3y.QuickPhrase?>()) {
      return (data != null ? _i8q0qx3y.QuickPhrase.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_id3ymnod.Scene?>()) {
      return (data != null ? _id3ymnod.Scene.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_idpmi5ts.SceneInfo?>()) {
      return (data != null ? _idpmi5ts.SceneInfo.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ikzlvz57.SceneSpot?>()) {
      return (data != null ? _ikzlvz57.SceneSpot.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iex9guyq.SceneSpotInfo?>()) {
      return (data != null ? _iex9guyq.SceneSpotInfo.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iveyennw.ViewOnlyLink?>()) {
      return (data != null ? _iveyennw.ViewOnlyLink.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i5yxvfrk.SitterTap?>()) {
      return (data != null ? _i5yxvfrk.SitterTap.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_igr2wwcr.SitterTapInfo?>()) {
      return (data != null ? _igr2wwcr.SitterTapInfo.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_inv1atzh.AiUsage?>()) {
      return (data != null ? _inv1atzh.AiUsage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ix1g4tqw.PhotoIdeaCache?>()) {
      return (data != null ? _ix1g4tqw.PhotoIdeaCache.fromJson(data) : null)
          as T;
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
    if (t == _is.getType<_ix06wsh7.ModelledTally?>()) {
      return (data != null ? _ix06wsh7.ModelledTally.fromJson(data) : null)
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
    if (t == _is.getType<_ittyvjrh.DeviceSeen?>()) {
      return (data != null ? _ittyvjrh.DeviceSeen.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i1bd2zm2.DeviceStatus?>()) {
      return (data != null ? _i1bd2zm2.DeviceStatus.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iyiv61tv.CircleVoice?>()) {
      return (data != null ? _iyiv61tv.CircleVoice.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iex30usi.VoiceSetting?>()) {
      return (data != null ? _iex30usi.VoiceSetting.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_io8ht510.SuggestedWord?>()) {
      return (data != null ? _io8ht510.SuggestedWord.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i6q1oeir.SuggestedWordInfo?>()) {
      return (data != null ? _i6q1oeir.SuggestedWordInfo.fromJson(data) : null)
          as T;
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
    if (t == _is.getType<_i1rpqem2.CircleLanguage?>()) {
      return (data != null ? _i1rpqem2.CircleLanguage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_inhgof02.SecondLanguage?>()) {
      return (data != null ? _inhgof02.SecondLanguage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ikem9wvw.TileSetting?>()) {
      return (data != null ? _ikem9wvw.TileSetting.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_imk02hea.TileTranslation?>()) {
      return (data != null ? _imk02hea.TileTranslation.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_imidna6o.WordSettingsException?>()) {
      return (data != null
              ? _imidna6o.WordSettingsException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iupvr1f2.WordTranslation?>()) {
      return (data != null ? _iupvr1f2.WordTranslation.fromJson(data) : null)
          as T;
    }
    if (t == List<_i5nn4t9p.MemberInfo>) {
      return (data as List)
              .map((e) => deserialize<_i5nn4t9p.MemberInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i2osxjs3.BoardCopyWord>) {
      return (data as List)
              .map((e) => deserialize<_i2osxjs3.BoardCopyWord>(e))
              .toList()
          as T;
    }
    if (t == List<_itswlrkt.FocusReportLine>) {
      return (data as List)
              .map((e) => deserialize<_itswlrkt.FocusReportLine>(e))
              .toList()
          as T;
    }
    if (t == List<_iex9guyq.SceneSpotInfo>) {
      return (data as List)
              .map((e) => deserialize<_iex9guyq.SceneSpotInfo>(e))
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
    if (t == List<_ix06wsh7.ModelledTally>) {
      return (data as List)
              .map((e) => deserialize<_ix06wsh7.ModelledTally>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<_ix06wsh7.ModelledTally>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_ix06wsh7.ModelledTally>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_iun4jhfl.CircleInfo>) {
      return (data as List)
              .map((e) => deserialize<_iun4jhfl.CircleInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_iv6nrv5r.BoardCopyInfo>) {
      return (data as List)
              .map((e) => deserialize<_iv6nrv5r.BoardCopyInfo>(e))
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
    if (t == List<_isrvpywl.MemberInfo>) {
      return (data as List)
              .map((e) => deserialize<_isrvpywl.MemberInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_iwth5r5i.FocusWordInfo>) {
      return (data as List)
              .map((e) => deserialize<_iwth5r5i.FocusWordInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i0srdpzw.SceneInfo>) {
      return (data as List)
              .map((e) => deserialize<_i0srdpzw.SceneInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_ipw1gwuw.SceneSpotInfo>) {
      return (data as List)
              .map((e) => deserialize<_ipw1gwuw.SceneSpotInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_iie3inqt.SitterTapInfo>) {
      return (data as List)
              .map((e) => deserialize<_iie3inqt.SitterTapInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_iknl7ub9.WordSuggestion>) {
      return (data as List)
              .map((e) => deserialize<_iknl7ub9.WordSuggestion>(e))
              .toList()
          as T;
    }
    if (t == List<_iu25h168.DeviceStatus>) {
      return (data as List)
              .map((e) => deserialize<_iu25h168.DeviceStatus>(e))
              .toList()
          as T;
    }
    if (t == List<_igagi3at.SuggestedWordInfo>) {
      return (data as List)
              .map((e) => deserialize<_igagi3at.SuggestedWordInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_i1jjj2rd.WordUseEntry>) {
      return (data as List)
              .map((e) => deserialize<_i1jjj2rd.WordUseEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_is.UuidValue>) {
      return (data as List).map((e) => deserialize<_is.UuidValue>(e)).toList()
          as T;
    }
    if (t == List<_iv8bzygo.WordTranslation>) {
      return (data as List)
              .map((e) => deserialize<_iv8bzygo.WordTranslation>(e))
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
      _ijs3emu0.BoardCopy => 'BoardCopy',
      _icohyzn9.BoardCopyInfo => 'BoardCopyInfo',
      _i2osxjs3.BoardCopyWord => 'BoardCopyWord',
      _izw8z7ou.Greeting => 'Greeting',
      _ixdzvre4.LiveEvent => 'LiveEvent',
      _il8wtxvt.LiveKind => 'LiveKind',
      _i8mjpd0r.MediaKind => 'MediaKind',
      _i87lco0i.MediaObject => 'MediaObject',
      _illp1jkh.UploadTicket => 'UploadTicket',
      _ihy8fc6y.FocusNudge => 'FocusNudge',
      _id6gvdoh.FocusNudgeInfo => 'FocusNudgeInfo',
      _i0v59hpr.FocusWord => 'FocusWord',
      _i5dbpwlf.FocusWordInfo => 'FocusWordInfo',
      _ilvwtkyp.PracticeException => 'PracticeException',
      _iv6qijxa.PracticeFailure => 'PracticeFailure',
      _iu9klhki.PracticeWord => 'PracticeWord',
      _if9s8td9.SharedSnapshot => 'SharedSnapshot',
      _iergzj3e.SnapshotKind => 'SnapshotKind',
      _itswlrkt.FocusReportLine => 'FocusReportLine',
      _i5135299.ProgressReport => 'ProgressReport',
      _i6l0lkqz.ProgressReportLink => 'ProgressReportLink',
      _i8q0qx3y.QuickPhrase => 'QuickPhrase',
      _id3ymnod.Scene => 'Scene',
      _idpmi5ts.SceneInfo => 'SceneInfo',
      _ikzlvz57.SceneSpot => 'SceneSpot',
      _iex9guyq.SceneSpotInfo => 'SceneSpotInfo',
      _iveyennw.ViewOnlyLink => 'ViewOnlyLink',
      _i5yxvfrk.SitterTap => 'SitterTap',
      _igr2wwcr.SitterTapInfo => 'SitterTapInfo',
      _inv1atzh.AiUsage => 'AiUsage',
      _ix1g4tqw.PhotoIdeaCache => 'PhotoIdeaCache',
      _iw5bueja.SuggestException => 'SuggestException',
      _iv4peolp.SuggestFailure => 'SuggestFailure',
      _ifctwajg.WordSuggestion => 'WordSuggestion',
      _ix06wsh7.ModelledTally => 'ModelledTally',
      _iaf8iewd.WeekReport => 'WeekReport',
      _ikaxfpae.WeeklySummary => 'WeeklySummary',
      _i6roonjc.WordTally => 'WordTally',
      _ittyvjrh.DeviceSeen => 'DeviceSeen',
      _i1bd2zm2.DeviceStatus => 'DeviceStatus',
      _iyiv61tv.CircleVoice => 'CircleVoice',
      _iex30usi.VoiceSetting => 'VoiceSetting',
      _io8ht510.SuggestedWord => 'SuggestedWord',
      _i6q1oeir.SuggestedWordInfo => 'SuggestedWordInfo',
      _i163yf92.WordLogException => 'WordLogException',
      _i352cmsp.WordLogFailure => 'WordLogFailure',
      _i8exouxb.WordLogSetting => 'WordLogSetting',
      _i5lyi3mq.WordLogStatus => 'WordLogStatus',
      _in1k2ibs.WordUseEntry => 'WordUseEntry',
      _iqz5pl6l.WordUseRecord => 'WordUseRecord',
      _i1rpqem2.CircleLanguage => 'CircleLanguage',
      _inhgof02.SecondLanguage => 'SecondLanguage',
      _ikem9wvw.TileSetting => 'TileSetting',
      _imk02hea.TileTranslation => 'TileTranslation',
      _imidna6o.WordSettingsException => 'WordSettingsException',
      _iupvr1f2.WordTranslation => 'WordTranslation',
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
      case _ijs3emu0.BoardCopy():
        return 'BoardCopy';
      case _icohyzn9.BoardCopyInfo():
        return 'BoardCopyInfo';
      case _i2osxjs3.BoardCopyWord():
        return 'BoardCopyWord';
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
      case _ihy8fc6y.FocusNudge():
        return 'FocusNudge';
      case _id6gvdoh.FocusNudgeInfo():
        return 'FocusNudgeInfo';
      case _i0v59hpr.FocusWord():
        return 'FocusWord';
      case _i5dbpwlf.FocusWordInfo():
        return 'FocusWordInfo';
      case _ilvwtkyp.PracticeException():
        return 'PracticeException';
      case _iv6qijxa.PracticeFailure():
        return 'PracticeFailure';
      case _iu9klhki.PracticeWord():
        return 'PracticeWord';
      case _if9s8td9.SharedSnapshot():
        return 'SharedSnapshot';
      case _iergzj3e.SnapshotKind():
        return 'SnapshotKind';
      case _itswlrkt.FocusReportLine():
        return 'FocusReportLine';
      case _i5135299.ProgressReport():
        return 'ProgressReport';
      case _i6l0lkqz.ProgressReportLink():
        return 'ProgressReportLink';
      case _i8q0qx3y.QuickPhrase():
        return 'QuickPhrase';
      case _id3ymnod.Scene():
        return 'Scene';
      case _idpmi5ts.SceneInfo():
        return 'SceneInfo';
      case _ikzlvz57.SceneSpot():
        return 'SceneSpot';
      case _iex9guyq.SceneSpotInfo():
        return 'SceneSpotInfo';
      case _iveyennw.ViewOnlyLink():
        return 'ViewOnlyLink';
      case _i5yxvfrk.SitterTap():
        return 'SitterTap';
      case _igr2wwcr.SitterTapInfo():
        return 'SitterTapInfo';
      case _inv1atzh.AiUsage():
        return 'AiUsage';
      case _ix1g4tqw.PhotoIdeaCache():
        return 'PhotoIdeaCache';
      case _iw5bueja.SuggestException():
        return 'SuggestException';
      case _iv4peolp.SuggestFailure():
        return 'SuggestFailure';
      case _ifctwajg.WordSuggestion():
        return 'WordSuggestion';
      case _ix06wsh7.ModelledTally():
        return 'ModelledTally';
      case _iaf8iewd.WeekReport():
        return 'WeekReport';
      case _ikaxfpae.WeeklySummary():
        return 'WeeklySummary';
      case _i6roonjc.WordTally():
        return 'WordTally';
      case _ittyvjrh.DeviceSeen():
        return 'DeviceSeen';
      case _i1bd2zm2.DeviceStatus():
        return 'DeviceStatus';
      case _iyiv61tv.CircleVoice():
        return 'CircleVoice';
      case _iex30usi.VoiceSetting():
        return 'VoiceSetting';
      case _io8ht510.SuggestedWord():
        return 'SuggestedWord';
      case _i6q1oeir.SuggestedWordInfo():
        return 'SuggestedWordInfo';
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
      case _i1rpqem2.CircleLanguage():
        return 'CircleLanguage';
      case _inhgof02.SecondLanguage():
        return 'SecondLanguage';
      case _ikem9wvw.TileSetting():
        return 'TileSetting';
      case _imk02hea.TileTranslation():
        return 'TileTranslation';
      case _imidna6o.WordSettingsException():
        return 'WordSettingsException';
      case _iupvr1f2.WordTranslation():
        return 'WordTranslation';
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
    if (dataClassName == 'BoardCopy') {
      return deserialize<_ijs3emu0.BoardCopy>(data['data']);
    }
    if (dataClassName == 'BoardCopyInfo') {
      return deserialize<_icohyzn9.BoardCopyInfo>(data['data']);
    }
    if (dataClassName == 'BoardCopyWord') {
      return deserialize<_i2osxjs3.BoardCopyWord>(data['data']);
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
    if (dataClassName == 'FocusNudge') {
      return deserialize<_ihy8fc6y.FocusNudge>(data['data']);
    }
    if (dataClassName == 'FocusNudgeInfo') {
      return deserialize<_id6gvdoh.FocusNudgeInfo>(data['data']);
    }
    if (dataClassName == 'FocusWord') {
      return deserialize<_i0v59hpr.FocusWord>(data['data']);
    }
    if (dataClassName == 'FocusWordInfo') {
      return deserialize<_i5dbpwlf.FocusWordInfo>(data['data']);
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
    if (dataClassName == 'SharedSnapshot') {
      return deserialize<_if9s8td9.SharedSnapshot>(data['data']);
    }
    if (dataClassName == 'SnapshotKind') {
      return deserialize<_iergzj3e.SnapshotKind>(data['data']);
    }
    if (dataClassName == 'FocusReportLine') {
      return deserialize<_itswlrkt.FocusReportLine>(data['data']);
    }
    if (dataClassName == 'ProgressReport') {
      return deserialize<_i5135299.ProgressReport>(data['data']);
    }
    if (dataClassName == 'ProgressReportLink') {
      return deserialize<_i6l0lkqz.ProgressReportLink>(data['data']);
    }
    if (dataClassName == 'QuickPhrase') {
      return deserialize<_i8q0qx3y.QuickPhrase>(data['data']);
    }
    if (dataClassName == 'Scene') {
      return deserialize<_id3ymnod.Scene>(data['data']);
    }
    if (dataClassName == 'SceneInfo') {
      return deserialize<_idpmi5ts.SceneInfo>(data['data']);
    }
    if (dataClassName == 'SceneSpot') {
      return deserialize<_ikzlvz57.SceneSpot>(data['data']);
    }
    if (dataClassName == 'SceneSpotInfo') {
      return deserialize<_iex9guyq.SceneSpotInfo>(data['data']);
    }
    if (dataClassName == 'ViewOnlyLink') {
      return deserialize<_iveyennw.ViewOnlyLink>(data['data']);
    }
    if (dataClassName == 'SitterTap') {
      return deserialize<_i5yxvfrk.SitterTap>(data['data']);
    }
    if (dataClassName == 'SitterTapInfo') {
      return deserialize<_igr2wwcr.SitterTapInfo>(data['data']);
    }
    if (dataClassName == 'AiUsage') {
      return deserialize<_inv1atzh.AiUsage>(data['data']);
    }
    if (dataClassName == 'PhotoIdeaCache') {
      return deserialize<_ix1g4tqw.PhotoIdeaCache>(data['data']);
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
    if (dataClassName == 'ModelledTally') {
      return deserialize<_ix06wsh7.ModelledTally>(data['data']);
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
    if (dataClassName == 'DeviceSeen') {
      return deserialize<_ittyvjrh.DeviceSeen>(data['data']);
    }
    if (dataClassName == 'DeviceStatus') {
      return deserialize<_i1bd2zm2.DeviceStatus>(data['data']);
    }
    if (dataClassName == 'CircleVoice') {
      return deserialize<_iyiv61tv.CircleVoice>(data['data']);
    }
    if (dataClassName == 'VoiceSetting') {
      return deserialize<_iex30usi.VoiceSetting>(data['data']);
    }
    if (dataClassName == 'SuggestedWord') {
      return deserialize<_io8ht510.SuggestedWord>(data['data']);
    }
    if (dataClassName == 'SuggestedWordInfo') {
      return deserialize<_i6q1oeir.SuggestedWordInfo>(data['data']);
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
    if (dataClassName == 'CircleLanguage') {
      return deserialize<_i1rpqem2.CircleLanguage>(data['data']);
    }
    if (dataClassName == 'SecondLanguage') {
      return deserialize<_inhgof02.SecondLanguage>(data['data']);
    }
    if (dataClassName == 'TileSetting') {
      return deserialize<_ikem9wvw.TileSetting>(data['data']);
    }
    if (dataClassName == 'TileTranslation') {
      return deserialize<_imk02hea.TileTranslation>(data['data']);
    }
    if (dataClassName == 'WordSettingsException') {
      return deserialize<_imidna6o.WordSettingsException>(data['data']);
    }
    if (dataClassName == 'WordTranslation') {
      return deserialize<_iupvr1f2.WordTranslation>(data['data']);
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
      case _ijs3emu0.BoardCopy:
        return _ijs3emu0.BoardCopy.t;
      case _i87lco0i.MediaObject:
        return _i87lco0i.MediaObject.t;
      case _ihy8fc6y.FocusNudge:
        return _ihy8fc6y.FocusNudge.t;
      case _i0v59hpr.FocusWord:
        return _i0v59hpr.FocusWord.t;
      case _if9s8td9.SharedSnapshot:
        return _if9s8td9.SharedSnapshot.t;
      case _i6l0lkqz.ProgressReportLink:
        return _i6l0lkqz.ProgressReportLink.t;
      case _i8q0qx3y.QuickPhrase:
        return _i8q0qx3y.QuickPhrase.t;
      case _id3ymnod.Scene:
        return _id3ymnod.Scene.t;
      case _ikzlvz57.SceneSpot:
        return _ikzlvz57.SceneSpot.t;
      case _i5yxvfrk.SitterTap:
        return _i5yxvfrk.SitterTap.t;
      case _inv1atzh.AiUsage:
        return _inv1atzh.AiUsage.t;
      case _ix1g4tqw.PhotoIdeaCache:
        return _ix1g4tqw.PhotoIdeaCache.t;
      case _ikaxfpae.WeeklySummary:
        return _ikaxfpae.WeeklySummary.t;
      case _ittyvjrh.DeviceSeen:
        return _ittyvjrh.DeviceSeen.t;
      case _iyiv61tv.CircleVoice:
        return _iyiv61tv.CircleVoice.t;
      case _io8ht510.SuggestedWord:
        return _io8ht510.SuggestedWord.t;
      case _i8exouxb.WordLogSetting:
        return _i8exouxb.WordLogSetting.t;
      case _iqz5pl6l.WordUseRecord:
        return _iqz5pl6l.WordUseRecord.t;
      case _i1rpqem2.CircleLanguage:
        return _i1rpqem2.CircleLanguage.t;
      case _ikem9wvw.TileSetting:
        return _ikem9wvw.TileSetting.t;
      case _imk02hea.TileTranslation:
        return _imk02hea.TileTranslation.t;
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
