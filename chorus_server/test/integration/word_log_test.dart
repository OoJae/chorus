/// Endpoint tests for the word log: off until a guardian turns it on, only a
/// guardian changes or deletes it, and what it takes is limited to the
/// circle's own tiles, at sensible times, in sensible amounts.
library;

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_server/src/wordlog/word_log_endpoint.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_circles.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Matches a [WordLogException] carrying [failure].
Matcher loggedNothing(WordLogFailure failure) => throwsA(
  isA<WordLogException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  withServerpod(
    'Given the word log endpoint,',
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final circles = Circles(sessionBuilder, endpoints);
      final session = circles.session;
      final log = endpoints.wordLog;

      /// [tile] spoken at [at] (default: a minute ago).
      WordUseEntry spoken(Tile tile, {DateTime? at}) => WordUseEntry(
        tileId: tile.id!,
        boardId: tile.boardId,
        spokenAt:
            at ?? DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );

      Future<int> rows(UuidValue space) => WordUseRecord.db.count(
        session,
        where: (t) => t.circleSpace.equals(space),
      );

      /// A circle with the log on for the last month and three tiles.
      Future<(TestCircle, List<Tile>)> logging() async {
        final circle = await circles.create();
        await circles.logOn(circle);
        final tiles = await circles.addTiles(circle, ['more', 'go', 'stop']);
        return (circle, tiles);
      }

      Future<WordLogSetting> settingOf(TestCircle circle) async =>
          (await WordLogSetting.db.findFirstRow(
            session,
            where: (t) => t.circleSpace.equals(circle.space),
          ))!;

      test('when nobody is signed in then every method is refused.', () async {
        final space = const Uuid().v7obj();
        await expectLater(log.status(sessionBuilder, space), unauthenticated);
        await expectLater(
          log.setEnabled(sessionBuilder, space, true),
          unauthenticated,
        );
        await expectLater(
          log.record(sessionBuilder, space, []),
          unauthenticated,
        );
        await expectLater(
          log.deleteAll(sessionBuilder, space),
          unauthenticated,
        );
      });

      test('when a circle is new then its log is off, and only the guardian '
          'is told they may change it.', () async {
        final circle = await circles.create();
        final therapist = await circles.member(circle, CircleRole.therapist);
        final partner = await circles.member(circle, CircleRole.partner);

        final asGuardian = await log.status(
          circle.guardian.session,
          circle.space,
        );
        expect(asGuardian.enabled, isFalse);
        expect(asGuardian.canChange, isTrue);
        for (final other in [therapist, partner]) {
          final status = await log.status(other.session, circle.space);
          expect(status.enabled, isFalse);
          expect(status.canChange, isFalse);
        }
        await expectLater(
          log.status(circles.user().session, circle.space),
          refusedWith(CircleFailure.notAMember),
        );
      });

      test('when the guardian turns it on and off then every member sees '
          'it, and nobody else may change it.', () async {
        final circle = await circles.create();
        final teacher = await circles.member(circle, CircleRole.teacher);
        final therapist = await circles.member(circle, CircleRole.therapist);
        final partner = await circles.member(circle, CircleRole.partner);

        final on = await log.setEnabled(
          circle.guardian.session,
          circle.space,
          true,
        );
        expect(on.enabled, isTrue);
        expect((await log.status(teacher.session, circle.space)).enabled, true);
        final setting = await WordLogSetting.db.findFirstRow(
          session,
          where: (t) => t.circleSpace.equals(circle.space),
        );
        expect(setting!.changedBy, circle.guardian.id);

        for (final other in [teacher, therapist, partner]) {
          await expectLater(
            log.setEnabled(other.session, circle.space, false),
            refusedWith(CircleFailure.notAllowed),
          );
        }
        await expectLater(
          log.setEnabled(circles.user().session, circle.space, false),
          refusedWith(CircleFailure.notAMember),
        );
        expect((await log.status(teacher.session, circle.space)).enabled, true);

        await log.setEnabled(circle.guardian.session, circle.space, false);
        expect(
          (await log.status(teacher.session, circle.space)).enabled,
          isFalse,
        );
      });

      test('when the log is off then words are refused and nothing is '
          'kept.', () async {
        final circle = await circles.create();
        final tiles = await circles.addTiles(circle, ['more']);

        await expectLater(
          log.record(circle.guardian.session, circle.space, [
            spoken(tiles.first),
          ]),
          loggedNothing(WordLogFailure.off),
        );

        await log.setEnabled(circle.guardian.session, circle.space, true);
        await log.setEnabled(circle.guardian.session, circle.space, false);
        await expectLater(
          log.record(circle.guardian.session, circle.space, [
            spoken(tiles.first),
          ]),
          loggedNothing(WordLogFailure.off),
        );
        expect(await rows(circle.space), 0);
      });

      test('when the log is on then an editing member\'s words are kept as '
          'tile, board and time, and nothing else.', () async {
        final (circle, tiles) = await logging();
        final teacher = await circles.member(circle, CircleRole.teacher);
        final at = DateTime.utc(2026, 10, 14, 9, 30);
        final now = DateTime.now().toUtc();
        final when = at.isAfter(now) ? now : at;

        final added = await log.record(teacher.session, circle.space, [
          spoken(tiles[0], at: when),
          spoken(tiles[1], at: when.add(const Duration(seconds: 2))),
        ]);

        expect(added, 2);
        final kept = await WordUseRecord.db.find(
          session,
          where: (t) => t.circleSpace.equals(circle.space),
          orderBy: (t) => t.spokenAt,
        );
        expect(kept.map((r) => r.tileId), [tiles[0].id, tiles[1].id]);
        expect(kept.map((r) => r.boardId).toSet(), {circle.board});
        expect(kept.first.spokenAt, when);
        expect(
          kept.first.receivedAt.difference(now).inSeconds.abs(),
          lessThan(60),
        );
        // Ids, times and whether an adult modelled it only: the table has
        // no column for a word.
        expect(WordUseRecord.t.columns.map((c) => c.columnName).toSet(), {
          'id',
          'circleSpace',
          'tileId',
          'boardId',
          'spokenAt',
          'receivedAt',
          'modelled',
        });
        expect(kept.every((r) => !r.modelled), isTrue);
      });

      test('when a partner or a stranger sends words then they are '
          'refused.', () async {
        final (circle, tiles) = await logging();
        final partner = await circles.member(circle, CircleRole.partner);

        await expectLater(
          log.record(partner.session, circle.space, [spoken(tiles.first)]),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          log.record(circles.user().session, circle.space, [
            spoken(tiles.first),
          ]),
          refusedWith(CircleFailure.notAMember),
        );
        expect(await rows(circle.space), 0);
      });

      test('when a batch is sent twice then each word is kept once.', () async {
        final (circle, tiles) = await logging();
        final batch = [spoken(tiles[0]), spoken(tiles[2])];

        expect(
          await log.record(circle.guardian.session, circle.space, batch),
          2,
        );
        expect(
          await log.record(circle.guardian.session, circle.space, batch),
          0,
        );
        expect(await rows(circle.space), 2);
      });

      test('when a call has 200 words it is taken, and 201 are refused '
          'whole.', () async {
        final (circle, tiles) = await logging();
        final start = DateTime.now().toUtc().subtract(const Duration(hours: 1));
        List<WordUseEntry> many(int count, int offset) => [
          for (var i = 0; i < count; i++)
            spoken(
              tiles[i % 3],
              at: start.add(Duration(seconds: offset + i)),
            ),
        ];

        await expectLater(
          log.record(
            circle.guardian.session,
            circle.space,
            many(maxWordUsesPerCall + 1, 0),
          ),
          loggedNothing(WordLogFailure.tooMany),
        );
        expect(await rows(circle.space), 0);
        expect(
          await log.record(
            circle.guardian.session,
            circle.space,
            many(maxWordUsesPerCall, 1000),
          ),
          maxWordUsesPerCall,
        );
        expect(await log.record(circle.guardian.session, circle.space, []), 0);
      });

      test('when a time is too far ahead or too old then the whole call is '
          'refused, and the edges are taken.', () async {
        final (circle, tiles) = await logging();
        final now = DateTime.now().toUtc();
        final good = spoken(tiles[0]);

        for (final bad in [
          now.add(wordUseClockSlack + const Duration(minutes: 1)),
          now.subtract(wordUseMaxAge + const Duration(hours: 1)),
        ]) {
          await expectLater(
            log.record(circle.guardian.session, circle.space, [
              good,
              spoken(tiles[1], at: bad),
            ]),
            loggedNothing(WordLogFailure.badTime),
            reason: '$bad',
          );
        }
        expect(await rows(circle.space), 0);

        expect(
          await log.record(circle.guardian.session, circle.space, [
            spoken(tiles[0], at: now.add(const Duration(minutes: 4))),
            spoken(tiles[1], at: now.subtract(const Duration(days: 29))),
          ]),
          2,
        );
      });

      test('when a tile is not one of the circle\'s then the whole call is '
          'refused.', () async {
        final (circle, tiles) = await logging();
        final (_, foreign) = await logging();
        final invented = WordUseEntry(
          tileId: const Uuid().v7obj(),
          boardId: circle.board,
          spokenAt: DateTime.now().toUtc(),
        );

        for (final stranger in [spoken(foreign.first), invented]) {
          await expectLater(
            log.record(circle.guardian.session, circle.space, [
              spoken(tiles.first),
              stranger,
            ]),
            loggedNothing(WordLogFailure.unknownTile),
          );
        }
        expect(await rows(circle.space), 0);
      });

      test('when a tile is marked never to be logged then its words are '
          'dropped and the rest kept.', () async {
        final (circle, tiles) = await logging();
        final quiet = await circles.addTiles(
          circle,
          ['secret'],
          noLog: true,
          firstCell: 10,
        );

        expect(
          await log.record(circle.guardian.session, circle.space, [
            spoken(tiles.first),
            spoken(quiet.first),
          ]),
          1,
        );
        expect(
          (await WordUseRecord.db.find(
            session,
            where: (t) => t.circleSpace.equals(circle.space),
          )).single.tileId,
          tiles.first.id,
        );
      });

      test('when the guardian deletes the log then every word and stored '
          'week goes, the count comes back, and other circles keep '
          'theirs.', () async {
        final (circle, tiles) = await logging();
        final (other, otherTiles) = await logging();
        await log.record(circle.guardian.session, circle.space, [
          spoken(tiles[0]),
          spoken(tiles[1]),
          spoken(tiles[2]),
        ]);
        await log.record(other.guardian.session, other.space, [
          spoken(otherTiles[0]),
        ]);
        final report = await endpoints.summary.week(
          circle.guardian.session,
          circle.space,
        );
        await WeeklySummary.db.insertRow(
          session,
          WeeklySummary(
            circleSpace: circle.space,
            weekStart: report.weekStart,
            report: report,
          ),
        );

        expect(await log.deleteAll(circle.guardian.session, circle.space), 3);

        expect(await rows(circle.space), 0);
        expect(await rows(other.space), 1);
        expect(
          await WeeklySummary.db.count(
            session,
            where: (t) => t.circleSpace.equals(circle.space),
          ),
          0,
        );
        expect(await log.deleteAll(circle.guardian.session, circle.space), 0);
      });

      test('when the guardian deletes the log then the words sitters tapped '
          'and the progress report links go too, and other circles keep '
          'theirs.', () async {
        final (circle, tiles) = await logging();
        final (other, _) = await logging();
        await log.record(circle.guardian.session, circle.space, [
          spoken(tiles[0]),
        ]);
        final now = DateTime.now().toUtc();
        for (final space in [circle.space, other.space]) {
          await SitterTap.db.insertRow(
            session,
            SitterTap(circleSpace: space, label: 'tired', tappedAt: now),
          );
        }
        final token = await endpoints.progress.makeReport(
          circle.guardian.session,
          circle.space,
        );
        await endpoints.progress.makeReport(
          other.guardian.session,
          other.space,
        );
        expect(
          await endpoints.sitter.recentTaps(
            circle.guardian.session,
            circle.space,
          ),
          hasLength(1),
        );

        expect(await log.deleteAll(circle.guardian.session, circle.space), 1);

        expect(
          await endpoints.sitter.recentTaps(
            circle.guardian.session,
            circle.space,
          ),
          isEmpty,
        );
        expect(
          await SitterTap.db.count(
            session,
            where: (t) => t.circleSpace.equals(circle.space),
          ),
          0,
        );
        expect(
          await ProgressReportLink.db.findFirstRow(
            session,
            where: (t) => t.token.equals(token),
          ),
          isNull,
        );
        expect(
          await SitterTap.db.count(
            session,
            where: (t) => t.circleSpace.equals(other.space),
          ),
          1,
        );
        expect(
          await ProgressReportLink.db.count(
            session,
            where: (t) => t.circleSpace.equals(other.space),
          ),
          1,
        );
      });

      test('when a device sends words it still held from before the delete '
          'then they are not taken again, and later words are.', () async {
        final (circle, tiles) = await logging();
        final therapist = await circles.member(circle, CircleRole.therapist);
        // The child's device sent this, but never heard that it arrived.
        final batch = [spoken(tiles[0]), spoken(tiles[1])];
        expect(await log.record(therapist.session, circle.space, batch), 2);

        expect(await log.deleteAll(circle.guardian.session, circle.space), 2);
        expect((await settingOf(circle)).changedBy, circle.guardian.id);

        expect(await log.record(therapist.session, circle.space, batch), 0);
        expect(await rows(circle.space), 0);
        expect(
          await WeeklySummary.db.count(
            session,
            where: (t) => t.circleSpace.equals(circle.space),
          ),
          0,
        );

        // The log is still on: what is said from now on is kept.
        expect(
          await log.record(therapist.session, circle.space, [
            spoken(tiles[2], at: DateTime.now().toUtc()),
          ]),
          1,
        );
        expect(await rows(circle.space), 1);
      });

      test('when the guardian turns the log on then words spoken before are '
          'not taken, and turning it on again keeps its time.', () async {
        final circle = await circles.create();
        final [word] = await circles.addTiles(circle, ['more']);
        final hourAgo = DateTime.now().toUtc().subtract(
          const Duration(hours: 1),
        );

        await log.setEnabled(circle.guardian.session, circle.space, true);
        final turnedOn = (await settingOf(circle)).changedAt;
        expect(
          await log.record(circle.guardian.session, circle.space, [
            spoken(word, at: hourAgo),
          ]),
          0,
        );

        await log.setEnabled(circle.guardian.session, circle.space, true);
        expect((await settingOf(circle)).changedAt, turnedOn);
        expect(
          await log.record(circle.guardian.session, circle.space, [
            spoken(word, at: DateTime.now().toUtc()),
          ]),
          1,
        );

        // Words spoken while it was off are not taken once it is back on.
        await log.setEnabled(circle.guardian.session, circle.space, false);
        final whileOff = DateTime.now().toUtc();
        await log.setEnabled(circle.guardian.session, circle.space, true);
        expect(
          await log.record(circle.guardian.session, circle.space, [
            spoken(word, at: whileOff),
          ]),
          0,
        );
        expect(await rows(circle.space), 1);
      });

      test('when anyone but the guardian deletes the log then nothing '
          'goes.', () async {
        final (circle, tiles) = await logging();
        await log.record(circle.guardian.session, circle.space, [
          spoken(tiles[0]),
        ]);

        for (final role in [
          CircleRole.therapist,
          CircleRole.teacher,
          CircleRole.partner,
        ]) {
          final other = await circles.member(circle, role);
          await expectLater(
            log.deleteAll(other.session, circle.space),
            refusedWith(CircleFailure.notAllowed),
            reason: role.name,
          );
        }
        await expectLater(
          log.deleteAll(circles.user().session, circle.space),
          refusedWith(CircleFailure.notAMember),
        );
        expect(await rows(circle.space), 1);
      });
    },
  );
}
