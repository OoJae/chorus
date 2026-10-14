import 'dart:async';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';

/// The server-event channel that tells [user]'s live streams in
/// [circleSpace] to close.
String removedChannel(UuidValue circleSpace, UuidValue user) =>
    'chorus-removed-${circleSpace.uuid}-${user.uuid}';

/// Calls [close] when [user] is removed from [circleSpace] while a live
/// stream of theirs is open. Returns the way to stop listening.
void Function() closeOnRemoval(
  Session session,
  UuidValue circleSpace,
  UuidValue user,
  Future<void> Function() close,
) {
  final channel = removedChannel(circleSpace, user);
  void onRemoved(dynamic _) => unawaited(close());
  session.messages.addListener(channel, onRemoved);
  return () => session.messages.removeListener(channel, onRemoved);
}

/// Who is in a circle, and a guardian's way to remove someone.
class MembersEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Everyone in [circleSpace], guardians first, then by name. Any member.
  Future<List<MemberInfo>> list(Session session, UuidValue circleSpace) async {
    await requireMember(session, circleSpace);
    final rows = await Membership.db.find(
      session,
      where: (t) => t.circleSpace.equals(circleSpace),
    );
    rows.sort((a, b) {
      final byRole = a.role.index.compareTo(b.role.index);
      return byRole != 0
          ? byRole
          : a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return [
      for (final row in rows)
        MemberInfo(
          userId: row.userId,
          displayName: row.displayName,
          role: row.role,
        ),
    ];
  }

  /// Removes [userId] from [circleSpace]: their sync access is revoked,
  /// their membership deleted, and a live stream of theirs closes at once.
  /// The words they added stay. Guardians only, and never themselves.
  ///
  /// Throws [CircleException] with `notAllowed` for a caller who is not a
  /// guardian or who names themselves, and `notAMember` when [userId] is
  /// not in the circle.
  Future<void> remove(
    Session session,
    UuidValue circleSpace,
    UuidValue userId,
  ) async {
    final me = await requireMember(session, circleSpace);
    if (me.role != CircleRole.guardian || me.userId == userId) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    await session.db.transaction((transaction) async {
      final target = await Membership.db.findFirstRow(
        session,
        where: (t) =>
            t.circleSpace.equals(circleSpace) & t.userId.equals(userId),
        transaction: transaction,
      );
      if (target == null) {
        throw CircleException(failure: CircleFailure.notAMember);
      }
      await session.offlineSync.spaces.revoke(
        space: circleSpace,
        user: userId,
        transaction: transaction,
      );
      await Membership.db.deleteRow(
        session,
        target,
        transaction: transaction,
      );
    });
    // Any live stream of theirs is listening on this channel.
    unawaited(
      session.messages.postMessage(
        removedChannel(circleSpace, userId),
        LiveEvent(
          kind: LiveKind.presence,
          text: 'removed',
          fromUser: me.userId,
          fromName: me.displayName,
          at: DateTime.now().toUtc(),
        ),
        scope: MessageScope.local,
      ),
    );
  }
}
