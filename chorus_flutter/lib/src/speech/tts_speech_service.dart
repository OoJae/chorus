/// On-device speech through the platform's text-to-speech engine.
library;

import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_device.dart' show QuietSpeech;
import 'package:chorus_ui/contracts_voice.dart' show VoicePrefs;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'chosen_voice.dart';
import 'online_voices.dart';

/// Speaks with the device's own voice.
///
/// Nothing here throws: where there is no engine (some browsers, widget
/// tests) every call is quiet and [offlineVoiceReady] stays false.
class TtsSpeechService implements SpeechService, QuietSpeech {
  TtsSpeechService({
    this.language = 'en-US',
    bool? web,
    Set<String> Function()? onlineVoices,
  }) : _web = web ?? kIsWeb,
       _onlineVoices = onlineVoices ?? onlineVoiceNames;

  /// Language tag the voice is asked for.
  final String language;

  /// True in a browser. The app leaves it to the build; tests pass it to
  /// walk the browser's path.
  final bool _web;

  /// The names of the browser's voices that are not on this device. The
  /// app reads the browser's own list (flutter_tts does not say); tests
  /// pass their own.
  final Set<String> Function() _onlineVoices;

  /// One wait for the browser's engine to go quiet, and how many of them a
  /// word is held for at most (300 ms in all) when the engine never reports.
  static const Duration _turn = Duration(milliseconds: 10);
  static const int _quietTurns = 30;

  /// Everyday en-US voices by the start of the name browsers give them,
  /// best first: macOS, then Windows, then names Chrome and Edge also give
  /// online voices. Only a voice on the device is ever chosen (see
  /// [_deviceVoice]).
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
      // The circle's chosen voice, once it is known or has changed.
      if (await _voice.applyIfChanged(tts, web: _web, online: _onlineVoices)) {
        // Back to the device's own voice, chosen as at first.
        if (_web) {
          _voiceChosen = false;
          await _chooseVoice(tts);
        } else {
          await tts.setLanguage(language);
        }
      }
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

  /// Gives a browser an everyday voice for [language] that is on the
  /// device.
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
      final voice = _deviceVoice(voices, _onlineVoices());
      if (voice != null) await tts.setVoice(voice);
      _voiceChosen = true;
    } catch (_) {
      // Speak with the voice the browser has.
    }
  }

  /// The voice to set from [voices], as the name and locale the browser
  /// listed, or null to keep the one the language took.
  ///
  /// A voice named in [online] is never chosen: it sends every word the
  /// child taps to a speech service, and is silent with no network. So
  /// this is the first of [_everydayVoices] on the device for [language];
  /// else, when the voice the language took (the first listed for it) is
  /// online, the first on the device for [language], then for any variant
  /// of it. With no voice of its own for the language, the browser speaks
  /// as it chooses.
  Map<String, String>? _deviceVoice(List<Object?> voices, Set<String> online) {
    final wanted = language.toLowerCase();
    final base = wanted.split('-').first;
    final listed = [
      for (final voice in voices)
        if (voice is Map)
          (name: '${voice['name'] ?? ''}', locale: '${voice['locale'] ?? ''}'),
    ];
    final onDevice = [
      for (final voice in listed)
        if (!online.contains(voice.name)) voice,
    ];
    Map<String, String> chosen(({String name, String locale}) voice) => {
      'name': voice.name,
      'locale': voice.locale,
    };

    for (final everyday in _everydayVoices) {
      for (final voice in onDevice) {
        if (voice.locale.toLowerCase() == wanted &&
            voice.name.startsWith(everyday)) {
          return chosen(voice);
        }
      }
    }
    // As flutter_tts matches it when the language is set.
    final taken = listed
        .where((voice) => voice.locale.toLowerCase().startsWith(wanted))
        .firstOrNull;
    if (taken == null || !online.contains(taken.name)) return null;
    for (final fits in <bool Function(String locale)>[
      (locale) => locale == wanted,
      (locale) => locale == base || locale.startsWith('$base-'),
    ]) {
      for (final voice in onDevice) {
        if (fits(voice.locale.toLowerCase())) return chosen(voice);
      }
    }
    return null;
  }

  /// The circle's chosen voice, speed and pitch (see [VoicePrefs]), used
  /// from the next word on.
  final ChosenVoice _voice = ChosenVoice();

  /// Speaks with [prefs] from the next word on.
  void useVoice(VoicePrefs prefs) => _voice.use(prefs);

  /// The voices on this device for [language] that need no network.
  Future<List<String>> deviceVoiceNames() async {
    await warmUp();
    final tts = _tts;
    if (tts == null) return const [];
    Future<List<String>> read() => _voice.deviceVoiceNames(
      tts,
      language: language,
      web: _web,
      online: _onlineVoices,
    );
    final names = await read();
    if (names.isNotEmpty || !_web) return names;
    // A browser lists its voices a moment after the page first asks.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return read();
  }

  /// Says [text] at a lower volume: the spoken preview while scanning.
  @override
  Future<void> speakQuietly(String text) async {
    await warmUp();
    final tts = _tts;
    try {
      await tts?.setVolume(ChosenVoice.quietVolume);
      await speak(text);
    } finally {
      try {
        await tts?.setVolume(1.0);
      } catch (_) {}
    }
  }

  @override
  Future<void> stop() async {
    _utterance++;
    try {
      await _tts?.stop();
    } catch (_) {}
    _speaking.value = false;
  }

  /// Speaks [text] with this device's voice for [languageTag] (a circle's
  /// second language, e.g. `yo` or `es`), then goes back to [language] for
  /// the next word. Completes with false, having said nothing, when the
  /// device has no voice of its own for that language. Never throws.
  Future<bool> speakIn(String languageTag, String text) async {
    if (text.trim().isEmpty) return true;
    final mine = ++_utterance;
    await warmUp();
    final tts = _tts;
    if (tts == null || mine != _utterance) return false;
    try {
      final voices = await tts.getVoices;
      final voice = voiceForLanguage(
        voices is List ? voices : const [],
        languageTag,
        _onlineVoices(),
      );
      if (voice == null) return false;
      if (_web) {
        await _stopInBrowser(tts, mine);
      } else {
        await tts.stop();
      }
      if (mine != _utterance) return true;
      await tts.setLanguage(voice['locale']!);
      await tts.setVoice(voice);
      // The next word in [language] chooses its own voice again.
      _voiceChosen = false;
      await tts.speak(text);
      return true;
    } catch (_) {
      return false;
    } finally {
      try {
        await tts.setLanguage(language);
      } catch (_) {}
      if (mine == _utterance) _speaking.value = false;
    }
  }

  /// The voice on this device for [languageTag] in [voices] (as the engine
  /// lists them), or null when there is none. A voice named in [online], or
  /// listed but not downloaded, is never chosen.
  @visibleForTesting
  static Map<String, String>? voiceForLanguage(
    List<Object?> voices,
    String languageTag,
    Set<String> online,
  ) {
    final wanted = languageTag.toLowerCase().replaceAll('_', '-');
    final base = wanted.split('-').first;
    final usable = [
      for (final voice in voices)
        if (voice is Map &&
            !online.contains('${voice['name'] ?? ''}') &&
            !'${voice['features'] ?? ''}'.split('\t').contains('notInstalled'))
          (
            name: '${voice['name'] ?? ''}',
            locale: '${voice['locale'] ?? ''}',
          ),
    ];
    for (final fits in <bool Function(String locale)>[
      (locale) => locale == wanted,
      (locale) => locale == base || locale.startsWith('$base-'),
    ]) {
      for (final voice in usable) {
        final locale = voice.locale.toLowerCase().replaceAll('_', '-');
        if (voice.name.isNotEmpty && fits(locale)) {
          return {'name': voice.name, 'locale': voice.locale};
        }
      }
    }
    return null;
  }
}
