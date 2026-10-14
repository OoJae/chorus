import 'package:chorus_shared/chorus_shared.dart'
    show
        SpotRect,
        maxSpotsPerScene,
        maxTileSpeechLength,
        sceneNameProblem,
        spotWordProblem,
        tidyText;
import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';
import '../media/media_files.dart' show isSha256Hex;

/// Most scenes one circle keeps in use.
const int maxScenesPerCircle = 50;

/// Picture scenes: a family photo with spots that speak when the child taps
/// them. Every member may list them; editing roles make and change them.
///
/// Each method throws [CircleException] with `notAMember` for someone
/// outside the circle, and with `notAllowed` for a read-only partner who
/// tries to change something, for a scene that is not one of the circle's
/// scenes in use, and for a name, photo or spot the rules refuse.
class SceneEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The circle's scenes in use, oldest first, each with its spots in the
  /// order they were drawn. Members only.
  Future<List<SceneInfo>> list(Session session, UuidValue circleSpace) async {
    await requireMember(session, circleSpace);
    final scenes = await Scene.db.find(
      session,
      where: (t) => t.circleSpace.equals(circleSpace) & t.archivedAt.equals(null),
      orderBy: (t) => t.id,
    );
    if (scenes.isEmpty) return [];
    final spots = await SceneSpot.db.find(
      session,
      where: (t) => t.sceneId.inSet({for (final s in scenes) s.id!}),
      orderBy: (t) => t.position,
    );
    return [
      for (final scene in scenes)
        _info(scene, spots.where((spot) => spot.sceneId == scene.id)),
    ];
  }

  /// Makes a scene called [name] from the photo with hash [imageHash], with
  /// no spots yet. Editing roles only.
  ///
  /// The photo may still be on its way from the adult's device: like a
  /// tile's picture, it is shown wherever it has arrived.
  Future<SceneInfo> create(
    Session session,
    UuidValue circleSpace,
    String name,
    String imageHash,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    if (sceneNameProblem(name) != null || !isSha256Hex(imageHash)) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    final inUse = await Scene.db.count(
      session,
      where: (t) => t.circleSpace.equals(circleSpace) & t.archivedAt.equals(null),
    );
    if (inUse >= maxScenesPerCircle) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    final scene = await Scene.db.insertRow(
      session,
      Scene(
        circleSpace: circleSpace,
        name: tidyText(name),
        imageHash: imageHash,
        createdBy: callerId(session),
        createdAt: DateTime.now().toUtc(),
      ),
    );
    return _info(scene, const []);
  }

  /// Renames the scene [sceneId]. Editing roles only.
  Future<SceneInfo> rename(
    Session session,
    UuidValue circleSpace,
    int sceneId,
    String name,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    if (sceneNameProblem(name) != null) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    final scene = await _inUse(session, circleSpace, sceneId);
    final renamed = await Scene.db.updateRow(
      session,
      scene.copyWith(name: tidyText(name)),
      columns: (t) => [t.name],
    );
    return _info(renamed, await _spotsOf(session, sceneId));
  }

  /// Archives the scene [sceneId]: it leaves every device's list. Nothing
  /// is deleted. Editing roles only. Returns false when it was already
  /// archived.
  Future<bool> archive(
    Session session,
    UuidValue circleSpace,
    int sceneId,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    final scene = await Scene.db.findFirstRow(
      session,
      where: (t) => t.id.equals(sceneId) & t.circleSpace.equals(circleSpace),
    );
    if (scene == null) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    if (scene.archivedAt != null) return false;
    await Scene.db.updateRow(
      session,
      scene.copyWith(archivedAt: DateTime.now().toUtc()),
      columns: (t) => [t.archivedAt],
    );
    return true;
  }

  /// Replaces every spot of the scene [sceneId] with [spots], in that
  /// order, all or nothing. Editing roles only.
  ///
  /// Each spot must lie on the photo with each side at least `minSpotSide`
  /// and carry a word the tile rules accept; at most [maxSpotsPerScene].
  Future<SceneInfo> setSpots(
    Session session,
    UuidValue circleSpace,
    int sceneId,
    List<SceneSpotInfo> spots,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    if (spots.length > maxSpotsPerScene) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    for (final spot in spots) {
      final rect = SpotRect(spot.x, spot.y, spot.width, spot.height);
      if (!rect.isValid ||
          spotWordProblem(spot.label, speech: spot.speech) != null) {
        throw CircleException(failure: CircleFailure.notAllowed);
      }
    }
    final scene = await _inUse(session, circleSpace, sceneId);
    final rows = [
      for (var i = 0; i < spots.length; i++)
        SceneSpot(
          sceneId: sceneId,
          x: spots[i].x,
          y: spots[i].y,
          width: spots[i].width,
          height: spots[i].height,
          label: tidyText(spots[i].label),
          speech: _speechOf(spots[i].speech),
          position: i,
        ),
    ];
    final kept = await session.db.transaction((tx) async {
      await SceneSpot.db.deleteWhere(
        session,
        where: (t) => t.sceneId.equals(sceneId),
        transaction: tx,
      );
      if (rows.isEmpty) return <SceneSpot>[];
      return SceneSpot.db.insert(session, rows, transaction: tx);
    });
    return _info(scene, kept);
  }

  /// The scene [sceneId] of [circleSpace], still in use.
  Future<Scene> _inUse(
    Session session,
    UuidValue circleSpace,
    int sceneId,
  ) async {
    final scene = await Scene.db.findFirstRow(
      session,
      where: (t) =>
          t.id.equals(sceneId) &
          t.circleSpace.equals(circleSpace) &
          t.archivedAt.equals(null),
    );
    if (scene == null) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    return scene;
  }

  Future<List<SceneSpot>> _spotsOf(Session session, int sceneId) =>
      SceneSpot.db.find(
        session,
        where: (t) => t.sceneId.equals(sceneId),
        orderBy: (t) => t.position,
      );

  static String? _speechOf(String? speech) {
    if (speech == null) return null;
    final tidy = tidyText(speech, maxLength: maxTileSpeechLength);
    return tidy.isEmpty ? null : tidy;
  }

  static SceneInfo _info(Scene scene, Iterable<SceneSpot> spots) {
    final ordered = spots.toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return SceneInfo(
      id: scene.id!,
      name: scene.name,
      imageHash: scene.imageHash,
      createdAt: scene.createdAt,
      spots: [
        for (final spot in ordered)
          SceneSpotInfo(
            x: spot.x,
            y: spot.y,
            width: spot.width,
            height: spot.height,
            label: spot.label,
            speech: spot.speech,
          ),
      ],
    );
  }
}
