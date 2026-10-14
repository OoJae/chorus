// Picture scenes over stand-in server calls: kept on this device and read
// back with no connection, asked for again when sync goes live, and every
// failure in words for the adult.
import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_flutter/src/scenes/server_scene_book.dart';
import 'package:chorus_ui/contracts.dart' show SyncState;
import 'package:chorus_ui/contracts_scenes.dart';
import 'package:chorus_ui/fakes.dart' show FakeSyncStatus;
import 'package:flutter_test/flutter_test.dart';

final String photo = 'd' * 64;

api.SceneInfo info(int id, String name, {List<api.SceneSpotInfo>? spots}) =>
    api.SceneInfo(
      id: id,
      name: name,
      imageHash: photo,
      createdAt: DateTime.utc(2026, 10, 14),
      spots: spots ?? [],
    );

api.SceneSpotInfo spot(String label) => api.SceneSpotInfo(
  x: 0.1,
  y: 0.2,
  width: 0.3,
  height: 0.4,
  label: label,
);

/// A server held in a list, which can be switched off.
class FakeServer {
  final List<api.SceneInfo> scenes = [];
  bool up = true;
  int lists = 0;
  int _next = 1;

  void _check() {
    if (!up) throw const api.ServerpodClientNetworkException('down');
  }

  SceneCalls get calls => SceneCalls(
    list: () async {
      lists++;
      _check();
      return [...scenes];
    },
    create: (name, hash) async {
      _check();
      final made = info(_next++, name);
      scenes.add(made);
      return made;
    },
    rename: (id, name) async {
      _check();
      final i = scenes.indexWhere((s) => s.id == id);
      return scenes[i] = scenes[i].copyWith(name: name);
    },
    archive: (id) async {
      _check();
      scenes.removeWhere((s) => s.id == id);
      return true;
    },
    setSpots: (id, spots) async {
      _check();
      final i = scenes.indexWhere((s) => s.id == id);
      return scenes[i] = scenes[i].copyWith(spots: spots);
    },
  );
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeServer server;
  late MemorySceneCache cache;
  late FakeSyncStatus sync;

  setUp(() {
    server = FakeServer();
    cache = MemorySceneCache();
    sync = FakeSyncStatus();
  });

  ServerSceneBook open({bool canEdit = true}) => ServerSceneBook(
    calls: server.calls,
    cache: cache,
    canEdit: canEdit,
    sync: sync,
  );

  test('scenes are read from the server, kept, and read back with no '
      'connection', () async {
    server.scenes.add(info(7, 'Park', spots: [spot('Grandma'), spot('dog')]));
    final book = open();
    await settle();
    expect(book.scenes.single.id, '7');
    expect(book.scenes.single.spots.map((s) => s.label), ['Grandma', 'dog']);
    expect(
      book.scenes.single.spots.first.rect,
      const SpotRect(0.1, 0.2, 0.3, 0.4),
    );
    book.dispose();

    server.up = false;
    final offline = open();
    await settle();
    expect(offline.scenes.single.name, 'Park');
    expect(offline.scenes.single.spots, hasLength(2));
    offline.dispose();
  });

  test('a change is made on the server and kept, and fails in plain words '
      'with no connection', () async {
    final book = open();
    await settle();
    final made = await book.create('Kitchen', photo);
    await book.setSpots(made.id, const [
      SceneSpot(rect: SpotRect(0.1, 0.1, 0.2, 0.2), label: 'cup'),
    ]);
    await book.rename(made.id, 'Our kitchen');
    expect(book.scenes.single.name, 'Our kitchen');
    expect(server.scenes.single.spots.single.label, 'cup');
    expect(decodeScenes(cache.text!).single.spots.single.label, 'cup');

    server.up = false;
    await expectLater(
      book.rename(made.id, 'Again'),
      throwsA(isA<ScenesFailed>()),
    );
    server.up = true;
    await book.archive(made.id);
    expect(book.scenes, isEmpty);
    book.dispose();
  });

  test(
    'a paused device asks nothing, and asks again when sync is live',
    () async {
      await sync.setWorkingOffline(true);
      final book = open();
      await settle();
      expect(server.lists, 0);
      await expectLater(
        book.create('Park', photo),
        throwsA(isA<ScenesFailed>()),
      );
      await sync.setWorkingOffline(false);
      await settle();
      expect(server.lists, 1);
      book.dispose();
    },
  );

  test('while live, a merge asks again, at most every 30 seconds', () async {
    var now = DateTime.utc(2026, 10, 14, 9);
    final book = ServerSceneBook(
      calls: server.calls,
      cache: cache,
      canEdit: true,
      sync: sync,
      now: () => now,
    );
    await settle();
    expect(server.lists, 1);
    sync.lastMergeAt = now;
    await settle();
    expect(server.lists, 1);
    now = now.add(const Duration(seconds: 31));
    server.scenes.add(info(4, 'Garden'));
    sync.lastMergeAt = now;
    await settle();
    expect(server.lists, 2);
    expect(book.scenes.single.name, 'Garden');
    book.dispose();
  });

  test('a read-only partner sees the scenes and changes none', () async {
    server.scenes.add(info(1, 'Park'));
    final book = open(canEdit: false);
    await settle();
    expect(book.scenes, hasLength(1));
    expect(() => book.create('Mine', photo), throwsStateError);
    book.dispose();
  });

  test('text that is not kept scenes reads as none', () {
    expect(decodeScenes('not json'), isEmpty);
    expect(decodeScenes('{}'), isEmpty);
    expect(SyncState.values, contains(SyncState.live));
  });
}
