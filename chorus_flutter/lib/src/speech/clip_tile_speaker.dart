/// Says a word in the family's own voice when this device has the
/// recording, and in the device's voice when it does not.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_media.dart';

import '../media/cached_media_store.dart';
import '../media/clip_player.dart';

/// A [TileSpeaker] over a circle's cached clips and the existing
/// [SpeechService].
///
/// The clip is played only from the local files, so it works with no
/// connection; a clip that has not arrived, or will not play on this
/// device, is spoken from the tile's text instead. Either way the child
/// hears the word.
class ClipTileSpeaker implements TileSpeaker {
  ClipTileSpeaker({
    required this._speech,
    required this._clips,
    required this._player,
  });

  final SpeechService _speech;
  final ClipSource _clips;
  final ClipPlayer _player;

  /// Counts calls, so a clip that fails after a newer word was tapped does
  /// not talk over it.
  int _turn = 0;

  @override
  Future<void> speakTile(TileFacts tile) async {
    final mine = ++_turn;
    try {
      final hash = tile.audioHash;
      if (hash != null && _clips.hasAudio(hash)) {
        await _speech.stop();
        final path = _clips.clipPath(hash);
        final played = await _player.play(
          path: path,
          bytes: path == null ? await _clips.clipBytes(hash) : null,
        );
        if (played || mine != _turn) return;
      } else {
        await _player.stop();
      }
      await _speech.speak(tile.spokenText);
    } catch (_) {
      // Speech must never break the board.
    }
  }

  /// Stops a clip or an utterance in flight.
  Future<void> stop() async {
    _turn++;
    await _player.stop();
    try {
      await _speech.stop();
    } catch (_) {}
  }
}
