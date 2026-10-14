import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';

/// "Who is up to date": when each member's devices last synced a circle.
///
/// Each device reports itself after a successful sync with [heartbeat];
/// any member may read the list with [devices]. Nothing here holds a word.
class DeviceSeenEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  static const int _maxDeviceId = 64;
  static const int _maxLabel = 40;

  /// A report sent sooner than this after the last one from the same device
  /// is taken as seen but not written again.
  static const Duration minInterval = Duration(seconds: 50);

  /// Records that the caller's device [deviceId], described as
  /// [deviceLabel], finished a sync of [circleSpace] at [lastSyncAt]. Any
  /// member, read-only partners included: their devices sync too.
  Future<void> heartbeat(
    Session session,
    UuidValue circleSpace,
    String deviceId,
    String deviceLabel,
    DateTime lastSyncAt,
  ) async {
    final membership = await requireMember(session, circleSpace);
    final id = deviceId.trim();
    if (id.isEmpty || id.length > _maxDeviceId) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    final label = _clean(deviceLabel);
    final now = DateTime.now().toUtc();
    // A device's clock may be ahead; it never claims a sync in the future.
    final synced = lastSyncAt.toUtc().isAfter(now) ? now : lastSyncAt.toUtc();
    final existing = await DeviceSeen.db.findFirstRow(
      session,
      where: (t) =>
          t.circleSpace.equals(circleSpace) &
          t.userId.equals(membership.userId) &
          t.deviceId.equals(id),
    );
    if (existing == null) {
      try {
        await DeviceSeen.db.insertRow(
          session,
          DeviceSeen(
            circleSpace: circleSpace,
            userId: membership.userId,
            userName: membership.displayName,
            deviceId: id,
            deviceLabel: label,
            lastSyncAt: synced,
            lastSeenAt: now,
          ),
        );
        return;
      } on DatabaseUniqueViolationException {
        // A second report from the same device got there first.
        return;
      }
    }
    if (now.difference(existing.lastSeenAt) < minInterval &&
        !synced.isAfter(existing.lastSyncAt)) {
      return;
    }
    await DeviceSeen.db.updateRow(
      session,
      existing.copyWith(
        userName: membership.displayName,
        deviceLabel: label,
        lastSyncAt: synced.isAfter(existing.lastSyncAt)
            ? synced
            : existing.lastSyncAt,
        lastSeenAt: now,
      ),
      columns: (t) => [t.userName, t.deviceLabel, t.lastSyncAt, t.lastSeenAt],
    );
  }

  /// Every device that has reported a sync of [circleSpace], most recently
  /// synced first. Any member.
  Future<List<DeviceStatus>> devices(
    Session session,
    UuidValue circleSpace,
  ) async {
    await requireMember(session, circleSpace);
    final members = await Membership.db.find(
      session,
      where: (t) => t.circleSpace.equals(circleSpace),
    );
    final names = {for (final m in members) m.userId: m.displayName};
    final rows =
        await DeviceSeen.db.find(
            session,
            where: (t) => t.circleSpace.equals(circleSpace),
          )
          ..sort((a, b) => b.lastSyncAt.compareTo(a.lastSyncAt));
    return [
      for (final row in rows)
        // Someone who has left the circle is no longer listed.
        if (names.containsKey(row.userId))
          DeviceStatus(
            userId: row.userId,
            userName: names[row.userId]!,
            deviceId: row.deviceId,
            deviceLabel: row.deviceLabel,
            lastSyncAt: row.lastSyncAt,
            lastSeenAt: row.lastSeenAt,
          ),
    ];
  }

  static String _clean(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'A device';
    return trimmed.length > _maxLabel
        ? trimmed.substring(0, _maxLabel)
        : trimmed;
  }
}
