import 'dart:convert';
import 'dart:math';

import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';
import 'print_page.dart';
import 'print_routes.dart';

/// How long a link to a printable board works.
const Duration printLinkLifetime = Duration(days: 30);

/// A new token: 32 random bytes as URL-safe base64, 43 characters.
String newPrintToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// Paper backups of a board.
class PrintingEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Stores [boardJson], a snapshot the caller built from its own replica,
  /// and returns an unguessable token. `GET /print/<token>` on the web server
  /// renders the snapshot as a printable page. Members only.
  ///
  /// The link works for 30 days. Throws [CircleException] with `notAllowed`
  /// when the snapshot is over 200 KB or is not a board the page can lay out
  /// (see `print_page.dart` for the format).
  Future<String> publishBoard(
    Session session,
    UuidValue circleSpace,
    String boardJson,
  ) async {
    await requireMember(session, circleSpace);
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

    final now = DateTime.now().toUtc();
    // Expired snapshots are of no use to anyone; clear them as we go.
    await SharedSnapshot.db.deleteWhere(
      session,
      where: (t) => t.expiresAt < now,
    );
    final token = newPrintToken();
    await SharedSnapshot.db.insertRow(
      session,
      SharedSnapshot(
        token: token,
        circleSpace: circleSpace,
        boardJson: boardJson,
        createdBy: callerId(session),
        createdAt: now,
        expiresAt: now.add(printLinkLifetime),
      ),
    );
    return token;
  }

  /// The address of the printable page for [token], on the web server as
  /// the outside world reaches it. The app's own server address is the API
  /// server's, which does not serve the page, so a phone has to ask.
  ///
  /// Reads no data: the answer is the same for a token that does not exist.
  /// Throws [CircleException] with `notAllowed` for text that is not a
  /// token.
  Future<String> pageUrl(Session session, String token) async {
    if (!isPrintToken(token)) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    return printPageUrl(session.serverpod.config.webServer, token);
  }
}

/// `<scheme>://<public host>[:<port>]/print/<token>` for the web server
/// described by [web]; with no web server configured, a path alone.
String printPageUrl(ServerConfig? web, String token) {
  if (web == null) return '/print/$token';
  return Uri(
    scheme: web.publicScheme,
    host: web.publicHost,
    port: web.publicPort,
    path: '/print/$token',
  ).toString();
}
