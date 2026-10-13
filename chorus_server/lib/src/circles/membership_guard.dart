import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// The signed-in caller's user id.
///
/// Throws [CircleException] (`notAMember`) when nobody is signed in, so an
/// endpoint that forgot `requireLogin` still refuses.
UuidValue callerId(Session session) {
  final identifier = session.authenticated?.userIdentifier;
  if (identifier == null) {
    throw CircleException(failure: CircleFailure.notAMember);
  }
  return UuidValue.withValidation(identifier);
}

/// The caller's membership of [circleSpace].
///
/// Throws [CircleException] with `notAMember` when the caller is not in the
/// circle, and with `notAllowed` when [editing] is set and the caller is a
/// read-only partner.
Future<Membership> requireMember(
  Session session,
  UuidValue circleSpace, {
  bool editing = false,
  Transaction? transaction,
}) async {
  final me = callerId(session);
  final membership = await Membership.db.findFirstRow(
    session,
    where: (t) => t.circleSpace.equals(circleSpace) & t.userId.equals(me),
    transaction: transaction,
  );
  if (membership == null) {
    throw CircleException(failure: CircleFailure.notAMember);
  }
  if (editing && membership.role == CircleRole.partner) {
    throw CircleException(failure: CircleFailure.notAllowed);
  }
  return membership;
}
