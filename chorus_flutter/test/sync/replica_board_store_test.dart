// These tests run the real sync engine on a real SQLite replica; only the
// server is missing. See replica_harness.dart for why the circle is the
// user's personal space.
import 'dart:async';

import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_flutter/src/sync/adapters.dart';
import 'package:chorus_flutter/src/sync/chorus_session.dart';
import 'package:chorus_flutter/src/sync/replica_board_store.dart';
import 'package:chorus_flutter/src/sync/sync_supervisor.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_offline_sync_client/offline_sync.dart'
    show CrdtDataField, CrdtSchemaColumn;

import 'replica_harness.dart';

/// A server that is always there, or never.
class _Link implements SyncLink {
  bool reachable = true;
  int onceCalls = 0;

  @override
  bool get isSignedIn => true;

  @override
  Future<api.ServerInfo> serverInfo() async {
    if (!reachable) throw const api.ServerpodClientNetworkException('down');
    return api.ServerInfo(serverTime: DateTime.now().toUtc(), minBuild: 1);
  }

  @override
  Future<void> syncOnce(VoidCallback onMerge) async => onceCalls++;

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
  late _Link link;
  late SyncSupervisor sync;
  late ChorusSession session;
  late api.CircleInfo circle;
  late ReplicaBoardStore store;
  late String home;

  api.CircleInfo circleAs(api.CircleRole role) => api.CircleInfo(
    spaceUuid: harness.userId,
    childName: 'Maya',
    myRole: role,
    myDisplayName: 'Ada',
    members: const [],
  );

  Future<List<api.TileEdit>> editsOf(String tileId) => harness.replica.read(
    (s) => api.TileEdit.db.find(
      s,
      where: (t) => t.tileId.equals(uuidOf(tileId)),
      orderByList: (t) => [t.editedAt, t.prop],
    ),
  );

  TileFacts tileNamed(String label) =>
      store.tiles.singleWhere((t) => t.label == label);

  TileFacts tileAt(int row, int col) =>
      gridOf(home, store.tiles, store.boards)[(row, col)]!;

  setUp(() async {
    harness = await ReplicaHarness.open();
    link = _Link();
    sync = SyncSupervisor(link);
    session = ChorusSession.of(harness.replica, sync);
    sync.start();
    circle = circleAs(api.CircleRole.guardian);
    await session.ensureCircleReady(circle, seedIfEmpty: true);
    store = session.boardStore(circle);
    await store.refresh();
    home = starterBoardId(idOf(harness.userId));
  });

  tearDown(() async {
    await session.close();
    await harness.close();
  });

  group('seeding', () {
    test('writes the home board and its 36 tiles, tray empty', () {
      expect(
        store.boards,
        unorderedEquals([
          starterBoard(idOf(harness.userId)),
          wordsBoard(idOf(harness.userId)),
        ]),
        reason: 'the core board plus the empty My words board',
      );
      expect(store.tiles, hasLength(36));
      expect(trayOf(store.tiles, store.boards), isEmpty);
      expect(gridOf(home, store.tiles, store.boards), hasLength(36));
      expect(
        emptyCells(
          store.boards.firstWhere((board) => board.isHome),
          store.tiles,
          store.boards,
        ),
        isEmpty,
      );
      expect(tileAt(0, 0).label, 'like');
      expect(tileAt(5, 5).label, 'stop');
      expect(tileAt(0, 0).createdByName, 'Ada');
      expect(tileAt(0, 0).createdBy, idOf(harness.userId));
    });

    test('a second seed changes nothing', () async {
      final before = store.tiles;
      await session.ensureCircleReady(circle, seedIfEmpty: true);
      await store.refresh();
      expect(store.boards, hasLength(2));
      expect(store.tiles, before);
    });

    test('a starter board that is no longer the home board is not seeded '
        'again', () async {
      final space = harness.userId;
      await harness.replica.write(space, (tx) async {
        final board = await api.Board.db.findById(
          harness.replica.session,
          uuidOf(home),
          transaction: tx,
        );
        await api.Board.db.updateRow(
          harness.replica.session,
          board!.copyWith(isHome: false),
          columns: (t) => [t.isHome],
          transaction: tx,
        );
      });

      await session
          .ensureCircleReady(circle, seedIfEmpty: true)
          .timeout(const Duration(seconds: 10));
      await store.refresh();
      expect(store.boards, hasLength(2));
      expect(store.tiles, hasLength(36));
    });

    test('is not attempted for a circle that already has a board, even '
        'offline', () async {
      link.reachable = false;
      final calls = link.onceCalls;
      await session
          .ensureCircleReady(circle, seedIfEmpty: true)
          .timeout(const Duration(seconds: 2));
      expect(link.onceCalls, calls, reason: 'no sync was needed');
    });
  });

  group('seeding without a server', () {
    test(
      'waits rather than risk writing over a board not yet received',
      () async {
        final other = await ReplicaHarness.open();
        final offline = _Link()..reachable = false;
        final supervisor = SyncSupervisor(offline);
        final second = ChorusSession.of(other.replica, supervisor);
        supervisor.start();
        addTearDown(() async {
          await second.close();
          await other.close();
        });
        final info = api.CircleInfo(
          spaceUuid: other.userId,
          childName: 'Maya',
          myRole: api.CircleRole.guardian,
          myDisplayName: 'Ada',
          members: const [],
        );

        var finished = false;
        unawaited(
          second
              .ensureCircleReady(info, seedIfEmpty: true)
              .then((_) => finished = true, onError: (_) => finished = true),
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));
        expect(finished, isFalse);
        final boards = await other.replica.read((s) => api.Board.db.find(s));
        expect(boards, isEmpty);

        // The same call without seeding has nothing to wait for.
        await second
            .ensureCircleReady(info)
            .timeout(const Duration(seconds: 1));
      },
    );
  });

  group('addTile', () {
    test('into an occupied cell lands in the tray and returns false', () async {
      final placed = await store.addTile(
        boardId: home,
        row: 0,
        col: 0,
        label: ' banana ',
        colorKey: 'noun',
      );
      expect(placed, isFalse);
      final tile = tileNamed('banana');
      expect(CellKey.parse(tile.cellKey), TrayCell(tile.id));
      expect(tile.cellKey, trayKey(tile.id));
      expect(tile.colorKey, 'noun');
      expect(tile.boardId, home);
      expect(tile.id, tile.id.toLowerCase());
      expect(tileAt(0, 0).label, 'like', reason: 'the holder is untouched');
      expect(
        trayOf(store.tiles, store.boards).single.reason,
        TrayReason.unplaced,
      );
    });

    test('into a freed cell is placed and returns true', () async {
      await store.archiveTile(tileAt(2, 3).id);
      final placed = await store.addTile(
        boardId: home,
        row: 2,
        col: 3,
        label: 'banana',
        speech: 'a banana',
      );
      expect(placed, isTrue);
      final tile = tileAt(2, 3);
      expect(tile.label, 'banana');
      expect(tile.spokenText, 'a banana');
      expect(tile.cellKey, placedKey(home, 2, 3));
      expect(tile.createdByName, 'Ada');
    });

    test('logs who added what, in the same transaction', () async {
      await store.addTile(boardId: home, row: 0, col: 0, label: 'banana');
      final tile = tileNamed('banana');
      final edits = await editsOf(tile.id);
      expect({for (final e in edits) e.prop}, {'label', 'cellKey'});
      for (final edit in edits) {
        expect(edit.reason, EditReason.add);
        expect(edit.oldValue, isNull);
        expect(edit.actorId, harness.userId);
        expect(edit.actorName, 'Ada');
        expect(edit.circleId, harness.userId);
        expect(edit.baseEditId, isNull);
      }
      expect(edits.singleWhere((e) => e.prop == 'label').newValue, 'banana');
      expect(
        edits.singleWhere((e) => e.prop == 'cellKey').newValue,
        trayKey(tile.id),
      );
    });

    test(
      'falls back to the tray when a row it cannot see holds the cell',
      () async {
        // A row of some other circle in the same space, holding the key the
        // new tile wants. The store's own check filters on the circle and so
        // misses it; the unique index does not.
        await store.archiveTile(tileAt(1, 1).id);
        final stranger = api.UuidValue.fromString(
          '0198f0aa-1111-7222-8333-444455556666',
        );
        await harness.replica.write(harness.userId, (tx) async {
          await api.Tile.db.insertRow(
            harness.replica.session,
            api.Tile(
              circleId: stranger,
              boardId: uuidOf(home),
              cellKey: placedKey(home, 1, 1),
              label: 'hidden',
              noLog: false,
              createdBy: harness.userId,
              createdByName: 'Someone',
              createdAt: DateTime.now().toUtc(),
            ),
            transaction: tx,
          );
        });

        final placed = await store.addTile(
          boardId: home,
          row: 1,
          col: 1,
          label: 'banana',
        );
        expect(placed, isFalse);
        expect(tileNamed('banana').cellKey, trayKey(tileNamed('banana').id));
        expect(await editsOf(tileNamed('banana').id), hasLength(2));
        expect(
          store.tiles.where((t) => t.label == 'hidden'),
          isEmpty,
          reason: 'rows of another circle are not this store\'s',
        );
      },
    );

    test(
      'refuses a blank word, an unknown board and a cell off the grid',
      () async {
        await expectLater(
          store.addTile(boardId: home, row: 0, col: 0, label: '  '),
          throwsArgumentError,
        );
        await expectLater(
          store.addTile(
            boardId: '0198f0aa-1111-7222-8333-444455556666',
            row: 0,
            col: 0,
            label: 'x',
          ),
          throwsArgumentError,
        );
        await expectLater(
          store.addTile(boardId: home, row: 6, col: 0, label: 'x'),
          throwsRangeError,
        );
        expect(store.tiles, hasLength(36));
      },
    );
  });

  group('placeTile', () {
    late String waiting;

    setUp(() async {
      await store.addTile(boardId: home, row: 0, col: 0, label: 'banana');
      waiting = tileNamed('banana').id;
    });

    test('into an empty cell gives a tray tile a home', () async {
      await store.archiveTile(tileAt(4, 4).id);
      expect(await store.placeTile(waiting, row: 4, col: 4), isTrue);
      expect(tileAt(4, 4).id, waiting);
      expect(tileNamed('banana').cellKey, placedKey(home, 4, 4));
      expect(
        trayOf(store.tiles, store.boards),
        isEmpty,
        reason: 'archived tiles are not in the tray',
      );

      final move = (await editsOf(waiting)).last;
      expect(move.prop, 'cellKey');
      expect(move.reason, EditReason.resolve);
      expect(move.oldValue, trayKey(waiting));
      expect(move.newValue, placedKey(home, 4, 4));
      expect(move.baseEditId, isNotNull);
    });

    test('into an occupied cell returns false and writes nothing', () async {
      final edits = (await editsOf(waiting)).length;
      var writes = 0;
      harness.replica.onLocalWrite = () => writes++;

      expect(await store.placeTile(waiting, row: 3, col: 3), isFalse);
      expect(tileNamed('banana').cellKey, trayKey(waiting));
      expect(tileAt(3, 3).label, 'up');
      expect(await editsOf(waiting), hasLength(edits));
      expect(writes, 0, reason: 'nothing unsent is claimed');
    });

    test('never moves a tile that already has a cell', () async {
      await store.archiveTile(tileAt(4, 4).id);
      await expectLater(
        store.placeTile(tileAt(0, 0).id, row: 4, col: 4),
        throwsStateError,
      );
      expect(tileAt(0, 0).label, 'like');
      expect(gridOf(home, store.tiles, store.boards)[(4, 4)], isNull);
    });

    test('refuses an archived tile and a cell off the grid', () async {
      await expectLater(
        store.placeTile(waiting, row: 0, col: 9),
        throwsRangeError,
      );
      await store.archiveTile(waiting);
      await store.archiveTile(tileAt(4, 4).id);
      await expectLater(
        store.placeTile(waiting, row: 4, col: 4),
        throwsStateError,
      );
    });
  });

  group('updateTile', () {
    test('changes only what it is given, and never the cell', () async {
      final before = tileAt(0, 1);
      await store.updateTile(before.id, label: 'need');
      final after = tileAt(0, 1);
      expect(after.id, before.id);
      expect(after.label, 'need');
      expect(after, before.copyWith(label: 'need'));

      final edits = await editsOf(before.id);
      expect(edits, hasLength(1));
      expect(edits.single.prop, 'label');
      expect((edits.single.oldValue, edits.single.newValue), ('want', 'need'));
      expect(edits.single.reason, EditReason.edit);
    });

    test('logs one row per changed property', () async {
      final id = tileAt(0, 1).id;
      await store.updateTile(
        id,
        label: 'want',
        speech: 'I want',
        colorKey: 'pronoun',
      );
      final after = tileAt(0, 1);
      expect(after.speech, 'I want');
      expect(after.colorKey, 'pronoun');
      final edits = await editsOf(id);
      expect({for (final e in edits) e.prop}, {'speech', 'colorKey'});
      expect(edits.singleWhere((e) => e.prop == 'colorKey').oldValue, 'verb');
    });

    test('an empty speech clears it', () async {
      final id = tileAt(0, 1).id;
      await store.updateTile(id, speech: 'I want');
      await store.updateTile(id, speech: '');
      expect(tileAt(0, 1).speech, isNull);
      expect(tileAt(0, 1).spokenText, 'want');
    });

    test('each edit points at the one before it', () async {
      final id = tileAt(0, 1).id;
      await store.updateTile(id, label: 'need');
      await store.updateTile(id, label: 'wish');
      final edits = await editsOf(id);
      expect(edits, hasLength(2));
      final first = edits.singleWhere((e) => e.newValue == 'need');
      final second = edits.singleWhere((e) => e.newValue == 'wish');
      expect(first.baseEditId, isNull);
      expect(second.baseEditId, first.id);
      expect(second.oldValue, 'need');
    });

    test('with nothing to change writes nothing', () async {
      final id = tileAt(0, 1).id;
      var writes = 0;
      var notified = 0;
      harness.replica.onLocalWrite = () => writes++;
      store.addListener(() => notified++);

      await store.updateTile(id, label: 'want');
      await store.updateTile(id);
      expect(writes, 0);
      expect(notified, 0);
      expect(await editsOf(id), isEmpty);
    });

    test('works on a tile in the tray', () async {
      await store.addTile(boardId: home, row: 0, col: 0, label: 'banana');
      final id = tileNamed('banana').id;
      await store.updateTile(id, label: 'apple');
      expect(tileNamed('apple').cellKey, trayKey(id));
    });

    test('refuses a blank word and an unknown tile', () async {
      await expectLater(
        store.updateTile(tileAt(0, 1).id, label: ' '),
        throwsArgumentError,
      );
      await expectLater(
        store.updateTile('0198f0aa-1111-7222-8333-444455556666', label: 'x'),
        throwsStateError,
      );
    });
  });

  group('archiveTile', () {
    test('sets archived and frees the cell in one go', () async {
      final before = tileAt(5, 0);
      await store.archiveTile(before.id);
      final after = store.tiles.singleWhere((t) => t.id == before.id);
      expect(after.archived, isTrue);
      expect(after.cellKey, trayKey(before.id));
      expect(gridOf(home, store.tiles, store.boards)[(5, 0)], isNull);
      expect(
        emptyCells(
          store.boards.firstWhere((board) => board.isHome),
          store.tiles,
          store.boards,
        ),
        [
          (5, 0),
        ],
      );
      expect(trayOf(store.tiles, store.boards), isEmpty);

      final edits = await editsOf(before.id);
      expect({for (final e in edits) e.prop}, {'archivedAt', 'cellKey'});
      final move = edits.singleWhere((e) => e.prop == 'cellKey');
      expect(
        (move.oldValue, move.newValue),
        (placedKey(home, 5, 0), trayKey(before.id)),
      );
      expect(edits.every((e) => e.reason == EditReason.archive), isTrue);
    });

    test('twice is the same as once', () async {
      final id = tileAt(5, 0).id;
      await store.archiveTile(id);
      var writes = 0;
      harness.replica.onLocalWrite = () => writes++;
      await store.archiveTile(id);
      expect(writes, 0);
      expect(await editsOf(id), hasLength(2));
    });

    test('of a tray tile only sets the flag', () async {
      await store.addTile(boardId: home, row: 0, col: 0, label: 'banana');
      final id = tileNamed('banana').id;
      await store.archiveTile(id);
      expect(tileNamed('banana').archived, isTrue);
      expect(tileNamed('banana').cellKey, trayKey(id));
      final edits = await editsOf(id);
      expect(
        edits.where((e) => e.reason == EditReason.archive).single.prop,
        'archivedAt',
      );
    });
  });

  group('setTileMedia', () {
    test('sets, keeps and clears the two hashes, logs each change and '
        'never touches the cell or the words', () async {
      final before = tileAt(0, 1);
      final photo = 'a' * 64, clip = 'b' * 64;

      await store.setTileMedia(before.id, imageHash: photo, audioHash: clip);
      var tile = tileAt(0, 1);
      expect(tile.imageHash, photo);
      expect(tile.audioHash, clip);
      expect(tile.cellKey, before.cellKey);
      expect(tile.label, before.label);

      // Null leaves a property alone; an empty string clears it.
      await store.setTileMedia(before.id, imageHash: '');
      tile = tileAt(0, 1);
      expect(tile.imageHash, isNull);
      expect(tile.audioHash, clip);

      final edits = await editsOf(before.id);
      expect(
        [for (final e in edits) (e.prop, e.oldValue, e.newValue)],
        containsAll([
          ('imageHash', null, photo),
          ('audioHash', null, clip),
          ('imageHash', photo, null),
        ]),
      );
      expect(edits.every((e) => e.reason == EditReason.edit), isTrue);
    });

    test('with nothing to change writes nothing', () async {
      final id = tileAt(0, 1).id;
      await store.setTileMedia(id, imageHash: 'a' * 64);
      final logged = (await editsOf(id)).length;
      await store.setTileMedia(id, imageHash: 'a' * 64);
      await store.setTileMedia(id);
      expect(await editsOf(id), hasLength(logged));
    });

    test('is refused for a partner', () async {
      final viewer = session.boardStore(circleAs(api.CircleRole.partner));
      await viewer.refresh();
      expect(
        () => viewer.setTileMedia(tileAt(0, 1).id, imageHash: 'a' * 64),
        throwsStateError,
      );
    });
  });

  group('the edit log', () {
    test('is read with the tiles, and a restore is logged as one', () async {
      final id = tileAt(0, 1).id;
      await store.updateTile(id, label: 'need');
      expect(store.edits.where((e) => e.tileId == id).single.reason, 'edit');

      await store.updateTileAs(id, label: 'want', reason: EditReason.restore);
      final mine = store.edits.where((e) => e.tileId == id).toList();
      expect([for (final e in mine) e.reason], ['edit', 'restore']);
      expect(mine.last.baseEditId, mine.first.id);
      expect(tileAt(0, 1).label, 'want');
    });
  });

  group('updates name only the columns they change', () {
    // The engine keeps one clock stamp per updated column. A column stamped
    // without being changed would beat another device's edit of it, so the
    // set of stamps an operation leaves behind is what "narrowed" means.
    Future<Map<int, (String, DateTime, int)>> stamps() => harness.replica.read(
      (s) async => {
        for (final field in await CrdtDataField.db.find(
          s,
          include: CrdtDataField.include(column: CrdtSchemaColumn.include()),
        ))
          field.id!: (field.column!.name, field.hlcDatetime, field.hlcCounter),
      },
    );

    Future<Set<String>> stampedBy(Future<void> Function() operation) async {
      final before = await stamps();
      await operation();
      final after = await stamps();
      return {
        for (final MapEntry(:key, :value) in after.entries)
          if (before[key] != value) value.$1,
      };
    }

    test('updateTile', () async {
      final id = tileAt(0, 1).id;
      expect(
        await stampedBy(() => store.updateTile(id, label: 'need')),
        {'label'},
      );
      expect(
        await stampedBy(
          () => store.updateTile(id, label: 'need', speech: 'I need'),
        ),
        {'speech'},
      );
    });

    test('setTileMedia', () async {
      final id = tileAt(0, 1).id;
      expect(
        await stampedBy(() => store.setTileMedia(id, imageHash: 'a' * 64)),
        {'imageHash'},
      );
      expect(
        await stampedBy(
          () => store.setTileMedia(
            id,
            imageHash: 'a' * 64,
            audioHash: 'b' * 64,
          ),
        ),
        {'audioHash'},
      );
    });

    test('archiveTile', () async {
      final id = tileAt(0, 1).id;
      expect(
        await stampedBy(() => store.archiveTile(id)),
        {'archivedAt', 'cellKey'},
      );
    });

    test('placeTile', () async {
      await store.addTile(boardId: home, row: 0, col: 0, label: 'banana');
      await store.archiveTile(tileAt(4, 4).id);
      final id = tileNamed('banana').id;
      expect(
        await stampedBy(() => store.placeTile(id, row: 4, col: 4)),
        {'cellKey'},
      );
    });
  });

  group('a partner', () {
    late ReplicaBoardStore readOnly;

    setUp(() async {
      readOnly = session.boardStore(circleAs(api.CircleRole.partner));
      await readOnly.refresh();
    });

    test('sees the board', () {
      expect(readOnly.role, CircleRole.partner);
      expect(readOnly.tiles, hasLength(36));
      expect(readOnly.childName, 'Maya');
      expect(readOnly.myName, 'Ada');
    });

    test('never reaches the database with a write', () async {
      var writes = 0;
      harness.replica.onLocalWrite = () => writes++;
      final id = readOnly.tiles.first.id;

      await expectLater(
        readOnly.addTile(boardId: home, row: 0, col: 0, label: 'x'),
        throwsStateError,
      );
      await expectLater(
        readOnly.placeTile(id, row: 0, col: 0),
        throwsStateError,
      );
      await expectLater(readOnly.updateTile(id, label: 'x'), throwsStateError);
      await expectLater(readOnly.archiveTile(id), throwsStateError);

      expect(writes, 0);
      await readOnly.refresh();
      expect(readOnly.tiles, hasLength(36));
      expect(await editsOf(id), isEmpty);
    });
  });

  group('listening', () {
    test('a write shows up in the store before its future completes', () async {
      var notified = 0;
      store.addListener(() => notified++);
      await store.updateTile(tileAt(0, 0).id, label: 'love');
      expect(tileAt(0, 0).label, 'love');
      expect(notified, 1);
    });

    test('a revision bump with no change does not notify', () async {
      var notified = 0;
      store.addListener(() => notified++);
      sync.noteLocalWrite();
      await store.refresh();
      expect(notified, 0);
    });

    test('a change made elsewhere arrives with the next revision', () async {
      final other = session.boardStore(circle);
      await other.refresh();
      var notified = 0;
      other.addListener(() => notified++);

      await store.updateTile(tileAt(0, 0).id, label: 'love');
      await other.refresh();
      expect(notified, 1);
      expect(other.tiles.where((t) => t.label == 'love'), hasLength(1));
    });

    test('a local write marks the device as holding unsent changes', () async {
      expect(sync.hasUnsent, isTrue, reason: 'the seed has not been sent');
      final revision = sync.revision.value;
      await store.updateTile(tileAt(0, 0).id, label: 'love');
      expect(sync.revision.value, revision + 1);
    });

    test('a disposed store stops listening and is forgotten', () async {
      final other = session.boardStore(circle);
      await other.refresh();
      other.dispose();
      other.dispose();
      await store.updateTile(tileAt(0, 0).id, label: 'love');
      expect(other.tiles.where((t) => t.label == 'love'), isEmpty);
    });
  });
}
