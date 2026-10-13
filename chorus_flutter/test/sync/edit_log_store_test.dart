// These tests run the real sync engine on a real SQLite replica; only the
// server is missing, so a merge is stood in for by inserting the other
// adult's edit row directly. See replica_harness.dart for why the circle is
// the user's personal space.
import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_flutter/src/sync/adapters.dart';
import 'package:chorus_flutter/src/sync/replica_board_store.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'replica_harness.dart';

void main() {
  late ReplicaHarness harness;
  late ReplicaBoardStore store;
  late String home;
  late String cookie;
  late DateTime clock;

  final start = DateTime.utc(2026, 10, 13, 9);
  const teacher = '0198f0aa-1111-7222-8333-444455556666';

  ReplicaBoardStore open({CircleRole role = CircleRole.guardian}) {
    final opened = ReplicaBoardStore(
      replica: harness.replica,
      revision: ValueNotifier(0),
      circleId: harness.userId,
      role: role,
      childName: 'Maya',
      myName: 'Mum',
      // A minute later on every write, so the order of edits is known.
      now: () => clock = clock.add(const Duration(minutes: 1)),
    );
    addTearDown(opened.dispose);
    return opened;
  }

  EditFacts newest(String prop) =>
      store.edits.lastWhere((e) => e.tileId == cookie && e.prop == prop);

  /// What a merge would bring: an edit row by another adult. The tile is
  /// left as it is, which is what losing looks like.
  Future<void> merged({
    String prop = 'label',
    required String? from,
    required String? to,
    required String? base,
    required int minute,
    api.UuidValue? circle,
  }) async {
    await harness.replica.write(harness.userId, (tx) async {
      await api.TileEdit.db.insertRow(
        harness.replica.session,
        api.TileEdit(
          circleId: circle ?? harness.userId,
          tileId: uuidOf(cookie),
          prop: prop,
          oldValue: from,
          newValue: to,
          baseEditId: base == null ? null : uuidOf(base),
          reason: EditReason.edit,
          actorId: uuidOf(teacher),
          actorName: 'Teacher',
          editedAt: start.add(Duration(minutes: minute)),
        ),
        transaction: tx,
      );
    });
    await store.refresh();
  }

  TileFacts tile() => store.tiles.singleWhere((t) => t.id == cookie);

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
    // 09:01: the word is added. 09:02: Mum renames it.
    await store.addTile(boardId: home, row: 0, col: 0, label: 'cookie');
    cookie = store.tiles.single.id;
    await store.updateTile(cookie, label: 'biscuit');
    await store.refresh();
  });

  tearDown(() async {
    store.dispose();
    await harness.close();
  });

  group('edits', () {
    test('are the circle\'s rows as plain values, oldest first', () {
      expect(store.edits.map((e) => e.reason), [
        EditReason.add,
        EditReason.add,
        EditReason.edit,
      ]);
      final added = store.edits.firstWhere((e) => e.prop == 'label');
      final rename = store.edits.last;
      expect(rename.tileId, cookie);
      expect(rename.prop, 'label');
      expect((rename.oldValue, rename.newValue), ('cookie', 'biscuit'));
      expect(rename.baseEditId, added.id);
      expect(rename.actorId, idOf(harness.userId));
      expect(rename.actorName, 'Mum');
      expect(rename.editedAt, start.add(const Duration(minutes: 2)));
      expect(rename.id, rename.id.toLowerCase());
      expect(added.baseEditId, isNull);
      expect((added.oldValue, added.newValue), (null, 'cookie'));
    });

    test('leave out the rows of another circle', () async {
      final before = store.edits;
      await merged(
        from: 'cookie',
        to: 'snack',
        base: null,
        minute: 1,
        circle: api.UuidValue.fromString(teacher),
      );
      expect(store.edits, before);
    });

    test('a merged edit notifies even though no tile changed', () async {
      var notified = 0;
      store.addListener(() => notified++);
      final tiles = store.tiles;
      await merged(
        from: 'cookie',
        to: 'snack',
        base: newest('label').baseEditId,
        minute: 1,
      );
      expect(notified, 1);
      expect(store.tiles, tiles);
      expect(store.edits, hasLength(4));
    });

    test('one adult changing their mind is not an overwrite', () async {
      await store.updateTile(cookie, label: 'snack');
      await store.updateTile(cookie, label: 'treat');
      await store.refresh();
      expect(detectOverwrites(store.edits, store.tiles), isEmpty);
    });
  });

  group('restore', () {
    late String added;

    setUp(() => added = newest('label').baseEditId!);

    // Which edit the restoring device names as its base depends on the two
    // clocks; both orders must end the same way.
    for (final (name, minute) in [
      ('written before the kept edit', 1),
      ('written after the kept edit', 30),
    ]) {
      test('puts back a replaced label $name', () async {
        final kept = newest('label');
        await merged(from: 'cookie', to: 'snack', base: added, minute: minute);
        final found = detectOverwrites(store.edits, store.tiles);
        expect(found, hasLength(1));
        expect(found.single.kept, kept);
        expect(found.single.lost.newValue, 'snack');
        expect(found.single.lost.actorName, 'Teacher');

        var writes = 0;
        harness.replica.onLocalWrite = () => writes++;
        await store.restore(found.single);
        harness.replica.onLocalWrite = null;

        expect(writes, greaterThan(0));
        expect(tile().label, 'snack');
        expect(tile().cellKey, placedKey(home, 0, 0), reason: 'never moves');
        final restore = store.edits.singleWhere(
          (e) => e.reason == restoreReason,
        );
        expect((restore.oldValue, restore.newValue), ('biscuit', 'snack'));
        expect(restore.prop, 'label');
        expect(restore.actorName, 'Mum');
        expect(
          restore.baseEditId,
          minute == 1 ? kept.id : found.single.lost.id,
        );
        expect(store.edits, hasLength(5), reason: 'nothing leaves the log');
        expect(detectOverwrites(store.edits, store.tiles), isEmpty);
      });
    }

    test('can itself be undone from the log', () async {
      await merged(from: 'cookie', to: 'snack', base: added, minute: 1);
      final first = detectOverwrites(store.edits, store.tiles).single;
      await store.restore(first);
      // The pair is settled, so nothing is offered; the old value is still
      // an ordinary edit away and still in the log.
      expect(detectOverwrites(store.edits, store.tiles), isEmpty);
      expect(store.edits.map((e) => e.newValue), contains('biscuit'));
      await store.updateTile(cookie, label: 'biscuit');
      await store.refresh();
      expect(tile().label, 'biscuit');
      expect(detectOverwrites(store.edits, store.tiles), isEmpty);
    });

    test('puts back replaced speech, and a cleared one as cleared', () async {
      await store.updateTile(cookie, speech: 'biscuit please');
      await store.refresh();
      await merged(
        prop: 'speech',
        from: null,
        to: 'snack time',
        base: null,
        minute: 1,
      );
      final spoken = detectOverwrites(store.edits, store.tiles).single;
      expect(spoken.prop, 'speech');
      await store.restore(spoken);
      expect(tile().speech, 'snack time');
      expect(tile().label, 'biscuit', reason: 'only the one property');
      expect(detectOverwrites(store.edits, store.tiles), isEmpty);

      // Teacher, still not having seen any of it, clears the speech.
      await store.updateTile(cookie, speech: 'biscuit please');
      await merged(
        prop: 'speech',
        from: 'snack time',
        to: null,
        base: newest('speech').baseEditId,
        minute: 2,
      );
      final cleared = detectOverwrites(
        store.edits,
        store.tiles,
      ).singleWhere((o) => o.lost.newValue == null);
      await store.restore(cleared);
      expect(tile().speech, isNull);
      expect(tile().spokenText, 'biscuit');
    });

    test('puts back a replaced colour', () async {
      await store.updateTile(cookie, colorKey: 'noun');
      await store.refresh();
      await merged(
        prop: 'colorKey',
        from: null,
        to: 'verb',
        base: null,
        minute: 1,
      );
      await store.restore(detectOverwrites(store.edits, store.tiles).single);
      expect(tile().colorKey, 'verb');
      expect(detectOverwrites(store.edits, store.tiles), isEmpty);
    });

    test('writes nothing when the tile already holds the value', () async {
      await merged(from: 'cookie', to: 'snack', base: added, minute: 1);
      final found = detectOverwrites(store.edits, store.tiles).single;
      await store.updateTile(cookie, label: 'snack');
      await store.refresh();
      final count = store.edits.length;
      await store.restore(found);
      expect(store.edits, hasLength(count));
      expect(tile().label, 'snack');
    });

    test('refuses a property that cannot be restored', () async {
      final lost = EditFacts(
        id: added,
        tileId: cookie,
        prop: 'cellKey',
        newValue: trayKey(cookie),
        reason: EditReason.edit,
        actorId: teacher,
        actorName: 'Teacher',
        editedAt: start,
      );
      expect(
        () => store.restore(
          Overwrite(lost: lost, kept: newest('label'), tile: tile()),
        ),
        throwsUnsupportedError,
      );
      expect(tile().cellKey, placedKey(home, 0, 0));
    });

    test('is refused for a partner, who still sees the log', () async {
      await merged(from: 'cookie', to: 'snack', base: added, minute: 1);
      final partner = open(role: CircleRole.partner);
      await partner.refresh();
      final found = detectOverwrites(partner.edits, partner.tiles);
      expect(found, hasLength(1));
      await expectLater(partner.restore(found.single), throwsStateError);
      await store.refresh();
      expect(tile().label, 'biscuit');
      expect(store.edits.where((e) => e.reason == restoreReason), isEmpty);
    });
  });
}
