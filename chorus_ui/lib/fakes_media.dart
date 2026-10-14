/// In-memory stand-ins for photos, recordings, the camera and the
/// microphone.
///
/// They let the media parts of every screen run and be tested with no
/// plugin, no file system and no server.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'contracts.dart';
import 'contracts_media.dart';
import 'fakes.dart';

/// A one-pixel PNG: the smallest picture the framework will decode.
final Uint8List tinyPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x38, 0x61, 0x63, 0xF3,
  0x1F, 0x00, 0x05, 0x50, 0x02, 0x40, 0xD4, 0x25, 0x43, 0x5E, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// A stand-in for a hash: 64 lowercase hex characters that depend on every
/// byte. Not SHA-256, and only ever compared with itself.
String fakeHashOf(List<int> bytes) {
  final out = StringBuffer();
  for (var lane = 0; lane < 8; lane++) {
    var h = 0x811C9DC5 ^ lane;
    for (final byte in bytes) {
      h = ((h ^ byte) * 0x01000193) & 0xFFFFFFFF;
    }
    out.write(h.toRadixString(16).padLeft(8, '0'));
  }
  return out.toString();
}

/// A [MediaStore] held in memory. Nothing is shrunk or sent: what is added
/// is kept as it is and counted as waiting until [finishUploads].
class FakeMediaStore extends MediaStore {
  final Map<String, Uint8List> _files = {};
  final Map<String, MemoryImage> _images = {};
  int _pending = 0;

  /// When true, [addImage] refuses its bytes as a real store refuses a file
  /// that is not a picture.
  bool refuseImages = false;

  /// Every hash asked for that this device does not hold, in order.
  final List<String> requested = [];

  /// The bytes held for [hash], or null.
  Uint8List? bytesOf(String hash) => _files[hash];

  @override
  ImageProvider? imageFor(String? hash) {
    if (hash == null) return null;
    final bytes = _files[hash];
    if (bytes == null) {
      if (!requested.contains(hash)) requested.add(hash);
      return null;
    }
    // One provider per hash, so the framework's image cache can reuse it.
    return _images[hash] ??= MemoryImage(bytes);
  }

  @override
  bool hasAudio(String? hash) {
    if (hash == null) return false;
    if (_files.containsKey(hash)) return true;
    if (!requested.contains(hash)) requested.add(hash);
    return false;
  }

  @override
  Future<String> addImage(Uint8List bytes) async {
    if (refuseImages) throw const FormatException('Not a picture');
    return _add(bytes);
  }

  @override
  Future<String> addAudio(Uint8List bytes) async => _add(bytes);

  String _add(Uint8List bytes) {
    final hash = fakeHashOf(bytes);
    if (_files.containsKey(hash)) return hash;
    _files[hash] = bytes;
    _pending++;
    notifyListeners();
    return hash;
  }

  @override
  int get pendingUploads => _pending;

  /// Simulates the queue reaching the server.
  void finishUploads() {
    if (_pending == 0) return;
    _pending = 0;
    notifyListeners();
  }

  /// Simulates a file made on another device arriving in the local cache.
  /// Completes with its hash.
  String arrive(Uint8List bytes) {
    final hash = fakeHashOf(bytes);
    _files[hash] = bytes;
    notifyListeners();
    return hash;
  }
}

/// A [MediaCapture] that hands back prepared bytes and records what it was
/// asked to do.
class FakeMediaCapture implements MediaCapture {
  FakeMediaCapture({
    this.hasCamera = true,
    Uint8List? photo,
    Uint8List? clip,
    this.microphoneAllowed = true,
  }) : photo = photo ?? tinyPng,
       clip = clip ?? Uint8List.fromList(const [1, 2, 3, 4, 5]);

  @override
  final bool hasCamera;

  /// What [pickImage] returns; null stands for the adult backing out.
  Uint8List? photo;

  /// What [stopRecording] returns; null stands for a clip too short to use.
  Uint8List? clip;

  bool microphoneAllowed;

  /// One entry per [pickImage] call: whether the camera was asked for.
  final List<bool> picks = [];

  /// Clips passed to [playClip], oldest first.
  final List<Uint8List> played = [];

  int starts = 0;
  int stops = 0;
  int cancels = 0;

  /// True between a successful [startRecording] and the stop or cancel.
  bool recording = false;

  @override
  Future<Uint8List?> pickImage({required bool fromCamera}) async {
    picks.add(fromCamera);
    return photo;
  }

  @override
  Future<bool> startRecording() async {
    starts++;
    if (!microphoneAllowed) return false;
    recording = true;
    return true;
  }

  @override
  Future<Uint8List?> stopRecording() async {
    stops++;
    if (!recording) return null;
    recording = false;
    return clip;
  }

  @override
  Future<void> cancelRecording() async {
    cancels++;
    recording = false;
  }

  @override
  Future<void> playClip(Uint8List bytes) async {
    played.add(bytes);
  }

  @override
  Future<void> stopClip() async {}
}

/// A [TileSpeaker] that records which tiles it was asked to say and how:
/// with the clip when [media] holds it, otherwise through [speech].
class FakeTileSpeaker implements TileSpeaker {
  FakeTileSpeaker({this.media, this.speech});

  final MediaStore? media;
  final SpeechService? speech;

  /// Ids of the tiles said with their recorded clip, oldest first.
  final List<String> playedClips = [];

  /// Every tile passed to [speakTile], oldest first.
  final List<TileFacts> said = [];

  @override
  Future<void> speakTile(TileFacts tile) async {
    said.add(tile);
    if (media?.hasAudio(tile.audioHash) ?? false) {
      playedClips.add(tile.id);
      return;
    }
    await speech?.speak(tile.spokenText);
  }
}

/// A [FakeBoardStore] that can also carry a picture and a recording per
/// tile.
class FakeMediaBoardStore extends FakeBoardStore implements TileMediaWriter {
  FakeMediaBoardStore.seeded({
    super.role,
    super.childName,
    super.myName,
    super.leaveEmpty,
  }) : super.seeded();

  /// Hashes set through [setTileMedia], by tile id. A null entry value means
  /// "cleared".
  final Map<String, String?> _imageOf = {};
  final Map<String, String?> _audioOf = {};

  @override
  List<TileFacts> get tiles => List.unmodifiable([
    for (final tile in super.tiles)
      if (_imageOf.containsKey(tile.id) || _audioOf.containsKey(tile.id))
        _withMedia(tile)
      else
        tile,
  ]);

  // Rebuilt by hand: copyWith cannot set a property back to null.
  TileFacts _withMedia(TileFacts tile) => TileFacts(
    id: tile.id,
    boardId: tile.boardId,
    cellKey: tile.cellKey,
    label: tile.label,
    speech: tile.speech,
    imageHash: _imageOf.containsKey(tile.id)
        ? _imageOf[tile.id]
        : tile.imageHash,
    audioHash: _audioOf.containsKey(tile.id)
        ? _audioOf[tile.id]
        : tile.audioHash,
    colorKey: tile.colorKey,
    archived: tile.archived,
    createdBy: tile.createdBy,
    createdByName: tile.createdByName,
    createdAt: tile.createdAt,
  );

  @override
  Future<void> setTileMedia(
    String tileId, {
    String? imageHash,
    String? audioHash,
  }) async {
    if (!role.canEdit) {
      throw StateError('A partner can view this board but not change it.');
    }
    if (!super.tiles.any((tile) => tile.id == tileId)) {
      throw ArgumentError.value(tileId, 'tileId', 'No such tile');
    }
    if (imageHash != null) {
      _imageOf[tileId] = imageHash.isEmpty ? null : imageHash;
    }
    if (audioHash != null) {
      _audioOf[tileId] = audioHash.isEmpty ? null : audioHash;
    }
    notifyListeners();
  }
}
