// Adding, renaming, archiving and importing boards on the real sync engine
// and a real SQLite replica; only the server is missing. See
// ../sync/replica_harness.dart for why the circle is the user's personal
// space.
import 'dart:async';
import 'dart:convert';

import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_flutter/src/sync/adapters.dart';
import 'package:chorus_flutter/src/sync/chorus_session.dart';
import 'package:chorus_flutter/src/sync/replica_board_store.dart';
import 'package:chorus_flutter/src/sync/sync_supervisor.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts_boards.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_offline_sync_client/offline_sync.dart'
    show CrdtDataField, CrdtSchemaColumn;

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

/// An OBF board [rows] x [cols] with a word in every cell, labelled by its
/// cell: "r0c0", "r0c1" and so on. Cell 0:1 says "I want", and 0:0 is a
/// verb's green.
ObfBoard _obf(String name, {int rows = 7, int cols = 7}) {
  final buttons = <Map<String, Object?>>[];
  final order = <List<String>>[];
  for (var row = 0; row < rows; row++) {
    final line = <String>[];
    for (var col = 0; col < cols; col++) {
      final id = 'b$row$col';
      line.add(id);
      buttons.add({
        'id': id,
        'label': 'r${row}c$col',
        if (row == 0 && col == 1) 'vocalization': 'I want',
        if (row == 0 && col == 0) 'background_color': 'rgb(199, 239, 178)',
      });
    }
    order.add(line);
  }
  return parseObf(
    jsonEncode({
      'format': 'open-board-0.1',
      'id': 'imported',
      'name': name,
      'buttons': buttons,
      'grid': {'rows': rows, 'columns': cols, 'order': order},
    }),
  );
}

void main() {
  late ReplicaHarness harness;
  late SyncSupervisor sync;
  late ChorusSession session;
  late api.CircleInfo circle;
  late ReplicaBoardStore store;
  late String home;
  late String words;

  api.CircleInfo circleAs(api.CircleRole role) => api.CircleInfo(
    spaceUuid: harness.userId,
    childName: 'Maya',
    myRole: role,
    myDisplayName: 'Ada',
    members: const [],
  );

  BoardFacts board(String id) => store.boards.singleWhere((b) => b.id == id);

  Future<List<api.TileEdit>> editsOf(String tileId) => harness.replica.read(
    (s) => api.TileEdit.db.find(
      s,
      where: (t) => t.tileId.equals(uuidOf(tileId)),
    ),
  );

  Future<api.Board> rowOf(String id) async {
    final row = await harness.replica.read<api.Board?>(
      (s) => api.Board.db.findById(s, uuidOf(id)),
    );
    return row!;
  }

  setUp(() async {
    harness = await ReplicaHarness.open();
    sync = SyncSupervisor(_Link());
    session = ChorusSession.of(harness.replica, sync);
    sync.start();
    circle = circleAs(api.CircleRole.guardian);
    await session.ensureCircleReady(circle, seedIfEmpty: true);
    store = session.boardStore(circle);
    await store.refresh();
    home = starterBoardId(idOf(harness.userId));
    words = wordsBoardId(idOf(harness.userId));
  });

  tearDown(() async {
    await session.close();
    await harness.close();
  });

  test('the replica store is a board manager', () {
    expect(store, isA<BoardManager>());
  });

  group('addBoard', () {
    test(
      'adds an empty 6 x 6 board in the circle, not the home board',
      () async {
        final id = await store.addBoard('  Snack   time ');
        final added = board(id);
        expect(added.name, 'Snack time');
        expect(added.rows, starterRows);
        expect(added.cols, starterCols);
        expect(added.isHome, isFalse);
        expect(added.archived, isFalse);
        expect(store.tiles.where((t) => t.boardId == id), isEmpty);
        final row = await rowOf(id);
        expect(row.circleId, harness.userId);
        // A time-ordered UUID (version 7).
        expect(id[14], '7');
      },
    );

    test('refuses a name the rules refuse, writing nothing', () async {
      var writes = 0;
      harness.replica.onLocalWrite = () => writes++;
      await expectLater(store.addBoard('   '), throwsArgumentError);
      await expectLater(
        store.addBoard('x' * (maxBoardNameLength + 1)),
        throwsArgumentError,
      );
      expect(writes, 0);
      expect(store.boards, hasLength(2));
    });
  });

  group('renameBoard', () {
    test('renames, and a second board sees it', () async {
      await store.renameBoard(words, 'Food');
      expect(board(words).name, 'Food');
      final other = session.boardStore(circle);
      await other.refresh();
      expect(other.boards.singleWhere((b) => b.id == words).name, 'Food');
    });

    test('the same name writes nothing', () async {
      var writes = 0;
      await store.renameBoard(words, 'Food');
      harness.replica.onLocalWrite = () => writes++;
      await store.renameBoard(words, ' Food ');
      expect(writes, 0, reason: 'a rolled-back write is no local change');
    });

    test('refuses an unknown or archived board, and a bad name', () async {
      await expectLater(
        store.renameBoard('0190e0a0-0000-7000-8000-000000000000', 'X'),
        throwsArgumentError,
      );
      await expectLater(
        store.renameBoard('not-a-board', 'X'),
        throwsArgumentError,
      );
      await expectLater(store.renameBoard(words, ''), throwsArgumentError);
      await store.archiveBoard(words);
      await expectLater(store.renameBoard(words, 'X'), throwsArgumentError);
    });
  });

  group('archiveBoard', () {
    test('archives the board and every word on it, each to its tray key, '
        'logged as archived', () async {
      final a = await store.addTile(
        boardId: words,
        row: 0,
        col: 0,
        label: 'banana',
      );
      expect(a, isTrue);
      await store.addTile(boardId: words, row: 0, col: 0, label: 'apple');
      final mine = store.tiles.where((t) => t.boardId == words).toList();
      expect(mine, hasLength(2), reason: 'one placed, one in the tray');

      await store.archiveBoard(words);
      expect(board(words).archived, isTrue);
      for (final tile in store.tiles.where((t) => t.boardId == words)) {
        expect(tile.archived, isTrue);
        expect(tile.cellKey, trayKey(tile.id));
        final reasons = {for (final e in await editsOf(tile.id)) e.reason};
        expect(reasons, contains(EditReason.archive));
      }
      // Nothing left waiting for a cell on a board that has gone.
      expect(trayOf(store.tiles, store.boards), isEmpty);
      // The home board's words are untouched.
      expect(
        store.tiles.where((t) => t.boardId == home && !t.archived),
        hasLength(36),
      );
    });

    test('refuses the home board', () async {
      await expectLater(
        store.archiveBoard(home),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            archiveProblem(board(home), store.boards),
          ),
        ),
      );
      expect(board(home).archived, isFalse);
    });

    test('refuses the last board in use', () async {
      // A circle whose starter board is no longer the home board.
      await harness.replica.write(harness.userId, (tx) async {
        final row = await api.Board.db.findById(
          harness.replica.session,
          uuidOf(home),
          transaction: tx,
        );
        await api.Board.db.updateRow(
          harness.replica.session,
          row!.copyWith(isHome: false),
          columns: (t) => [t.isHome],
          transaction: tx,
        );
      });
      await store.archiveBoard(words);
      await expectLater(
        store.archiveBoard(home),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Keep at least one board.',
          ),
        ),
      );
      expect(board(home).archived, isFalse);
    });

    test('refuses an unknown board', () async {
      await expectLater(
        store.archiveBoard('0190e0a0-0000-7000-8000-000000000000'),
        throwsArgumentError,
      );
    });
  });

  group('importBoard', () {
    test('adds a board holding the words in their cells, in one write, and '
        'lists what did not fit', () async {
      var writes = 0;
      harness.replica.onLocalWrite = () => writes++;
      final result = await store.importBoard(_obf('Park'));
      expect(writes, 1, reason: 'one transaction');

      final added = board(result.boardId);
      expect(added.name, 'Park');
      expect(added.isHome, isFalse);
      final grid = gridOf(result.boardId, store.tiles, store.boards);
      expect(grid, hasLength(36));
      expect(grid[(0, 0)]!.label, 'r0c0');
      expect(grid[(0, 0)]!.colorKey, 'verb');
      expect(grid[(0, 1)]!.speech, 'I want');
      expect(grid[(5, 5)]!.label, 'r5c5');
      for (final tile in grid.values) {
        final (row, col) = grid.entries
            .firstWhere((entry) => entry.value.id == tile.id)
            .key;
        expect(tile.cellKey, placedKey(result.boardId, row, col));
      }
      // Row 6 and column 6 of the 7 x 7 file: 13 words.
      expect(result.leftOut, hasLength(13));
      expect(result.leftOut.first.label, 'r0c6');

      final logged = await editsOf(grid[(0, 1)]!.id);
      expect({for (final e in logged) e.reason}, {EditReason.add});
      expect({for (final e in logged) e.prop}, {'label', 'cellKey', 'speech'});
    });

    test('a name already in use gets a number', () async {
      await store.renameBoard(words, 'Park');
      final result = await store.importBoard(_obf('Park', rows: 2, cols: 2));
      expect(board(result.boardId).name, 'Park 2');
      expect(result.leftOut, isEmpty);
    });
  });

  group('board writes name only the columns they change', () {
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

    test('renameBoard', () async {
      expect(await stampedBy(() => store.renameBoard(words, 'Food')), {'name'});
    });

    test('archiveBoard, with an empty board', () async {
      expect(await stampedBy(() => store.archiveBoard(words)), {'archivedAt'});
    });

    test('archiveBoard, with a word on it', () async {
      await store.addTile(boardId: words, row: 1, col: 1, label: 'banana');
      expect(await stampedBy(() => store.archiveBoard(words)), {
        'archivedAt',
        'cellKey',
      });
    });
  });

  group('a partner', () {
    late ReplicaBoardStore readOnly;

    setUp(() async {
      readOnly = session.boardStore(circleAs(api.CircleRole.partner));
      await readOnly.refresh();
    });

    test('never reaches the database with a board write', () async {
      var writes = 0;
      harness.replica.onLocalWrite = () => writes++;
      await expectLater(readOnly.addBoard('Mine'), throwsStateError);
      await expectLater(readOnly.renameBoard(words, 'Mine'), throwsStateError);
      await expectLater(readOnly.archiveBoard(words), throwsStateError);
      await expectLater(readOnly.importBoard(_obf('Park')), throwsStateError);
      expect(writes, 0);
      await readOnly.refresh();
      expect(readOnly.boards, hasLength(2));
    });
  });
}
