import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../printing/print_routes.dart'
    show boardPageHeaders, isPrintToken, printMissingStatus;
import 'progress_page.dart';

/// Adds `GET /report/<token>`, the printable progress report, to the web
/// server. Call before the server starts.
void registerProgressRoutes(Serverpod pod) {
  pod.webServer.addRoute(ProgressRoute(), '/report/:token');
}

/// Serves the progress report. Needs no sign-in: the token is the key, as
/// for the paper copy.
class ProgressRoute extends Route {
  ProgressRoute() : super(methods: {Method.get});

  @override
  Future<Result> handleCall(Session session, Request request) =>
      progressResponse(session, request.pathParameters.raw[#token] ?? '');
}

/// The response for `GET /report/<token>`: the page, or the same "not here"
/// answer whether the token never existed, is malformed or has expired.
Future<Response> progressResponse(Session session, String token) async {
  if (!isPrintToken(token)) return _missing();
  final link = await ProgressReportLink.db.findFirstRow(
    session,
    where: (t) => t.token.equals(token),
  );
  if (link == null || !link.expiresAt.isAfter(DateTime.now())) {
    return _missing();
  }
  return Response.ok(
    body: Body.fromString(
      renderProgressPage(
        link.report,
        savedAt: link.createdAt,
        expiresAt: link.expiresAt,
      ),
      mimeType: MimeType.html,
    ),
    headers: _headers,
  );
}

Response _missing() => Response(
  printMissingStatus,
  body: Body.fromString(renderMissingReportPage(), mimeType: MimeType.html),
  headers: _headers,
);

/// As the paper copy: out of caches and search results, loading and running
/// nothing but one inline stylesheet and the inline mark.
final Headers _headers = boardPageHeaders(
  "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; "
  "form-action 'none'; frame-ancestors 'none'",
);
