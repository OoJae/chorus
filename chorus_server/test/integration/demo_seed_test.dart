/// Tests for the demo seed: three sign-ins that can really sign in, one
/// circle for the persona child, and no duplicates however often it runs.
library;

import 'package:chorus_server/src/demo/demo_seed.dart';
import 'package:chorus_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given the demo seed,',
    // The generated test tools build a plain Serverpod; the sync engine and
    // the auth services have to be wired in the way `server.dart` does it.
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    (sessionBuilder, endpoints) {
      final session = sessionBuilder.build();
      session.serverpod.initializeOfflineSync(syncTables: syncTables);
      session.serverpod.initializeAuthServices(
        tokenManagerBuilders: [JwtConfigFromPasswords()],
        identityProviderBuilders: [
          ServerpodCloudEmailIdpConfig(appDisplayName: 'chorus'),
        ],
      );

      Future<UuidValue> signIn(String email, String password) async {
        final success = await AuthServices.instance.emailIdp.login(
          session,
          email: email,
          password: password,
        );
        return success.authUserId;
      }

      // One scenario, in order: signing in opens its own transactions, which
      // the per-test rollback does not allow, so nothing is rolled back and
      // each test builds on the one before.
      var password = 'open sesame 1';
      late UuidValue space;
      late List<UuidValue> ids;

      test('when no demo password is set then scheduling does '
          'nothing.', () async {
        expect(session.serverpod.getPassword('demoPassword'), isNull);

        scheduleDemoSeed(session.serverpod);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(await Circle.db.count(session), 0);
      });

      test('when it runs then each demo address can sign in with the '
          'password and all three share one circle for Maya.', () async {
        space = await ensureDemoSeed(session, password);

        ids = [
          for (final persona in demoPersonas)
            await signIn(persona.email, password),
        ];
        expect(ids.toSet(), hasLength(3));

        final circle = (await Circle.db.find(session)).single;
        expect(circle.spaceUuid, space);
        expect(circle.childName, 'Maya');
        expect(circle.createdBy, ids[0]);

        final members = await Membership.db.find(
          session,
          where: (t) => t.circleSpace.equals(space),
          orderBy: (t) => t.joinedAt,
        );
        expect(members.map((m) => m.userId), ids);
        expect(members.map((m) => m.role), [
          CircleRole.guardian,
          CircleRole.therapist,
          CircleRole.partner,
        ]);
        expect(await session.offlineSync.spaces.members(space), {
          ids[0]: OfflineSyncSpaceRole.readWrite,
          ids[1]: OfflineSyncSpaceRole.readWrite,
          ids[2]: OfflineSyncSpaceRole.readOnly,
        });

        // The server seeds no board; the guardian's client does.
        expect(await Board.db.count(session), 0);
        expect(await Tile.db.count(session), 0);
      });

      test('when the guardian asks for their circles then the demo circle '
          'is listed with its three members.', () async {
        final circles = await endpoints.circle.myCircles(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              ids[0].uuid,
              {},
            ),
          ),
        );

        expect(circles.single.spaceUuid, space);
        expect(circles.single.childName, 'Maya');
        expect(circles.single.myRole, CircleRole.guardian);
        expect(circles.single.members, hasLength(3));
      });

      test('when it runs again then nothing is duplicated and the same '
          'circle is returned.', () async {
        expect(await ensureDemoSeed(session, password), space);
        expect(await ensureDemoSeed(session, password), space);

        expect(await Circle.db.count(session), 1);
        expect(await Membership.db.count(session), 3);
        for (final persona in demoPersonas) {
          expect(
            await AuthServices.instance.userProfiles.admin.listUserProfiles(
              session,
              email: persona.email,
            ),
            hasLength(1),
          );
        }
      });

      test('when the password changes then the next run sets the new one '
          'on the same accounts.', () async {
        const old = 'open sesame 1';
        password = 'a different one 2';

        await ensureDemoSeed(session, password);

        expect(await signIn(demoPersonas[1].email, password), ids[1]);
        await expectLater(
          signIn(demoPersonas[1].email, old),
          throwsA(anything),
        );
      });

      test('when a member is missing from the circle then the next run '
          'puts only that member back.', () async {
        await Membership.db.deleteWhere(
          session,
          where: (t) => t.userId.equals(ids[2]),
        );

        expect(await ensureDemoSeed(session, password), space);

        expect(await Membership.db.count(session), 3);
        expect(
          await session.offlineSync.spaces.roleOf(user: ids[2], space: space),
          OfflineSyncSpaceRole.readOnly,
        );
      });
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
