/// Picture scenes as the screens see them: a family photo with spots that
/// speak when the child taps them.
///
/// Kept apart from `contracts.dart` so every screen works without it: the
/// "Scenes" entries appear only when a [SceneBook] is given.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';

export 'package:chorus_shared/chorus_shared.dart'
    show
        SpotRect,
        fitPhoto,
        maxSceneNameLength,
        maxSpotsPerScene,
        minSpotSide,
        sceneNameProblem,
        spotAt,
        spotWordProblem;

/// One spot of a scene: where it is on the photo and the word it says.
@immutable
class SceneSpot {
  const SceneSpot({required this.rect, required this.label, this.speech});

  /// Where the spot is, in fractions of the photo.
  final SpotRect rect;
  final String label;

  /// What is spoken; the label when null or empty.
  final String? speech;

  String get spokenText =>
      (speech == null || speech!.trim().isEmpty) ? label : speech!;

  SceneSpot copyWith({SpotRect? rect, String? label, String? speech}) =>
      SceneSpot(
        rect: rect ?? this.rect,
        label: label ?? this.label,
        speech: speech ?? this.speech,
      );

  @override
  bool operator ==(Object other) =>
      other is SceneSpot &&
      other.rect == rect &&
      other.label == label &&
      other.speech == speech;

  @override
  int get hashCode => Object.hash(rect, label, speech);

  @override
  String toString() => 'SceneSpot("$label", $rect)';
}

/// A scene: a named photo and its spots, in the order they were drawn.
@immutable
class Scene {
  const Scene({
    required this.id,
    required this.name,
    required this.imageHash,
    this.spots = const [],
  });

  final String id;
  final String name;

  /// SHA-256 of the photo, as a tile's picture is named.
  final String imageHash;
  final List<SceneSpot> spots;

  Scene copyWith({String? name, List<SceneSpot>? spots}) => Scene(
    id: id,
    name: name ?? this.name,
    imageHash: imageHash,
    spots: spots ?? this.spots,
  );

  @override
  bool operator ==(Object other) =>
      other is Scene &&
      other.id == id &&
      other.name == name &&
      other.imageHash == imageHash &&
      listEquals(other.spots, spots);

  @override
  int get hashCode => Object.hash(id, name, imageHash, Object.hashAll(spots));

  @override
  String toString() => 'Scene($id, "$name", ${spots.length} spots)';
}

/// Thrown when a scene could not be made or changed, for example with no
/// connection. [message] is written for the adult.
class ScenesFailed implements Exception {
  const ScenesFailed(this.message);

  final String message;

  @override
  String toString() => 'ScenesFailed: $message';
}

/// Shown when a change to a scene could not be saved.
const String sceneNotSavedMessage =
    'That was not saved. Scenes are changed online: check the connection and '
    'try again.';

/// The circle's scenes on this device.
///
/// [scenes] is what this device last heard, kept so the child's scenes work
/// with no connection. Listeners hear every change.
abstract class SceneBook extends ChangeNotifier {
  /// The scenes in use, oldest first.
  List<Scene> get scenes;

  /// Whether this adult may make and change scenes. False for a read-only
  /// partner, whose device still shows them.
  bool get canEdit;

  /// Asks for the latest scenes. Never throws: with no connection the kept
  /// ones stay.
  Future<void> refresh();

  /// Makes a scene called [name] from a photo already added to the circle's
  /// media with hash [imageHash]. Throws [ScenesFailed].
  Future<Scene> create(String name, String imageHash);

  /// Throws [ScenesFailed].
  Future<Scene> rename(String sceneId, String name);

  /// Takes the scene out of use everywhere. Throws [ScenesFailed].
  Future<void> archive(String sceneId);

  /// Replaces the scene's spots with [spots]. Throws [ScenesFailed].
  Future<Scene> setSpots(String sceneId, List<SceneSpot> spots);
}
