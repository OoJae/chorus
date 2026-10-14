/// Interfaces the screens are written against.
///
/// The real implementations (local SQLite replica with Serverpod offline sync,
/// on-device text-to-speech) are wired in later. Every screen must work against
/// the in-memory fakes in `fakes.dart`, so the UI can be built and run before
/// sync exists.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';

/// What the signed-in adult may do in the current circle.
enum CircleRole { guardian, therapist, teacher, partner }

extension CircleRoleX on CircleRole {
  /// Partners are read-only; everyone else may edit the board.
  bool get canEdit => this != CircleRole.partner;
}

/// Thrown by [BoardStore.addTile] and [BoardStore.placeTile] when the target
/// cell is already occupied on this device. Callers do not need to catch it:
/// the store itself retries by sending the tile to the tray. It exists so the
/// UI can tell the adult what happened.
class CellOccupied implements Exception {
  const CellOccupied(this.boardId, this.row, this.col);
  final String boardId;
  final int row;
  final int col;
}

/// The local replica of one circle's boards and tiles.
///
/// Notifies listeners after every local write and after every merge from
/// another device.
abstract class BoardStore extends ChangeNotifier {
  /// Display name of the child this circle is for.
  String get childName;

  /// Name shown for the signed-in adult.
  String get myName;

  CircleRole get role;

  /// Every board in the circle, including archived ones.
  List<BoardFacts> get boards;

  /// Every tile in the circle, including archived, tray and contested ones.
  List<TileFacts> get tiles;

  /// Adds a new word. If the cell is occupied on this device the tile is
  /// created in the tray instead and the returned future completes with
  /// `false`; otherwise `true`.
  Future<bool> addTile({
    required String boardId,
    required int row,
    required int col,
    required String label,
    String? speech,
    String? colorKey,
  });

  /// Gives a tray or contested tile a home in an empty cell. Completes with
  /// `false` (tile stays in the tray) if the cell turned out to be occupied.
  Future<bool> placeTile(String tileId, {required int row, required int col});

  /// Changes a tile's content. Never changes its cell.
  Future<void> updateTile(
    String tileId, {
    String? label,
    String? speech,
    String? colorKey,
  });

  /// Removes a word from the board: sets it archived and frees its cell.
  Future<void> archiveTile(String tileId);
}

/// On-device speech.
abstract class SpeechService {
  /// Prepares the engine so the first tap is not slow. Safe to call twice.
  Future<void> warmUp();

  /// Speaks [text], interrupting anything already playing.
  Future<void> speak(String text);

  Future<void> stop();

  /// True while audio is playing.
  ValueListenable<bool> get speaking;

  /// False when no offline voice is available; the UI then shows a warning
  /// to adults.
  ValueListenable<bool> get offlineVoiceReady;
}

enum SyncState {
  signedOut,
  offline,
  clockSkew,
  connecting,
  live,
  backoff,
  needsUpdate,
  accessLost,
}

/// What the status chip shows.
abstract class SyncStatus extends ChangeNotifier {
  SyncState get state;

  /// When the last merge from or to the server completed.
  DateTime? get lastMergeAt;

  /// True while this device holds changes the server has not confirmed.
  bool get hasUnsent;

  /// Manual retry, behind the "Sync now" button.
  Future<void> syncNow();

  /// True while an adult has asked this device to work offline: sync is
  /// paused and every change stays on the device until it is switched back.
  bool get workingOffline => false;

  /// Pauses or resumes sync on this device. Nothing is lost either way:
  /// changes made while paused are sent when sync resumes.
  Future<void> setWorkingOffline(bool value) async {}

  /// How many changes made on this device wait to be sent, or null when
  /// that is not known (after a restart, before the first sync).
  int? get unsentChanges => null;
}
