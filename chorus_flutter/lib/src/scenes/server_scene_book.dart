/// Picture scenes over the server's `scene` endpoint, kept on this device
/// so the child's scenes work with no connection.
library;

import 'dart:async';
import 'dart:convert';

import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_ui/contracts.dart' show SyncState, SyncStatus;
import 'package:chorus_ui/contracts_scenes.dart';
import 'package:flutter/foundation.dart';

import '../media/media_files.dart';

/// Where the scenes of one circle are kept on this device: a small text
/// under a name, as the media files keep their notes.
abstract class SceneCache {
  Future<String?> read();
  Future<void> write(String text);
}

/// A [SceneCache] in the media files' notes of this device, under [name]
/// (one per adult and circle).
class NoteSceneCache implements SceneCache {
  NoteSceneCache(this._files, this.name);

  final Future<MediaFiles> _files;
  final String name;

  @override
  Future<String?> read() async => (await _files).readNote(name);

  @override
  Future<void> write(String text) async => (await _files).writeNote(name, text);
}

/// A [SceneCache] held in memory, for tests.
class MemorySceneCache implements SceneCache {
  String? text;

  @override
  Future<String?> read() async => text;

  @override
  Future<void> write(String value) async => text = value;
}

/// The calls a [ServerSceneBook] makes, so tests can stand in for them.
class SceneCalls {
  const SceneCalls({
    required this.list,
    required this.create,
    required this.rename,
    required this.archive,
    required this.setSpots,
  });

  /// The calls of [client] for [circleSpace].
  factory SceneCalls.forClient(api.Client client, api.UuidValue circleSpace) =>
      SceneCalls(
        list: () => client.scene.list(circleSpace),
        create: (name, hash) => client.scene.create(circleSpace, name, hash),
        rename: (id, name) => client.scene.rename(circleSpace, id, name),
        archive: (id) => client.scene.archive(circleSpace, id),
        setSpots: (id, spots) => client.scene.setSpots(circleSpace, id, spots),
      );

  final Future<List<api.SceneInfo>> Function() list;
  final Future<api.SceneInfo> Function(String name, String imageHash) create;
  final Future<api.SceneInfo> Function(int id, String name) rename;
  final Future<bool> Function(int id) archive;
  final Future<api.SceneInfo> Function(int id, List<api.SceneSpotInfo> spots)
  setSpots;
}

/// The circle's scenes: what the server last said, kept in [SceneCache] and
/// read from it first, so they show with no connection. Asks again each
/// time sync goes live.
class ServerSceneBook extends SceneBook {
  ServerSceneBook({
    required this._calls,
    required this._cache,
    required this.canEdit,
    this._sync,
    this.timeout = const Duration(seconds: 20),
    this.askEvery = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _sync?.addListener(_onSync);
    _wasLive = _live;
    unawaited(_start());
  }

  final SceneCalls _calls;
  final SceneCache _cache;
  final SyncStatus? _sync;
  final Duration timeout;

  /// While sync is live, each merge asks for the scenes again, at most this
  /// often: another adult's new scene then reaches the child's board soon
  /// after any change to the boards.
  final Duration askEvery;
  final DateTime Function() _now;
  DateTime? _askedAt;

  @override
  final bool canEdit;

  List<Scene> _scenes = const [];
  bool _disposed = false;
  bool _wasLive = false;

  @override
  List<Scene> get scenes => _scenes;

  bool get _live =>
      _sync == null || (_sync.state == SyncState.live && !_sync.workingOffline);

  Future<void> _start() async {
    try {
      final kept = await _cache.read();
      if (kept != null && _scenes.isEmpty && !_disposed) {
        _set(decodeScenes(kept), keep: false);
      }
    } catch (_) {
      // A cache that cannot be read is an empty one.
    }
    await refresh();
  }

  void _onSync() {
    final live = _live;
    final asked = _askedAt;
    final due = asked == null || _now().difference(asked) >= askEvery;
    if (live && (!_wasLive || due)) unawaited(refresh());
    _wasLive = live;
  }

  void _set(List<Scene> scenes, {bool keep = true}) {
    if (_disposed) return;
    if (listEquals(scenes, _scenes)) return;
    _scenes = List.unmodifiable(scenes);
    notifyListeners();
    if (keep) {
      unawaited(
        _cache.write(encodeScenes(_scenes)).catchError((Object _) {}),
      );
    }
  }

  @override
  Future<void> refresh() async {
    if (_disposed || !_live) return;
    _askedAt = _now();
    try {
      final listed = await _calls.list().timeout(timeout);
      _set([for (final info in listed) sceneOf(info)]);
    } catch (_) {
      // Offline or refused: the kept scenes stay.
    }
  }

  Future<T> _call<T>(Future<T> Function() call) async {
    if (!canEdit) {
      throw StateError('A read-only partner changes no scene.');
    }
    if (!_live) throw const ScenesFailed(sceneNotSavedMessage);
    try {
      return await call().timeout(timeout);
    } catch (_) {
      throw const ScenesFailed(sceneNotSavedMessage);
    }
  }

  void _replace(Scene scene) => _set([
    for (final held in _scenes) held.id == scene.id ? scene : held,
    if (!_scenes.any((held) => held.id == scene.id)) scene,
  ]);

  static int _idOf(String sceneId) =>
      int.tryParse(sceneId) ?? (throw const ScenesFailed(sceneNotSavedMessage));

  @override
  Future<Scene> create(String name, String imageHash) async {
    final scene = sceneOf(await _call(() => _calls.create(name, imageHash)));
    _replace(scene);
    return scene;
  }

  @override
  Future<Scene> rename(String sceneId, String name) async {
    final id = _idOf(sceneId);
    final scene = sceneOf(await _call(() => _calls.rename(id, name)));
    _replace(scene);
    return scene;
  }

  @override
  Future<void> archive(String sceneId) async {
    final id = _idOf(sceneId);
    await _call(() => _calls.archive(id));
    _set([
      for (final scene in _scenes)
        if (scene.id != sceneId) scene,
    ]);
  }

  @override
  Future<Scene> setSpots(String sceneId, List<SceneSpot> spots) async {
    final id = _idOf(sceneId);
    final scene = sceneOf(
      await _call(
        () => _calls.setSpots(id, [
          for (final spot in spots)
            api.SceneSpotInfo(
              x: spot.rect.x,
              y: spot.rect.y,
              width: spot.rect.width,
              height: spot.rect.height,
              label: spot.label,
              speech: spot.speech,
            ),
        ]),
      ),
    );
    _replace(scene);
    return scene;
  }

  @override
  void dispose() {
    _disposed = true;
    _sync?.removeListener(_onSync);
    super.dispose();
  }
}

/// [info] as the screens see it.
Scene sceneOf(api.SceneInfo info) => Scene(
  id: '${info.id}',
  name: info.name,
  imageHash: info.imageHash,
  spots: [
    for (final spot in info.spots)
      SceneSpot(
        rect: SpotRect(spot.x, spot.y, spot.width, spot.height),
        label: spot.label,
        speech: spot.speech,
      ),
  ],
);

/// [scenes] as the text kept on this device.
String encodeScenes(List<Scene> scenes) => jsonEncode([
  for (final scene in scenes)
    {
      'id': scene.id,
      'name': scene.name,
      'imageHash': scene.imageHash,
      'spots': [
        for (final spot in scene.spots)
          {
            'x': spot.rect.x,
            'y': spot.rect.y,
            'w': spot.rect.width,
            'h': spot.rect.height,
            'label': spot.label,
            'speech': ?spot.speech,
          },
      ],
    },
]);

/// The scenes in [text] as [encodeScenes] wrote them; empty for anything
/// else.
List<Scene> decodeScenes(String text) {
  try {
    final list = jsonDecode(text);
    if (list is! List) return const [];
    double number(Object? value) => value is num ? value.toDouble() : 0;
    return [
      for (final item in list.whereType<Map<String, Object?>>())
        Scene(
          id: '${item['id']}',
          name: '${item['name']}',
          imageHash: '${item['imageHash']}',
          spots: [
            for (final spot
                in (item['spots'] as List? ?? const [])
                    .whereType<Map<String, Object?>>())
              SceneSpot(
                rect: SpotRect(
                  number(spot['x']),
                  number(spot['y']),
                  number(spot['w']),
                  number(spot['h']),
                ),
                label: '${spot['label']}',
                speech: spot['speech'] as String?,
              ),
          ],
        ),
    ];
  } catch (_) {
    return const [];
  }
}
