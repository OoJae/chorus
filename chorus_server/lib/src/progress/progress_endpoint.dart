import 'package:serverpod/serverpod.dart';

import '../circles/membership_guard.dart';
import '../generated/protocol.dart';
import '../modelling/focus_words.dart';
import '../printing/print_routes.dart' show isPrintToken;
import '../printing/printing_endpoint.dart' show webPageUrl;
import '../printing/snapshots.dart' show newPrintToken;
import '../summary/week_summaries.dart';

/// How long a progress report link opens.
const Duration progressLinkLifetime = Duration(days: 30);

/// The one-page progress report: this week's counts, kept behind a token so
/// it can be opened and printed anywhere. Counts only, never a transcript.
class ProgressEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Works out this week's report for [circleSpace], keeps it behind a new
  /// token for 30 days, and returns the token. Guardians and therapists
  /// only, as for "This week".
  Future<String> makeReport(Session session, UuidValue circleSpace) async {
    final membership = await requireMember(session, circleSpace);
    if (membership.role != CircleRole.guardian &&
        membership.role != CircleRole.therapist) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    final now = DateTime.now().toUtc();
    final report = await buildProgressReport(session, circleSpace, now);
    await ProgressReportLink.db.deleteWhere(
      session,
      where: (t) => t.expiresAt < now,
    );
    final link = await ProgressReportLink.db.insertRow(
      session,
      ProgressReportLink(
        token: newPrintToken(),
        circleSpace: circleSpace,
        report: report,
        createdBy: callerId(session),
        createdAt: now,
        expiresAt: now.add(progressLinkLifetime),
      ),
    );
    return link.token;
  }

  /// The address of the report page for [token] on this server's web
  /// server. Throws [CircleException] (`notAllowed`) for a malformed token.
  Future<String> reportUrl(Session session, String token) async {
    if (!isPrintToken(token)) {
      throw CircleException(failure: CircleFailure.notAllowed);
    }
    return webPageUrl(session.serverpod.config.webServer, '/report/$token');
  }
}

/// The week [day] falls in for [circleSpace], as the report shows it: the
/// week's counts and each focus word's modelled and said.
Future<ProgressReport> buildProgressReport(
  Session session,
  UuidValue circleSpace,
  DateTime day,
) async {
  final week = await computeWeek(session, circleSpace, day);
  final circle = await Circle.db.findFirstRow(
    session,
    where: (t) => t.spaceUuid.equals(circleSpace),
  );
  final pins = await focusWordsOf(session, circleSpace, day);
  final ids = {for (final pin in pins) pin.tileId};
  final counts = await modelledAndSaid(
    session,
    circleSpace,
    week.weekStart,
    ids,
  );
  // The synced tile table, read as the server sees it: filter on the circle.
  final tiles = ids.isEmpty
      ? const <Tile>[]
      : await Tile.db.find(
          session,
          where: (t) => t.circleId.equals(circleSpace) & t.id.inSet(ids),
        );
  final labels = {for (final tile in tiles) tile.id!: tile.label};
  return ProgressReport(
    childName: circle?.childName ?? '',
    week: week,
    focus: [
      for (final pin in pins)
        if (labels[pin.tileId] case final String label)
          FocusReportLine(
            label: label,
            tip: pin.tip,
            modelled: counts[pin.tileId]?.$1 ?? 0,
            said: counts[pin.tileId]?.$2 ?? 0,
          ),
    ],
  );
}
