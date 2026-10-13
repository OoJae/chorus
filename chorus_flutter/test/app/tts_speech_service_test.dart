import 'package:chorus_flutter/src/speech/tts_speech_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('with no speech engine every call is quiet', () async {
    final speech = TtsSpeechService();

    await speech.warmUp();
    await speech.speak('more');
    await speech.stop();
    // A second warm-up is allowed and tries again.
    await speech.warmUp();

    expect(speech.speaking.value, isFalse);
    expect(speech.offlineVoiceReady.value, isFalse);
  });
}
