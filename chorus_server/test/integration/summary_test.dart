/// Endpoint tests for "This week": who may see it, that the sums come out
/// right from the word log and the tiles, and that a week the weekly job
/// stored is read rather than worked out again.
library;

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_server/src/summary/week_summaries.dart';
import 'package:chorus_server/src/summary/weekly_summary_future_call.dart';
import 'package:chorus_shared/chorus_shared.dart' show weekStartOf;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_circles.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given the summary endpoint,',
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final circles = Circles(sessionBuilder, endpoints);
      final session = circles.session;

      // Last week, so every use the test sends is in the past and inside
      // the 30 days the log accepts.
      final thisWeek = weekStartOf(DateTime.now());
      final lastWeek = thisWeek.subtract(const Duration(days: 7));

      /// A circle with the log on since before last week.
      Future<TestCircle> logging() async {
        final circle = await circles.create();
        await circles.logOn(circle);
        return circle;
      }

      /// [tile] spoken at [at], through the endpoint as the app sends it.
      Future<void> say(TestCircle circle, Tile tile, DateTime at) async {
        await endpoints.wordLog.record(circle.guardian.session, circle.space, [
          WordUseEntry(tileId: tile.id!, boardId: tile.boardId, spokenAt: at),
        ]);
      }

      /// A report nobody could work out from an empty log.
      WeekReport invented(DateTime weekStart) => WeekReport(
        weekStart: weekStart,
        topWords: [WordTally(label: 'stored', count: 99)],
        firstTimeWords: ['stored'],
        addedWords: [],
        notUsedYet: [],
        totalUses: 99,
        wordsUsed: 1,
        computedAt: DateTime.utc(2026, 1, 1),
      );

      Future<List<DateTime>> storedWeeks(TestCircle circle) async => [
        for (final row in await WeeklySummary.db.find(
          session,
          where: (t) => t.circleSpace.equals(circle.space),
          orderBy: (t) => t.weekStart,
        ))
          row.weekStart,
      ];

      test('when nobody is signed in then it is refused.', () async {
        await expectLater(
          endpoints.summary.week(sessionBuilder, const Uuid().v7obj()),
          unauthenticated,
        );
      });

      test('when a guardian or a therapist asks then they get the week, and '
          'a teacher, a partner and a stranger are refused.', () async {
        final circle = await logging();
        final therapist = await circles.member(circle, CircleRole.therapist);
        final teacher = await circles.member(circle, CircleRole.teacher);
        final partner = await circles.member(circle, CircleRole.partner);

        for (final allowed in [circle.guardian, therapist]) {
          final report = await endpoints.summary.week(
            allowed.session,
            circle.space,
          );
          expect(report.weekStart, thisWeek);
          expect(report.totalUses, 0);
        }
        for (final other in [teacher, partner]) {
          await expectLater(
            endpoints.summary.week(other.session, circle.space),
            refusedWith(CircleFailure.notAllowed),
          );
        }
        await expectLater(
          endpoints.summary.week(circles.user().session, circle.space),
          refusedWith(CircleFailure.notAMember),
        );
      });

      test('when the log holds a week then the sums are right: top words, '
          'first-time words, words added, words not used yet and the '
          'totals.', () async {
        final circle = await logging();
        final before = lastWeek.subtract(const Duration(days: 3));
        final [more, go, stop, _] = await circles.addTiles(circle, [
          'more',
          'go',
          'stop',
          'want',
        ], createdAt: before);
        final [juice] = await circles.addTiles(
          circle,
          ['juice'],
          createdAt: lastWeek.add(const Duration(days: 1)),
          firstCell: 10,
        );
        // Made after the week, so not a word that week could have used.
        await circles.addTiles(circle, ['later'], firstCell: 20);

        DateTime day(int d, [int minute = 0]) =>
            lastWeek.add(Duration(days: d, minutes: minute));
        await say(circle, go, lastWeek.subtract(const Duration(days: 2)));
        for (var i = 0; i < 3; i++) {
          await say(circle, more, day(1, i));
        }
        await say(circle, go, day(2));
        await say(circle, go, day(3));
        await say(circle, juice, day(4));
        // This week's word does not count for last week.
        await say(circle, stop, DateTime.now().toUtc());

        final report = await endpoints.summary.week(
          circle.guardian.session,
          circle.space,
          day(3, 30),
        );

        expect(report.weekStart, lastWeek);
        expect(
          [for (final word in report.topWords) (word.label, word.count)],
          [('more', 3), ('go', 2), ('juice', 1)],
        );
        expect(report.firstTimeWords, ['juice', 'more']);
        expect(report.addedWords, ['juice']);
        expect(report.notUsedYet, ['stop', 'want']);
        expect(report.totalUses, 6);
        expect(report.wordsUsed, 3);
      });

      test('when the weekly job stored a week then that week is read as '
          'stored, and any other week is worked out.', () async {
        final circle = await logging();
        await WeeklySummary.db.insertRow(
          session,
          WeeklySummary(
            circleSpace: circle.space,
            weekStart: lastWeek,
            report: invented(lastWeek),
          ),
        );

        final stored = await endpoints.summary.week(
          circle.guardian.session,
          circle.space,
          lastWeek.add(const Duration(days: 2)),
        );
        final worked = await endpoints.summary.week(
          circle.guardian.session,
          circle.space,
        );

        expect(stored.totalUses, 99);
        expect(stored.topWords.single.label, 'stored');
        expect(stored.computedAt, DateTime.utc(2026, 1, 1));
        expect(worked.weekStart, thisWeek);
        expect(worked.totalUses, 0);
      });

      test('when the weekly job runs then last week is stored for circles '
          'with the log on and not for others, and running it again '
          'replaces it.', () async {
        final on = await logging();
        final off = await circles.create();
        final [word] = await circles.addTiles(on, [
          'more',
        ], createdAt: lastWeek.subtract(const Duration(days: 1)));
        await say(on, word, lastWeek.add(const Duration(days: 1)));

        final enabled = await WordLogSetting.db.count(
          session,
          where: (t) => t.enabled.equals(true),
        );
        expect(await storeLastWeekForAll(session), enabled);
        expect(await storedWeeks(on), [lastWeek]);
        expect(await storedWeeks(off), isEmpty);

        final first = await endpoints.summary.week(
          on.guardian.session,
          on.space,
          lastWeek,
        );
        expect(first.totalUses, 1);
        expect(first.topWords.single.label, 'more');

        // The weekly job runs the same work.
        await WeeklySummaryFutureCall().storeLastWeek(session);
        expect(await storedWeeks(on), [lastWeek]);
        final second = await endpoints.summary.week(
          on.guardian.session,
          on.space,
          lastWeek,
        );
        expect(second.computedAt.isAfter(first.computedAt), isTrue);
      });

      test('when a late word arrives for a stored week then that week and '
          'later ones are worked out again, and earlier ones are '
          'kept.', () async {
        final circle = await logging();
        final [word] = await circles.addTiles(circle, [
          'more',
        ], createdAt: lastWeek.subtract(const Duration(days: 21)));
        final weekBefore = lastWeek.subtract(const Duration(days: 7));
        for (final week in [weekBefore, lastWeek, thisWeek]) {
          await WeeklySummary.db.insertRow(
            session,
            WeeklySummary(
              circleSpace: circle.space,
              weekStart: week,
              report: invented(week),
            ),
          );
        }

        await say(circle, word, lastWeek.add(const Duration(days: 2)));

        expect(await storedWeeks(circle), [weekBefore]);
        final report = await endpoints.summary.week(
          circle.guardian.session,
          circle.space,
          lastWeek,
        );
        expect(report.totalUses, 1);
        expect(report.firstTimeWords, ['more']);
      });
    },
  );
}
