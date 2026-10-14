// The session's waiting, on fake time and with no database. The seeding
// itself is tested on a real replica in replica_board_store_test.dart.
import 'dart:async';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/src/sync/chorus_session.dart';
import 'package:chorus_flutter/src/sync/replica_service.dart';
import 'package:chorus_flutter/src/sync/sync_supervisor.dart';
import 'package:chorus_ui/contracts.dart' show SyncState;
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_offline_sync_client/offline_sync.dart'
    show OfflineSyncSpaceRole;

/// A replica that no sync has delivered a circle to. Every look is counted
/// and takes a moment, as a read of the database does.
class _EmptyReplica extends Fake implements ReplicaService {
  int roleReads = 0;

  @override
  VoidCallback? onLocalWrite;

  @override
  Future<OfflineSyncSpaceRole?> roleIn(UuidValue circleSpaceUuid) async {
    roleReads++;
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return null;
  }

  @override
  Future<void> close() async {}
}

/// A server that is there and has nothing to say.
class _Link implements SyncLink {
  _Link(this._now);

  final DateTime Function() _now;

  @override
  bool get isSignedIn => true;

  @override
  Future<ServerInfo> serverInfo() async =>
      ServerInfo(serverTime: _now(), minBuild: 1);

  @override
  Future<void> syncOnce(VoidCallback onMerge) async {}

  @override
  SyncRun syncContinuously(VoidCallback onMerge) {
    final open = Completer<void>();
    return SyncRun(
      done: open.future,
      cancel: () async {
        if (!open.isCompleted) open.complete();
      },
    );
  }
}

void main() {
  testWidgets('working offline, a circle that is not on this device yet is '
      'looked for about once a second, not in a spin', (tester) async {
    DateTime now() => tester.binding.clock.now();
    final replica = _EmptyReplica();
    final sync = SyncSupervisor(_Link(now), now: now);
    final session = ChorusSession.of(replica, sync);
    sync.start();
    await tester.pump(Duration.zero);
    expect(sync.state, SyncState.live);
    await sync.setWorkingOffline(true);

    // A board made or joined while sync is paused: the server call worked,
    // but nothing can bring the circle to this device until sync resumes.
    Object? ended;
    unawaited(
      session
          .ensureCircleReady(
            CircleInfo(
              spaceUuid: UuidValue.fromString(
                '6f1d2c3a-0b4e-4c5d-8e9f-a1b2c3d4e5f6',
              ),
              childName: 'Maya',
              myRole: CircleRole.guardian,
              myDisplayName: 'Mum',
              members: const [],
            ),
            seedIfEmpty: true,
          )
          .then<void>((_) => ended = 'ready', onError: (Object e) => ended = e),
    );
    await tester.pump(const Duration(seconds: 10));

    expect(ended, isNull, reason: 'still waiting for the circle');
    expect(replica.roleReads, greaterThan(5), reason: 'still looking');
    expect(replica.roleReads, lessThan(15), reason: 'one look a second');

    // Closing the session is what ends the wait; the last tick runs out.
    await session.close();
    await tester.pump(const Duration(seconds: 3));
    expect(ended, isStateError);
  });
}
