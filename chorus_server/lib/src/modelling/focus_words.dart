/// Focus words of the week and the Thursday nudge, worked out from the
/// server-only `focus_word`, `focus_nudge` and `word_use` tables.
library;

import 'package:chorus_shared/chorus_shared.dart' show weekStartOf;
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Most focus words a circle pins for one week.
const int maxFocusWords = 3;

/// Longest modelling tip, in characters.
const int maxFocusTipLength = 120;

/// The focus words of [circleSpace] for the week [day] falls in, oldest pin
/// first.
Future<List<FocusWord>> focusWordsOf(
  Session session,
  UuidValue circleSpace,
  DateTime day, {
  Transaction? transaction,
}) => FocusWord.db.find(
  session,
  where: (t) =>
      t.circleSpace.equals(circleSpace) & t.weekStart.equals(weekStartOf(day)),
  orderBy: (t) => t.pinnedAt,
  transaction: transaction,
);

/// How often each tile in [tileIds] was modelled and said in the week from
/// [weekStart], as (modelled, said), from the word log.
Future<Map<UuidValue, (int, int)>> modelledAndSaid(
  Session session,
  UuidValue circleSpace,
  DateTime weekStart,
  Set<UuidValue> tileIds,
) async {
  if (tileIds.isEmpty) return const {};
  final start = weekStartOf(weekStart);
  final end = start.add(const Duration(days: 7));
  final uses = await WordUseRecord.db.find(
    session,
    where: (t) =>
        t.circleSpace.equals(circleSpace) &
        (t.spokenAt >= start) &
        (t.spokenAt < end) &
        t.tileId.inSet(tileIds),
  );
  final counts = {for (final id in tileIds) id: (0, 0)};
  for (final use in uses) {
    final (modelled, said) = counts[use.tileId]!;
    counts[use.tileId] = use.modelled
        ? (modelled + 1, said)
        : (modelled, said + 1);
  }
  return counts;
}

/// Writes this week's nudge for every circle that has focus words, keeps a
/// word log, and has a focus word nobody has modelled yet this week. Returns
/// how many nudges were new.
///
/// Safe to run twice: a circle gets at most one nudge a week, and a second
/// run adds nothing.
Future<int> writeFocusNudges(Session session, {DateTime? now}) async {
  final at = (now ?? DateTime.now()).toUtc();
  final week = weekStartOf(at);
  final pins = await FocusWord.db.find(
    session,
    where: (t) => t.weekStart.equals(week),
    orderBy: (t) => t.pinnedAt,
  );
  final byCircle = <UuidValue, List<FocusWord>>{};
  for (final pin in pins) {
    (byCircle[pin.circleSpace] ??= []).add(pin);
  }
  var added = 0;
  for (final MapEntry(key: circle, value: words) in byCircle.entries) {
    if (await _writeNudge(session, circle, words, week, at)) added++;
  }
  return added;
}

/// When the Thursday nudge is due in the week from [weekStart]: Thursday
/// 09:00 UTC, as the job's cron says.
DateTime nudgeDueAt(DateTime weekStart) =>
    weekStartOf(weekStart).add(const Duration(days: 3, hours: 9));

/// Writes [circle]'s nudge for [week] when its log is on and one of
/// [words] has not been modelled yet. True when a row was added.
Future<bool> _writeNudge(
  Session session,
  UuidValue circle,
  List<FocusWord> words,
  DateTime week,
  DateTime at,
) async {
  if (words.isEmpty) return false;
  // Without the log nobody can tell whether a word was modelled.
  final setting = await WordLogSetting.db.findFirstRow(
    session,
    where: (t) => t.circleSpace.equals(circle),
  );
  if (setting == null || !setting.enabled) return false;
  final counts = await modelledAndSaid(session, circle, week, {
    for (final word in words) word.tileId,
  });
  final quiet = words.where((word) => counts[word.tileId]!.$1 == 0);
  if (quiet.isEmpty) return false;
  final rows = await FocusNudge.db.insert(
    session,
    [
      FocusNudge(
        circleSpace: circle,
        weekStart: week,
        tileId: quiet.first.tileId,
        createdAt: at,
      ),
    ],
    ignoreConflicts: true,
  );
  return rows.isNotEmpty;
}

/// This week's nudge for [circleSpace], or null when there is none, its
/// word is no longer a focus word or on a board, or someone has modelled it
/// since. From Thursday 09:00 UTC a nudge the job has not written yet is
/// written here first, so it works where future calls do not run.
Future<FocusNudgeInfo?> nudgeFor(
  Session session,
  UuidValue circleSpace, {
  DateTime? now,
}) async {
  final at = (now ?? DateTime.now()).toUtc();
  final week = weekStartOf(at);
  Future<FocusNudge?> stored() => FocusNudge.db.findFirstRow(
    session,
    where: (t) => t.circleSpace.equals(circleSpace) & t.weekStart.equals(week),
  );
  var found = await stored();
  if (found == null && !at.isBefore(nudgeDueAt(week))) {
    // Due, but the job has not run (a plan with no future calls): do its
    // work for this circle now, the same way and as safely.
    final words = await focusWordsOf(session, circleSpace, at);
    await _writeNudge(session, circleSpace, words, week, at);
    found = await stored();
  }
  if (found == null) return null;
  final nudge = found;
  final pin = await FocusWord.db.findFirstRow(
    session,
    where: (t) =>
        t.circleSpace.equals(circleSpace) &
        t.weekStart.equals(week) &
        t.tileId.equals(nudge.tileId),
  );
  if (pin == null) return null;
  // The synced tile table, read as the server sees it: filter on the circle.
  final tile = await Tile.db.findFirstRow(
    session,
    where: (t) => t.circleId.equals(circleSpace) & t.id.equals(nudge.tileId),
  );
  if (tile == null || tile.archivedAt != null) return null;
  final counts = await modelledAndSaid(session, circleSpace, week, {
    nudge.tileId,
  });
  if (counts[nudge.tileId]!.$1 > 0) return null;
  return FocusNudgeInfo(
    tileId: nudge.tileId,
    label: tile.label,
    tip: pin.tip,
    weekStart: week,
  );
}
