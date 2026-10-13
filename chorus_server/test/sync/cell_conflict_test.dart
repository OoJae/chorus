/// Scenarios T1, T2, T5 and T6: what happens when two tiles want one cell.
///
/// Run with `dart test test/sync --concurrency=1`.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:serverpod_database/serverpod_database.dart'
    show DatabaseUniqueViolationException;
import 'package:serverpod_offline_sync_client/serverpod_offline_sync_client.dart';
import 'package:test/test.dart';

import 'replicas.dart';

/// Two members who each put a different word in cell (0, 0) while unsynced,
/// after everyone has converged.
typedef Collision = ({
  UuidValue circle,
  BoardFacts board,
  Replica guardian,
  Replica teacher,
  String cell,
  Tile earlier,
  Tile later,
});

/// Builds a [Collision]. The guardian claims the cell first, unless
/// [teacherClaimsFirst]; the later claim reaches the server first, unless
/// [earlierSyncsFirst].
Future<Collision> collide(
  SyncWorld world, {
  bool earlierSyncsFirst = false,
  bool teacherClaimsFirst = false,
}) async {
  final [guardian, teacher] = await world.users(['Guardian', 'Teacher']);
  final circle = await world.circle(
    guardian,
    members: {teacher: CircleRole.teacher},
  );
  final board = await world.emptyBoard(circle, guardian, [guardian, teacher]);
  final cell = placedKey(board.id, 0, 0);

  final [one, two] = teacherClaimsFirst
      ? [teacher, guardian]
      : [guardian, teacher];
  final earlier = await one.insertTile(
    circle,
    one.newTile(circle, board, 'juice', cellKey: cell),
  );
  await Future<void>.delayed(tick);
  final later = await two.insertTile(
    circle,
    two.newTile(circle, board, 'water', cellKey: cell),
  );

  final rounds = await world.converge(
    circle,
    earlierSyncsFirst ? [one, two] : [two, one],
  );
  note(
    'T1',
    'rounds to converge (earlierSyncsFirst=$earlierSyncsFirst, '
        'teacherClaimsFirst=$teacherClaimsFirst)',
    rounds,
  );
  return (
    circle: circle,
    board: board,
    guardian: guardian,
    teacher: teacher,
    cell: cell,
    earlier: earlier,
    later: later,
  );
}

void main() {
  withSyncWorld('Given two members of one circle,', (world) {
    for (final (earlierSyncsFirst, teacherClaimsFirst) in [
      (false, false),
      (true, false),
      (false, true),
    ]) {
      test('T1 when both fill the same empty cell while unsynced '
          '(${teacherClaimsFirst ? 'teacher' : 'guardian'} claims first, '
          'earlier claim syncs ${earlierSyncsFirst ? 'first' : 'last'}) '
          'then both tiles survive, the earlier claim holds the cell and '
          'the later one is contested in the tray.', () async {
        final c = await collide(
          world,
          earlierSyncsFirst: earlierSyncsFirst,
          teacherClaimsFirst: teacherClaimsFirst,
        );
        final contested = '${c.cell}$conflictMarker${c.later.id!.uuid}';

        final views = {
          'server': await world.serverTiles(c.circle),
          'guardian': await c.guardian.tiles(c.circle),
          'teacher': await c.teacher.tiles(c.circle),
        };
        for (final MapEntry(key: where, value: tiles) in views.entries) {
          expect(tiles, hasLength(2), reason: where);
          final keys = {for (final t in tiles) t.id: t.cellKey};
          note('T1', 'keys on $where', keys.values.toList());
          expect(keys[c.earlier.id!.uuid], c.cell, reason: where);
          expect(keys[c.later.id!.uuid], contested, reason: where);

          final tray = trayOf(tiles, [c.board]);
          expect(tray, hasLength(1), reason: where);
          expect(tray.single.tile.id, c.later.id!.uuid, reason: where);
          expect(tray.single.reason, TrayReason.contested, reason: where);
          expect(tray.single.wanted, PlacedCell(c.board.id, 0, 0));
          expect(
            CellKey.parse(tray.single.tile.cellKey),
            ContestedCell(c.board.id, 0, 0, c.later.id!.uuid),
          );
          expect(gridOf(c.board.id, tiles, [c.board]), {
            (0, 0): tiles.singleWhere((t) => t.id == c.earlier.id!.uuid),
          }, reason: where);
        }
      });
    }

    test(
      'T2 when a replica that holds a tile in a cell inserts another with '
      'the same key then the insert throws, and the tray key works.',
      () async {
        final [guardian] = await world.users(['Guardian']);
        final circle = await world.circle(guardian);
        final board = await world.emptyBoard(circle, guardian, [guardian]);
        final cell = placedKey(board.id, 2, 3);
        final first = await guardian.insertTile(
          circle,
          guardian.newTile(circle, board, 'juice', cellKey: cell),
        );

        final second = guardian.newTile(circle, board, 'water', cellKey: cell);
        Object? insertError;
        try {
          await guardian.insertTile(circle, second);
        } catch (e) {
          insertError = e;
        }
        note('T2', 'duplicate insert error type', insertError.runtimeType);
        note('T2', 'duplicate insert error', '$insertError'.split('\n').first);
        expect(insertError, isA<DatabaseUniqueViolationException>());

        // The refused insert left nothing behind and did not poison the replica.
        expect(await guardian.tiles(circle), hasLength(1));
        await guardian.insertTile(
          circle,
          second.copyWith(cellKey: trayKey(second.id!.uuid)),
        );

        // Placing a tray tile into the occupied cell is refused the same way.
        Object? updateError;
        try {
          await guardian.updateTile(
            circle,
            second.id!,
            (row) => row.copyWith(cellKey: cell),
            columns: (t) => [t.cellKey],
          );
        } catch (e) {
          updateError = e;
        }
        note('T2', 'duplicate update error type', updateError.runtimeType);
        note('T2', 'duplicate update error', '$updateError'.split('\n').first);
        expect(updateError, isA<DatabaseUniqueViolationException>());

        // Authoring the engine's own marker is refused before it is stored.
        Object? reservedError;
        try {
          await guardian.insertTile(
            circle,
            guardian.newTile(
              circle,
              board,
              'forged',
              cellKey: '$cell$conflictMarker${first.id!.uuid}',
            ),
          );
        } catch (e) {
          reservedError = e;
        }
        note('T2', 'reserved value error type', reservedError.runtimeType);
        expect(reservedError, isA<OfflineSyncReservedValueException>());

        await world.converge(circle, [guardian]);
        final tiles = await world.serverTiles(circle);
        expect(tiles, hasLength(2));
        final tray = trayOf(tiles, [board]);
        expect(tray.single.tile.id, second.id!.uuid);
        expect(tray.single.reason, TrayReason.unplaced);
      },
    );

    for (final byAuthor in [true, false]) {
      test('T5 when the contested tile is given a fresh empty cell by '
          '${byAuthor ? 'its author' : 'the other member'} '
          'then it sits there, clean, everywhere.', () async {
        final c = await collide(world);
        final mover = byAuthor ? c.teacher : c.guardian;
        final home = placedKey(c.board.id, 0, 1);

        await mover.updateTile(
          c.circle,
          c.later.id!,
          (row) => row.copyWith(cellKey: home),
          columns: (t) => [t.cellKey],
        );
        final rounds = await world.converge(c.circle, [
          mover,
          byAuthor ? c.guardian : c.teacher,
        ]);
        note('T5', 'rounds to converge (byAuthor=$byAuthor)', rounds);

        for (final tiles in [
          await world.serverTiles(c.circle),
          await c.guardian.tiles(c.circle),
          await c.teacher.tiles(c.circle),
        ]) {
          expect(trayOf(tiles, [c.board]), isEmpty);
          final grid = gridOf(c.board.id, tiles, [c.board]);
          expect(grid[(0, 0)]?.id, c.earlier.id!.uuid);
          expect(grid[(0, 1)]?.id, c.later.id!.uuid);
          expect(grid[(0, 1)]?.cellKey, home);
        }
      });
    }

    test(
      'T6 when the tile holding a contested cell is archived to the tray '
      'then the waiting tile takes the freed cell by itself, everywhere.',
      () async {
        final c = await collide(world);
        final contested = '${c.cell}$conflictMarker${c.later.id!.uuid}';
        // What a talker on the teacher's device is showing the child.
        final held = BoardSnapshot.of(
          c.board,
          await c.teacher.tiles(c.circle),
          [c.board],
        );

        await c.guardian.updateTile(
          c.circle,
          c.earlier.id!,
          (row) => row.copyWith(
            archivedAt: DateTime.now().toUtc(),
            cellKey: trayKey(c.earlier.id!.uuid),
          ),
          columns: (t) => [t.archivedAt, t.cellKey],
        );

        // Before any sync: what the archiving device itself shows.
        final atOnce = await c.guardian.cellKeyOf(c.later.id!);
        note('T6', 'waiting tile on archiving device before sync', atOnce);
        expect(atOnce, c.cell);

        final rounds = await world.converge(c.circle, [c.guardian, c.teacher]);
        note('T6', 'rounds to converge', rounds);

        final views = {
          'server': await world.serverTiles(c.circle),
          'guardian': await c.guardian.tiles(c.circle),
          'teacher': await c.teacher.tiles(c.circle),
        };
        for (final MapEntry(key: where, value: tiles) in views.entries) {
          final winner = tiles.singleWhere((t) => t.id == c.earlier.id!.uuid);
          final waiting = tiles.singleWhere((t) => t.id == c.later.id!.uuid);
          note('T6', 'waiting tile on $where after sync', waiting.cellKey);
          expect(winner.archived, isTrue, reason: where);
          expect(winner.cellKey, trayKey(c.earlier.id!.uuid), reason: where);
          // Observed: the engine hands the freed cell to the waiting tile by
          // itself, on the archiving device at once and everywhere after sync.
          expect(waiting.cellKey, c.cell, reason: where);
          expect(waiting.cellKey, isNot(contested), reason: where);
          expect(trayOf(tiles, [c.board]), isEmpty, reason: where);
          expect(gridOf(c.board.id, tiles, [c.board])[(0, 0)]?.id, waiting.id);
        }

        // For the child this is one merge that swaps the word in a cell she
        // knows, so the held snapshot keeps it back for an adult.
        final plan = reconcileSnapshot(
          held,
          BoardSnapshot.of(c.board, views['teacher']!, [c.board]),
        );
        note('T6', 'held snapshot plan', '${plan.auto} / ${plan.needsAdult}');
        expect(plan.auto, isEmpty);
        expect(plan.needsAdult.single.kind, ChangeKind.replaced);
        expect(plan.next.cells[(0, 0)]?.id, c.earlier.id!.uuid);
      },
    );
  });
}
