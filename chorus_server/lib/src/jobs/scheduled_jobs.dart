import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../generated/future_calls.dart';

/// Identifier of the weekly "This week" job.
const String weeklySummaryJob = 'chorus-weekly-summary';

/// Identifier of the daily cleanup of expired links.
const String snapshotCleanupJob = 'chorus-snapshot-cleanup';

/// Mondays at 02:00 UTC, once the week before has ended everywhere.
const String weeklySummaryCron = '0 2 * * 1';

/// Every day at 03:30 UTC.
const String snapshotCleanupCron = '30 3 * * *';

/// Schedules the weekly summary and the daily cleanup. Call after the
/// server has started.
///
/// Does nothing where future calls are turned off, and never throws: a
/// failure is written to the log and the server runs on, because every job
/// has a twin that does the same work on demand.
///
/// The identifier is not unique in the future-call table, so each job is
/// cancelled before it is scheduled; otherwise every restart would add
/// another copy.
Future<void> scheduleJobs(Serverpod pod) async {
  if (pod.config.database == null || !pod.config.futureCall.enabled) return;
  try {
    final calls = pod.futureCalls;
    await calls.cancel(weeklySummaryJob);
    await calls
        .callRecurring(identifier: weeklySummaryJob)
        .cron(weeklySummaryCron)
        .weeklySummary
        .storeLastWeek();
    await calls.cancel(snapshotCleanupJob);
    await calls
        .callRecurring(identifier: snapshotCleanupJob)
        .cron(snapshotCleanupCron)
        .snapshotCleanup
        .sweep();
  } catch (error) {
    // The type only, as for the demo seed.
    stderr.writeln('Scheduling jobs failed: ${error.runtimeType}');
  }
}
