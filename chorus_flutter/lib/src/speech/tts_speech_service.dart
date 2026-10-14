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
  TtsSpeechService({this.language = 'en-US', bool? web}) : _web = web ?? kIsWeb;

  /// Language tag the voice is asked for.
  final String language;

  /// True in a browser. The app leaves it to the build; tests pass it to
  /// walk the browser's path.
  final bool _web;

  /// One wait for the browser's engine to go quiet, and how many of them a
  /// word is held for at most (300 ms in all) when the engine never reports.
  static const Duration _turn = Duration(milliseconds: 10);
  static const int _quietTurns = 30;

  /// Everyday en-US voices by the start of the name browsers give them,
  /// best first. The ones that live on the machine come first, because the
  /// board has to speak with no network: macOS, then Windows, then the
  /// online voices of Chrome and Edge.
  static const List<String> _everydayVoices = [
    'Samantha',
    'Microsoft Zira',
    'Microsoft David',
    'Google US English',
    'Microsoft Aria',
    'Microsoft Jenny',
  ];

  FlutterTts? _tts;
  Future<void>? _warming;

  /// Counts speak and stop calls, so a finished utterance only clears
  /// [speaking] when nothing newer has started.
  int _utterance = 0;

  /// What the engine itself last reported: true from its start callback to
  /// its end, cancel or error callback. [stop] clears [speaking] at once
  /// but not this, so it still tells when a word that was cut off has not
  /// gone quiet yet.
  bool _engineSpeaking = false;

  /// True once a browser's voice has been chosen from a loaded list.
  bool _voiceChosen = false;

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
      tts.setStartHandler(() => _engineSaid(true));
      tts.setCompletionHandler(() => _engineSaid(false));
      tts.setCancelHandler(() => _engineSaid(false));
      tts.setErrorHandler((_) => _engineSaid(false));
      await tts.awaitSpeakCompletion(true);
      await tts.setLanguage(language);
      // A little slower than normal speech. The plugin's "normal" is 0.5 on
      // phones and desktops and 1.0 in a browser.
      await tts.setSpeechRate(_web ? 0.9 : 0.45);
      _tts = tts;
      _offlineVoiceReady.value = await _hasOfflineVoice(tts);
    } catch (_) {
      // No engine. Let a later call try again.
      _tts = null;
      _warming = null;
      _offlineVoiceReady.value = false;
    }
  }

  void _engineSaid(bool speaking) {
    _engineSpeaking = speaking;
    _speaking.value = speaking;
  }

  /// True when a voice for [language] works without the network. Only
  /// Android reports this; anywhere else, and whenever the answer cannot be
  /// read, the engine that just accepted the language is trusted.
  Future<bool> _hasOfflineVoice(FlutterTts tts) async {
    if (_web || defaultTargetPlatform != TargetPlatform.android) return true;
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
        // Listed but not downloaded yet: it cannot speak offline.
        final features = '${voice['features'] ?? ''}'.split('\t');
        if (features.contains('notInstalled')) continue;
        if ('$needsNetwork' == '0') return true;
      }
      // Voices for the language exist and none of them works offline.
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
      if (_web) {
        await _stopInBrowser(tts, mine);
      } else {
        await tts.stop();
      }
      if (mine != _utterance) return;
      if (_web && !_voiceChosen) {
        await _chooseVoice(tts);
        if (mine != _utterance) return;
      }
      // Completes when the utterance ends, because of awaitSpeakCompletion.
      await tts.speak(text);
    } catch (_) {
      // Fall through to clear the flag.
    }
    // The handlers normally clear this; do it here too in case the engine
    // never called back.
    if (mine == _utterance) _speaking.value = false;
  }

  /// Stops the word being said and waits until the engine says it has.
  ///
  /// In a browser a stop only asks: the engine goes quiet on a later turn,
  /// and it drops, without a sound, any word handed to it before then. So
  /// the next word waits, a turn at a time, for the engine's own report. A
  /// newer call ends the wait at once, and an engine that never reports
  /// ends it after [_quietTurns].
  ///
  /// When nothing is being said there is nothing to wait for, and the word
  /// goes out in the same turn as the tap. Some browsers only let a page's
  /// first word start there.
  Future<void> _stopInBrowser(FlutterTts tts, int mine) async {
    final wasSpeaking = _engineSpeaking;
    await tts.stop();
    if (!wasSpeaking) return;
    for (var turn = 0; turn < _quietTurns; turn++) {
      await Future<void>.delayed(_turn);
      if (!_engineSpeaking || mine != _utterance) return;
    }
  }

  /// Gives a browser an everyday voice for [language].
  ///
  /// Chrome and Edge load their voices a moment after the page first asks,
  /// so the language set while warming up finds none, and the browser then
  /// reads with the voice of its own language. This runs before a word
  /// until it has seen a loaded list. The voice is picked by name because
  /// the first voice a browser lists for a language can be a novelty one.
  Future<void> _chooseVoice(FlutterTts tts) async {
    try {
      final voices = await tts.getVoices;
      // Sets the language and the first voice listed for it. It comes
      // first because setting a voice does not set the language.
      await tts.setLanguage(language);
      if (voices is! List || voices.isEmpty) return;
      final voice = _everydayVoice(voices);
      if (voice != null) await tts.setVoice(voice);
      _voiceChosen = true;
    } catch (_) {
      // Speak with the voice the browser has.
    }
  }

  /// The first of [_everydayVoices] that [voices] has for [language], as
  /// the name and locale the browser listed.
  Map<String, String>? _everydayVoice(List<Object?> voices) {
    final wanted = language.toLowerCase();
    for (final everyday in _everydayVoices) {
      for (final voice in voices) {
        if (voice is! Map) continue;
        final locale = '${voice['locale'] ?? ''}';
        if (locale.toLowerCase() != wanted) continue;
        final name = '${voice['name'] ?? ''}';
        if (name.startsWith(everyday)) return {'name': name, 'locale': locale};
      }
    }
    return null;
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
