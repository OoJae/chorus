import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';
import '../printing/print_routes.dart';
import '../printing/printing_endpoint.dart';
import '../printing/snapshots.dart';

/// How long a view-only board stays open.
const Duration viewOnlyLinkLifetime = Duration(days: 7);

/// Sharing a board with someone outside the circle, such as a babysitter:
/// a page that speaks, and the same board as an .obf file.
class SharingEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Stores [boardJson], a snapshot the caller built from its own replica
  /// (the paper copy's format, with `speech` where a tile says something
  /// other than its label), and returns the link to its view-only page.
  /// Editing roles only.
  ///
  /// The page opens for 7 days, unless withdrawn sooner. Throws
  /// [CircleException] with `notAllowed` when the snapshot is over 200 KB or
  /// is not a board the page can lay out.
  Future<ViewOnlyLink> publishViewOnly(
    Session session,
    UuidValue circleSpace,
    String boardJson,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    final snapshot = await storeSnapshot(
      session,
      circleSpace: circleSpace,
      boardJson: boardJson,
      kind: SnapshotKind.viewOnly,
      lifetime: viewOnlyLinkLifetime,
    );
    final web = session.serverpod.config.webServer;
    return ViewOnlyLink(
      token: snapshot.token,
      url: webPageUrl(web, '/b/${snapshot.token}'),
      exportUrl: webPageUrl(web, '/export/${snapshot.token}'),
      expiresAt: snapshot.expiresAt,
    );
  }

  /// Stops the page and the file behind [token] opening, now. Works for any
  /// link of the circle, paper copies included. Editing roles only.
  ///
  /// Returns false when there was nothing to withdraw: the link is unknown,
  /// belongs to another circle, or had already stopped. Throws
  /// [CircleException] with `notAllowed` for text that is not a token.
  Future<bool> withdraw(
    Session session,
    UuidValue circleSpace,
    String token,
  ) async {
    await requireMember(session, circleSpace, editing: true);
    if (!isPrintToken(token)) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    final now = DateTime.now().toUtc();
    // An expired row is a withdrawn one: both answer 410 until the cleanup
    // removes them.
    final withdrawn = await SharedSnapshot.db.updateWhere(
      session,
      columnValues: (t) => [t.expiresAt(now)],
      where: (t) =>
          t.token.equals(token) &
          t.circleSpace.equals(circleSpace) &
          (t.expiresAt > now),
    );
    return withdrawn.isNotEmpty;
  }

  /// The address of the .obf file for [token], on the web server as the
  /// outside world reaches it. Works for paper-copy tokens too.
  ///
  /// Reads no data: the answer is the same for a token that does not exist.
  /// Throws [CircleException] with `notAllowed` for text that is not a
  /// token.
  Future<String> exportUrl(Session session, String token) async {
    if (!isPrintToken(token)) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    return webPageUrl(session.serverpod.config.webServer, '/export/$token');
  }
}
