/// Tests for the scheduled jobs: each is scheduled once however often the
/// server starts, a server with future calls turned off starts without
/// them, and the daily cleanup removes only links that stopped working.
library;

import 'dart:convert';

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_server/src/jobs/scheduled_jobs.dart';
import 'package:chorus_server/src/printing/snapshot_cleanup_future_call.dart';
import 'package:chorus_server/src/printing/snapshots.dart';
import 'package:serverpod/protocol.dart' show FutureCallEntry;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  // First, so the generated future calls have never been set up in this
  // isolate, as on a server started with them turned off.
  withServerpod(
    'Given a server with future calls turned off,',
    rollbackDatabase: RollbackDatabase.disabled,
    configOverride: (config) =>
        config.copyWith(futureCall: const FutureCallConfig(enabled: false)),
    (sessionBuilder, endpoints) {
      final session = sessionBuilder.build();

      test('when the jobs are scheduled then nothing is scheduled and '
          'nothing fails.', () async {
        await scheduleJobs(session.serverpod);

        expect(
          await FutureCallEntry.db.count(
            session,
            where: (t) =>
                t.identifier.inSet({weeklySummaryJob, snapshotCleanupJob}),
          ),
          0,
        );
      });
    },
  );

  withServerpod(
    'Given a server with future calls,',
    // Scheduling writes through the server's own session, outside the
    // test's transaction.
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final session = sessionBuilder.build();

      Future<List<FutureCallEntry>> scheduled(String identifier) =>
          FutureCallEntry.db.find(
            session,
            where: (t) => t.identifier.equals(identifier),
          );

      test('when the server starts three times then each job is scheduled '
          'once, for the next time its cron names.', () async {
        for (var start = 0; start < 3; start++) {
          await scheduleJobs(session.serverpod);
        }

        final weekly = await scheduled(weeklySummaryJob);
        final daily = await scheduled(snapshotCleanupJob);
        expect(weekly, hasLength(1));
        expect(daily, hasLength(1));
        expect(weekly.single.name, 'WeeklySummaryStoreLastWeekFutureCall');
        expect(daily.single.name, 'SnapshotCleanupSweepFutureCall');
        final now = DateTime.now().toUtc();
        expect(weekly.single.time.isAfter(now), isTrue);
        expect(weekly.single.time.weekday, DateTime.monday);
        expect(
          weekly.single.time.isBefore(now.add(const Duration(days: 8))),
          isTrue,
        );
        expect(
          daily.single.time.isBefore(now.add(const Duration(days: 1))),
          isTrue,
        );
      });

      test('when the daily sweep runs then expired and withdrawn links go, '
          'and links still open stay.', () async {
        final now = DateTime.now().toUtc();
        SharedSnapshot row(String token, Duration fromNow) => SharedSnapshot(
          token: token,
          circleSpace: const Uuid().v7obj(),
          boardJson: jsonEncode({'rows': 1, 'cols': 1, 'tiles': <Object>[]}),
          createdBy: const Uuid().v7obj(),
          createdAt: now.subtract(const Duration(days: 1)),
          expiresAt: now.add(fromNow),
        );
        final open = row(newPrintToken(), const Duration(days: 3));
        final expired = row(newPrintToken(), const Duration(hours: -1));
        final withdrawn = row(newPrintToken(), const Duration(seconds: -1));
        await SharedSnapshot.db.insert(session, [open, expired, withdrawn]);

        await SnapshotCleanupFutureCall().sweep(session);

        final left = await SharedSnapshot.db.find(
          session,
          where: (t) => t.token.inSet({
            open.token,
            expired.token,
            withdrawn.token,
          }),
        );
        expect(left.map((s) => s.token), [open.token]);
        expect(await deleteExpiredSnapshots(session), 0);
      });
    },
  );
}
