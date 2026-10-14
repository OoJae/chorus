/// The view-only page reports back: taps are kept only while the word log
/// is on, never for a word kept out of the log, at most the word and the
/// time, and only guardians and therapists read them.
library;

import 'dart:convert';

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_server/src/sharing/sharing_routes.dart';
import 'package:chorus_server/src/sitter/sitter_taps.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_circles.dart';
import 'test_tools/serverpod_test_tools.dart';

/// A 6 x 6 board with "tired" at 0:0 and "secret" at 0:1.
String board() => jsonEncode({
  'childName': 'Maya',
  'name': 'Home',
  'rows': 6,
  'cols': 6,
  'tiles': [
    {'row': 0, 'col': 0, 'label': 'tired', 'colorKey': 'descriptor'},
    {'row': 0, 'col': 1, 'label': 'secret'},
  ],
});

void main() {
  withServerpod(
    'Given a view-only link,',
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final circles = Circles(sessionBuilder, endpoints);
      final session = circles.session;

      setUp(resetTapLimits);

      Future<(TestCircle, String)> shared({bool logOn = true}) async {
        final circle = await circles.create();
        if (logOn) await circles.logOn(circle);
        final link = await endpoints.sharing.publishViewOnly(
          circle.guardian.session,
          circle.space,
          board(),
        );
        return (circle, link.token);
      }

      test('with the log on, a tap is kept as the word and the time, and '
          'the page may send it', () async {
        final (circle, token) = await shared();
        final response = await viewOnlyResponse(session, token);
        final html = await response.readAsString();
        expect(html, contains('<body data-report="1">'));
        expect(html, contains('data-cell="0:0"'));
        expect(html, contains('fetch(url'));
        final csp = response.headers['content-security-policy']!.single;
        expect(csp, contains("connect-src 'self'"));

        expect(await recordSitterTap(session, token, '0:0'), isTrue);
        final taps = await endpoints.sitter.recentTaps(
          circle.guardian.session,
          circle.space,
        );
        expect(taps.map((t) => t.label), ['tired']);
      });

      test(
        'with the log off, nothing is kept and the page sends nothing',
        () async {
          final (circle, token) = await shared(logOn: false);
          final response = await viewOnlyResponse(session, token);
          final html = await response.readAsString();
          expect(html, isNot(contains('<body data-report')));
          expect(html, isNot(contains('data-cell="')));
        expect(html, isNot(contains('fetch(')));
          final csp = response.headers['content-security-policy']!.single;
          expect(csp, isNot(contains('connect-src')));
          expect(await recordSitterTap(session, token, '0:0'), isFalse);
          final rows = await SitterTap.db.find(
            session,
            where: (t) => t.circleSpace.equals(circle.space),
          );
          expect(rows, isEmpty);
        },
      );

      test('a word kept out of the log is never kept', () async {
        final (circle, token) = await shared();
        await circles.addTiles(circle, ['secret'], noLog: true, firstCell: 1);
        expect(await recordSitterTap(session, token, '0:1'), isFalse);
        expect(await recordSitterTap(session, token, '5:5'), isFalse);
        expect(await recordSitterTap(session, token, 'nonsense'), isFalse);
      });

      test('taps are rate limited per link', () async {
        final (_, token) = await shared();
        var kept = 0;
        for (var i = 0; i < maxTapsPerMinute + 5; i++) {
          if (await recordSitterTap(session, token, '0:0')) kept++;
        }
        expect(kept, maxTapsPerMinute);
      });

      test('only guardians and therapists read the taps', () async {
        final (circle, _) = await shared();
        final teacher = await circles.member(circle, CircleRole.teacher);
        final therapist = await circles.member(circle, CircleRole.therapist);
        await expectLater(
          endpoints.sitter.recentTaps(teacher.session, circle.space),
          refusedWith(CircleFailure.notAllowed),
        );
        expect(
          await endpoints.sitter.recentTaps(therapist.session, circle.space),
          isEmpty,
        );
      });
    },
  );
}
