/// Family photos and recorded voices as the screens see them.
///
/// Kept apart from `contracts.dart` so every screen keeps working with no
/// media at all: a tile whose picture or clip is not on this device shows
/// its label and is spoken by the device's own voice.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Longest clip an adult can record for one word.
const Duration maxClipLength = Duration(seconds: 5);

/// Says one word: the family's own recording when this device has it,
/// otherwise the device's voice.
abstract class TileSpeaker {
  /// Plays the tile's recorded clip when cached, otherwise speaks its text.
  /// Never throws.
  Future<void> speakTile(TileFacts tile);
}

/// The pictures and clips of one circle on this device, named by the SHA-256
/// of their bytes (lowercase hex).
///
/// Notifies listeners when a file arrives in the local cache and when
/// [pendingUploads] changes.
abstract class MediaStore extends ChangeNotifier {
  /// Local file path or bytes for a hash if cached, else null (and starts
  /// fetching).
  ImageProvider? imageFor(String? hash);

  /// True when the clip for [hash] is on this device. When it is not, a
  /// fetch is started and listeners hear when it lands.
  bool hasAudio(String? hash);

  /// Shrinks and re-encodes a picked picture, keeps it on this device and
  /// queues it for upload. Completes with its hash. Works with no
  /// connection. Throws [FormatException] for bytes that are not a picture.
  Future<String> addImage(Uint8List bytes);

  /// Keeps a recorded clip on this device and queues it for upload.
  /// Completes with its hash. Works with no connection.
  Future<String> addAudio(Uint8List bytes);

  /// Files added on this device that the server does not hold yet.
  int get pendingUploads;
}

/// Sets or clears the picture and the recording of a tile.
///
/// Implemented by the same object as the `BoardStore` when it can write the
/// two hashes; the add and edit sheets save media only into a store that
/// does. Kept out of `BoardStore` so stores without media keep compiling.
abstract class TileMediaWriter {
  /// A null argument leaves that property alone; an empty string clears it.
  /// Never changes the tile's cell. Throws if the store refuses the write.
  Future<void> setTileMedia(
    String tileId, {
    String? imageHash,
    String? audioHash,
  });
}

/// Camera, photo library, microphone and clip playback, as the add-word
/// sheet needs them. Nothing here stores or sends anything: the sheet hands
/// the bytes to a [MediaStore] only when the adult saves the word.
abstract class MediaCapture {
  /// False where there is no camera to open (desktop); the sheet then
  /// offers only "choose a photo".
  bool get hasCamera;

  /// Lets the adult take ([fromCamera]) or choose a picture. Null when they
  /// backed out or the device refused.
  Future<Uint8List?> pickImage({required bool fromCamera});

  /// Starts recording from the microphone, asking for permission the first
  /// time. False when permission was refused or there is no microphone.
  Future<bool> startRecording();

  /// Stops and returns the clip, at most [maxClipLength] long. Null when
  /// nothing usable was recorded.
  Future<Uint8List?> stopRecording();

  /// Stops and throws the recording away.
  Future<void> cancelRecording();

  /// Plays a clip that has not been saved yet. Never throws.
  Future<void> playClip(Uint8List bytes);

  /// Stops [playClip]. Safe when nothing is playing.
  Future<void> stopClip();
}
