/// Plays recorded clips.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'media_hash.dart';
import 'scratch_none.dart' if (dart.library.io) 'scratch_io.dart';

/// Plays one short clip at a time.
abstract class ClipPlayer {
  /// Plays the clip at [path] when given, otherwise [bytes], interrupting
  /// any clip already playing. Completes with true when the clip finished
  /// or was interrupted, false when it could not be played at all; the
  /// caller then falls back to the device's voice. Never throws.
  Future<bool> play({String? path, Uint8List? bytes});

  /// Stops the clip. Safe when nothing is playing. Never throws.
  Future<void> stop();

  Future<void> dispose();
}

/// [ClipPlayer] on the platform's own media player.
///
/// The player is made on first use, so constructing this costs nothing and
/// works where there is no audio plugin (widget tests): every call is then
/// quiet and [play] reports false.
class DeviceClipPlayer implements ClipPlayer {
  AudioPlayer? _player;
  StreamSubscription<void>? _completions;

  /// The clip in flight, completed when it ends or is interrupted.
  Completer<void>? _playing;

  /// A clip is at most five seconds; a player that never reports the end
  /// must not leave the caller waiting.
  static const Duration _longestWait = Duration(seconds: 8);

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _completions = player.onPlayerComplete.listen((_) => _finish());
    return _player = player;
  }

  void _finish() {
    final playing = _playing;
    _playing = null;
    if (playing != null && !playing.isCompleted) playing.complete();
  }

  @override
  Future<bool> play({String? path, Uint8List? bytes}) async {
    try {
      final Source source;
      if (path != null && !kIsWeb) {
        source = DeviceFileSource(path);
      } else if (bytes != null && bytes.isNotEmpty) {
        final format = sniffFormat(bytes);
        if (kIsWeb) {
          // The browser plays bytes from a data link.
          source = BytesSource(bytes, mimeType: format.mimeType);
        } else {
          // Not every platform plays from memory, and some choose the
          // decoder by file extension: go through a scratch file.
          final scratch =
              await writeScratch('chorus_preview.${format.extension}', bytes);
          if (scratch == null) return false;
          source = DeviceFileSource(scratch, mimeType: format.mimeType);
        }
      } else {
        return false;
      }
      final player = _ensurePlayer();
      _finish();
      await player.stop();
      final playing = _playing = Completer<void>();
      await player.play(source);
      await playing.future.timeout(_longestWait, onTimeout: () {});
      return true;
    } catch (_) {
      _finish();
      return false;
    }
  }

  @override
  Future<void> stop() async {
    _finish();
    try {
      await _player?.stop();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    _finish();
    try {
      await _completions?.cancel();
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }
}
