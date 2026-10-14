/// "This week", over the server's `summary.week`.
library;

import 'dart:async';

import 'package:chorus_client/chorus_client.dart' hide CircleRole;
import 'package:chorus_shared/chorus_shared.dart' show ModelledCount;
import 'package:chorus_ui/contracts.dart' show CircleRole, SyncStatus;
import 'package:chorus_ui/contracts_wordlog.dart';

/// Asks the server for the circle's week so far.
///
/// Only guardians and therapists may see it, and only while the log is on;
/// for anyone else, with the log off, or with the device paused or out of
/// reach, the answer is null without a call. Any failure is null too.
class ServerWeekSummary implements WeekSummarySource {
  /// [week] is the server's call for the circle and this week. [logOn]
  /// says whether the circle's log is on, as this device knows it.
  ServerWeekSummary({
    required this._week,
    this.mayView = true,
    this._logOn,
    this._sync,
    this.timeout = const Duration(seconds: 20),
  });

  /// The source the app uses for [circleSpace]. [log] is the circle's word
  /// log on this device, when there is one.
  factory ServerWeekSummary.forClient(
    Client client, {
    required UuidValue circleSpace,
    required CircleRole role,
    WordLog? log,
    SyncStatus? sync,
  }) => ServerWeekSummary(
    week: () => client.summary.week(circleSpace),
    mayView: role == CircleRole.guardian || role == CircleRole.therapist,
    logOn: log == null ? null : () => log.enabled,
    sync: sync,
  );

  final Future<WeekReport> Function() _week;
  final bool Function()? _logOn;
  final SyncStatus? _sync;

  /// False for a role the server would refuse: a teacher or a partner.
  final bool mayView;

  /// Longest wait for the answer.
  final Duration timeout;

  @override
  Future<WeekSummary?> thisWeek() async {
    if (!mayView) return null;
    if (_logOn?.call() == false) return null;
    if (_sync?.workingOffline ?? false) return null;
    try {
      return weekSummaryOf(await _week().timeout(timeout));
    } catch (_) {
      return null;
    }
  }
}

/// The server's [report] as the screens read it.
WeekSummary weekSummaryOf(WeekReport report) => WeekSummary(
  weekStart: report.weekStart.toUtc(),
  topWords: [
    for (final word in report.topWords) WordCount(word.label, word.count),
  ],
  firstTimeWords: List.unmodifiable(report.firstTimeWords),
  addedWords: List.unmodifiable(report.addedWords),
  notUsedYet: List.unmodifiable(report.notUsedYet),
  totalUses: report.totalUses,
  wordsUsed: report.wordsUsed,
  modelled: [
    for (final row in report.modelled ?? const <ModelledTally>[])
      ModelledCount(row.label, modelled: row.modelled, said: row.said),
  ],
);
