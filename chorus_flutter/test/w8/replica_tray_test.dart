// "Put back" from a board copy on the real sync engine and a real SQLite
// replica: the word goes to "Needs a home" with a tray key, its edit is
// logged, and no placed word moves. See ../sync/replica_harness.dart for
// why the circle is the user's personal space.
import 'dart:async';

import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_flutter/src/sync/adapters.dart';
import 'package:chorus_flutter/src/sync/chorus_session.dart';
import 'package:chorus_flutter/src/sync/replica_board_store.dart';
import 'package:chorus_flutter/src/sync/sync_supervisor.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sync/replica_harness.dart';

/// A server that is always there.
class _Link implements SyncLink {
  @override
  bool get isSignedIn => true;

  @override
  Future<api.ServerInfo> serverInfo() async =>
      api.ServerInfo(serverTime: DateTime.now().toUtc(), minBuild: 1);

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
  late ReplicaHarness harness;
  late ChorusSession session;
  late ReplicaBoardStore store;
  late String home;

  api.CircleInfo circleAs(api.CircleRole role) => api.CircleInfo(
    spaceUuid: harness.userId,
    childName: 'Maya',
    myRole: role,
    myDisplayName: 'Ada',
    members: const [],
  );

  setUp(() async {
    harness = await ReplicaHarness.open();
    final sync = SyncSupervisor(_Link());
    session = ChorusSession.of(harness.replica, sync);
    sync.start();
    final circle = circleAs(api.CircleRole.guardian);
    await session.ensureCircleReady(circle, seedIfEmpty: true);
    store = session.boardStore(circle);
    await store.refresh();
    home = starterBoardId(idOf(harness.userId));
  });

  tearDown(() async {
    await session.close();
    await harness.close();
  });

  test('a word put back waits in "Needs a home" with its picture, and no '
      'placed word moves', () async {
    final before = gridOf(home, store.tiles, store.boards);
    final hash = 'c' * 64;

    final id = await store.addToTray(
      boardId: home,
      label: ' swing ',
      speech: 'the swing',
      colorKey: 'noun',
      imageHash: hash,
    );

    final tile = store.tiles.singleWhere((t) => t.id == id);
    expect(CellKey.parse(tile.cellKey), TrayCell(id));
    expect(tile.label, 'swing');
    expect(tile.speech, 'the swing');
    expect(tile.imageHash, hash);
    expect(tile.boardId, home);
    final waiting = trayOf(store.tiles, store.boards);
    expect(waiting.single.tile.id, id);
    expect(waiting.single.reason, TrayReason.unplaced);
    expect(gridOf(home, store.tiles, store.boards), before);

    final edits = await harness.replica.read(
      (s) => api.TileEdit.db.find(
        s,
        where: (t) => t.tileId.equals(uuidOf(id)),
      ),
    );
    expect(
      {for (final edit in edits) edit.prop},
      containsAll(['label', 'cellKey', 'speech', 'colorKey', 'imageHash']),
    );
  });

  test('a read-only partner cannot put a word back', () async {
    final partner = session.boardStore(circleAs(api.CircleRole.partner));
    await partner.refresh();
    expect(
      () => partner.addToTray(boardId: home, label: 'swing'),
      throwsStateError,
    );
    partner.dispose();
  });
}
