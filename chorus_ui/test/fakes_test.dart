import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// A seeded store with (5, 5) and (4, 5) free.
  FakeBoardStore withGaps({CircleRole role = CircleRole.guardian}) =>
      FakeBoardStore.seeded(role: role, leaveEmpty: const {(4, 5), (5, 5)});

  Map<(int, int), TileFacts> grid(FakeBoardStore store) =>
      gridOf(store.homeBoardId, store.tiles, store.boards);

  List<TrayEntry> tray(FakeBoardStore store) =>
      trayOf(store.tiles, store.boards);

  TileFacts byLabel(FakeBoardStore store, String label) =>
      store.tiles.singleWhere((tile) => tile.label == label);

  group('seeded', () {
    test('is the full starter board with an empty tray', () {
      final store = FakeBoardStore.seeded();
      expect(store.boards, [starterBoard(FakeBoardStore.circleId)]);
      expect(store.tiles, hasLength(36));
      expect(grid(store), hasLength(36));
      expect(tray(store), isEmpty);
      expect(store.childName, 'Maya');
      expect(store.myName, 'Mum');
      expect(store.role, CircleRole.guardian);
    });

    test('leaveEmpty leaves exactly those cells free', () {
      final store = withGaps();
      expect(store.tiles, hasLength(34));
      final board = store.boards.single;
      expect(emptyCells(board, store.tiles, store.boards), [(4, 5), (5, 5)]);
    });
  });

  group('addTile', () {
    test('into an empty cell places the tile and returns true', () async {
      final store = withGaps();
      var notified = 0;
      store.addListener(() => notified++);

      final placed = await store.addTile(
          boardId: store.homeBoardId, row: 5, col: 5, label: ' swing ');

      expect(placed, isTrue);
      expect(notified, 1);
      final tile = grid(store)[(5, 5)]!;
      expect(tile.label, 'swing');
      expect(tile.cellKey, placedKey(store.homeBoardId, 5, 5));
      expect(tile.createdByName, 'Mum');
      expect(tray(store), isEmpty);
    });

    test('into an occupied cell creates the tile in the tray, returns false',
        () async {
      final store = withGaps();
      final holder = grid(store)[(0, 0)]!;

      final placed = await store.addTile(
          boardId: store.homeBoardId, row: 0, col: 0, label: 'swing');

      expect(placed, isFalse);
      expect(grid(store)[(0, 0)], holder);
      final entry = tray(store).single;
      expect(entry.tile.label, 'swing');
      expect(entry.reason, TrayReason.unplaced);
      expect(entry.tile.cellKey, trayKey(entry.tile.id));
    });

    test('rejects a cell outside the board and an empty label', () async {
      final store = withGaps();
      await expectLater(
          store.addTile(
              boardId: store.homeBoardId, row: 6, col: 0, label: 'x'),
          throwsArgumentError);
      await expectLater(
          store.addTile(
              boardId: store.homeBoardId, row: 5, col: 5, label: '  '),
          throwsArgumentError);
      expect(store.tiles, hasLength(34));
    });
  });

  group('placeTile', () {
    test('moves a tray tile into an empty cell', () async {
      final store = withGaps();
      await store.addTile(
          boardId: store.homeBoardId, row: 0, col: 0, label: 'swing');
      final waiting = tray(store).single.tile;

      expect(await store.placeTile(waiting.id, row: 5, col: 5), isTrue);

      expect(grid(store)[(5, 5)]!.id, waiting.id);
      expect(tray(store), isEmpty);
    });

    test('into an occupied cell returns false and leaves the tile waiting',
        () async {
      final store = withGaps();
      await store.addTile(
          boardId: store.homeBoardId, row: 0, col: 0, label: 'swing');
      final waiting = tray(store).single.tile;
      final holder = grid(store)[(1, 1)]!;

      expect(await store.placeTile(waiting.id, row: 1, col: 1), isFalse);

      expect(grid(store)[(1, 1)], holder);
      expect(tray(store).single.tile, waiting);
    });

    test('gives a contested tile a home', () async {
      final store = withGaps();
      store.remoteConflict(row: 0, col: 0, label: 'bus');
      final loser = tray(store).single.tile;

      expect(await store.placeTile(loser.id, row: 4, col: 5), isTrue);

      expect(byLabel(store, 'bus').cellKey,
          placedKey(store.homeBoardId, 4, 5));
      expect(tray(store), isEmpty);
    });

    test('never moves a tile that already holds a cell', () async {
      final store = withGaps();
      final placed = grid(store)[(0, 0)]!;

      await expectLater(
          store.placeTile(placed.id, row: 5, col: 5), throwsStateError);

      expect(grid(store)[(0, 0)], placed);
      expect(grid(store).containsKey((5, 5)), isFalse);
    });
  });

  test('archiveTile sets archived, rewrites the key and frees the cell',
      () async {
    final store = withGaps();
    final tile = grid(store)[(2, 2)]!;

    await store.archiveTile(tile.id);

    final after = store.tiles.singleWhere((t) => t.id == tile.id);
    expect(after.archived, isTrue);
    expect(after.cellKey, trayKey(tile.id));
    expect(grid(store).containsKey((2, 2)), isFalse);
    expect(tray(store), isEmpty, reason: 'an archived tile needs no home');
  });

  test('archiveTile hands the freed cell to the oldest tile that lost it',
      () async {
    final store = withGaps();
    final winner = grid(store)[(0, 0)]!;
    store.remoteConflict(row: 0, col: 0, label: 'bus');
    store.remoteConflict(row: 0, col: 0, label: 'train');
    store.remoteConflict(row: 0, col: 1, label: 'boat');

    await store.archiveTile(winner.id);

    final heir = grid(store)[(0, 0)]!;
    expect(heir.label, 'bus');
    expect(heir.cellKey, placedKey(store.homeBoardId, 0, 0));
    expect(tray(store).map((e) => e.tile.label), ['train', 'boat']);
    expect(tray(store).every((e) => e.reason == TrayReason.contested), isTrue);

    // Archiving a tray tile frees no cell, so nobody is handed one.
    await store.archiveTile(byLabel(store, 'boat').id);
    expect(grid(store)[(0, 0)]!.label, 'bus');
    expect(tray(store).single.tile.label, 'train');
  });

  test('updateTile changes content and never the cell', () async {
    final store = withGaps();
    final tile = grid(store)[(3, 3)]!;

    await store.updateTile(tile.id,
        label: 'upstairs', speech: 'go upstairs', colorKey: 'verb');

    final after = grid(store)[(3, 3)]!;
    expect(after.id, tile.id);
    expect(after.cellKey, tile.cellKey);
    expect(after.label, 'upstairs');
    expect(after.spokenText, 'go upstairs');
    expect(after.colorKey, 'verb');

    await store.updateTile(tile.id, speech: '');
    expect(grid(store)[(3, 3)]!.spokenText, 'upstairs');
    expect(grid(store)[(3, 3)]!.cellKey, tile.cellKey);
  });

  test('a partner cannot write', () async {
    final store = withGaps(role: CircleRole.partner);
    final before = store.tiles;
    final tile = grid(store)[(0, 0)]!;
    var notified = 0;
    store.addListener(() => notified++);

    await expectLater(
        store.addTile(
            boardId: store.homeBoardId, row: 5, col: 5, label: 'swing'),
        throwsStateError);
    await expectLater(
        store.placeTile(tile.id, row: 5, col: 5), throwsStateError);
    await expectLater(
        store.updateTile(tile.id, label: 'love'), throwsStateError);
    await expectLater(store.archiveTile(tile.id), throwsStateError);

    expect(store.tiles, before);
    expect(notified, 0);
  });

  group('remote changes', () {
    test('remoteAdd fills an empty cell and notifies', () {
      final store = withGaps();
      var notified = 0;
      store.addListener(() => notified++);

      store.remoteAdd(row: 5, col: 5, label: 'juice');

      expect(notified, 1);
      final tile = grid(store)[(5, 5)]!;
      expect(tile.label, 'juice');
      expect(tile.createdByName, 'Ms Lee');
      expect(tray(store), isEmpty);
    });

    test('remoteAdd into an occupied cell loses it', () {
      final store = withGaps();
      final holder = grid(store)[(0, 0)]!;

      store.remoteAdd(row: 0, col: 0, label: 'juice');

      expect(grid(store)[(0, 0)], holder);
      expect(tray(store).single.reason, TrayReason.contested);
    });

    test('remoteConflict adds the loser with the engine-suffixed key', () {
      final store = withGaps();
      final holder = grid(store)[(0, 0)]!;

      store.remoteConflict(row: 0, col: 0, label: 'bus');

      final loser = byLabel(store, 'bus');
      expect(loser.createdByName, 'Teacher');
      expect(loser.cellKey,
          '${placedKey(store.homeBoardId, 0, 0)}$conflictMarker${loser.id}');
      expect(
          CellKey.parse(loser.cellKey),
          isA<ContestedCell>()
              .having((c) => c.loserRowId, 'loserRowId', loser.id)
              .having((c) => c.wanted, 'wanted',
                  PlacedCell(store.homeBoardId, 0, 0)));
      expect(grid(store)[(0, 0)], holder);
      final entry = tray(store).single;
      expect(entry.tile, loser);
      expect(entry.reason, TrayReason.contested);
      expect(entry.wanted, PlacedCell(store.homeBoardId, 0, 0));
    });
  });

  test('FakeSpeech records what it was asked to say', () async {
    final speech = FakeSpeech();
    await speech.warmUp();
    await speech.speak('I want');
    await speech.speak('more');
    expect(speech.spoken, ['I want', 'more']);
    expect(speech.warmUps, 1);
    expect(speech.speaking.value, isFalse);
    expect(speech.offlineVoiceReady.value, isTrue);
  });

  test('FakeSyncStatus notifies on a state change and syncNow goes live',
      () async {
    final sync = FakeSyncStatus();
    final seen = <SyncState>[];
    sync.addListener(() => seen.add(sync.state));

    sync.state = SyncState.offline;
    sync.state = SyncState.offline;
    await sync.syncNow();

    expect(seen, [SyncState.offline, SyncState.live]);
    expect(sync.syncNowCalls, 1);
    expect(sync.lastMergeAt, isNotNull);

    sync.state = SyncState.accessLost;
    await sync.syncNow();
    expect(sync.state, SyncState.accessLost);
  });
}
