/// "This week", worked out from a circle's word log and its tiles with
/// `summarizeWeek` from chorus_shared, on demand or ahead by the weekly job.
library;

import 'package:chorus_shared/chorus_shared.dart'
    show
        TileFacts,
        WeekSummary,
        WordUse,
        modelledVersusSaid,
        summarizeWeek,
        weekStartOf;
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// The week from Monday 00:00 UTC of the week [day] falls in, for
/// [circleSpace]: the stored one when the weekly job left one, else worked
/// out now.
Future<WeekReport> weekReport(
  Session session,
  UuidValue circleSpace,
  DateTime day,
) async {
  final start = weekStartOf(day);
  final stored = await WeeklySummary.db.findFirstRow(
    session,
    where: (t) => t.circleSpace.equals(circleSpace) & t.weekStart.equals(start),
  );
  return stored?.report ?? computeWeek(session, circleSpace, start);
}

/// Works out the week from Monday 00:00 UTC of the week [day] falls in for
/// [circleSpace], from its word log and its tiles as the server holds them.
Future<WeekReport> computeWeek(
  Session session,
  UuidValue circleSpace,
  DateTime day,
) async {
  final start = weekStartOf(day);
  final end = start.add(const Duration(days: 7));

  final week = await WordUseRecord.db.find(
    session,
    where: (t) =>
        t.circleSpace.equals(circleSpace) &
        (t.spokenAt >= start) &
        (t.spokenAt < end),
  );
  // Before the week only "was it ever spoken" counts, so one use per tile
  // is enough, and a long log is not read in full.
  final before = start.subtract(const Duration(microseconds: 1));
  final earlier = [
    for (final tileId in await _tilesSpokenBefore(session, circleSpace, start))
      WordUse(tileId: tileId, boardId: '', spokenAt: before),
  ];

  // The synced tile table, read as the server sees it, so it must filter on
  // the circle itself. Tiles made after the week were not there to use.
  final tiles = await Tile.db.find(
    session,
    where: (t) => t.circleId.equals(circleSpace) & (t.createdAt < end),
  );

  // What the child said; an adult's modelled taps are counted apart.
  WordUse useOf(WordUseRecord use) => WordUse(
    tileId: use.tileId.uuid,
    boardId: use.boardId.uuid,
    spokenAt: use.spokenAt,
  );
  final said = [
    for (final use in week)
      if (!use.modelled) useOf(use),
  ];
  final modelled = [
    for (final use in week)
      if (use.modelled) useOf(use),
  ];
  final facts = [for (final tile in tiles) _factsOf(tile)];
  final summary = summarizeWeek([...earlier, ...said], facts, start);
  return reportOf(summary, computedAt: DateTime.now().toUtc()).copyWith(
    modelled: [
      for (final row in modelledVersusSaid(said, modelled, facts, start))
        ModelledTally(
          label: row.label,
          modelled: row.modelled,
          said: row.said,
        ),
    ],
  );
}

/// Works out last week (the one before the week [now] falls in) for every
/// circle whose log is on, and stores it for `summary.week` to read.
/// Returns how many circles were done.
///
/// Safe to run again: a stored week is replaced.
Future<int> storeLastWeekForAll(Session session, {DateTime? now}) async {
  final lastWeek = weekStartOf(
    now ?? DateTime.now(),
  ).subtract(const Duration(days: 7));
  final circles = await WordLogSetting.db.find(
    session,
    where: (t) => t.enabled.equals(true),
  );
  for (final setting in circles) {
    final report = await computeWeek(session, setting.circleSpace, lastWeek);
    await WeeklySummary.db.upsertRow(
      session,
      WeeklySummary(
        circleSpace: setting.circleSpace,
        weekStart: report.weekStart,
        report: report,
      ),
      conflictColumns: (t) => [t.circleSpace, t.weekStart],
    );
  }
  return circles.length;
}

/// [summary] as the model sent to the app.
WeekReport reportOf(WeekSummary summary, {required DateTime computedAt}) =>
    WeekReport(
      weekStart: summary.weekStart,
      topWords: [
        for (final word in summary.topWords)
          WordTally(label: word.label, count: word.count),
      ],
      firstTimeWords: summary.firstTimeWords,
      addedWords: summary.addedWords,
      notUsedYet: summary.notUsedYet,
      totalUses: summary.totalUses,
      wordsUsed: summary.wordsUsed,
      computedAt: computedAt,
    );

/// Ids of the tiles of [circleSpace] the child spoke before [start], each
/// once. Modelled taps do not count.
Future<List<String>> _tilesSpokenBefore(
  Session session,
  UuidValue circleSpace,
  DateTime start,
) async {
  final rows = await session.db.unsafeQuery(
    'SELECT DISTINCT "tileId"::text FROM "word_use" '
    'WHERE "circleSpace" = CAST(@circle AS uuid) '
    'AND "spokenAt" < CAST(@start AS timestamp) '
    'AND "modelled" = false',
    parameters: QueryParameters.named({
      'circle': circleSpace.uuid,
      'start': _sqlTimestamp(start),
    }),
  );
  return [for (final row in rows) row.first as String];
}

/// [time] in UTC as Postgres reads a `timestamp`, which is how the ORM
/// stores a [DateTime].
String _sqlTimestamp(DateTime time) =>
    time.toUtc().toIso8601String().replaceFirst('T', ' ').replaceAll('Z', '');

TileFacts _factsOf(Tile tile) => TileFacts(
  id: tile.id!.uuid,
  boardId: tile.boardId.uuid,
  cellKey: tile.cellKey,
  label: tile.label,
  speech: tile.speech,
  colorKey: tile.colorKey,
  archived: tile.archivedAt != null,
  createdBy: tile.createdBy.uuid,
  createdByName: tile.createdByName,
  createdAt: tile.createdAt,
);
