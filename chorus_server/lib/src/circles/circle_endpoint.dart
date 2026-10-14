import 'dart:math';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';

import '../generated/protocol.dart';

/// Creates circles and decides who is in them.
///
/// The sync module owns the data rules of a shared space (who may read and
/// write); it deliberately performs no authorization of its own. This
/// endpoint is where the app's policy lives: only a guardian may invite, and
/// the caller's identity always comes from the authenticated session.
class CircleEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  static const _inviteLifetime = Duration(days: 7);
  static const _maxName = 60;

  // No 0/O or 1/I/L, so a code survives being read aloud.
  static const _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static final _random = Random.secure();

  /// Creates a circle for [childName] with the caller as its guardian.
  ///
  /// The circle's boards live in a new shared sync space. The caller's client
  /// seeds the starter board after its next sync delivers that space.
  Future<CircleInfo> createCircle(
    Session session,
    String childName,
    String displayName,
  ) async {
    final me = _me(session);
    final now = DateTime.now().toUtc();
    return session.db.transaction((transaction) async {
      final space = await session.offlineSync.spaces.createFor(
        me,
        role: OfflineSyncSpaceRole.readWrite,
        transaction: transaction,
      );
      await Circle.db.insertRow(
        session,
        Circle(
          spaceUuid: space,
          childName: _clean(childName, fallback: 'My child'),
          createdBy: me,
          createdAt: now,
        ),
        transaction: transaction,
      );
      await Membership.db.insertRow(
        session,
        Membership(
          circleSpace: space,
          userId: me,
          role: CircleRole.guardian,
          displayName: _clean(displayName, fallback: 'Guardian'),
          joinedAt: now,
        ),
        transaction: transaction,
      );
      return _info(session, space, me, transaction: transaction);
    });
  }

  /// Every circle the caller belongs to, oldest first.
  Future<List<CircleInfo>> myCircles(Session session) async {
    final me = _me(session);
    final mine = await Membership.db.find(
      session,
      where: (t) => t.userId.equals(me),
      orderBy: (t) => t.joinedAt,
    );
    return [
      for (final membership in mine)
        await _info(session, membership.circleSpace, me),
    ];
  }

  /// Creates a single-use code that lets one more adult join [circleSpace]
  /// with [role]. Only a guardian may invite.
  Future<String> createInvite(
    Session session,
    UuidValue circleSpace,
    CircleRole role,
  ) async {
    final me = _me(session);
    final mine = await _membership(session, circleSpace, me);
    if (mine == null) throw CircleException(failure: CircleFailure.notAMember);
    if (mine.role != CircleRole.guardian) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    final now = DateTime.now().toUtc();
    final invitation = await Invitation.db.insertRow(
      session,
      Invitation(
        code: _newCode(),
        circleSpace: circleSpace,
        role: role,
        createdBy: me,
        createdAt: now,
        expiresAt: now.add(_inviteLifetime),
      ),
    );
    return invitation.code;
  }

  /// Joins the circle that [code] was issued for.
  ///
  /// Grants the caller read-write or read-only access to the circle's sync
  /// space according to the invited role. A caller who is already a member
  /// keeps their existing role.
  Future<CircleInfo> acceptInvite(
    Session session,
    String code,
    String displayName,
  ) async {
    final me = _me(session);
    final now = DateTime.now().toUtc();
    final normalized = code.trim().toUpperCase();
    return session.db.transaction((transaction) async {
      final invitation = await Invitation.db.findFirstRow(
        session,
        where: (t) => t.code.equals(normalized),
        lockMode: LockMode.forUpdate,
        transaction: transaction,
      );
      if (invitation == null) {
        throw CircleException(failure: CircleFailure.inviteInvalid);
      }
      final space = invitation.circleSpace;
      final existing = await _membership(
        session,
        space,
        me,
        transaction: transaction,
      );
      // A used code lets only the person who used it try again, and only
      // while they are still in the circle (an answer that never arrived).
      // Someone removed since needs a new invite.
      if (invitation.acceptedBy != null &&
          (invitation.acceptedBy != me || existing == null)) {
        throw CircleException(failure: CircleFailure.inviteUsed);
      }
      if (invitation.expiresAt.isBefore(now)) {
        throw CircleException(failure: CircleFailure.inviteExpired);
      }
      if (existing == null) {
        await session.offlineSync.spaces.grant(
          space: space,
          user: me,
          role: _spaceRole(invitation.role),
          transaction: transaction,
        );
        await Membership.db.insertRow(
          session,
          Membership(
            circleSpace: space,
            userId: me,
            role: invitation.role,
            displayName: _clean(displayName, fallback: 'Member'),
            joinedAt: now,
          ),
          transaction: transaction,
        );
      }
      await Invitation.db.updateRow(
        session,
        invitation.copyWith(acceptedBy: me),
        columns: (t) => [t.acceptedBy],
        transaction: transaction,
      );
      return _info(session, space, me, transaction: transaction);
    });
  }

  UuidValue _me(Session session) =>
      UuidValue.withValidation(session.authenticated!.userIdentifier);

  /// Guardians, therapists and teachers edit the board; partners only view.
  static OfflineSyncSpaceRole _spaceRole(CircleRole role) =>
      role == CircleRole.partner
      ? OfflineSyncSpaceRole.readOnly
      : OfflineSyncSpaceRole.readWrite;

  Future<Membership?> _membership(
    Session session,
    UuidValue circleSpace,
    UuidValue user, {
    Transaction? transaction,
  }) => Membership.db.findFirstRow(
    session,
    where: (t) => t.circleSpace.equals(circleSpace) & t.userId.equals(user),
    transaction: transaction,
  );

  Future<CircleInfo> _info(
    Session session,
    UuidValue circleSpace,
    UuidValue me, {
    Transaction? transaction,
  }) async {
    final circle = await Circle.db.findFirstRow(
      session,
      where: (t) => t.spaceUuid.equals(circleSpace),
      transaction: transaction,
    );
    final members = await Membership.db.find(
      session,
      where: (t) => t.circleSpace.equals(circleSpace),
      orderBy: (t) => t.joinedAt,
      transaction: transaction,
    );
    final mine = members.where((m) => m.userId == me).firstOrNull;
    if (circle == null || mine == null) {
      throw CircleException(failure: CircleFailure.notAMember);
    }
    return CircleInfo(
      spaceUuid: circleSpace,
      childName: circle.childName,
      myRole: mine.role,
      myDisplayName: mine.displayName,
      members: [
        for (final m in members)
          MemberInfo(
            userId: m.userId,
            displayName: m.displayName,
            role: m.role,
          ),
      ],
    );
  }

  static String _clean(String value, {required String fallback}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.length > _maxName ? trimmed.substring(0, _maxName) : trimmed;
  }

  static String _newCode() => String.fromCharCodes(
    Iterable.generate(
      8,
      (_) => _codeAlphabet.codeUnitAt(_random.nextInt(_codeAlphabet.length)),
    ),
  );
}
