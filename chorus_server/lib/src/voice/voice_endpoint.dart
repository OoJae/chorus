import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';
import 'circle_voices.dart';

/// The voice, speed and pitch the child speaks with, the same on every
/// device of the circle.
class VoiceEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// [circleSpace]'s voice: the defaults when nobody has chosen one. Any
  /// member may read it.
  Future<VoiceSetting> getVoice(Session session, UuidValue circleSpace) async {
    await requireMember(session, circleSpace);
    return voiceSettingOf(await findCircleVoice(session, circleSpace));
  }

  /// Chooses [circleSpace]'s voice. [voiceName] null is each device's own
  /// everyday voice; [rate] and [pitch] are kept within what every engine
  /// accepts. Editors only: a read-only partner gets [CircleException]
  /// with `notAllowed`.
  Future<VoiceSetting> setVoice(
    Session session,
    UuidValue circleSpace,
    String? voiceName,
    double rate,
    double pitch,
  ) async {
    final membership = await requireMember(
      session,
      circleSpace,
      editing: true,
    );
    final name = voiceName?.trim();
    final row = CircleVoice(
      circleSpace: circleSpace,
      voiceName: name == null || name.isEmpty
          ? null
          : (name.length > maxVoiceNameLength
                ? name.substring(0, maxVoiceNameLength)
                : name),
      rate: clampVoiceValue(rate, minVoiceRate, maxVoiceRate, defaultVoiceRate),
      pitch: clampVoiceValue(
        pitch,
        minVoicePitch,
        maxVoicePitch,
        defaultVoicePitch,
      ),
      changedBy: membership.userId,
      changedAt: DateTime.now().toUtc(),
    );
    final saved = await session.db.transaction((tx) async {
      final existing = await CircleVoice.db.findFirstRow(
        session,
        where: (t) => t.circleSpace.equals(circleSpace),
        transaction: tx,
      );
      if (existing == null) {
        return CircleVoice.db.insertRow(session, row, transaction: tx);
      }
      return CircleVoice.db.updateRow(
        session,
        row.copyWith(id: existing.id),
        transaction: tx,
      );
    });
    return voiceSettingOf(saved);
  }
}
