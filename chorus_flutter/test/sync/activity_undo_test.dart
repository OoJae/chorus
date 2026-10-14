// Undo from "What changed" on the real sync engine and a real SQLite
// replica: each undo is a newer edit with reason `undo`, and bringing a
// word back never moves a placed word.
import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_flutter/src/sync/adapters.dart';
import 'package:chorus_flutter/src/sync/replica_board_store.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_activity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'replica_harness.dart';

void main() {
  late ReplicaHarness harness;
  late ReplicaBoardStore store;
  late String home;
  late DateTime clock;

  final start = DateTime.utc(2026, 10, 13, 9);

  ReplicaBoardStore open({CircleRole role = CircleRole.guardian}) {
    final opened = ReplicaBoardStore(
      replica: harness.replica,
      revision: ValueNotifier(0),
      circleId: harness.userId,
      role: role,
      childName: 'Maya',
      myName: 'Mum',
      now: () => clock = clock.add(const Duration(minutes: 1)),
    );
    addTearDown(opened.dispose);
    return opened;
  }

  ActivityEntry entryOf(ActivityKind kind, String tileId) =>
      activityOf(store.tiles, store.edits).firstWhere(
        (e) => e.kind == kind && e.tileId == tileId,
      );

  setUp(() async {
    harness = await ReplicaHarness.open();
    clock = start;
    final circle = idOf(harness.userId);
    home = starterBoard(circle).id;
    await harness.replica.write(harness.userId, (tx) async {
      await api.Board.db.insertRow(
        harness.replica.session,
        starterBoardRow(
          starterBoard(circle),
          circleId: harness.userId,
          createdAt: start,
        ),
        transaction: tx,
      );
    });
    store = open();
    await store.refresh();
  });

  tearDown(() async {
    store.dispose();
    await harness.close();
  });

  test('undo of a rename writes the old label as an undo edit', () async {
    await store.addTile(boardId: home, row: 0, col: 0, label: 'cup');
    final id = store.tiles.single.id;
    await store.updateTile(id, label: 'mug');
    await store.refresh();

    final outcome = await store.undo(entryOf(ActivityKind.renamed, id));
    expect(outcome, UndoOutcome.done);
    expect(store.tiles.single.label, 'cup');
    final last = store.edits.last;
    expect(last.reason, undoReason);
    expect((last.oldValue, last.newValue), ('mug', 'cup'));
  });

  test('undo of an added word puts it away, restorably', () async {
    await store.addTile(boardId: home, row: 0, col: 1, label: 'swing');
    final id = store.tiles.single.id;
    await store.undo(entryOf(ActivityKind.added, id));
    final tile = store.tiles.single;
    expect(tile.archived, isTrue);
    expect(tile.cellKey, trayKey(id));
    expect(store.edits.where((e) => e.reason == undoReason), hasLength(2));
  });

  test('undo of put away brings the word back into its empty cell', () async {
    await store.addTile(boardId: home, row: 1, col: 1, label: 'cake');
    final id = store.tiles.single.id;
    await store.archiveTile(id);
    await store.refresh();

    final outcome = await store.undo(entryOf(ActivityKind.putAway, id));
    expect(outcome, UndoOutcome.done);
    final tile = store.tiles.single;
    expect(tile.archived, isFalse);
    expect(tile.cellKey, placedKey(home, 1, 1));
  });

  test('a taken cell is never emptied: the word waits in the tray', () async {
    await store.addTile(boardId: home, row: 2, col: 2, label: 'cake');
    final cake = store.tiles.single.id;
    await store.archiveTile(cake);
    await store.addTile(boardId: home, row: 2, col: 2, label: 'pie');
    await store.refresh();
    final pie = store.tiles.firstWhere((t) => t.label == 'pie').id;

    final outcome = await store.undo(entryOf(ActivityKind.putAway, cake));
    expect(outcome, UndoOutcome.waiting);
    final back = store.tiles.firstWhere((t) => t.id == cake);
    expect(back.archived, isFalse);
    expect(back.cellKey, trayKey(cake));
    expect(
      store.tiles.firstWhere((t) => t.id == pie).cellKey,
      placedKey(home, 2, 2),
    );
    final tray = trayOf(store.tiles, store.boards);
    expect(tray.map((e) => e.tile.id), [cake]);
  });

  test('a read-only member cannot undo', () async {
    await store.addTile(boardId: home, row: 0, col: 0, label: 'cup');
    final id = store.tiles.single.id;
    final entry = entryOf(ActivityKind.added, id);
    final partner = open(role: CircleRole.partner);
    await partner.refresh();
    expect(() => partner.undo(entry), throwsStateError);
  });
}
