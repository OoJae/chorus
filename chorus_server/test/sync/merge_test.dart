/// Scenarios T3, T4 and T7: how edits to one tile, and two seeds of one
/// board, merge.
///
/// Run with `dart test test/sync --concurrency=1`.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:serverpod_database/serverpod_database.dart'
    show DatabaseQueryException, DatabaseUniqueViolationException;
import 'package:test/test.dart';

import 'replicas.dart';

/// Two members who both hold the same synced tile, 'juice', in cell (0, 0).
typedef SharedTile = ({
  UuidValue circle,
  BoardFacts board,
  Replica guardian,
  Replica teacher,
  UuidValue tile,
});

Future<SharedTile> shareTile(SyncWorld world) async {
  final [guardian, teacher] = await world.users(['Guardian', 'Teacher']);
  final circle = await world.circle(
    guardian,
    members: {teacher: CircleRole.teacher},
  );
  final board = await world.emptyBoard(circle, guardian, [guardian, teacher]);
  final tile = await guardian.insertTile(
    circle,
    guardian.newTile(
      circle,
      board,
      'juice',
      cellKey: placedKey(board.id, 0, 0),
    ),
  );
  await world.converge(circle, [guardian, teacher]);
  return (
    circle: circle,
    board: board,
    guardian: guardian,
    teacher: teacher,
    tile: tile.id!,
  );
}

/// The one tile of [s]'s circle as the server and both replicas hold it.
Future<Map<String, TileFacts>> views(SyncWorld world, SharedTile s) async => {
  'server': (await world.serverTiles(s.circle)).single,
  'guardian': (await s.guardian.tiles(s.circle)).single,
  'teacher': (await s.teacher.tiles(s.circle)).single,
};

/// Inserts the starter board and its 36 tiles from [device], the way the
/// app seeds a new circle. Returns how long the local write took.
Future<Duration> seed(Replica device, UuidValue circle) async {
  final watch = Stopwatch()..start();
  final tiles = starterTiles(
    circleId: circle.uuid,
    createdBy: device.userId.uuid,
    createdByName: device.name,
    createdAt: DateTime.now().toUtc(),
  );
  await device.write(circle, (db, tx) async {
    await Board.db.insertRow(
      db,
      boardRow(starterBoard(circle.uuid), circle),
      transaction: tx,
    );
    await Tile.db.insert(
      db,
      [for (final tile in tiles) starterTileRow(tile, circle)],
      transaction: tx,
    );
  });
  return watch.elapsed;
}

void main() {
  withSyncWorld('Given two members holding the same tile,', (world) {
    test('T3 when they change different properties while unsynced, naming '
        'the changed column, then both changes survive.', () async {
      final s = await shareTile(world);
      await s.guardian.updateTile(
        s.circle,
        s.tile,
        (row) => row.copyWith(label: 'apple juice'),
        columns: (t) => [t.label],
      );
      await Future<void>.delayed(tick);
      await s.teacher.updateTile(
        s.circle,
        s.tile,
        (row) => row.copyWith(speech: 'I want juice'),
        columns: (t) => [t.speech],
      );
      final rounds = await world.converge(s.circle, [s.guardian, s.teacher]);
      note('T3', 'rounds to converge', rounds);

      for (final MapEntry(key: where, value: tile) in (await views(
        world,
        s,
      )).entries) {
        note(
          'T3',
          'narrowed columns, $where',
          '${tile.label} / ${tile.speech}',
        );
        expect(tile.label, 'apple juice', reason: where);
        expect(tile.speech, 'I want juice', reason: where);
        expect(tile.cellKey, placedKey(s.board.id, 0, 0), reason: where);
      }
    });

    test('T3 control: when the same two changes are written without naming '
        'columns then the later write replaces the whole row and the '
        'earlier change is lost.', () async {
      final s = await shareTile(world);
      await s.guardian.updateTile(
        s.circle,
        s.tile,
        (row) => row.copyWith(label: 'apple juice'),
        columns: null,
      );
      await Future<void>.delayed(tick);
      await s.teacher.updateTile(
        s.circle,
        s.tile,
        (row) => row.copyWith(speech: 'I want juice'),
        columns: null,
      );
      await world.converge(s.circle, [s.guardian, s.teacher]);

      for (final MapEntry(key: where, value: tile) in (await views(
        world,
        s,
      )).entries) {
        note('T3', 'whole-row write, $where', '${tile.label} / ${tile.speech}');
        // The teacher never saw 'apple juice'; its stale 'juice' wins.
        expect(tile.label, 'juice', reason: where);
        expect(tile.speech, 'I want juice', reason: where);
      }
    });

    for (final (laterSyncsFirst, teacherWritesLater) in [
      (true, true),
      (false, true),
      (true, false),
    ]) {
      test('T4 when both change the label while unsynced '
          '(${teacherWritesLater ? 'teacher' : 'guardian'} writes later, '
          'later write syncs ${laterSyncsFirst ? 'first' : 'last'}) '
          'then the later write wins everywhere and both edit-log rows '
          'survive.', () async {
        final s = await shareTile(world);
        final [one, two] = teacherWritesLater
            ? [s.guardian, s.teacher]
            : [s.teacher, s.guardian];
        late final TileEdit first, second;
        await one.updateTile(
          s.circle,
          s.tile,
          (row) => row.copyWith(label: 'apple juice'),
          columns: (t) => [t.label],
          edit: (before) => first = one.newEdit(
            s.circle,
            s.tile,
            'label',
            before.label,
            'apple juice',
          ),
        );
        await Future<void>.delayed(tick);
        await two.updateTile(
          s.circle,
          s.tile,
          (row) => row.copyWith(label: 'orange juice'),
          columns: (t) => [t.label],
          edit: (before) => second = two.newEdit(
            s.circle,
            s.tile,
            'label',
            before.label,
            'orange juice',
          ),
        );
        final order = laterSyncsFirst ? [two, one] : [one, two];
        final rounds = await world.converge(s.circle, order);
        note(
          'T4',
          'rounds to converge (laterSyncsFirst=$laterSyncsFirst, '
              'teacherWritesLater=$teacherWritesLater)',
          rounds,
        );

        for (final MapEntry(key: where, value: tile) in (await views(
          world,
          s,
        )).entries) {
          note('T4', 'label on $where', tile.label);
          expect(tile.label, 'orange juice', reason: where);
        }

        final both = {first.id!.uuid, second.id!.uuid};
        expect(await world.serverEditIds(s.circle), both);
        for (final replica in [s.guardian, s.teacher]) {
          final edits = await replica.edits(s.circle);
          expect({for (final e in edits) e.id!.uuid}, both, reason: '$replica');
          // The overwritten value is still in the log, so it can be restored.
          expect(
            edits.singleWhere((e) => e.id == first.id).newValue,
            'apple juice',
          );
          expect(
            {for (final e in edits) e.oldValue},
            {'juice'},
            reason: 'both authors edited from the same base',
          );
        }
      });
    }
  });

  withSyncWorld('Given a new circle with no board,', (world) {
    test('T7 when two devices of the guardian both seed the starter board '
        'while unsynced then there are 36 tiles and an empty tray.', () async {
      final [phone] = await world.users(['Guardian']);
      final tablet = await world.secondDevice(phone);
      final circle = await world.circle(phone);
      await tablet.sync();

      note('T7', 'local seed time, first device', await seed(phone, circle));
      await Future<void>.delayed(tick);
      note('T7', 'local seed time, second device', await seed(tablet, circle));
      note('T7', 'first sync after seeding', await phone.sync());
      final rounds = await world.converge(circle, [tablet, phone]);
      note('T7', 'rounds to converge (same user)', rounds);

      await _expectOneCleanStarterBoard(world, circle, [phone, tablet]);
    });

    test('T7 when the guardian and a teacher both seed the starter board '
        'while unsynced then there are 36 tiles and an empty tray.', () async {
      final [guardian, teacher] = await world.users(['Guardian', 'Teacher']);
      final circle = await world.circle(
        guardian,
        members: {teacher: CircleRole.teacher},
      );

      await seed(guardian, circle);
      await Future<void>.delayed(tick);
      await seed(teacher, circle);
      final rounds = await world.converge(circle, [teacher, guardian]);
      note('T7', 'rounds to converge (two users)', rounds);

      await _expectOneCleanStarterBoard(world, circle, [guardian, teacher]);
      // Same row, two authors: the later seed's columns win, field by field.
      final authors = {
        for (final t in await world.serverTiles(circle)) t.createdByName,
      };
      note('T7', 'createdByName after two users seed', authors);
      expect(authors, {'Teacher'});
    });

    test('T7 when a device that already holds the starter board seeds again '
        'then the insert is refused and nothing changes.', () async {
      final [guardian] = await world.users(['Guardian']);
      final circle = await world.circle(guardian);
      await seed(guardian, circle);
      await world.converge(circle, [guardian]);

      Object? error;
      try {
        await seed(guardian, circle);
      } catch (e) {
        error = e;
      }
      note('T7', 'second seed on one device, error type', error.runtimeType);
      note(
        'T7',
        'second seed on one device, error',
        '$error'.split('\n').first,
      );
      // A primary-key clash is the base query exception, not the
      // unique-violation subtype a taken cell gives.
      expect(error, isA<DatabaseQueryException>());
      expect(error, isNot(isA<DatabaseUniqueViolationException>()));

      await world.converge(circle, [guardian]);
      await _expectOneCleanStarterBoard(world, circle, [guardian]);
    });
  });
}

Future<void> _expectOneCleanStarterBoard(
  SyncWorld world,
  UuidValue circle,
  List<Replica> replicas,
) async {
  final board = starterBoard(circle.uuid);
  final views = {
    'server': await world.serverTiles(circle),
    for (final replica in replicas) replica.name: await replica.tiles(circle),
  };
  for (final MapEntry(key: where, value: tiles) in views.entries) {
    final tray = trayOf(tiles, [board]);
    note('T7', 'tiles / tray on $where', '${tiles.length} / ${tray.length}');
    expect(tiles, hasLength(36), reason: where);
    expect(tray, isEmpty, reason: where);
    expect(gridOf(board.id, tiles, [board]), hasLength(36), reason: where);
    expect(emptyCells(board, tiles, [board]), isEmpty, reason: where);
    expect(
      {for (final t in tiles) t.cellKey},
      {for (final w in universalCore36) placedKey(board.id, w.row, w.col)},
      reason: where,
    );
  }
}
