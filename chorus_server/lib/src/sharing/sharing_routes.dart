import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../obf/obf_export.dart';
import '../printing/print_page.dart';
import '../printing/print_routes.dart';
import '../printing/snapshots.dart';
import '../voice/circle_voices.dart';
import 'view_only_page.dart';

/// Status for a token that never existed.
const int sharedUnknownStatus = 404;

/// Status for a link that has expired or was withdrawn.
const int sharedGoneStatus = 410;

/// Adds `GET /b/<token>` (the view-only board) and `GET /export/<token>`
/// (the same board as an .obf file) to the web server. Call before the
/// server starts.
void registerSharingRoutes(Serverpod pod) {
  pod.webServer.addRoute(ViewOnlyRoute(), '/b/:token');
  pod.webServer.addRoute(ObfExportRoute(), '/export/:token');
}

/// Serves the view-only board.
///
/// Needs no sign-in: the token is the key, so a babysitter can open it on
/// any phone.
class ViewOnlyRoute extends Route {
  ViewOnlyRoute() : super(methods: {Method.get});

  @override
  Future<Result> handleCall(Session session, Request request) =>
      viewOnlyResponse(session, request.pathParameters.raw[#token] ?? '');
}

/// The response for `GET /b/<token>`: the page; 404 for a token that never
/// existed or is not a view-only one; 410 once it has expired or was
/// withdrawn.
Future<Response> viewOnlyResponse(Session session, String token) async {
  final snapshot = await findSnapshot(session, token);
  // A paper copy's token does not open the speaking page.
  if (snapshot == null || snapshot.kind != SnapshotKind.viewOnly) {
    return sharedPageUnknown();
  }
  if (!isLive(snapshot)) return sharedPageGone();
  final PrintBoard board;
  try {
    board = PrintBoard.parse(snapshot.boardJson);
  } on FormatException {
    // Checked when it was published, so this means the row was damaged.
    return sharedPageUnknown();
  }
  // The circle's chosen speed and pitch, as on every device of it.
  final voice = voiceSettingOf(
    await findCircleVoice(session, snapshot.circleSpace),
  );
  return Response.ok(
    body: Body.fromString(
      renderViewOnlyPage(
        board,
        expiresAt: snapshot.expiresAt,
        rate: voice.rate,
        pitch: voice.pitch,
      ),
      mimeType: MimeType.html,
    ),
    headers: viewOnlyHeaders,
  );
}

/// 404 with the "not here" page.
Response sharedPageUnknown() => Response(
  sharedUnknownStatus,
  body: Body.fromString(renderViewOnlyUnknownPage(), mimeType: MimeType.html),
  headers: viewOnlyHeaders,
);

/// 410 with the "no longer shared" page.
Response sharedPageGone() => Response(
  sharedGoneStatus,
  body: Body.fromString(renderViewOnlyGonePage(), mimeType: MimeType.html),
  headers: viewOnlyHeaders,
);

/// The print page's rules plus the one inline script, and pictures only as
/// data: nothing is loaded from anywhere, and nothing is sent.
final Headers viewOnlyHeaders = boardPageHeaders(
  "default-src 'none'; style-src 'unsafe-inline'; "
  "script-src 'unsafe-inline'; img-src data:; base-uri 'none'; "
  "form-action 'none'; frame-ancestors 'none'",
);
