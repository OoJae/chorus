/// Everything the signed-in user needs to work offline: the replica, the
/// sync supervisor and a board store per circle.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_database/serverpod_database.dart'
    show DatabaseQueryException;
import 'package:serverpod_offline_sync_client/offline_sync.dart';

import 'adapters.dart';
import 'replica_board_store.dart';
import 'replica_service.dart';
import 'sync_supervisor.dart';

/// This app's build number. The server's `minBuild` is compared with it
/// before every sync; raise both together when the synced tables change.
const int chorusBuild = 1;

/// The sync core of one signed-in user. Open one after sign-in and close it
/// at sign-out; a different user gets a different replica file.
class ChorusSession {
  ChorusSession._(this._replica, this.sync);

  final ReplicaService _replica;

  /// Keeps sync going and reports its state. Call `start()` once.
  final SyncSupervisor sync;

  final Set<ReplicaBoardStore> _stores = {};
  bool _closed = false;

  /// The one wait on the supervisor's own next sync, shared by every tick
  /// of every [ensureCircleReady] call until it completes.
  Future<bool>? _nextSync;

  /// Opens the replica of the user signed in on [client]. Works with no
  /// network. Throws [StateError] if nobody is signed in.
  static Future<ChorusSession> open(Client client) async {
    final userId = client.auth.authInfo?.authUserId;
    if (userId == null) {
      throw StateError('Sign in before opening a Chorus session.');
    }
    final replica = await ReplicaService.open(client, userId);
    final sync = SyncSupervisor.forClient(
      client,
      replica.session,
      build: chorusBuild,
    );
    replica.onLocalWrite = sync.noteLocalWrite;
    return ChorusSession._(replica, sync);
  }

  /// A session over parts made elsewhere, for tests.
  factory ChorusSession.of(ReplicaService replica, SyncSupervisor sync) {
    replica.onLocalWrite = sync.noteLocalWrite;
    return ChorusSession._(replica, sync);
  }

  UuidValue get userId => _replica.userId;

  /// Completes once a sync has delivered this circle's space to this device;
  /// if [seedIfEmpty] and the circle has no home board, seeds the starter
  /// board.
  ///
  /// With the circle already on the device this needs no network. Seeding
  /// does: a home board that exists on the server but has not arrived yet
  /// must not be written over, so the starter board is only inserted
  /// straight after a sync that succeeded. Until then the call keeps
  /// waiting; put a timeout on it if the caller should give up. Throws
  /// [StateError] if the session is closed first.
  Future<void> ensureCircleReady(
    CircleInfo circle, {
    bool seedIfEmpty = false,
  }) async {
    final space = circle.spaceUuid;

    // Whether the latest sync succeeded with the circle already known, which
    // is when this device has seen everything the server holds for it.
    var upToDate = false;
    var role = await _roleIn(space);
    for (var round = 0; role == null; round++) {
      final synced = await _syncedOrTick(first: round == 0);
      role = await _roleIn(space);
      upToDate = synced && role != null;
    }

    if (!seedIfEmpty || !role.canWrite) return;
    for (var round = 0; !await _hasHomeBoard(space); round++) {
      if (upToDate) {
        await _seed(circle);
        break;
      }
      upToDate = await _syncedOrTick(first: round == 0);
    }
    await _ensureWordsBoard(circle);
  }

  /// Adds the empty "My words" board if this device does not have it.
  ///
  /// The starter board fills every cell, so added words need a page of their
  /// own. The id is derived from the circle: two devices adding it apart
  /// write the same row, and the merge keeps one board.
  Future<void> _ensureWordsBoard(CircleInfo circle) async {
    _checkOpen();
    final space = circle.spaceUuid;
    final words = wordsBoard(idOf(space));
    final wordsId = uuidOf(words.id);
    final session = _replica.session;
    try {
      await _replica.write(space, (tx) async {
        final existing = await Board.db.findFirstRow(
          session,
          where: (t) => t.id.equals(wordsId),
          transaction: tx,
        );
        if (existing != null) throw const _AlreadySeeded();
        await Board.db.insertRow(
          session,
          starterBoardRow(
            words,
            circleId: space,
            createdAt: DateTime.now().toUtc(),
          ),
          transaction: tx,
        );
      });
    } on _AlreadySeeded {
      // Nothing was written.
    } on DatabaseQueryException {
      // The row is already on this device (for example archived).
    }
  }

  /// Waits for news and returns whether it was a sync that succeeded.
  ///
  /// The [first] call asks the supervisor to sync now. Later calls ride on
  /// its own retries instead of defeating its backoff, and give up after a
  /// couple of seconds so the caller looks at the replica again: a live
  /// stream can deliver a circle without any new attempt being made.
  Future<bool> _syncedOrTick({required bool first}) async {
    const tick = Duration(seconds: 2);
    final synced = await Future.any<bool>([
      if (first)
        sync.syncAttempt()
      else ...[
        // One waiter however many ticks pass before the next sync.
        _nextSync ??= sync
            .syncAttempt(nudge: false)
            .whenComplete(() => _nextSync = null),
        Future<bool>.delayed(tick, () => false),
      ],
    ]);
    // A supervisor that is not running answers at once; do not spin on it.
    if (first && !synced) await Future<void>.delayed(tick ~/ 2);
    _checkOpen();
    return synced;
  }

  /// The store of one circle. Each call makes a new one; dispose it when
  /// its screen goes away, or leave it to [close].
  ReplicaBoardStore boardStore(CircleInfo circle) {
    _checkOpen();
    late final ReplicaBoardStore store;
    store = ReplicaBoardStore(
      replica: _replica,
      revision: sync.revision,
      circleId: circle.spaceUuid,
      role: roleOf(circle.myRole),
      childName: circle.childName,
      myName: circle.myDisplayName,
      onDispose: () => _stores.remove(store),
    );
    _stores.add(store);
    return store;
  }

  /// Stops sync, disposes the stores and closes the database, in that
  /// order: the engine must not be merging into a closed database.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await sync.stop();
    // A one-shot sync cannot be cancelled; give one that was abandoned a
    // moment to finish before the database goes away under it.
    await sync.settled();
    for (final store in _stores.toList()) {
      store.dispose();
    }
    sync.dispose();
    await _replica.close();
  }

  void _checkOpen() {
    if (_closed) throw StateError('The Chorus session is closed.');
  }

  Future<OfflineSyncSpaceRole?> _roleIn(UuidValue space) {
    _checkOpen();
    return _replica.roleIn(space);
  }

  Future<bool> _hasHomeBoard(UuidValue space) {
    _checkOpen();
    return _replica.read(
      (session) async =>
          await Board.db.findFirstRow(
            session,
            where: (t) => t.circleId.equals(space) & t.isHome.equals(true),
          ) !=
          null,
    );
  }

  /// Inserts the starter board and its tiles in one transaction.
  ///
  /// The ids are derived from the circle, so a second device seeding the
  /// same circle writes the same rows and the merge keeps one board. The
  /// check is repeated inside the transaction in case two calls raced here,
  /// and also looks for the starter board by its id: a starter board that
  /// was archived or is no longer the home board still counts as seeded.
  Future<void> _seed(CircleInfo circle) async {
    _checkOpen();
    final space = circle.spaceUuid;
    final circleId = idOf(space);
    final starterId = uuidOf(starterBoard(circleId).id);
    final session = _replica.session;
    try {
      await _replica.write(space, (tx) async {
        final existing = await Board.db.findFirstRow(
          session,
          where: (t) =>
              t.circleId.equals(space) &
              (t.isHome.equals(true) | t.id.equals(starterId)),
          transaction: tx,
        );
        if (existing != null) throw const _AlreadySeeded();

        final at = DateTime.now().toUtc();
        await Board.db.insertRow(
          session,
          starterBoardRow(
            starterBoard(circleId),
            circleId: space,
            createdAt: at,
          ),
          transaction: tx,
        );
        final tiles = starterTiles(
          circleId: circleId,
          createdBy: idOf(userId),
          createdByName: circle.myDisplayName,
          createdAt: at,
        );
        await Tile.db.insert(session, [
          for (final tile in tiles)
            starterTileRow(tile, circleId: space, createdAt: at),
        ], transaction: tx);
      });
    } on _AlreadySeeded {
      // Nothing was written.
    } on DatabaseQueryException {
      // Inserting a row whose id is already here fails with the plain query
      // exception, not the unique-violation one. If starter rows of this
      // circle are on the device, part of the seed arrived from elsewhere
      // and sync brings the rest; anything else is a real failure.
      if (!await _hasRowsOf(space)) rethrow;
    }
  }

  /// Whether any board or tile of [space] is on this device.
  Future<bool> _hasRowsOf(UuidValue space) {
    _checkOpen();
    return _replica.read((session) async {
      final board = await Board.db.findFirstRow(
        session,
        where: (t) => t.circleId.equals(space),
      );
      if (board != null) return true;
      final tile = await Tile.db.findFirstRow(
        session,
        where: (t) => t.circleId.equals(space),
      );
      return tile != null;
    });
  }
}

/// Thrown inside the seeding transaction when a home board is already
/// there, so the transaction rolls back and counts as no local write.
class _AlreadySeeded implements Exception {
  const _AlreadySeeded();
}
