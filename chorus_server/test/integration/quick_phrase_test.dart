/// Endpoint tests for quick phrases: every member reads them, editing roles
/// change them, and a circle with none of its own gets the defaults.
library;

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_shared/chorus_shared.dart'
    show defaultQuickPhrases, maxQuickPhrases;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_circles.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given the quick phrase endpoint,',
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final circles = Circles(sessionBuilder, endpoints);
      final session = circles.session;
      final phrases = endpoints.quickPhrase;

      Future<List<QuickPhrase>> rows(UuidValue space) => QuickPhrase.db.find(
        session,
        where: (t) => t.circleSpace.equals(space),
        orderBy: (t) => t.position,
      );

      test('when nobody is signed in then both methods are refused.', () async {
        final space = const Uuid().v7obj();
        await expectLater(phrases.list(sessionBuilder, space), unauthenticated);
        await expectLater(
          phrases.set(sessionBuilder, space, ['Stop']),
          unauthenticated,
        );
      });

      test('when a circle has none of its own then the defaults come back, '
          'and nothing is stored.', () async {
        final circle = await circles.create();
        expect(
          await phrases.list(circle.guardian.session, circle.space),
          defaultQuickPhrases,
        );
        expect(await rows(circle.space), isEmpty);
      });

      test(
        'when an editor sets them then every member reads them in order.',
        () async {
          final circle = await circles.create();
          final therapist = await circles.member(circle, CircleRole.therapist);
          final partner = await circles.member(circle, CircleRole.partner);
          final kept = await phrases.set(therapist.session, circle.space, [
            'Stop',
            ' I want  a hug ',
            '',
            'stop',
            'Toilet',
          ]);
          expect(kept, ['Stop', 'I want a hug', 'Toilet']);
          for (final reader in [circle.guardian, therapist, partner]) {
            expect(await phrases.list(reader.session, circle.space), kept);
          }
          final stored = await rows(circle.space);
          expect([for (final r in stored) r.position], [0, 1, 2]);
          expect([for (final r in stored) r.text], kept);
        },
      );

      test(
        'when they are set again then the old list is replaced whole.',
        () async {
          final circle = await circles.create();
          final guardian = circle.guardian.session;
          await phrases.set(guardian, circle.space, ['A', 'B', 'C', 'D']);
          await phrases.set(guardian, circle.space, ['D', 'A']);
          expect(await phrases.list(guardian, circle.space), ['D', 'A']);
          expect(await rows(circle.space), hasLength(2));
        },
      );

      test('when an empty list is set then the defaults come back.', () async {
        final circle = await circles.create();
        final guardian = circle.guardian.session;
        await phrases.set(guardian, circle.space, ['Mine']);
        expect(
          await phrases.set(guardian, circle.space, []),
          defaultQuickPhrases,
        );
        expect(
          await phrases.list(guardian, circle.space),
          defaultQuickPhrases,
        );
        expect(await rows(circle.space), isEmpty);
      });

      test(
        'when too many are sent then only the first ones are kept.',
        () async {
          final circle = await circles.create();
          final many = [for (var i = 0; i < 40; i++) 'Phrase $i'];
          final kept = await phrases.set(
            circle.guardian.session,
            circle.space,
            many,
          );
          expect(kept, hasLength(maxQuickPhrases));
          expect(kept.first, 'Phrase 0');
        },
      );

      test('when a read-only partner sets them then it is refused and '
          'nothing changes.', () async {
        final circle = await circles.create();
        final partner = await circles.member(circle, CircleRole.partner);
        await expectLater(
          phrases.set(partner.session, circle.space, ['Mine']),
          refusedWith(CircleFailure.notAllowed),
        );
        expect(await rows(circle.space), isEmpty);
      });

      test('when someone outside the circle asks then both methods are '
          'refused.', () async {
        final circle = await circles.create();
        final other = await circles.create(child: 'Sam');
        await expectLater(
          phrases.list(other.guardian.session, circle.space),
          refusedWith(CircleFailure.notAMember),
        );
        await expectLater(
          phrases.set(other.guardian.session, circle.space, ['Mine']),
          refusedWith(CircleFailure.notAMember),
        );
      });

      test('when two circles set theirs then each keeps its own.', () async {
        final one = await circles.create();
        final two = await circles.create(child: 'Sam');
        await phrases.set(one.guardian.session, one.space, ['One']);
        await phrases.set(two.guardian.session, two.space, ['Two']);
        expect(await phrases.list(one.guardian.session, one.space), ['One']);
        expect(await phrases.list(two.guardian.session, two.space), ['Two']);
      });
    },
  );
}
