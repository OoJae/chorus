/// The word log, "This week", sharing and board management of one circle,
/// made for the app's `CircleServices`.
library;

import 'package:chorus_client/chorus_client.dart' hide CircleRole;
import 'package:chorus_ui/contracts.dart' show CircleRole, CircleRoleX;
import 'package:chorus_ui/contracts.dart' as ui show SyncStatus;
import 'package:chorus_ui/contracts.dart' show SpeechService;
import 'package:chorus_ui/features/flags/w3.dart' show voiceChoiceEnabled;
import 'package:chorus_ui/contracts_boards.dart';
import 'package:chorus_ui/contracts_copies.dart' show BoardCopies;
import 'package:chorus_ui/contracts_scenes.dart' show SceneBook;
import 'package:chorus_ui/contracts_sharing.dart';
import 'package:chorus_ui/contracts_wordlog.dart';

import '../copies/server_board_copies.dart';
import '../media/media_files.dart' show openMediaFiles;
import '../scenes/server_scene_book.dart';
import '../sharing/server_board_sharing.dart';
import '../sync/adapters.dart';
import '../sync/replica_board_store.dart';
import '../voice/server_voice_choice.dart';
import '../wordlog/server_week_summary.dart';
import '../wordlog/server_word_log.dart';
import '../wordsettings/word_settings_wiring.dart';

/// What [openCircleFeatures] made for one circle and adult. The word log
/// holds a timer and a listener on sync, so the owner keeps this for as
/// long as the circle is open and calls [dispose] once.
class CircleFeatures {
  CircleFeatures._({
    required this.wordLog,
    required this.summary,
    required this.sharing,
    required this.boards,
    required this._log,
    required this._manager,
    this.scenes,
    this.copies,
    this.wordSettings,
    this.voice,
  });

  /// The circle's voice on this device. Null without a speech service or
  /// with the feature off.
  final ServerVoiceChoice? voice;

  /// The circle's word log on this device. Every role has one, to see
  /// whether it is on; only a guardian may change it, and a partner's
  /// device never sends anything.
  final WordLog wordLog;

  /// "This week". Null for a teacher or a partner, whom the server refuses.
  final WeekSummarySource? summary;

  /// View-only links and .obf exports. Null for a partner.
  final BoardSharing? sharing;

  /// Adding, renaming, archiving and importing boards. Null for a partner.
  final BoardManager? boards;

  /// The circle's picture scenes, kept on this device. Every role has
  /// them; only an editor changes them.
  final SceneBook? scenes;

  /// Named board copies. Every role may look; only an editor takes or
  /// deletes one.
  final BoardCopies? copies;

  /// Words hidden for now and the second language. Null when both are off.
  final WordSettings? wordSettings;

  final ServerWordLog _log;
  final _StoreBoardManager? _manager;
  bool _disposed = false;

  /// Stops the word log and closes any store opened for these features.
  /// Safe to call twice.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _log.dispose();
    _manager?.dispose();
    scenes?.dispose();
    wordSettings?.dispose();
    voice?.dispose();
  }
}

/// Makes the features of [circle] for the adult signed in as [userId] (the
/// replica's user id, lowercase as `CircleServices.userId` holds it).
///
/// [sync] is the workspace's supervisor: the word log sends only while it
/// is live and not paused. [openStore] opens a new store of [circle] on
/// this device's replica (in `SessionWorkspace`,
/// `() => _session.boardStore(circle)`); a store is opened only when board
/// management or a snapshot needs one, and closed again here.
///
/// Call it once per circle, and [CircleFeatures.dispose] the result when
/// the workspace closes. If the adult's role in the circle changes, dispose
/// the old features before opening new ones: both word logs would keep
/// their words in the same place on this device.
CircleFeatures openCircleFeatures(
  Client client, {
  required CircleInfo circle,
  required String userId,
  required ui.SyncStatus sync,
  required ReplicaBoardStore Function() openStore,
  SpeechService? speech,
}) {
  final role = roleOf(circle.myRole);
  final space = circle.spaceUuid;
  final log = ServerWordLog.forClient(
    client,
    circleSpace: space,
    userId: userId,
    role: role,
    sync: sync,
  );
  final mayView = role == CircleRole.guardian || role == CircleRole.therapist;
  final manager = role.canEdit ? _StoreBoardManager(openStore) : null;
  return CircleFeatures._(
    wordLog: log,
    summary: mayView
        ? ServerWeekSummary.forClient(
            client,
            circleSpace: space,
            role: role,
            log: log,
            sync: sync,
          )
        : null,
    sharing: role.canEdit
        ? ServerBoardSharing.forClient(
            client,
            circleSpace: space,
            snapshot: () => readSnapshot(openStore),
            sync: sync,
          )
        : null,
    boards: manager,
    log: log,
    manager: manager,
    scenes: ServerSceneBook(
      calls: SceneCalls.forClient(client, space),
      cache: NoteSceneCache(openMediaFiles(), 'scenes_${userId}_${space.uuid}'),
      canEdit: role.canEdit,
      sync: sync,
    ),
    copies: ServerBoardCopies(
      calls: CopyCalls.forClient(client, space),
      canEdit: role.canEdit,
      sync: sync,
    ),
    wordSettings: openWordSettings(
      client,
      circleSpace: space,
      userId: userId,
      role: role,
      sync: sync,
    ),
    voice: voiceChoiceEnabled && speech != null
        ? ServerVoiceChoice.forClient(
            client,
            circleSpace: space,
            canChange: role.canEdit,
            speech: speech,
            sync: sync,
          )
        : null,
  );
}

/// Holds what one circle's features are for the adult's role now: made on
/// first use, made again (after the old ones are disposed) when the role
/// changes, and never two at once, as two word logs of one circle would
/// keep their words in the same place on this device.
///
/// When making them fails, the slot holds nothing for that role and does
/// not try again: the board works without them.
class FeatureSlot<T extends Object> {
  FeatureSlot(this._dispose);

  final void Function(T features) _dispose;
  T? _value;
  Object? _role;
  bool _failed = false;
  bool _closed = false;

  /// The role the slot holds features for; null before the first ask.
  Object? get role => _role;

  /// The features for [role], made with [open] when the slot holds none
  /// for it. Null once [dispose]d or when [open] threw.
  T? forRole(Object role, T Function() open) {
    if (_closed) return null;
    if (_role == role && (_value != null || _failed)) return _value;
    _release();
    _role = role;
    _failed = false;
    try {
      return _value = open();
    } catch (_) {
      _failed = true;
      return null;
    }
  }

  /// Disposes what the slot holds; it makes nothing more after this.
  void dispose() {
    _closed = true;
    _release();
  }

  void _release() {
    final old = _value;
    _value = null;
    if (old != null) _dispose(old);
  }
}

/// The boards and words on this device now, read through a store opened
/// for the purpose and closed again.
Future<BoardSnapshot> readSnapshot(ReplicaBoardStore Function() open) async {
  final store = open();
  try {
    await store.refresh();
    return (
      childName: store.childName,
      boards: store.boards,
      tiles: store.tiles,
    );
  } finally {
    store.dispose();
  }
}

/// A [BoardManager] on a store of its own, opened on first use. Its writes
/// reach the replica like any other, and every other store of the circle
/// reads them on the next revision. Every failure, a closed circle's
/// included, arrives through the returned future.
class _StoreBoardManager implements BoardManager {
  _StoreBoardManager(this._open);

  final ReplicaBoardStore Function() _open;
  ReplicaBoardStore? _store;
  bool _disposed = false;

  ReplicaBoardStore get _target {
    if (_disposed) throw StateError('The circle is closed.');
    return _store ??= _open();
  }

  @override
  Future<String> addBoard(String name) async => _target.addBoard(name);

  @override
  Future<void> renameBoard(String boardId, String name) async =>
      _target.renameBoard(boardId, name);

  @override
  Future<void> archiveBoard(String boardId) async =>
      _target.archiveBoard(boardId);

  @override
  Future<BoardImport> importBoard(ObfBoard board) async =>
      _target.importBoard(board);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _store?.dispose();
    _store = null;
  }
}
