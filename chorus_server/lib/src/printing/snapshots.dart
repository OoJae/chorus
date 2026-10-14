/// Board snapshots kept behind a token: the paper copy and the view-only
/// page store them the same way and differ only in kind and lifetime.
library;

import 'dart:convert';
import 'dart:math';

import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';
import 'print_page.dart';
import 'print_routes.dart';

/// A new token: 32 random bytes as URL-safe base64, 43 characters.
String newPrintToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// Checks that [boardJson] is a snapshot worth keeping. Throws
/// [CircleException] with `notAllowed` when it is over 200 KB or is not a
/// board the pages can lay out (see `print_page.dart` for the format).
void checkSnapshot(String boardJson) {
  // Each UTF-16 unit is at least one byte, so the cheap check comes first.
  if (boardJson.length > maxSnapshotBytes ||
      utf8.encode(boardJson).length > maxSnapshotBytes) {
    throw CircleException(failure: CircleFailure.notAllowed);
  }
  try {
    PrintBoard.parse(boardJson);
  } on FormatException {
    throw CircleException(failure: CircleFailure.notAllowed);
  }
}

/// Stores [boardJson] for the caller under a new token, as [kind], for
/// [lifetime]. Checks it first with [checkSnapshot]; the caller checks the
/// membership.
Future<SharedSnapshot> storeSnapshot(
  Session session, {
  required UuidValue circleSpace,
  required String boardJson,
  required SnapshotKind kind,
  required Duration lifetime,
}) async {
  checkSnapshot(boardJson);
  final now = DateTime.now().toUtc();
  // Expired snapshots are of no use to anyone; clear them as we go. The
  // daily cleanup does the same where the plan runs future calls.
  await deleteExpiredSnapshots(session, now: now);
  return SharedSnapshot.db.insertRow(
    session,
    SharedSnapshot(
      token: newPrintToken(),
      circleSpace: circleSpace,
      boardJson: boardJson,
      createdBy: callerId(session),
      createdAt: now,
      expiresAt: now.add(lifetime),
      kind: kind,
    ),
  );
}

/// Removes every snapshot that stopped working before [now] (default: the
/// present), withdrawn ones included. Returns how many went.
Future<int> deleteExpiredSnapshots(Session session, {DateTime? now}) async {
  final cutoff = (now ?? DateTime.now()).toUtc();
  final gone = await SharedSnapshot.db.deleteWhere(
    session,
    where: (t) => t.expiresAt < cutoff,
  );
  return gone.length;
}

/// The snapshot behind [token], expired or not, or null when the token is
/// malformed or unknown. The caller decides what an expired one means.
Future<SharedSnapshot?> findSnapshot(Session session, String token) async {
  if (!isPrintToken(token)) return null;
  return SharedSnapshot.db.findFirstRow(
    session,
    where: (t) => t.token.equals(token),
  );
}

/// True while [snapshot] still opens: not expired and not withdrawn.
bool isLive(SharedSnapshot snapshot, {DateTime? now}) =>
    snapshot.expiresAt.isAfter(now ?? DateTime.now());
