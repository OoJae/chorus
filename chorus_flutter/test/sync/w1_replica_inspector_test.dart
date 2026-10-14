// "Under the hood" over a real replica: the rows of the circle, the sync
// facts and the module version.
import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/src/trust/replica_inspector.dart';
import 'package:chorus_shared/chorus_shared.dart' show placedKey, trayKey;
import 'package:chorus_ui/contracts.dart' show SyncState;
import 'package:chorus_ui/fakes.dart';
import 'package:flutter_test/flutter_test.dart';

import 'replica_harness.dart';

void main() {
  late ReplicaHarness harness;

  setUp(() async => harness = await ReplicaHarness.open());
  tearDown(() async => harness.close());

  test('counts the circle\'s rows in each synced table and reports the '
      'sync facts', () async {
    final space = harness.userId;
    final board = const Uuid().v7obj();
    final now = DateTime.now().toUtc();
    await harness.replica.write(space, (tx) async {
      final session = harness.replica.session;
      await Board.db.insertRow(
        session,
        Board(
          id: board,
          circleId: space,
          name: 'Home',
          rows: 6,
          cols: 6,
          isHome: true,
          createdAt: now,
        ),
        transaction: tx,
      );
      for (final (i, label) in ['more', 'go'].indexed) {
        final id = const Uuid().v7obj();
        await Tile.db.insertRow(
          session,
          Tile(
            id: id,
            circleId: space,
            boardId: board,
            cellKey: i == 0 ? placedKey(board.uuid, 0, 0) : trayKey(id.uuid),
            label: label,
            noLog: false,
            createdBy: space,
            createdByName: 'Mum',
            createdAt: now,
          ),
          transaction: tx,
        );
      }
    });

    final sync = FakeSyncStatus(state: SyncState.live);
    final report = await LocalReplicaInspector(
      replica: harness.replica,
      circleSpace: space,
      sync: sync,
      serverAddress: 'https://chorus.example/',
    ).inspect();
    expect(report.boards, 1);
    expect(report.tiles, 2);
    expect(report.tileEdits, 0);
    expect(report.parked, isEmpty);
    expect(report.circleSpaceId, space.uuid);
    expect(report.moduleVersion, '0.0.10');
    expect(report.serverAddress, 'https://chorus.example/');
    expect(report.syncState, 'live');
    expect(report.hasUnsent, isFalse);

    // Another circle's rows are not counted.
    final other = await LocalReplicaInspector(
      replica: harness.replica,
      circleSpace: const Uuid().v7obj(),
      sync: sync,
      serverAddress: '',
    ).inspect();
    expect(other.boards, 0);
    expect(other.tiles, 0);
  });
}
