/// The signed-in user's local replica: one SQLite file, one queue.
///
/// Every board the user can see lives in this database, and every write the
/// app makes goes through [ReplicaService.write], which is the only place
/// that knows how to address a circle's shared space.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:serverpod_database/serverpod_database.dart';
import 'package:serverpod_offline_sync_client/offline_sync.dart';

import 'replica_files_stub.dart' if (dart.library.io) 'replica_files_io.dart';

/// Owns the replica session of one user.
class ReplicaService {
  /// Wraps an already open [session]. Use [open] in the app; this
  /// constructor exists so tests can supply their own database.
  ReplicaService(this.session, this.userId, {this.onLocalWrite});

  /// The sync-wrapped database session. Generated `Model.db` calls take it.
  final OfflineSyncDatabaseSession session;

  /// The user every local operation belongs to.
  final UuidValue userId;

  /// Called after each committed [write]. The session wires this to the
  /// supervisor so the status chip and the stores hear about local changes.
  VoidCallback? onLocalWrite;

  /// Tail of the queue: completes when the last queued job has finished,
  /// whether it succeeded or not.
  Future<void> _tail = Future<void>.value();
  bool _closed = false;

  /// File name of [userId]'s replica. One file per user, so signing in as
  /// someone else never shows the previous user's boards.
  static String fileNameFor(UuidValue userId) =>
      'chorus_${userId.uuid.toLowerCase()}.sqlite';

  /// Opens (and migrates) [userId]'s replica.
  ///
  /// On the web the database is addressed by a bare file name; elsewhere it
  /// lives in the app-support directory. In debug builds only, a database
  /// that fails to open is deleted and opened once more, because a schema
  /// changed during development leaves a file no migration can repair. A
  /// release build never deletes: the file may hold unsent edits.
  static Future<ReplicaService> open(
    Client client,
    UuidValue userId, {
    VoidCallback? onLocalWrite,
  }) async {
    final name = fileNameFor(userId);
    final path = kIsWeb
        ? name
        : p.join((await getApplicationSupportDirectory()).path, name);

    Future<OfflineSyncDatabaseSession> openSession() =>
        client.createSyncSession(
          path,
          isDebugMode: kDebugMode,
          persistentUserId: userId,
        );

    OfflineSyncDatabaseSession session;
    try {
      session = await openSession();
    } catch (_) {
      if (!kDebugMode) rethrow;
      await deleteReplicaFiles(path);
      session = await openSession();
    }
    return ReplicaService(session, userId, onLocalWrite: onLocalWrite);
  }

  /// Runs [job] after everything queued before it. A failed job fails its
  /// own future only; the queue carries on.
  Future<R> _enqueue<R>(Future<R> Function() job) {
    if (_closed) {
      return Future<R>.error(StateError('The replica is closed.'));
    }
    final result = _tail.then((_) {
      if (_closed) throw StateError('The replica is closed.');
      return job();
    });
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  /// Writes into the shared space of one circle.
  ///
  /// [fn] runs in a transaction that acts as [userId] in [circleSpaceUuid].
  /// Pass its transaction to every database call inside, reads included: a
  /// call without it lands in the user's personal space, where nobody else
  /// sees it, and on the web it waits for a connection the transaction holds.
  ///
  /// Throws [OfflineSyncSpaceMembershipException] until a sync has delivered
  /// the circle to this device, and [OfflineSyncSpaceRoleException] for a
  /// read-only member. Whatever [fn] throws rolls the transaction back.
  Future<R> write<R>(
    UuidValue circleSpaceUuid,
    TransactionFunction<R> fn,
  ) async {
    final result = await _enqueue(
      () => session.db.transactionForUser<R>(
        userId,
        fn,
        spaceId: circleSpaceUuid,
      ),
    );
    onLocalWrite?.call();
    return result;
  }

  /// Runs a read in the same queue as the writes, so the app never issues a
  /// query while one of its own transactions is open.
  Future<R> read<R>(Future<R> Function(DatabaseSession session) fn) =>
      _enqueue(() => fn(session));

  /// The role this user holds in [circleSpaceUuid] as far as this device
  /// knows, or null when no sync has delivered the circle yet.
  Future<OfflineSyncSpaceRole?> roleIn(UuidValue circleSpaceUuid) => read(
    (session) => OfflineSyncSpaceMembership.roleOf(
      session,
      userUuid: userId,
      spaceUuid: circleSpaceUuid,
    ),
  );

  /// Lets the job in flight finish, then closes the database; jobs still
  /// queued behind it fail with a [StateError]. Cancel any running sync
  /// first. Safe to call twice.
  Future<void> close() async {
    if (_closed) return;
    final pending = _tail;
    _closed = true;
    await pending;
    await session.close();
  }
}
