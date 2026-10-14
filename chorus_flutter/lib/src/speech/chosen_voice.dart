/// The circle's chosen voice, speed and pitch, handed to the device's
/// text-to-speech engine.
library;

import 'package:chorus_ui/contracts_voice.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Keeps the voice the circle chose and sets it on the engine before the
/// next word, once each time it changes.
class ChosenVoice {
  /// The volume of the spoken preview while scanning.
  static const double quietVolume = 0.4;

  VoicePrefs? _wanted;
  VoicePrefs? _applied;

  /// What the engine is asked for from the next word on.
  VoicePrefs? get wanted => _wanted;

  void use(VoicePrefs prefs) => _wanted = prefs;

  /// The engine's speed for [rate], a share of normal speech: the plugin's
  /// normal is 0.5 on phones and desktops and 1.0 in a browser.
  static double engineRate(double rate, {required bool web}) =>
      web ? rate : rate * 0.5;

  /// Sets what changed on [tts]. True when the voice went back to the
  /// device's own: the caller then chooses that again, as it did at first.
  Future<bool> applyIfChanged(
    FlutterTts tts, {
    required bool web,
    required Set<String> Function() online,
  }) async {
    final wanted = _wanted;
    if (wanted == null || wanted == _applied) return false;
    final before = _applied;
    _applied = wanted;
    try {
      await tts.setSpeechRate(engineRate(wanted.rate, web: web));
      await tts.setPitch(wanted.pitch);
      final name = wanted.voiceName;
      if (name != null) {
        final voice = await _find(tts, name, online());
        if (voice != null) await tts.setVoice(voice);
      } else if (before?.voiceName != null) {
        return true;
      }
    } catch (_) {
      // Speak with what the engine has.
    }
    return false;
  }

  Future<Map<String, String>?> _find(
    FlutterTts tts,
    String name,
    Set<String> online,
  ) async {
    final voices = await tts.getVoices;
    if (voices is! List) return null;
    for (final voice in voices) {
      if (voice is! Map) continue;
      if ('${voice['name'] ?? ''}' != name) continue;
      if (!_onDevice(voice, online)) return null;
      return {'name': name, 'locale': '${voice['locale'] ?? ''}'};
    }
    return null;
  }

  /// The names of the voices on this device for [language] (any variant of
  /// it) that need no network, sorted.
  Future<List<String>> deviceVoiceNames(
    FlutterTts tts, {
    required String language,
    required bool web,
    required Set<String> Function() online,
  }) async {
    try {
      final voices = await tts.getVoices;
      if (voices is! List) return const [];
      final base = language.toLowerCase().split('-').first;
      final away = online();
      final names = <String>{};
      for (final voice in voices) {
        if (voice is! Map) continue;
        final locale = '${voice['locale'] ?? ''}'.toLowerCase().replaceAll(
          '_',
          '-',
        );
        if (locale != base && !locale.startsWith('$base-')) continue;
        if (!_onDevice(voice, away)) continue;
        final name = '${voice['name'] ?? ''}';
        if (name.isNotEmpty) names.add(name);
      }
      return names.toList()..sort();
    } catch (_) {
      return const [];
    }
  }

  /// A voice that would send words to a speech service, or that is listed
  /// but not downloaded, is never used.
  static bool _onDevice(Map<Object?, Object?> voice, Set<String> online) {
    if (online.contains('${voice['name'] ?? ''}')) return false;
    if ('${voice['network_required'] ?? '0'}' == '1') return false;
    final features = '${voice['features'] ?? ''}'.split('\t');
    return !features.contains('notInstalled');
  }
}
