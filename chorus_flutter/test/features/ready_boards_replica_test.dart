// The ready-made boards chorus_ui bundles, imported on the real sync engine
// and a real SQLite replica, as "Add a ready-made board" does: each becomes
// a new board of 24 words in their cells and colours, in one write. See
// ../sync/replica_harness.dart for why the circle is the user's personal
// space.
import 'dart:async';
import 'dart:io';

import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_flutter/src/sync/chorus_session.dart';
import 'package:chorus_flutter/src/sync/replica_board_store.dart';
import 'package:chorus_flutter/src/sync/sync_supervisor.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/editor/ready_boards.dart';
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

/// The bundled file, read from chorus_ui's folder next to this package.
String _fileOf(ReadyBoard board) =>
    File('../chorus_ui/${board.asset}').readAsStringSync();

void main() {
  late ReplicaHarness harness;
  late SyncSupervisor sync;
  late ChorusSession session;
  late ReplicaBoardStore store;

  setUp(() async {
    harness = await ReplicaHarness.open();
    sync = SyncSupervisor(_Link());
    session = ChorusSession.of(harness.replica, sync);
    sync.start();
    final circle = api.CircleInfo(
      spaceUuid: harness.userId,
      childName: 'Maya',
      myRole: api.CircleRole.guardian,
      myDisplayName: 'Ada',
      members: const [],
    );
    await session.ensureCircleReady(circle, seedIfEmpty: true);
    store = session.boardStore(circle);
    await store.refresh();
  });

  tearDown(() async {
    await session.close();
    await harness.close();
  });

  for (final ready in readyBoards) {
    test(
      '${ready.name} imports as a new board of 24 words in one write',
      () async {
        var writes = 0;
        harness.replica.onLocalWrite = () => writes++;
        final file = parseObf(_fileOf(ready));
        final result = await store.importBoard(file);
        expect(writes, 1, reason: 'one transaction');
        expect(result.leftOut, isEmpty);

        final added = store.boards.singleWhere((b) => b.id == result.boardId);
        expect(added.name, ready.name);
        expect(added.isHome, isFalse);
        final grid = gridOf(result.boardId, store.tiles, store.boards);
        expect(grid, hasLength(24));
        final expected = obfPlacements(file).fitted;
        for (final word in expected) {
          final tile = grid[(word.row, word.col)]!;
          expect(tile.label, word.label);
          expect(tile.colorKey, word.colorKey);
          expect(tile.cellKey, placedKey(result.boardId, word.row, word.col));
          expect(tile.cellKey, isNot(contains('__conflict__')));
        }
      },
    );
  }
}
