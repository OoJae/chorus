import 'package:serverpod/serverpod.dart';

import 'snapshots.dart';

/// Removes expired and withdrawn snapshots once a day.
///
/// Its twin is the sweep every publish does, so links are cleared even
/// where the Cloud plan runs no future calls.
class SnapshotCleanupFutureCall extends FutureCall {
  Future<void> sweep(Session session) async {
    await deleteExpiredSnapshots(session);
  }
}
