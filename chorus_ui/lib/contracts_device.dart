/// Settings that belong to this device, not to the circle: how the child's
/// board answers a touch, switch scanning and keyguard mode.
///
/// They are kept on the device (the app stores them beside its other local
/// facts) and never synced, because they fit the child's hands and the
/// device's own screen.
library;

import 'package:flutter/foundation.dart';

/// How the child's switches scan the board.
enum ScanMode {
  /// No scanning: the board answers touch only.
  off,

  /// The highlight moves by itself, a row then a word at a time; the switch
  /// (space or enter) selects.
  oneSwitch,

  /// One switch (space) moves the highlight, the other (enter) selects.
  twoSwitches,
}

/// This device's settings for the child's board. The defaults are the board
/// as it has always been.
@immutable
class DeviceSettings {
  const DeviceSettings({
    this.holdTime = Duration.zero,
    this.repeatGuard = Duration.zero,
    this.selectOnRelease = true,
    this.scanMode = ScanMode.off,
    this.scanStep = const Duration(milliseconds: 1500),
    this.scanPreview = false,
    this.keyguard = false,
  });

  /// How long a word must be held before it speaks. Zero is a plain tap.
  final Duration holdTime;

  /// After a word speaks, touches are ignored for this long. Zero ignores
  /// none.
  final Duration repeatGuard;

  /// True: a word speaks when the finger lifts. False: as soon as it has
  /// been held for [holdTime] (at once when that is zero).
  final bool selectOnRelease;

  final ScanMode scanMode;

  /// How long the highlight rests on each row or word in one-switch
  /// scanning.
  final Duration scanStep;

  /// Says each highlighted word quietly while scanning.
  final bool scanPreview;

  /// The grid keeps one fixed size and place, for a plastic keyguard.
  final bool keyguard;

  /// The choices offered for [holdTime].
  static const List<Duration> holdTimes = [
    Duration.zero,
    Duration(milliseconds: 300),
    Duration(milliseconds: 600),
    Duration(seconds: 1),
  ];

  /// The choices offered for [repeatGuard].
  static const List<Duration> repeatGuards = [
    Duration.zero,
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];

  /// The choices offered for [scanStep]: slow, steady, quick.
  static const List<Duration> scanSteps = [
    Duration(milliseconds: 2500),
    Duration(milliseconds: 1500),
    Duration(milliseconds: 1000),
  ];

  /// True when touch works as it always has: no gate is needed.
  bool get plainTouch =>
      holdTime == Duration.zero &&
      repeatGuard == Duration.zero &&
      selectOnRelease;

  DeviceSettings copyWith({
    Duration? holdTime,
    Duration? repeatGuard,
    bool? selectOnRelease,
    ScanMode? scanMode,
    Duration? scanStep,
    bool? scanPreview,
    bool? keyguard,
  }) => DeviceSettings(
    holdTime: holdTime ?? this.holdTime,
    repeatGuard: repeatGuard ?? this.repeatGuard,
    selectOnRelease: selectOnRelease ?? this.selectOnRelease,
    scanMode: scanMode ?? this.scanMode,
    scanStep: scanStep ?? this.scanStep,
    scanPreview: scanPreview ?? this.scanPreview,
    keyguard: keyguard ?? this.keyguard,
  );

  /// As kept on the device.
  Map<String, Object> toJson() => {
    'holdMs': holdTime.inMilliseconds,
    'repeatMs': repeatGuard.inMilliseconds,
    'release': selectOnRelease,
    'scan': scanMode.name,
    'stepMs': scanStep.inMilliseconds,
    'preview': scanPreview,
    'keyguard': keyguard,
  };

  /// Reads what [toJson] wrote. Anything missing or unreadable is the
  /// default, so a damaged file gives the board as it always was.
  factory DeviceSettings.fromJson(Object? json) {
    const plain = DeviceSettings();
    if (json is! Map) return plain;
    Duration ms(Object? value, Duration fallback, {int max = 10000}) =>
        value is int && value >= 0 && value <= max
        ? Duration(milliseconds: value)
        : fallback;
    final scan = ScanMode.values
        .where((mode) => mode.name == json['scan'])
        .firstOrNull;
    final step = ms(json['stepMs'], plain.scanStep);
    return DeviceSettings(
      holdTime: ms(json['holdMs'], plain.holdTime),
      repeatGuard: ms(json['repeatMs'], plain.repeatGuard),
      selectOnRelease: json['release'] is bool
          ? json['release'] as bool
          : plain.selectOnRelease,
      scanMode: scan ?? plain.scanMode,
      scanStep: step < const Duration(milliseconds: 300)
          ? plain.scanStep
          : step,
      scanPreview: json['preview'] == true,
      keyguard: json['keyguard'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DeviceSettings &&
      other.holdTime == holdTime &&
      other.repeatGuard == repeatGuard &&
      other.selectOnRelease == selectOnRelease &&
      other.scanMode == scanMode &&
      other.scanStep == scanStep &&
      other.scanPreview == scanPreview &&
      other.keyguard == keyguard;

  @override
  int get hashCode => Object.hash(
    holdTime,
    repeatGuard,
    selectOnRelease,
    scanMode,
    scanStep,
    scanPreview,
    keyguard,
  );
}

/// Where this device keeps its [DeviceSettings]. Notifies after every
/// change, so the child's board follows at once.
abstract class DeviceSettingsStore extends ChangeNotifier {
  DeviceSettings get settings;

  /// Keeps [value] on this device. Never throws: a value that could not be
  /// kept holds for this run.
  Future<void> save(DeviceSettings value);
}

/// Speech that can say a word quietly: the spoken preview while scanning.
/// A [SpeechService] without it says the preview at its usual volume.
abstract interface class QuietSpeech {
  Future<void> speakQuietly(String text);
}
