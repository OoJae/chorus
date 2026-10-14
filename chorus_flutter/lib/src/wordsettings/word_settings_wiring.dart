/// Hidden words and the second language of one circle, made for the app's
/// `CircleFeatures` (engineer W5).
library;

import 'package:chorus_client/chorus_client.dart' hide CircleRole;
import 'package:chorus_ui/contracts.dart' show CircleRole, SpeechService;
import 'package:chorus_ui/contracts.dart' as ui show SyncStatus;
import 'package:chorus_ui/contracts_hidden.dart';
import 'package:chorus_ui/contracts_language.dart';
import 'package:chorus_ui/features/flags/w5.dart';

import '../speech/tts_speech_service.dart';
import 'server_word_settings.dart';
import 'tts_language_voice.dart';

/// What [openWordSettings] made. Holds timers and a listener on sync, so
/// the owner calls [dispose] once when the circle closes.
class WordSettings {
  WordSettings._(this._hidden, this._languages);

  final ServerHiddenWords? _hidden;
  final ServerHomeLanguages? _languages;

  /// Words hidden for now. Null when the feature is off.
  HiddenWords? get hiddenWords => _hidden;

  /// The circle's second language. Null when the feature is off.
  HomeLanguages? get languages => _languages;

  bool _disposed = false;

  /// Stops both. Safe to call twice.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _hidden?.dispose();
    _languages?.dispose();
  }
}

/// Hidden words and the second language of [circleSpace] for the adult
/// signed in as [userId] in [role], kept on this device. Null when both
/// features are off.
WordSettings? openWordSettings(
  Client client, {
  required UuidValue circleSpace,
  required String userId,
  required CircleRole role,
  ui.SyncStatus? sync,
}) {
  if (!hideWordsEnabled && !homeLanguageEnabled) return null;
  return WordSettings._(
    hideWordsEnabled
        ? ServerHiddenWords.forClient(
            client,
            circleSpace: circleSpace,
            userId: userId,
            role: role,
            sync: sync,
          )
        : null,
    homeLanguageEnabled
        ? ServerHomeLanguages.forClient(
            client,
            circleSpace: circleSpace,
            userId: userId,
            role: role,
            sync: sync,
          )
        : null,
  );
}

/// The device's voices for a second language, over [speech] when it is the
/// app's own; null otherwise (a word in it then plays its recording, else
/// is said in the first language).
LanguageVoice? languageVoiceFor(SpeechService speech) =>
    homeLanguageEnabled && speech is TtsSpeechService
    ? TtsLanguageVoice(speech)
    : null;
