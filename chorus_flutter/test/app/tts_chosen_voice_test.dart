// The circle's chosen voice, speed and pitch reach the device's engine
// before the next word, and the spoken preview is quieter.
import 'dart:async';

import 'package:chorus_flutter/src/speech/tts_speech_service.dart';
import 'package:chorus_ui/contracts_voice.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tts_speech_service_test.dart' show FakeEngine;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FakeEngine engineFor(WidgetTester tester, {bool browser = true}) {
    final engine = FakeEngine(
      tester.binding.defaultBinaryMessenger,
      browser: browser,
    );
    addTearDown(engine.dispose);
    return engine;
  }

  testWidgets('in a browser the chosen voice, speed and pitch are used', (
    tester,
  ) async {
    final engine = engineFor(tester)
      ..voices = [
        {'name': 'Samantha', 'locale': 'en-US'},
        {'name': 'Daniel', 'locale': 'en-GB'},
      ];
    final speech = TtsSpeechService(web: true, onlineVoices: () => const {});
    await speech.warmUp();
    speech.useVoice(
      const VoicePrefs(voiceName: 'Daniel', rate: 1.2, pitch: 0.8),
    );
    unawaited(speech.speak('go'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(engine.calls, contains('setSpeechRate 1.2'));
    expect(engine.calls, contains('setPitch 0.8'));
    expect(engine.voice, 'Daniel');
    expect(engine.said, ['go']);
    engine.finish();
    await tester.pump();
  });

  testWidgets('on a phone the speed is half the share, the plugin\'s way', (
    tester,
  ) async {
    final engine = engineFor(tester, browser: false);
    final speech = TtsSpeechService(web: false);
    await speech.warmUp();
    speech.useVoice(const VoicePrefs(rate: 0.7));
    unawaited(speech.speak('go'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(engine.calls, contains('setSpeechRate 0.35'));
    engine.finish();
    await tester.pump();
  });

  testWidgets('a voice that needs the network is never set', (tester) async {
    final engine = engineFor(tester)
      ..voices = [
        {'name': 'Google US English', 'locale': 'en-US'},
        {'name': 'Samantha', 'locale': 'en-US'},
      ];
    final speech = TtsSpeechService(
      web: true,
      onlineVoices: () => const {'Google US English'},
    );
    await speech.warmUp();
    expect(await speech.deviceVoiceNames(), ['Samantha']);
    speech.useVoice(const VoicePrefs(voiceName: 'Google US English'));
    unawaited(speech.speak('go'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(engine.voice, isNot('Google US English'));
    engine.finish();
    await tester.pump();
  });

  testWidgets('after a word in the second language the chosen voice is back', (
    tester,
  ) async {
    final engine = engineFor(tester)
      ..voices = [
        {'name': 'Samantha', 'locale': 'en-US'},
        {'name': 'Daniel', 'locale': 'en-GB'},
        {'name': 'Monica', 'locale': 'es-ES'},
      ];
    final speech = TtsSpeechService(web: true, onlineVoices: () => const {});
    await speech.warmUp();
    speech.useVoice(
      const VoicePrefs(voiceName: 'Daniel', rate: 1.2, pitch: 0.8),
    );
    unawaited(speech.speak('go'));
    await tester.pump(const Duration(milliseconds: 100));
    engine.finish();
    await tester.pump(const Duration(milliseconds: 100));

    final spoken = speech.speakIn('es', 'agua');
    await tester.pump(const Duration(milliseconds: 100));
    engine.finish();
    await tester.pump(const Duration(milliseconds: 100));
    expect(await spoken, isTrue);

    engine.calls.clear();
    unawaited(speech.speak('want'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(engine.said, ['go', 'agua', 'want']);
    expect(engine.saidWith, ['Daniel', 'Monica', 'Daniel']);
    expect(engine.calls, contains('setSpeechRate 1.2'));
    expect(engine.calls, contains('setPitch 0.8'));
    engine.finish();
    await tester.pump();
  });

  testWidgets('the spoken preview is quieter, then the volume comes back', (
    tester,
  ) async {
    final engine = engineFor(tester);
    final speech = TtsSpeechService(web: true, onlineVoices: () => const {});
    await speech.warmUp();
    unawaited(speech.speakQuietly('want'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(engine.calls, contains('setVolume 0.4'));
    engine.finish();
    await tester.pump(const Duration(milliseconds: 100));
    expect(engine.calls.last, 'setVolume 1.0');
  });
}
