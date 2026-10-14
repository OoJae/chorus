/// The voice the child speaks with: chosen by an adult for the whole
/// circle, the same on every device and on the view-only page.
library;

import 'package:flutter/foundation.dart';

/// A voice, its speed and its pitch.
@immutable
class VoicePrefs {
  const VoicePrefs({
    this.voiceName,
    this.rate = defaultRate,
    this.pitch = defaultPitch,
  });

  /// The name the device lists the voice under; null is the device's own
  /// everyday voice. A device without this voice uses its own.
  final String? voiceName;

  /// Speed as a share of normal speech.
  final double rate;

  /// 1 is the voice's own pitch.
  final double pitch;

  /// A little slower than normal speech, as Chorus has always spoken.
  static const double defaultRate = 0.9;
  static const double defaultPitch = 1.0;

  /// The speeds offered, slowest first.
  static const List<double> rates = [0.7, 0.9, 1.0, 1.2];

  /// The pitches offered, lowest first.
  static const List<double> pitches = [0.8, 1.0, 1.25];

  VoicePrefs copyWith({
    String? Function()? voiceName,
    double? rate,
    double? pitch,
  }) => VoicePrefs(
    voiceName: voiceName == null ? this.voiceName : voiceName(),
    rate: rate ?? this.rate,
    pitch: pitch ?? this.pitch,
  );

  Map<String, Object?> toJson() => {
    'voice': voiceName,
    'rate': rate,
    'pitch': pitch,
  };

  /// Reads what [toJson] wrote; anything unreadable is the default.
  factory VoicePrefs.fromJson(Object? json) {
    if (json is! Map) return const VoicePrefs();
    double number(Object? value, double fallback) =>
        value is num && value.isFinite && value >= 0.5 && value <= 2
        ? value.toDouble()
        : fallback;
    final name = json['voice'];
    return VoicePrefs(
      voiceName: name is String && name.isNotEmpty ? name : null,
      rate: number(json['rate'], defaultRate),
      pitch: number(json['pitch'], defaultPitch),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VoicePrefs &&
      other.voiceName == voiceName &&
      other.rate == rate &&
      other.pitch == pitch;

  @override
  int get hashCode => Object.hash(voiceName, rate, pitch);
}

/// The circle's voice on this device: kept here so it works offline, sent
/// to the circle when an editor changes it. Notifies after every change.
abstract class VoiceChoice extends ChangeNotifier {
  VoicePrefs get prefs;

  /// False for a read-only partner, who hears the voice but cannot change
  /// it.
  bool get canChange;

  /// The voices on this device for the board's language. Voices that would
  /// send words to a speech service are never listed.
  Future<List<String>> voiceNames();

  /// Uses [prefs] on this device at once and sends it to the circle. Throws
  /// only when the circle refused it.
  Future<void> choose(VoicePrefs prefs);

  /// Says [text] in the chosen voice.
  Future<void> tryIt(String text);

  /// Reads the circle's latest choice, where it can. Never throws.
  Future<void> refresh() async {}
}
