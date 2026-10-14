/// The circle's chosen voice: its defaults, its limits, and reading it.
library;

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Speed when nobody has chosen one: a little slower than normal speech,
/// as the app has always spoken.
const double defaultVoiceRate = 0.9;

/// The voice's own pitch.
const double defaultVoicePitch = 1.0;

/// The slowest and fastest speed, and the lowest and highest pitch, that
/// every engine Chorus speaks with accepts.
const double minVoiceRate = 0.5;
const double maxVoiceRate = 2.0;
const double minVoicePitch = 0.5;
const double maxVoicePitch = 2.0;

/// The longest voice name kept.
const int maxVoiceNameLength = 200;

/// [circleSpace]'s voice row, or null when nobody has chosen one.
Future<CircleVoice?> findCircleVoice(
  Session session,
  UuidValue circleSpace,
) => CircleVoice.db.findFirstRow(
  session,
  where: (t) => t.circleSpace.equals(circleSpace),
);

/// [voice] as the app and the view-only page read it; the defaults when
/// there is no row.
VoiceSetting voiceSettingOf(CircleVoice? voice) => VoiceSetting(
  voiceName: voice?.voiceName,
  rate: voice?.rate ?? defaultVoiceRate,
  pitch: voice?.pitch ?? defaultVoicePitch,
  changedAt: voice?.changedAt,
);

/// [value] kept within [min] and [max]; a value that is not a number is
/// [fallback].
double clampVoiceValue(double value, double min, double max, double fallback) {
  if (value.isNaN || value.isInfinite) return fallback;
  return value.clamp(min, max).toDouble();
}
