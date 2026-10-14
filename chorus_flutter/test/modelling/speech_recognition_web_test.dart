@TestOn('browser')
library;

import 'package:chorus_flutter/src/modelling/browser_speech_listener.dart';
import 'package:chorus_flutter/src/modelling/open_link.dart';
import 'package:flutter_test/flutter_test.dart';

/// Run with
/// `flutter test --platform chrome test/modelling/speech_recognition_web_test.dart`.
void main() {
  test('the browser says whether it can listen, and stopping is safe', () {
    final speech = browserSpeechListener();
    // Chrome has webkitSpeechRecognition; Firefox has none.
    expect(speech.available, isA<bool>());
    expect(speech.listening, isFalse);
    speech.stop();
    expect(speech.listening, isFalse);
    speech.dispose();
  });

  test('opening a link in a new tab is there to call', () {
    // Not called: a test must not open windows.
    expect(openInNewTab, isA<bool Function(String)>());
  });
}
