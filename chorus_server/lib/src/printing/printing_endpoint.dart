import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';
import 'print_routes.dart';
import 'snapshots.dart';

/// How long a link to a printable board works.
const Duration printLinkLifetime = Duration(days: 30);

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
    final snapshot = await storeSnapshot(
      session,
      circleSpace: circleSpace,
      boardJson: boardJson,
      kind: SnapshotKind.print,
      lifetime: printLinkLifetime,
    );
    return snapshot.token;
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
String printPageUrl(ServerConfig? web, String token) =>
    webPageUrl(web, '/print/$token');

/// `<scheme>://<public host>[:<port>]<path>` for the web server described by
/// [web]; with no web server configured, [path] alone.
String webPageUrl(ServerConfig? web, String path) {
  if (web == null) return path;
  return Uri(
    scheme: web.publicScheme,
    host: web.publicHost,
    port: web.publicPort,
    path: path,
  ).toString();
}
