/// Endpoint tests for circles and invitations: who may invite, how a code
/// is spent, and which sync role each circle role is given.
library;

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// Matches a [CircleException] carrying [failure].
Matcher refusedWith(CircleFailure failure) => throwsA(
  isA<CircleException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  withServerpod(
    'Given the circle endpoint,',
    // The generated test tools build a plain Serverpod; the sync engine has
    // to be wired in the way the generated `Serverpod` class does it.
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    (sessionBuilder, endpoints) {
      final session = sessionBuilder.build();
      session.serverpod.initializeOfflineSync(syncTables: syncTables);

      /// A new user id and a session builder signed in as that user.
      (UuidValue, TestSessionBuilder) user() {
        final id = const Uuid().v7obj();
        return (
          id,
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              id.uuid,
              {},
            ),
          ),
        );
      }

      Future<OfflineSyncSpaceRole?> spaceRole(UuidValue space, UuidValue who) =>
          session.offlineSync.spaces.roleOf(user: who, space: space);

      test('when nobody is signed in then every method is refused.', () async {
        final space = const Uuid().v7obj();
        final unauthenticated = throwsA(
          isA<ServerpodUnauthenticatedException>(),
        );
        await expectLater(
          endpoints.circle.createCircle(sessionBuilder, 'Ada', 'Mum'),
          unauthenticated,
        );
        await expectLater(
          endpoints.circle.myCircles(sessionBuilder),
          unauthenticated,
        );
        await expectLater(
          endpoints.circle.createInvite(
            sessionBuilder,
            space,
            CircleRole.teacher,
          ),
          unauthenticated,
        );
        await expectLater(
          endpoints.circle.acceptInvite(sessionBuilder, 'ABCDEFGH', 'Sam'),
          unauthenticated,
        );
      });

      test('when a user creates a circle then they are its guardian with '
          'read-write access to a new sync space.', () async {
        final (me, asMe) = user();

        final info = await endpoints.circle.createCircle(asMe, ' Ada ', 'Mum');

        expect(info.childName, 'Ada');
        expect(info.myRole, CircleRole.guardian);
        expect(info.myDisplayName, 'Mum');
        expect(info.members, hasLength(1));
        expect(info.members.single.userId, me);
        expect(info.members.single.role, CircleRole.guardian);
        expect(
          await spaceRole(info.spaceUuid, me),
          OfflineSyncSpaceRole.readWrite,
        );
        expect(await session.offlineSync.spaces.members(info.spaceUuid), {
          me: OfflineSyncSpaceRole.readWrite,
        });
      });

      test('when names are blank or too long then they are replaced or '
          'cut to 60 characters.', () async {
        final (_, asMe) = user();

        final blank = await endpoints.circle.createCircle(asMe, '  ', '');
        final long = await endpoints.circle.createCircle(asMe, 'x' * 80, 'Mum');

        expect(blank.childName, 'My child');
        expect(blank.myDisplayName, 'Guardian');
        expect(long.childName, 'x' * 60);
      });

      test('when a user has two circles then myCircles lists both, oldest '
          'first, and another user sees none of them.', () async {
        final (_, asMe) = user();
        final (_, asOther) = user();
        final first = await endpoints.circle.createCircle(asMe, 'Ada', 'Mum');
        final second = await endpoints.circle.createCircle(asMe, 'Ben', 'Mum');

        final mine = await endpoints.circle.myCircles(asMe);

        expect(mine.map((c) => c.spaceUuid), [
          first.spaceUuid,
          second.spaceUuid,
        ]);
        expect(mine.map((c) => c.childName), ['Ada', 'Ben']);
        expect(await endpoints.circle.myCircles(asOther), isEmpty);
      });

      test('when a guardian invites then the code is 8 characters that '
          'survive being read aloud.', () async {
        final (_, asMe) = user();
        final circle = await endpoints.circle.createCircle(asMe, 'Ada', 'Mum');

        final code = await endpoints.circle.createInvite(
          asMe,
          circle.spaceUuid,
          CircleRole.therapist,
        );

        expect(code, matches(RegExp(r'^[A-HJKMNP-Z2-9]{8}$')));
      });

      test('when a teacher accepts an invitation then they join with '
          'read-write access and appear in the circle for everyone.', () async {
        final (guardian, asGuardian) = user();
        final (teacher, asTeacher) = user();
        final circle = await endpoints.circle.createCircle(
          asGuardian,
          'Ada',
          'Mum',
        );
        final code = await endpoints.circle.createInvite(
          asGuardian,
          circle.spaceUuid,
          CircleRole.teacher,
        );

        // Typed the way a person would: lower case, stray spaces.
        final joined = await endpoints.circle.acceptInvite(
          asTeacher,
          '  ${code.toLowerCase()} ',
          'Ms Okoro',
        );

        expect(joined.spaceUuid, circle.spaceUuid);
        expect(joined.myRole, CircleRole.teacher);
        expect(joined.myDisplayName, 'Ms Okoro');
        expect(
          {for (final m in joined.members) m.userId: m.role},
          {guardian: CircleRole.guardian, teacher: CircleRole.teacher},
        );
        expect(
          await spaceRole(circle.spaceUuid, teacher),
          OfflineSyncSpaceRole.readWrite,
        );
        final seenByGuardian = await endpoints.circle.myCircles(asGuardian);
        expect(seenByGuardian.single.members, hasLength(2));
        expect(
          (await endpoints.circle.myCircles(asTeacher)).single.spaceUuid,
          circle.spaceUuid,
        );
      });

      test('when a therapist accepts an invitation then they get '
          'read-write access.', () async {
        final (_, asGuardian) = user();
        final (therapist, asTherapist) = user();
        final circle = await endpoints.circle.createCircle(
          asGuardian,
          'Ada',
          'Mum',
        );
        final code = await endpoints.circle.createInvite(
          asGuardian,
          circle.spaceUuid,
          CircleRole.therapist,
        );

        await endpoints.circle.acceptInvite(asTherapist, code, 'Sam');

        expect(
          await spaceRole(circle.spaceUuid, therapist),
          OfflineSyncSpaceRole.readWrite,
        );
      });

      test('when a partner accepts an invitation then they get read-only '
          'access.', () async {
        final (_, asGuardian) = user();
        final (partner, asPartner) = user();
        final circle = await endpoints.circle.createCircle(
          asGuardian,
          'Ada',
          'Mum',
        );
        final code = await endpoints.circle.createInvite(
          asGuardian,
          circle.spaceUuid,
          CircleRole.partner,
        );

        final joined = await endpoints.circle.acceptInvite(
          asPartner,
          code,
          'Gran',
        );

        expect(joined.myRole, CircleRole.partner);
        expect(
          await spaceRole(circle.spaceUuid, partner),
          OfflineSyncSpaceRole.readOnly,
        );
      });

      test('when the code is wrong then joining is refused.', () async {
        final (stranger, asStranger) = user();
        final (_, asGuardian) = user();
        final circle = await endpoints.circle.createCircle(
          asGuardian,
          'Ada',
          'Mum',
        );
        await endpoints.circle.createInvite(
          asGuardian,
          circle.spaceUuid,
          CircleRole.teacher,
        );

        await expectLater(
          endpoints.circle.acceptInvite(asStranger, 'ZZZZ9999', 'Sam'),
          refusedWith(CircleFailure.inviteInvalid),
        );
        expect(await spaceRole(circle.spaceUuid, stranger), isNull);
        expect(await endpoints.circle.myCircles(asStranger), isEmpty);
      });

      test('when a code has been used then a second person cannot use it, '
          'and the first person using it again changes nothing.', () async {
        final (_, asGuardian) = user();
        final (_, asFirst) = user();
        final (second, asSecond) = user();
        final circle = await endpoints.circle.createCircle(
          asGuardian,
          'Ada',
          'Mum',
        );
        final code = await endpoints.circle.createInvite(
          asGuardian,
          circle.spaceUuid,
          CircleRole.teacher,
        );
        await endpoints.circle.acceptInvite(asFirst, code, 'First');

        await expectLater(
          endpoints.circle.acceptInvite(asSecond, code, 'Second'),
          refusedWith(CircleFailure.inviteUsed),
        );
        expect(await spaceRole(circle.spaceUuid, second), isNull);

        final again = await endpoints.circle.acceptInvite(
          asFirst,
          code,
          'Renamed',
        );
        expect(again.members, hasLength(2));
        expect(again.myDisplayName, 'First');
      });

      test('when a code has expired then joining is refused.', () async {
        final (_, asGuardian) = user();
        final (late, asLate) = user();
        final circle = await endpoints.circle.createCircle(
          asGuardian,
          'Ada',
          'Mum',
        );
        final code = await endpoints.circle.createInvite(
          asGuardian,
          circle.spaceUuid,
          CircleRole.teacher,
        );
        final invitation = (await Invitation.db.findFirstRow(
          session,
          where: (t) => t.code.equals(code),
        ))!;
        // Codes last seven days.
        expect(
          invitation.expiresAt.difference(invitation.createdAt),
          const Duration(days: 7),
        );
        await Invitation.db.updateRow(
          session,
          invitation.copyWith(
            expiresAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 1),
            ),
          ),
          columns: (t) => [t.expiresAt],
        );

        await expectLater(
          endpoints.circle.acceptInvite(asLate, code, 'Late'),
          refusedWith(CircleFailure.inviteExpired),
        );
        expect(await spaceRole(circle.spaceUuid, late), isNull);
      });

      test('when someone who is not a guardian invites then it is refused: '
          'a member is not allowed, a stranger is not a member.', () async {
        final (_, asGuardian) = user();
        final (_, asTeacher) = user();
        final (_, asPartner) = user();
        final (_, asStranger) = user();
        final circle = await endpoints.circle.createCircle(
          asGuardian,
          'Ada',
          'Mum',
        );
        for (final (role, who) in [
          (CircleRole.teacher, asTeacher),
          (CircleRole.partner, asPartner),
        ]) {
          final code = await endpoints.circle.createInvite(
            asGuardian,
            circle.spaceUuid,
            role,
          );
          await endpoints.circle.acceptInvite(who, code, role.name);
        }

        await expectLater(
          endpoints.circle.createInvite(
            asTeacher,
            circle.spaceUuid,
            CircleRole.partner,
          ),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          endpoints.circle.createInvite(
            asPartner,
            circle.spaceUuid,
            CircleRole.partner,
          ),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          endpoints.circle.createInvite(
            asStranger,
            circle.spaceUuid,
            CircleRole.partner,
          ),
          refusedWith(CircleFailure.notAMember),
        );
      });

      test('when a member accepts a second invitation with another role '
          'then they keep the role they had.', () async {
        final (_, asGuardian) = user();
        final (partner, asPartner) = user();
        final circle = await endpoints.circle.createCircle(
          asGuardian,
          'Ada',
          'Mum',
        );
        final asPartnerCode = await endpoints.circle.createInvite(
          asGuardian,
          circle.spaceUuid,
          CircleRole.partner,
        );
        final asTeacherCode = await endpoints.circle.createInvite(
          asGuardian,
          circle.spaceUuid,
          CircleRole.teacher,
        );
        await endpoints.circle.acceptInvite(asPartner, asPartnerCode, 'Gran');

        final again = await endpoints.circle.acceptInvite(
          asPartner,
          asTeacherCode,
          'Gran',
        );

        expect(again.myRole, CircleRole.partner);
        expect(
          await spaceRole(circle.spaceUuid, partner),
          OfflineSyncSpaceRole.readOnly,
        );
      });
    },
  );
}
