/// On-device speech through the platform's text-to-speech engine.
library;

import 'package:chorus_ui/contracts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Speaks with the device's own voice.
///
/// Nothing here throws: where there is no engine (some browsers, widget
/// tests) every call is quiet and [offlineVoiceReady] stays false.
class TtsSpeechService implements SpeechService {
  TtsSpeechService({this.language = 'en-US'});

  /// Language tag the voice is asked for.
  final String language;

  FlutterTts? _tts;
  Future<void>? _warming;

  /// Counts speak and stop calls, so a finished utterance only clears
  /// [speaking] when nothing newer has started.
  int _utterance = 0;

  final ValueNotifier<bool> _speaking = ValueNotifier(false);
  final ValueNotifier<bool> _offlineVoiceReady = ValueNotifier(false);

  @override
  ValueListenable<bool> get speaking => _speaking;

  @override
  ValueListenable<bool> get offlineVoiceReady => _offlineVoiceReady;

  @override
  Future<void> warmUp() => _warming ??= _warmUp();

  Future<void> _warmUp() async {
    try {
      final tts = FlutterTts();
      tts.setStartHandler(() => _speaking.value = true);
      tts.setCompletionHandler(() => _speaking.value = false);
      tts.setCancelHandler(() => _speaking.value = false);
      tts.setErrorHandler((_) => _speaking.value = false);
      await tts.awaitSpeakCompletion(true);
      await tts.setLanguage(language);
      // A little slower than normal speech. The plugin's "normal" is 0.5 on
      // phones and desktops and 1.0 in a browser.
      await tts.setSpeechRate(kIsWeb ? 0.9 : 0.45);
      _tts = tts;
      _offlineVoiceReady.value = await _hasOfflineVoice(tts);
    } catch (_) {
      // No engine. Let a later call try again.
      _tts = null;
      _warming = null;
      _offlineVoiceReady.value = false;
    }
  }

  /// True when a voice for [language] works without the network. Only
  /// Android reports this; anywhere else, and whenever the answer cannot be
  /// read, the engine that just accepted the language is trusted.
  Future<bool> _hasOfflineVoice(FlutterTts tts) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final voices = await tts.getVoices;
      if (voices is! List || voices.isEmpty) return true;
      final wanted = language.toLowerCase();
      final prefix = '${wanted.split('-').first}-';
      var sawFlag = false;
      for (final voice in voices) {
        if (voice is! Map) continue;
        final locale = '${voice['locale'] ?? ''}'.toLowerCase();
        if (locale != wanted && !locale.startsWith(prefix)) continue;
        final needsNetwork = voice['network_required'];
        if (needsNetwork == null) continue;
        sawFlag = true;
        if ('$needsNetwork' == '0') return true;
      }
      // Voices for the language exist and every one needs the network.
      return !sawFlag;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    final mine = ++_utterance;
    await warmUp();
    final tts = _tts;
    if (tts == null || mine != _utterance) return;
    try {
      await tts.stop();
      if (mine != _utterance) return;
      // Completes when the utterance ends, because of awaitSpeakCompletion.
      await tts.speak(text);
    } catch (_) {
      // Fall through to clear the flag.
    }
    // The handlers normally clear this; do it here too in case the engine
    // never called back.
    if (mine == _utterance) _speaking.value = false;
  }

  @override
  Future<void> stop() async {
    _utterance++;
    try {
      await _tts?.stop();
    } catch (_) {}
    _speaking.value = false;
  }
}
