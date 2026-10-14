/// The view-only page reports back: each word a sitter taps, while the
/// circle's word log is on and the word is not kept out of it, becomes a
/// line in the circle's "What changed". Only the word and the time are
/// kept.
library;

import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';
import '../printing/print_page.dart';
import '../printing/snapshots.dart';
import '../wordlog/word_log_endpoint.dart' show isWordLogOn;

/// The server's switch for tap reports: false makes every view-only page
/// send nothing and keeps nothing, as before.
const bool sitterTapsEnabled = true;

/// Most taps one link may report per minute; more are dropped.
const int maxTapsPerMinute = 30;

/// How far back the feed shows a sitter's words.
const Duration sitterTapWindow = Duration(days: 7);

/// Most taps the feed is given.
const int maxSitterTaps = 100;

final Map<String, List<DateTime>> _recent = {};

/// True when [token] may report one more tap at [now]; counts it if so.
bool allowTap(String token, DateTime now) {
  final cutoff = now.subtract(const Duration(minutes: 1));
  final taps = _recent.putIfAbsent(token, () => [])
    ..removeWhere((at) => at.isBefore(cutoff));
  if (_recent.length > 1000) {
    _recent.removeWhere((key, value) => value.isEmpty);
  }
  if (taps.length >= maxTapsPerMinute) return false;
  taps.add(now);
  return true;
}

/// Forgets every count, for tests.
void resetTapLimits() => _recent.clear();

/// Handles `POST /b/<token>/tap` with the tapped cell as `row:col` in the
/// body. Always answers 204: the page never learns whether a tap was kept.
class SitterTapRoute extends Route {
  SitterTapRoute() : super(methods: {Method.post});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final token = request.pathParameters.raw[#token] ?? '';
    String body;
    try {
      body = await request.readAsString(maxLength: 16);
    } catch (_) {
      body = '';
    }
    await recordSitterTap(session, token, body);
    return Response(204);
  }
}

final RegExp _cellPattern = RegExp(r'^(\d{1,2}):(\d{1,2})$');

/// Keeps the tap of cell [cell] (`row:col`) on [token]'s view-only page,
/// when the link is live, the circle's word log is on, the word is not
/// kept out of the log, and the link is under its rate limit. Completes
/// with whether it was kept.
Future<bool> recordSitterTap(
  Session session,
  String token,
  String cell, {
  DateTime? now,
}) async {
  if (!sitterTapsEnabled) return false;
  final at = (now ?? DateTime.now()).toUtc();
  final match = _cellPattern.firstMatch(cell.trim());
  if (match == null) return false;
  final snapshot = await findSnapshot(session, token);
  if (snapshot == null ||
      snapshot.kind != SnapshotKind.viewOnly ||
      !isLive(snapshot, now: at)) {
    return false;
  }
  final space = snapshot.circleSpace;
  if (!await isWordLogOn(session, space)) return false;
  final PrintBoard board;
  try {
    board = PrintBoard.parse(snapshot.boardJson);
  } on FormatException {
    return false;
  }
  final tile =
      board.cells[(int.parse(match.group(1)!), int.parse(match.group(2)!))];
  if (tile == null) return false;
  // The page's copy has no tile ids: a word of the circle with this label
  // that is kept out of the log keeps the tap out too. The synced table is
  // read as the server sees it, so the query filters on the circle.
  final privateWord = await Tile.db.findFirstRow(
    session,
    where: (t) =>
        t.circleId.equals(space) &
        t.label.equals(tile.label) &
        t.noLog.equals(true),
  );
  if (privateWord != null) return false;
  if (!allowTap(token, at)) return false;
  await SitterTap.db.insertRow(
    session,
    SitterTap(circleSpace: space, label: tile.label, tappedAt: at),
  );
  return true;
}

/// What sitters tapped, for the circle's "What changed".
class SitterEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The words sitters tapped on [circleSpace]'s view-only pages in the
  /// last week, newest first. Guardians and therapists only, as for the
  /// word log's "This week".
  Future<List<SitterTapInfo>> recentTaps(
    Session session,
    UuidValue circleSpace,
  ) async {
    final me = await requireMember(session, circleSpace);
    if (me.role != CircleRole.guardian && me.role != CircleRole.therapist) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    final since = DateTime.now().toUtc().subtract(sitterTapWindow);
    final rows = await SitterTap.db.find(
      session,
      where: (t) => t.circleSpace.equals(circleSpace) & (t.tappedAt > since),
      orderBy: (t) => t.tappedAt.desc(),
      limit: maxSitterTaps,
    );
    return [
      for (final row in rows)
        SitterTapInfo(label: row.label, tappedAt: row.tappedAt),
    ];
  }
}
