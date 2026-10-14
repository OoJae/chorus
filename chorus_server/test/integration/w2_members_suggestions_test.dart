/// Endpoint tests for words suggested by the circle and for removing a
/// member.
library;

import 'package:chorus_server/src/demo/demo_seed.dart';
import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_server/src/word_suggestions/word_suggestion_endpoint.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
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

      test('a member with ten words waiting may send no more until one is '
          'answered, and a long word is cut short', () async {
        final circle = await circles.create();
        final partner = await circles.member(circle, CircleRole.partner);
        final first = await endpoints.wordSuggestion.suggest(
          partner.session,
          circle.space,
          'x' * 100,
          null,
          null,
        );
        expect(first.label, hasLength(maxSuggestedLabelLength));
        for (var i = 1; i < maxOpenSuggestionsPerMember; i++) {
          await endpoints.wordSuggestion.suggest(
            partner.session,
            circle.space,
            'word $i',
            null,
            null,
          );
        }
        await expectLater(
          endpoints.wordSuggestion.suggest(
            partner.session,
            circle.space,
            'one too many',
            null,
            null,
          ),
          refusedWith(CircleFailure.notAllowed),
        );
        await endpoints.wordSuggestion.resolve(
          circle.guardian.session,
          circle.space,
          first.id,
          false,
        );
        await endpoints.wordSuggestion.suggest(
          partner.session,
          circle.space,
          'room again',
          null,
          null,
        );
        final open = await endpoints.wordSuggestion.list(
          circle.guardian.session,
          circle.space,
        );
        expect(open, hasLength(maxOpenSuggestionsPerMember));
      });

      test(
        'a circle with thirty words waiting takes no more from anyone',
        () async {
          final circle = await circles.create();
          final senders = [
            circle.guardian,
            for (
              var i = 1;
              i < maxOpenSuggestionsPerCircle ~/ maxOpenSuggestionsPerMember;
              i++
            )
              await circles.member(circle, CircleRole.partner),
          ];
          var sent = 0;
          for (final sender in senders) {
            for (var i = 0; i < maxOpenSuggestionsPerMember; i++) {
              if (sent == maxOpenSuggestionsPerCircle) break;
              await endpoints.wordSuggestion.suggest(
                sender.session,
                circle.space,
                'word $sent',
                null,
                null,
              );
              sent++;
            }
          }
          expect(sent, maxOpenSuggestionsPerCircle);
          final late = await circles.member(circle, CircleRole.teacher);
          await expectLater(
            endpoints.wordSuggestion.suggest(
              late.session,
              circle.space,
              'swing',
              null,
              null,
            ),
            refusedWith(CircleFailure.notAllowed),
          );
          final open = await endpoints.wordSuggestion.list(
            circle.guardian.session,
            circle.space,
          );
          expect(open, hasLength(maxOpenSuggestionsPerCircle));
        },
      );

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

      test('a removed member cannot come back with the code they joined '
          'with, but can with a new one', () async {
        final circle = await circles.create();
        final sitter = circles.user();
        final code = await endpoints.circle.createInvite(
          circle.guardian.session,
          circle.space,
          CircleRole.teacher,
        );
        await endpoints.circle.acceptInvite(sitter.session, code, 'Sitter');
        await endpoints.members.remove(
          circle.guardian.session,
          circle.space,
          sitter.id,
        );

        await expectLater(
          endpoints.circle.acceptInvite(sitter.session, code, 'Sitter'),
          refusedWith(CircleFailure.inviteUsed),
        );
        final list = await endpoints.members.list(
          circle.guardian.session,
          circle.space,
        );
        expect(list.map((m) => m.userId), isNot(contains(sitter.id)));
        expect(
          await circles.session.offlineSync.spaces.roleOf(
            user: sitter.id,
            space: circle.space,
          ),
          isNull,
        );

        final again = await endpoints.circle.createInvite(
          circle.guardian.session,
          circle.space,
          CircleRole.teacher,
        );
        final back = await endpoints.circle.acceptInvite(
          sitter.session,
          again,
          'Sitter',
        );
        expect(back.myRole, CircleRole.teacher);
      });

      test('the unused codes a removed guardian made stop working', () async {
        final circle = await circles.create();
        final other = await circles.member(circle, CircleRole.guardian);
        final code = await endpoints.circle.createInvite(
          other.session,
          circle.space,
          CircleRole.therapist,
        );
        await endpoints.members.remove(
          circle.guardian.session,
          circle.space,
          other.id,
        );
        await expectLater(
          endpoints.circle.acceptInvite(other.session, code, 'Back'),
          refusedWith(CircleFailure.inviteInvalid),
        );
        await expectLater(
          endpoints.circle.acceptInvite(circles.user().session, code, 'Anyone'),
          refusedWith(CircleFailure.inviteInvalid),
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

  withServerpod(
    'Given the demo circle that every judge shares,',
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final circles = Circles(sessionBuilder, endpoints);
      // The demo sign-ins are made with the email provider's admin calls.
      circles.session.serverpod.initializeAuthServices(
        tokenManagerBuilders: [JwtConfigFromPasswords()],
        identityProviderBuilders: [
          ServerpodCloudEmailIdpConfig(appDisplayName: 'chorus'),
        ],
      );

      late UuidValue demo;
      late List<TestUser> personas;

      setUpAll(() async {
        demo = await ensureDemoSeed(circles.session, 'open sesame 1');
        final accounts = await demoAccounts(circles.session);
        personas = [
          for (final persona in demoPersonas)
            TestUser(
              accounts[persona.email]!,
              sessionBuilder.copyWith(
                authentication: AuthenticationOverride.authenticationInfo(
                  accounts[persona.email]!.uuid,
                  {},
                ),
              ),
            ),
        ];
      });

      Future<List<UuidValue>> membersOf(UuidValue space) async => [
        for (final m in await endpoints.members.list(
          personas[0].session,
          space,
        ))
          m.userId,
      ];

      test(
        'the demo guardian cannot remove the demo therapist or partner',
        () async {
          for (final persona in personas.skip(1)) {
            await expectLater(
              endpoints.members.remove(personas[0].session, demo, persona.id),
              refusedWith(CircleFailure.notAllowed),
            );
          }
          expect(await membersOf(demo), [for (final p in personas) p.id]);
          expect(
            await circles.session.offlineSync.spaces.roleOf(
              user: personas[1].id,
              space: demo,
            ),
            OfflineSyncSpaceRole.readWrite,
          );
        },
      );

      test('nobody a judge invited into the demo circle can be removed '
          'either', () async {
        final judge = circles.user();
        final code = await endpoints.circle.createInvite(
          personas[0].session,
          demo,
          CircleRole.teacher,
        );
        await endpoints.circle.acceptInvite(judge.session, code, 'Judge');
        await expectLater(
          endpoints.members.remove(personas[0].session, demo, judge.id),
          refusedWith(CircleFailure.notAllowed),
        );
        expect(await membersOf(demo), contains(judge.id));
      });

      test('a demo sign-in in someone else\'s circle cannot be removed, '
          'and anyone else still can', () async {
        final circle = await circles.create();
        final code = await endpoints.circle.createInvite(
          circle.guardian.session,
          circle.space,
          CircleRole.partner,
        );
        await endpoints.circle.acceptInvite(personas[2].session, code, 'Gran');
        final teacher = await circles.member(circle, CircleRole.teacher);

        await expectLater(
          endpoints.members.remove(
            circle.guardian.session,
            circle.space,
            personas[2].id,
          ),
          refusedWith(CircleFailure.notAllowed),
        );
        await endpoints.members.remove(
          circle.guardian.session,
          circle.space,
          teacher.id,
        );
        final left = await endpoints.members.list(
          circle.guardian.session,
          circle.space,
        );
        expect(left.map((m) => m.userId), [
          circle.guardian.id,
          personas[2].id,
        ]);
      });
    },
  );
}
