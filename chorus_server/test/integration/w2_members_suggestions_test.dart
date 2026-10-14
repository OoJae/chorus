/// Endpoint tests for words suggested by the circle and for removing a
/// member.
library;

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_circles.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given suggested words,',
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final circles = Circles(sessionBuilder, endpoints);

      test('a read-only member suggests and an editor sees it', () async {
        final circle = await circles.create();
        final partner = await circles.member(circle, CircleRole.partner);
        final made = await endpoints.wordSuggestion.suggest(
          partner.session,
          circle.space,
          '  swing  ',
          null,
          'noun',
        );
        expect(made.label, 'swing');
        expect(made.source, 'person');
        expect(made.suggestedByName, 'partner');
        final open = await endpoints.wordSuggestion.list(
          circle.guardian.session,
          circle.space,
        );
        expect([for (final s in open) s.label], ['swing']);
      });

      test('a read-only member may not list or answer', () async {
        final circle = await circles.create();
        final partner = await circles.member(circle, CircleRole.partner);
        await expectLater(
          endpoints.wordSuggestion.list(partner.session, circle.space),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          endpoints.wordSuggestion.resolve(
            partner.session,
            circle.space,
            1,
            true,
          ),
          refusedWith(CircleFailure.notAllowed),
        );
      });

      test('an answered suggestion leaves the list', () async {
        final circle = await circles.create();
        final teacher = await circles.member(circle, CircleRole.teacher);
        final a = await endpoints.wordSuggestion.suggest(
          teacher.session,
          circle.space,
          'slide',
          null,
          null,
        );
        await endpoints.wordSuggestion.suggest(
          teacher.session,
          circle.space,
          'sand',
          null,
          null,
        );
        await endpoints.wordSuggestion.resolve(
          circle.guardian.session,
          circle.space,
          a.id,
          false,
        );
        final open = await endpoints.wordSuggestion.list(
          circle.guardian.session,
          circle.space,
        );
        expect([for (final s in open) s.label], ['sand']);
      });

      test('someone outside the circle cannot suggest', () async {
        final circle = await circles.create();
        final stranger = circles.user();
        await expectLater(
          endpoints.wordSuggestion.suggest(
            stranger.session,
            circle.space,
            'x',
            null,
            null,
          ),
          refusedWith(CircleFailure.notAMember),
        );
      });

      test('an empty word is refused', () async {
        final circle = await circles.create();
        await expectLater(
          endpoints.wordSuggestion.suggest(
            circle.guardian.session,
            circle.space,
            '   ',
            null,
            null,
          ),
          throwsA(anything),
        );
      });
    },
  );

  withServerpod(
    'Given the members of a circle,',
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final circles = Circles(sessionBuilder, endpoints);

      test('any member sees everyone, guardians first', () async {
        final circle = await circles.create();
        final partner = await circles.member(circle, CircleRole.partner);
        final list = await endpoints.members.list(
          partner.session,
          circle.space,
        );
        expect(
          [for (final m in list) m.role],
          [
            CircleRole.guardian,
            CircleRole.partner,
          ],
        );
      });

      test('a guardian removes a member, whose access goes', () async {
        final circle = await circles.create();
        final teacher = await circles.member(circle, CircleRole.teacher);
        await endpoints.members.remove(
          circle.guardian.session,
          circle.space,
          teacher.id,
        );
        final list = await endpoints.members.list(
          circle.guardian.session,
          circle.space,
        );
        expect(list.map((m) => m.userId), isNot(contains(teacher.id)));
        final role = await circles.session.offlineSync.spaces.roleOf(
          user: teacher.id,
          space: circle.space,
        );
        expect(role, isNull);
        await expectLater(
          endpoints.members.list(teacher.session, circle.space),
          refusedWith(CircleFailure.notAMember),
        );
      });

      test('only a guardian removes, and never themselves', () async {
        final circle = await circles.create();
        final therapist = await circles.member(circle, CircleRole.therapist);
        await expectLater(
          endpoints.members.remove(
            therapist.session,
            circle.space,
            circle.guardian.id,
          ),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          endpoints.members.remove(
            circle.guardian.session,
            circle.space,
            circle.guardian.id,
          ),
          refusedWith(CircleFailure.notAllowed),
        );
      });

      test('removing someone not in the circle says so', () async {
        final circle = await circles.create();
        await expectLater(
          endpoints.members.remove(
            circle.guardian.session,
            circle.space,
            const Uuid().v7obj(),
          ),
          refusedWith(CircleFailure.notAMember),
        );
      });

      test('a removed member\'s live stream closes', () async {
        final circle = await circles.create();
        final teacher = await circles.member(circle, CircleRole.teacher);
        final stream = endpoints.live.join(
          teacher.session,
          circle.space,
          const Stream<LiveEvent>.empty(),
        );
        final done = stream.toList();
        // Let the stream subscribe before the removal is posted.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await endpoints.members.remove(
          circle.guardian.session,
          circle.space,
          teacher.id,
        );
        await expectLater(done.timeout(const Duration(seconds: 5)), completes);
      });
    },
  );
}
