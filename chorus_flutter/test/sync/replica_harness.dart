/// A real replica in a temporary directory, for tests that need the sync
/// engine's local behaviour without a server.
///
/// The "circle" used here is the user's personal space (its id equals the
/// user id), because that is the one space a replica may write to before any
/// sync has delivered a membership. The engine treats it like any other
/// space for unique keys, narrowed updates and tombstones.
library;

import 'dart:io';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/src/sync/replica_service.dart';

/// An open replica and the directory holding its file.
class ReplicaHarness {
  ReplicaHarness._(this.replica, this._dir);

  final ReplicaService replica;
  final Directory _dir;

  UuidValue get userId => replica.userId;

  /// Opens a fresh, migrated replica for a new random user.
  static Future<ReplicaHarness> open() async {
    final dir = await Directory.systemTemp.createTemp('chorus_replica_');
    final userId = UuidValue.fromString(const Uuid().v4());
    // The client never connects; it is only the factory for the database.
    final client = Client('http://localhost:1/');
    final session = await client.createSyncSession(
      '${dir.path}/${ReplicaService.fileNameFor(userId)}',
      persistentUserId: userId,
    );
    return ReplicaHarness._(ReplicaService(session, userId), dir);
  }

  /// Closes the database and removes its directory.
  Future<void> close() async {
    await replica.close();
    if (await _dir.exists()) await _dir.delete(recursive: true);
  }
}
