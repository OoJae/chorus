/// Scenarios T8, T9 and T10: who may write, and where a write lands.
///
/// Run with `dart test test/sync --concurrency=1`.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:serverpod_offline_sync_client/serverpod_offline_sync_client.dart';
import 'package:test/test.dart';

import 'replicas.dart';

/// Runs [body] and returns what it threw, or null.
Future<Object?> errorOf(Future<void> Function() body) async {
  try {
    await body();
    return null;
  } catch (e) {
    return e;
  }
}

void main() {
  withSyncWorld('Given a guardian, a teacher and a partner in one circle,', (
    world,
  ) {
    test('T8 when the guardian and the teacher write then all three see '
        'both tiles, and a partner write is refused on the device.', () async {
      final [guardian, teacher, partner] = await world.users([
        'Guardian',
        'Teacher',
        'Partner',
      ]);
      final circle = await world.circle(
        guardian,
        members: {teacher: CircleRole.teacher, partner: CircleRole.partner},
      );
      final all = [guardian, teacher, partner];
      final board = await world.emptyBoard(circle, guardian, all);

      await guardian.insertTile(
        circle,
        guardian.newTile(
          circle,
          board,
          'juice',
          cellKey: placedKey(board.id, 0, 0),
        ),
      );
      await teacher.insertTile(
        circle,
        teacher.newTile(
          circle,
          board,
          'book',
          cellKey: placedKey(board.id, 0, 1),
        ),
      );
      final rounds = await world.converge(circle, all);
      note('T8', 'rounds to converge, three replicas', rounds);
      for (final replica in all) {
        expect(
          {for (final t in await replica.tiles(circle)) t.label},
          {'juice', 'book'},
          reason: '$replica',
        );
      }

      // The partner's own replica refuses, before anything is stored.
      final insertError = await errorOf(
        () => partner.insertTile(
          circle,
          partner.newTile(
            circle,
            board,
            'nope',
            cellKey: placedKey(board.id, 5, 5),
          ),
        ),
      );
      note('T8', 'partner insert error type', insertError.runtimeType);
      note('T8', 'partner insert error', insertError);
      expect(insertError, isA<OfflineSyncSpaceRoleException>());
      expect(
        (insertError! as OfflineSyncSpaceRoleException).role,
        OfflineSyncSpaceRole.readOnly,
      );

      final juice = (await partner.tileRows(circle)).firstWhere(
        (t) => t.label == 'juice',
      );
      final updateError = await errorOf(
        () => partner.updateTile(
          circle,
          juice.id!,
          (row) => row.copyWith(label: 'changed'),
          columns: (t) => [t.label],
        ),
      );
      note('T8', 'partner update error type', updateError.runtimeType);
      expect(updateError, isA<OfflineSyncSpaceRoleException>());

      await world.converge(circle, all);
      expect(await partner.tiles(circle), hasLength(2));
      expect(
        {for (final t in await world.serverTiles(circle)) t.label},
        {'juice', 'book'},
      );
    });

    test('T8 when a member joined but has not synced yet then a write is '
        'refused until one sync has delivered the membership.', () async {
      final [guardian, teacher] = await world.users(['Guardian', 'Teacher']);
      final circle = await world.circle(
        guardian,
        members: {teacher: CircleRole.teacher},
        deliver: false,
      );
      final board = starterBoard(circle.uuid);
      Tile tile() => teacher.newTile(circle, board, 'early');

      final before = await errorOf(() => teacher.insertTile(circle, tile()));
      note('T8', 'write before first sync, error type', before.runtimeType);
      note('T8', 'write before first sync, error', before);
      expect(before, isA<OfflineSyncSpaceMembershipException>());

      note('T8', 'sync that delivers a membership', await teacher.sync());
      await guardian.sync();
      await world.emptyBoard(circle, guardian, [guardian, teacher]);
      expect(await errorOf(() => teacher.insertTile(circle, tile())), isNull);
      await world.converge(circle, [teacher, guardian]);
      expect(await guardian.tiles(circle), hasLength(1));
    });

    test('T8 when a member is made read-only on the server while holding an '
        'unsynced write then the server silently drops that write and the '
        'device keeps showing it.', () async {
      final [guardian, teacher] = await world.users(['Guardian', 'Teacher']);
      final circle = await world.circle(
        guardian,
        members: {teacher: CircleRole.teacher},
      );
      final board = await world.emptyBoard(circle, guardian, [
        guardian,
        teacher,
      ]);

      // The teacher's replica still believes it is read-write.
      await world.setServerRole(circle, teacher, OfflineSyncSpaceRole.readOnly);
      final stale = await teacher.insertTile(
        circle,
        teacher.newTile(
          circle,
          board,
          'stale',
          cellKey: placedKey(board.id, 3, 3),
        ),
      );

      // Observed: nothing fails. The sync completes, the server just never
      // takes the row, and the device keeps showing it.
      final syncError = await errorOf(teacher.sync);
      note('T8', 'stale read-write sync, error type', syncError.runtimeType);
      expect(syncError, isNull);
      expect(await errorOf(teacher.sync), isNull);
      await guardian.sync();

      final onServer = await world.serverTiles(circle);
      final onTeacher = await teacher.tiles(circle);
      note(
        'T8',
        'stale write on server',
        onServer.map((t) => t.label).toList(),
      );
      note(
        'T8',
        'stale write on its own device',
        onTeacher.map((t) => t.label).toList(),
      );
      expect(onServer, isEmpty);
      expect(await guardian.tiles(circle), isEmpty);
      expect(onTeacher.single.id, stale.id!.uuid);

      // The device has learnt its new role, so later writes are refused.
      final after = await errorOf(
        () =>
            teacher.insertTile(circle, teacher.newTile(circle, board, 'again')),
      );
      note(
        'T8',
        'write after the demotion was synced, error type',
        after.runtimeType,
      );
      expect(after, isA<OfflineSyncSpaceRoleException>());
    });
  });

  withSyncWorld('Given two members of one circle,', (world) {
    test('T9 when a tile for a shared board is written outside '
        'transactionForUser then it is hidden at once, even from its '
        'author, and nobody else ever gets it.', () async {
      final [guardian, teacher] = await world.users(['Guardian', 'Teacher']);
      final circle = await world.circle(
        guardian,
        members: {teacher: CircleRole.teacher},
      );
      final board = await world.emptyBoard(circle, guardian, [
        guardian,
        teacher,
      ]);

      // Control: the same write, made properly, is seen by the teacher.
      final proper = await guardian.insertTile(
        circle,
        guardian.newTile(
          circle,
          board,
          'shared',
          cellKey: placedKey(board.id, 0, 0),
        ),
      );

      // The bug: the ordinary ORM call, with the right circleId on the row.
      final cell = placedKey(board.id, 0, 1);
      final lost = guardian.newTile(circle, board, 'lost', cellKey: cell);
      final error = await errorOf(
        () => guardian.local((db) => Tile.db.insertRow(db, lost)),
      );
      note('T9', 'unwrapped insert error type', error.runtimeType);
      expect(error, isNull, reason: 'nothing warns the author');

      // Observed: the row went to the personal space, its board lives in
      // the circle's space, and the engine hides a row whose parent is in
      // another space. It is gone from ordinary reads before any sync.
      Future<List<Tile>> withHidden() => guardian.local(
        (db) => Tile.db.find(db, where: (t) => t.includeHiddenRows),
      );
      final hiddenKey = (await withHidden())
          .singleWhere((t) => t.id == lost.id)
          .cellKey;
      note('T9', 'author sees before sync', {
        for (final t in await guardian.tiles(circle)) t.label,
      });
      note('T9', 'cellKey of the hidden row', hiddenKey);
      expect(
        {for (final t in await guardian.tiles(circle)) t.label},
        {'shared'},
      );
      expect(hiddenKey, '${cell}__hidden__${lost.id!.uuid}');
      expect(CellKey.parse(hiddenKey), isA<UnknownCell>());

      for (var round = 0; round < 3; round++) {
        await guardian.sync();
        await teacher.sync();
      }

      note(
        'T9',
        'server space of the proper tile',
        await world.serverSpaceOfTile(proper.id!),
      );
      note(
        'T9',
        'server space of the unwrapped tile',
        await world.serverSpaceOfTile(lost.id!),
      );
      note(
        'T9',
        'circle space / author id',
        '${circle.uuid} / ${guardian.userId.uuid}',
      );
      expect(
        {for (final t in await guardian.tiles(circle)) t.label},
        {'shared'},
      );
      expect(
        {for (final t in await teacher.tiles(circle)) t.label},
        {'shared'},
      );
      expect(await world.serverSpaceOfTile(proper.id!), circle.uuid);
      expect(await world.serverSpaceOfTile(lost.id!), guardian.userId.uuid);

      // The cell itself is still free for a proper write.
      await guardian.insertTile(
        circle,
        guardian.newTile(circle, board, 'found', cellKey: cell),
      );
      await world.converge(circle, [guardian, teacher]);
      expect(await teacher.tiles(circle), hasLength(2));
    });

    test('T9 when a whole board is seeded outside transactionForUser then '
        'its author sees it under the circle filter and nobody else ever '
        'does.', () async {
      final [guardian, teacher] = await world.users(['Guardian', 'Teacher']);
      final circle = await world.circle(
        guardian,
        members: {teacher: CircleRole.teacher},
      );
      final board = starterBoard(circle.uuid);

      await guardian.local((db) async {
        await Board.db.insertRow(db, boardRow(board, circle));
        await Tile.db.insertRow(
          db,
          guardian.newTile(
            circle,
            board,
            'like',
            cellKey: placedKey(board.id, 0, 0),
          ),
        );
      });
      for (var round = 0; round < 3; round++) {
        await guardian.sync();
        await teacher.sync();
      }

      final author = {for (final t in await guardian.tiles(circle)) t.label};
      note('T9', 'unwrapped seed, author sees', author);
      note(
        'T9',
        'unwrapped seed, other member sees',
        await teacher.tiles(circle),
      );
      // Board and tile are both personal, so nothing is hidden: the author's
      // device shows a board that exists for nobody else.
      expect(author, {'like'});
      expect(await teacher.tiles(circle), isEmpty);
      expect(await teacher.state(circle), isEmpty);
    });

    test(
      'T10 when a user belongs to two circles and has personal rows then '
      'a query filtered by circleId returns only that circle\'s rows.',
      () async {
        final [guardian, teacher] = await world.users(['Guardian', 'Teacher']);
        final first = await world.circle(
          guardian,
          members: {teacher: CircleRole.teacher},
        );
        final second = await world.circle(guardian);
        final firstBoard = await world.emptyBoard(first, guardian, [
          guardian,
          teacher,
        ]);
        final secondBoard = await world.emptyBoard(second, guardian, [
          guardian,
        ]);

        await guardian.insertTile(
          first,
          guardian.newTile(
            first,
            firstBoard,
            'one',
            cellKey: placedKey(firstBoard.id, 0, 0),
          ),
        );
        await guardian.insertTile(
          second,
          guardian.newTile(
            second,
            secondBoard,
            'two',
            cellKey: placedKey(secondBoard.id, 0, 0),
          ),
        );
        // Personal rows: a board and a tile written without a space.
        final nowhere = const Uuid().v7obj();
        final ownBoard = BoardFacts(
          id: const Uuid().v7(),
          name: 'Mine',
          rows: 1,
          cols: 1,
        );
        await guardian.local((db) async {
          await Board.db.insertRow(db, boardRow(ownBoard, nowhere));
          await Tile.db.insertRow(
            db,
            guardian.newTile(nowhere, ownBoard, 'mine'),
          );
        });
        for (var round = 0; round < 2; round++) {
          await guardian.sync();
          await teacher.sync();
        }

        expect({for (final t in await guardian.tiles(first)) t.label}, {'one'});
        expect(
          {for (final t in await guardian.tiles(second)) t.label},
          {'two'},
        );
        expect({for (final t in await teacher.tiles(first)) t.label}, {'one'});
        expect(await teacher.tiles(second), isEmpty);

        // Unfiltered reads span every space and do not say which is which.
        final everything = await guardian.local((db) => Tile.db.find(db));
        final teachers = await teacher.local((db) => Tile.db.find(db));
        note('T10', 'unfiltered read, user in two circles', {
          for (final t in everything) t.label,
        });
        note('T10', 'spaceId on rows read back', {
          for (final t in everything) t.spaceId,
        });
        note('T10', 'unfiltered read, user in one circle', {
          for (final t in teachers) t.label,
        });
        expect({for (final t in everything) t.label}, {'one', 'two', 'mine'});
        expect({for (final t in everything) t.spaceId}, {null});
        expect({for (final t in teachers) t.label}, {'one'});
      },
    );
  });
}
