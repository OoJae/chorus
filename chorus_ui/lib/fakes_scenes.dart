/// An in-memory stand-in for picture scenes.
///
/// It keeps the contract's rules: only an editor changes anything, the
/// names and spots the shared rules refuse are refused, and while
/// [FakeSceneBook.online] is off every change fails as the real one
/// would.
library;

import 'package:chorus_shared/chorus_shared.dart';

import 'contracts.dart';
import 'contracts_scenes.dart';

/// A [SceneBook] held in memory.
class FakeSceneBook extends SceneBook {
  FakeSceneBook({
    List<Scene> scenes = const [],
    this.role = CircleRole.guardian,
    this.online = true,
  }) : _scenes = [...scenes];

  List<Scene> _scenes;
  int _sequence = 0;

  CircleRole role;

  /// Stands in for the connection: while off, every change fails and
  /// [refresh] keeps what is held.
  bool online;

  /// How many times [refresh] was called.
  int refreshes = 0;

  @override
  List<Scene> get scenes => List.unmodifiable(_scenes);

  @override
  bool get canEdit => role.canEdit;

  void _check() {
    if (!canEdit) throw StateError('A read-only partner changes no scene.');
    if (!online) throw const ScenesFailed(sceneNotSavedMessage);
  }

  @override
  Future<void> refresh() async {
    refreshes++;
  }

  @override
  Future<Scene> create(String name, String imageHash) async {
    _check();
    if (sceneNameProblem(name) != null) {
      throw ArgumentError.value(name, 'name', sceneNameProblem(name));
    }
    final scene = Scene(
      id: 'scene-${++_sequence}',
      name: tidyText(name),
      imageHash: imageHash,
    );
    _scenes = [..._scenes, scene];
    notifyListeners();
    return scene;
  }

  Scene _find(String id) => _scenes.firstWhere(
    (scene) => scene.id == id,
    orElse: () => throw const ScenesFailed(sceneNotSavedMessage),
  );

  void _replace(Scene scene) {
    _scenes = [
      for (final held in _scenes) held.id == scene.id ? scene : held,
    ];
    notifyListeners();
  }

  @override
  Future<Scene> rename(String sceneId, String name) async {
    _check();
    final scene = _find(sceneId).copyWith(name: tidyText(name));
    _replace(scene);
    return scene;
  }

  @override
  Future<void> archive(String sceneId) async {
    _check();
    _find(sceneId);
    _scenes = [
      for (final scene in _scenes)
        if (scene.id != sceneId) scene,
    ];
    notifyListeners();
  }

  @override
  Future<Scene> setSpots(String sceneId, List<SceneSpot> spots) async {
    _check();
    if (spots.length > maxSpotsPerScene ||
        spots.any(
          (spot) =>
              !spot.rect.isValid ||
              spotWordProblem(spot.label, speech: spot.speech) != null,
        )) {
      throw ArgumentError.value(spots, 'spots', 'A spot the rules refuse');
    }
    final scene = _find(sceneId).copyWith(spots: List.unmodifiable(spots));
    _replace(scene);
    return scene;
  }
}
