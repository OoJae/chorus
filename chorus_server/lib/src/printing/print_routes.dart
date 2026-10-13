import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'print_page.dart';

/// The only shape a token ever has: 32 random bytes as URL-safe base64.
final RegExp _tokenShape = RegExp(r'^[A-Za-z0-9_-]{43}$');

/// True when [token] could have come from `publishBoard`.
bool isPrintToken(String token) => _tokenShape.hasMatch(token);

/// Status sent for an unknown or expired token.
///
/// 410 and not 404 on purpose: `server.dart` wraps the whole web server in a
/// fallback that replaces every 404 with the web app's start page, so a 404
/// from here would never reach the browser. 410 does, with the "not here"
/// page.
const int printMissingStatus = 410;

/// Adds `GET /print/<token>`, the printable page of a published board, to the
/// web server. Call before the server starts.
void registerPrintRoutes(Serverpod pod) {
  pod.webServer.addRoute(PrintRoute(), '/print/:token');
}

/// Serves the printable page of a published board.
///
/// Needs no sign-in: the token is the key, so the page can be opened on
/// whatever computer has a printer.
class PrintRoute extends Route {
  PrintRoute() : super(methods: {Method.get});

  @override
  Future<Result> handleCall(Session session, Request request) =>
      printResponse(session, request.pathParameters.raw[#token] ?? '');
}

/// The response for `GET /print/<token>`: the page, or the same "not here"
/// answer whether the token never existed, is malformed or has expired.
Future<Response> printResponse(Session session, String token) async {
  if (!isPrintToken(token)) return _missing();
  final snapshot = await SharedSnapshot.db.findFirstRow(
    session,
    where: (t) => t.token.equals(token),
  );
  if (snapshot == null || !snapshot.expiresAt.isAfter(DateTime.now())) {
    return _missing();
  }
  final PrintBoard board;
  try {
    board = PrintBoard.parse(snapshot.boardJson);
  } on FormatException {
    // Checked when it was published, so this means the row was damaged.
    return _missing();
  }
  return Response.ok(
    body: Body.fromString(
      renderPrintPage(
        board,
        savedAt: snapshot.createdAt,
        expiresAt: snapshot.expiresAt,
      ),
      mimeType: MimeType.html,
    ),
    headers: _headers,
  );
}

Response _missing() => Response(
  printMissingStatus,
  body: Body.fromString(renderMissingPage(), mimeType: MimeType.html),
  headers: _headers,
);

/// Keeps the page out of caches and search results, and lets it load or run
/// nothing: it is text and one inline stylesheet.
final Headers _headers = Headers.build((h) {
  h['Cache-Control'] = ['private, no-store'];
  h['Referrer-Policy'] = ['no-referrer'];
  h['X-Robots-Tag'] = ['noindex, nofollow'];
  h['X-Content-Type-Options'] = ['nosniff'];
  h['Content-Security-Policy'] = [
    "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; "
        "form-action 'none'; frame-ancestors 'none'",
  ];
});
