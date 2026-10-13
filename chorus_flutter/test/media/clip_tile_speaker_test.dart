import 'dart:typed_data';

import 'package:chorus_flutter/src/media/cached_media_store.dart';
import 'package:chorus_flutter/src/media/clip_player.dart';
import 'package:chorus_flutter/src/speech/clip_tile_speaker.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeClips implements ClipSource {
  final Map<String, Uint8List> held = {};

  /// When set, clips are reported as files at this path.
  String? path;

  @override
  bool hasAudio(String? hash) => hash != null && held.containsKey(hash);

  @override
  String? clipPath(String hash) => held.containsKey(hash) ? path : null;

  @override
  Future<Uint8List?> clipBytes(String hash) async => held[hash];
}

class FakePlayer implements ClipPlayer {
  /// What the device makes of a clip: played, cannot play, or throws.
  bool canPlay = true;
  bool throws = false;

  /// One entry per [play]: the path, or the bytes when there was none.
  final List<Object?> played = [];
  int stops = 0;

  @override
  Future<bool> play({String? path, Uint8List? bytes}) async {
    played.add(path ?? bytes);
    if (throws) throw StateError('no audio device');
    return canPlay;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {}
}

class ThrowingSpeech extends FakeSpeech {
  @override
  Future<void> speak(String text) => throw StateError('no engine');
}

TileFacts _tile({String? audioHash, String? speech}) => TileFacts(
      id: 't1',
      boardId: 'b1',
      cellKey: placedKey('b1', 0, 0),
      label: 'Grandma',
      speech: speech,
      audioHash: audioHash,
    );

void main() {
  late FakeClips clips;
  late FakePlayer player;
  late FakeSpeech speech;
  late ClipTileSpeaker speaker;
  final clip = Uint8List.fromList(const [1, 2, 3]);

  setUp(() {
    clips = FakeClips();
    player = FakePlayer();
    speech = FakeSpeech();
    speaker = ClipTileSpeaker(speech: speech, clips: clips, player: player);
  });

  test('a tile with no recording is spoken by the device voice', () async {
    await speaker.speakTile(_tile());

    expect(speech.spoken, ['Grandma']);
    expect(player.played, isEmpty);
  });

  test('the spoken text is used when it differs from the label', () async {
    await speaker.speakTile(_tile(speech: 'my grandmother'));

    expect(speech.spoken, ['my grandmother']);
  });

  test('a cached recording is played and the device voice stays quiet',
      () async {
    clips.held['h'] = clip;

    await speaker.speakTile(_tile(audioHash: 'h'));

    expect(player.played, [clip]);
    expect(speech.spoken, isEmpty);
  });

  test('where files have paths the clip is played from its file', () async {
    clips.held['h'] = clip;
    clips.path = '/media/h.m4a';

    await speaker.speakTile(_tile(audioHash: 'h'));

    expect(player.played, ['/media/h.m4a']);
  });

  test('a recording that has not arrived falls back to the device voice',
      () async {
    await speaker.speakTile(_tile(audioHash: 'not-here-yet'));

    expect(player.played, isEmpty);
    expect(speech.spoken, ['Grandma']);
  });

  test('a recording this device cannot play falls back to the device voice',
      () async {
    clips.held['h'] = clip;
    player.canPlay = false;

    await speaker.speakTile(_tile(audioHash: 'h'));

    expect(player.played, [clip]);
    expect(speech.spoken, ['Grandma']);
  });

  test('a new word interrupts a clip that is playing', () async {
    await speaker.speakTile(_tile());

    expect(player.stops, 1);
  });

  test('never throws, whatever the player or the engine does', () async {
    clips.held['h'] = clip;
    player.throws = true;
    await speaker.speakTile(_tile(audioHash: 'h'));

    final broken = ClipTileSpeaker(
        speech: ThrowingSpeech(), clips: clips, player: FakePlayer());
    await broken.speakTile(_tile());
    await broken.stop();
  });

  test('the real player is quiet where there is no audio plugin', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final real = DeviceClipPlayer();

    expect(await real.play(bytes: Uint8List(0)), isFalse);
    expect(await real.play(), isFalse);
    await real.stop();
    await real.dispose();
  });
}
