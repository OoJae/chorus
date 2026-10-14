import 'dart:async';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';

import '../generated/protocol.dart';

/// One demo sign-in and its place in the demo circle.
class DemoPersona {
  const DemoPersona(this.email, this.displayName, this.role);

  final String email;
  final String displayName;
  final CircleRole role;
}

/// The persona child of the demo circle. Nobody real.
const demoChildName = 'Maya';

/// The demo sign-ins. The first is the guardian who owns the circle.
const demoPersonas = [
  DemoPersona('demo.parent@chorus.example', "Maya's mum", CircleRole.guardian),
  DemoPersona(
    'demo.therapist@chorus.example',
    'Speech therapist',
    CircleRole.therapist,
  ),
  DemoPersona('demo.partner@chorus.example', 'Grandad', CircleRole.partner),
];

/// The auth users of the demo sign-ins that exist on this server, by
/// address. Empty when no demo password was ever set.
///
/// Read from the email provider's own table, so it works whether or not
/// the auth services are set up in this process.
Future<Map<String, UuidValue>> demoAccounts(Session session) async {
  final rows = await EmailAccount.db.find(
    session,
    where: (t) => t.email.inSet({for (final p in demoPersonas) p.email}),
  );
  return {for (final row in rows) row.email: row.authUserId};
}

/// True when [user] may not be taken out of [circleSpace] because the demo
/// needs them there: [circleSpace] is the demo circle (the demo guardian's
/// circle for [demoChildName]), or [user] is one of the demo sign-ins.
///
/// Every judge shares the demo sign-ins, and [ensureDemoSeed] only puts a
/// missing member back when the server starts, so one removal would leave
/// that sign-in with no board for every judge after.
Future<bool> isDemoProtected(
  Session session,
  UuidValue circleSpace,
  UuidValue user,
) async {
  final demo = await demoAccounts(session);
  if (demo.isEmpty) return false;
  if (demo.values.contains(user)) return true;
  final guardian = demo[demoPersonas.first.email];
  if (guardian == null) return false;
  final circle = await Circle.db.findFirstRow(
    session,
    where: (t) =>
        t.spaceUuid.equals(circleSpace) &
        t.createdBy.equals(guardian) &
        t.childName.equals(demoChildName),
  );
  return circle != null;
}

/// Makes sure the demo accounts and their circle exist. Call after the
/// server has started.
///
/// Does nothing unless the password `demoPassword` is set. Runs in the
/// background and never stops the server: a failure is written to the log.
void scheduleDemoSeed(Serverpod pod) {
  final password = pod.getPassword('demoPassword');
  if (password == null || password.trim().isEmpty) return;
  unawaited(
    pod
        .withSession(
          (session) => ensureDemoSeed(session, password),
          enableLogging: false,
        )
        .then<void>(
          (_) {},
          onError: (Object error) {
            // The type only; the message could repeat the password's hash
            // inputs or an address.
            stderr.writeln('Demo seed failed: ${error.runtimeType}');
          },
        ),
  );
}

/// Creates what is missing of the demo sign-ins and their shared circle, and
/// sets each sign-in's password to [password]. Safe to run on every start.
///
/// Accounts are made with the email provider's own admin calls, which treat
/// the address as verified; no auth table is written directly. The starter
/// board is not seeded here: the guardian's client does that on first open.
///
/// Returns the circle's space id.
Future<UuidValue> ensureDemoSeed(Session session, String password) async {
  final users = <UuidValue>[
    for (final persona in demoPersonas)
      await _ensureAccount(session, persona, password),
  ];
  return session.db.transaction((transaction) async {
    final guardian = users.first;
    final now = DateTime.now().toUtc();
    final existing = await Circle.db.findFirstRow(
      session,
      where: (t) =>
          t.createdBy.equals(guardian) & t.childName.equals(demoChildName),
      orderBy: (t) => t.createdAt,
      transaction: transaction,
    );
    final UuidValue space;
    if (existing != null) {
      space = existing.spaceUuid;
    } else {
      space = await session.offlineSync.spaces.createFor(
        guardian,
        role: OfflineSyncSpaceRole.readWrite,
        transaction: transaction,
      );
      await Circle.db.insertRow(
        session,
        Circle(
          spaceUuid: space,
          childName: demoChildName,
          createdBy: guardian,
          createdAt: now,
        ),
        transaction: transaction,
      );
    }
    for (var i = 0; i < demoPersonas.length; i++) {
      final persona = demoPersonas[i];
      final user = users[i];
      final member = await Membership.db.findFirstRow(
        session,
        where: (t) => t.circleSpace.equals(space) & t.userId.equals(user),
        transaction: transaction,
      );
      if (member != null) continue;
      // The guardian got read-write access when the space was created.
      if (i > 0) {
        await session.offlineSync.spaces.grant(
          space: space,
          user: user,
          role: persona.role == CircleRole.partner
              ? OfflineSyncSpaceRole.readOnly
              : OfflineSyncSpaceRole.readWrite,
          transaction: transaction,
        );
      }
      await Membership.db.insertRow(
        session,
        Membership(
          circleSpace: space,
          userId: user,
          role: persona.role,
          displayName: persona.displayName,
          joinedAt: now.add(Duration(milliseconds: i)),
        ),
        transaction: transaction,
      );
    }
    return space;
  });
}

/// The auth user behind [persona]'s address, created if missing, with its
/// password set to [password].
Future<UuidValue> _ensureAccount(
  Session session,
  DemoPersona persona,
  String password,
) async {
  final auth = AuthServices.instance;
  final email = auth.emailIdp;
  final account = await email.admin.findAccount(session, email: persona.email);
  if (account != null) {
    await email.admin.setPassword(
      session,
      email: persona.email,
      password: password,
    );
    return account.authUserId;
  }
  return session.db.transaction((transaction) async {
    final user = await auth.authUsers.create(session, transaction: transaction);
    await auth.userProfiles.createUserProfile(
      session,
      user.id,
      UserProfileData(email: persona.email, fullName: persona.displayName),
      transaction: transaction,
    );
    await email.admin.createEmailAuthentication(
      session,
      authUserId: user.id,
      email: persona.email,
      password: password,
      transaction: transaction,
    );
    return user.id;
  });
}
