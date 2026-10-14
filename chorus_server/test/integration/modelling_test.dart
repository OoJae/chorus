/// Endpoint tests for modelling: modelled taps in the word log, "modelled
/// versus said" in the week, focus words, the Thursday nudge and the
/// one-page progress report.
library;

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_server/src/jobs/scheduled_jobs.dart';
import 'package:chorus_server/src/modelling/focus_words.dart';
import 'package:chorus_server/src/progress/progress_routes.dart';
import 'package:chorus_shared/chorus_shared.dart' show weekStartOf;
import 'package:serverpod/protocol.dart' show FutureCallEntry;
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_circles.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given modelling,',
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final circles = Circles(sessionBuilder, endpoints);
      final session = circles.session;
      final thisWeek = weekStartOf(DateTime.now());

      Future<TestCircle> logging() async {
        final circle = await circles.create();
        await circles.logOn(circle);
        return circle;
      }

      List<WordUseEntry> entries(Tile tile, int times) {
        final now = DateTime.now().toUtc();
        return [
          for (var i = 0; i < times; i++)
            WordUseEntry(
              tileId: tile.id!,
              boardId: tile.boardId,
              spokenAt: now.subtract(Duration(seconds: i + 1)),
            ),
        ];
      }

      Future<void> model(TestCircle circle, Tile tile, int times) =>
          endpoints.wordLog.recordModelled(
            circle.guardian.session,
            circle.space,
            entries(tile, times),
          );

      Future<void> say(TestCircle circle, Tile tile, int times) =>
          endpoints.wordLog.record(
            circle.guardian.session,
            circle.space,
            entries(tile, times),
          );

      test('when an adult models words then the week counts them apart from '
          'what the child said.', () async {
        final circle = await logging();
        final [go, help] = await circles.addTiles(circle, ['go', 'help']);
        await model(circle, go, 4);
        await say(circle, go, 1);
        await model(circle, help, 2);

        final report = await endpoints.summary.week(
          circle.guardian.session,
          circle.space,
        );
        // Only the child's word counts as said.
        expect(report.totalUses, 1);
        expect(report.wordsUsed, 1);
        expect(
          [
            for (final row in report.modelled!)
              (row.label, row.modelled, row.said),
          ],
          [('go', 4, 1), ('help', 2, 0)],
        );
        // A modelled word is not "used" by the child yet.
        expect(report.notUsedYet, ['help']);
      });

      test('when the log is off or the word is never logged then modelled '
          'taps are not kept, and a partner may not send them.', () async {
        final circle = await circles.create();
        final [go] = await circles.addTiles(circle, ['go']);
        await expectLater(
          model(circle, go, 1),
          throwsA(isA<WordLogException>()),
        );
        await circles.logOn(circle);
        final [secret] = await circles.addTiles(
          circle,
          ['secret'],
          noLog: true,
          firstCell: 5,
        );
        final kept = await endpoints.wordLog.recordModelled(
          circle.guardian.session,
          circle.space,
          entries(secret, 2),
        );
        expect(kept, 0);
        final partner = await circles.member(circle, CircleRole.partner);
        await expectLater(
          endpoints.wordLog.recordModelled(
            partner.session,
            circle.space,
            entries(go, 1),
          ),
          refusedWith(CircleFailure.notAllowed),
        );
      });

      test('when a therapist pins focus words then every member reads them, '
          'and the limits hold.', () async {
        final circle = await logging();
        final therapist = await circles.member(circle, CircleRole.therapist);
        final teacher = await circles.member(circle, CircleRole.teacher);
        final [go, help, more, stop] = await circles.addTiles(circle, [
          'go',
          'help',
          'more',
          'stop',
        ]);
        FocusWordInfo pin(Tile tile, [String tip = '']) =>
            FocusWordInfo(tileId: tile.id!, tip: tip, weekStart: thisWeek);

        final kept = await endpoints.focus.setWords(
          therapist.session,
          circle.space,
          [pin(help, '  At snack time: "help me open"  '), pin(go)],
        );
        expect(kept.first.tip, 'At snack time: "help me open"');
        final read = await endpoints.focus.words(teacher.session, circle.space);
        expect([for (final w in read) w.tileId], [help.id, go.id]);
        expect(read.first.weekStart, thisWeek);

        await expectLater(
          endpoints.focus.setWords(teacher.session, circle.space, [pin(go)]),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          endpoints.focus.setWords(circle.guardian.session, circle.space, [
            pin(go),
            pin(help),
            pin(more),
            pin(stop),
          ]),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          endpoints.focus.setWords(circle.guardian.session, circle.space, [
            pin(go, 'x' * 121),
          ]),
          refusedWith(CircleFailure.notAllowed),
        );
        final other = await circles.create();
        final [foreign] = await circles.addTiles(other, ['foreign']);
        await expectLater(
          endpoints.focus.setWords(circle.guardian.session, circle.space, [
            pin(foreign),
          ]),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          endpoints.focus.words(circles.user().session, circle.space),
          refusedWith(CircleFailure.notAMember),
        );

        // Replacing keeps only the new set.
        await endpoints.focus.setWords(
          circle.guardian.session,
          circle.space,
          [pin(stop)],
        );
        final now = await endpoints.focus.words(
          circle.guardian.session,
          circle.space,
        );
        expect([for (final w in now) w.tileId], [stop.id]);
      });

      test(
        'when Thursday comes and a focus word was not modelled then one '
        'nudge is written, safely twice, and it goes once modelled.',
        () async {
          final circle = await logging();
          final [go, help] = await circles.addTiles(circle, ['go', 'help']);
          await endpoints.focus.setWords(
            circle.guardian.session,
            circle.space,
            [
              FocusWordInfo(tileId: go.id!, tip: '', weekStart: thisWeek),
              FocusWordInfo(
                tileId: help.id!,
                tip: 'At snack time.',
                weekStart: thisWeek,
              ),
            ],
          );
          await model(circle, go, 1);

          expect(
            await endpoints.focus.nudge(circle.guardian.session, circle.space),
            isNull,
          );
          final first = await writeFocusNudges(session);
          expect(first, greaterThanOrEqualTo(1));
          await writeFocusNudges(session);
          final rows = await FocusNudge.db.find(
            session,
            where: (t) => t.circleSpace.equals(circle.space),
          );
          expect(rows, hasLength(1));

          final teacher = await circles.member(circle, CircleRole.teacher);
          final nudge = await endpoints.focus.nudge(
            teacher.session,
            circle.space,
          );
          expect(nudge?.label, 'help');
          expect(nudge?.tip, 'At snack time.');

          await model(circle, help, 1);
          expect(
            await endpoints.focus.nudge(circle.guardian.session, circle.space),
            isNull,
          );
        },
      );

      test('when a circle keeps no log then no nudge is written.', () async {
        final circle = await circles.create();
        final [go] = await circles.addTiles(circle, ['go']);
        await endpoints.focus.setWords(circle.guardian.session, circle.space, [
          FocusWordInfo(tileId: go.id!, tip: '', weekStart: thisWeek),
        ]);
        await writeFocusNudges(session);
        final rows = await FocusNudge.db.find(
          session,
          where: (t) => t.circleSpace.equals(circle.space),
        );
        expect(rows, isEmpty);
      });

      test('when a guardian makes a progress report then the page shows the '
          'counts and focus words, and a teacher may not make one.', () async {
        final circle = await logging();
        final [go, help, _] = await circles.addTiles(circle, [
          'go',
          'help',
          'swing',
        ]);
        await endpoints.focus.setWords(circle.guardian.session, circle.space, [
          FocusWordInfo(
            tileId: help.id!,
            tip: 'At bath time: <more>',
            weekStart: thisWeek,
          ),
        ]);
        await model(circle, help, 3);
        await say(circle, help, 1);
        await say(circle, go, 2);

        final token = await endpoints.progress.makeReport(
          circle.guardian.session,
          circle.space,
        );
        final url = await endpoints.progress.reportUrl(
          circle.guardian.session,
          token,
        );
        expect(url, endsWith('/report/$token'));

        final response = await progressResponse(session, token);
        expect(response.statusCode, 200);
        expect(
          response.headers['Content-Security-Policy']?.single,
          contains("default-src 'none'"),
        );
        final html = await response.readAsString();
        expect(html, contains('Maya: progress'));
        expect(html, contains('different words'));
        expect(html, contains('<td class="w">help</td><td>3</td><td>1</td>'));
        expect(html, contains('At bath time: &lt;more&gt;'));
        expect(html, contains('swing'));
        expect(html, isNot(contains('<more>')));

        final teacher = await circles.member(circle, CircleRole.teacher);
        await expectLater(
          endpoints.progress.makeReport(teacher.session, circle.space),
          refusedWith(CircleFailure.notAllowed),
        );
      });

      test('when a report link is wrong or expired then it reads as not '
          'here.', () async {
        final circle = await logging();
        final token = await endpoints.progress.makeReport(
          circle.guardian.session,
          circle.space,
        );
        final link = await ProgressReportLink.db.findFirstRow(
          session,
          where: (t) => t.token.equals(token),
        );
        await ProgressReportLink.db.updateRow(
          session,
          link!.copyWith(expiresAt: DateTime.now().toUtc()),
          columns: (t) => [t.expiresAt],
        );
        for (final bad in [token, 'nope', 'A' * 43]) {
          final response = await progressResponse(session, bad);
          expect(response.statusCode, 410);
          expect(
            await response.readAsString(),
            contains('This report is not here'),
          );
        }
      });
    },
  );

  withServerpod(
    'Given a server with future calls,',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final session = sessionBuilder.build();

      test('when the server starts twice then the Thursday nudge is '
          'scheduled once, for a Thursday.', () async {
        await scheduleJobs(session.serverpod);
        await scheduleJobs(session.serverpod);
        final calls = await FutureCallEntry.db.find(
          session,
          where: (t) => t.identifier.equals(focusNudgeJob),
        );
        expect(calls, hasLength(1));
        expect(calls.single.time.weekday, DateTime.thursday);
      });
    },
  );
}
