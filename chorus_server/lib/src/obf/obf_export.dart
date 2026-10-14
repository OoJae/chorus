/// `GET /export/<token>`: a stored board snapshot, paper copy or view-only,
/// as an Open Board Format 0.1 file another AAC app can import.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart'
    show BoardFacts, TileFacts, deterministicId, obfJsonOf, placedKey;
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../printing/print_page.dart';
import '../printing/print_routes.dart';
import '../printing/snapshots.dart';
import '../sharing/sharing_routes.dart';

/// Serves a stored snapshot as an .obf download.
///
/// Needs no sign-in: the token is the key, as for the pages.
class ObfExportRoute extends Route {
  ObfExportRoute() : super(methods: {Method.get});

  @override
  Future<Result> handleCall(Session session, Request request) =>
      obfExportResponse(session, request.pathParameters.raw[#token] ?? '');
}

/// The response for `GET /export/<token>`: the file, 404 with the "not
/// here" page for a token that never existed, or 410 once the link has
/// expired or was withdrawn.
Future<Response> obfExportResponse(Session session, String token) async {
  final snapshot = await findSnapshot(session, token);
  if (snapshot == null) return sharedPageUnknown();
  if (!isLive(snapshot)) return sharedPageGone();
  final PrintBoard board;
  try {
    board = PrintBoard.parse(snapshot.boardJson);
  } on FormatException {
    // Checked when it was published, so this means the row was damaged.
    return sharedPageUnknown();
  }
  return Response.ok(
    body: Body.fromString(
      obfOfSnapshot(board, snapshot),
      mimeType: MimeType.json,
    ),
    headers: _headers.transform((h) {
      h['Content-Disposition'] = [obfContentDisposition(board.name)];
    }),
  );
}

/// [board] as OBF 0.1 JSON, written by `obfJsonOf` in chorus_shared.
///
/// A snapshot carries no ids, so the board's id is derived from the
/// circle and the stored row, and each word's from the board and its cell:
/// the same link always gives the same file, and nothing is revealed.
String obfOfSnapshot(PrintBoard board, SharedSnapshot snapshot) {
  final boardId = deterministicId(
    snapshot.circleSpace.uuid,
    'snapshot:${snapshot.id}',
  );
  final facts = BoardFacts(
    id: boardId,
    name: board.name,
    rows: board.rows,
    cols: board.cols,
  );
  final tiles = [
    for (final MapEntry(key: (row, col), value: tile) in board.cells.entries)
      TileFacts(
        id: deterministicId(boardId, 'cell:$row:$col'),
        boardId: boardId,
        cellKey: placedKey(boardId, row, col),
        label: tile.label,
        speech: tile.speech,
        colorKey: tile.colorKey,
      ),
  ];
  return obfJsonOf(facts, tiles);
}

/// `attachment; filename="<name>.obf"`, with the name cut down to what
/// every browser saves safely, plus the full name for those that read
/// `filename*` (RFC 6266).
String obfContentDisposition(String boardName) {
  final plain = boardName
      .replaceAll(RegExp(r'[^A-Za-z0-9 ._-]'), '_')
      .replaceAll(RegExp(r'^[ .]+|[ .]+$'), '');
  final ascii = plain.replaceAll('_', '').trim().isEmpty ? 'board' : plain;
  final full = Uri.encodeComponent('$boardName.obf');
  return 'attachment; filename="$ascii.obf"; filename*=UTF-8\'\'$full';
}

/// Kept out of caches and never sniffed: the file is the board.
final Headers _headers = boardPageHeaders("default-src 'none'");
