/// The device's voices for a circle's second language.
library;

import 'package:chorus_ui/contracts_language.dart';

import '../speech/tts_speech_service.dart';

/// A [LanguageVoice] over the board's own [TtsSpeechService], so a word in
/// the second language never talks over a word in the first.
class TtsLanguageVoice implements LanguageVoice {
  TtsLanguageVoice(this._speech);

  final TtsSpeechService _speech;

  @override
  Future<bool> speakIn(String languageCode, String text) async {
    try {
      return await _speech.speakIn(languageCode, text);
    } catch (_) {
      return false;
    }
  }
}
