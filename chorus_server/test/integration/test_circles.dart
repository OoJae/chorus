/// Circles for the endpoint tests of the word log, "This week" and sharing:
/// signed-in users, members in each role, and tiles written into a circle's
/// sync space the way the app writes them.
///
/// Tiles are written through `transactionForUser` in a session of the
/// server's own, outside the test's transaction (a test session's database
/// does not offer it), so groups that add tiles run with
/// `RollbackDatabase.disabled` and keep each test to its own circles.
library;

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_shared/chorus_shared.dart' show placedKey;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// Matches a [CircleException] carrying [failure].
Matcher refusedWith(CircleFailure failure) => throwsA(
  isA<CircleException>().having((e) => e.failure, 'failure', failure),
);

/// Matches a [ServerpodUnauthenticatedException].
final Matcher unauthenticated = throwsA(
  isA<ServerpodUnauthenticatedException>(),
);

/// A signed-in adult.
class TestUser {
  TestUser(this.id, this.session);

  final UuidValue id;
  final TestSessionBuilder session;
}

/// A circle and its guardian.
class TestCircle {
  TestCircle(this.space, this.guardian, this.board);

  final UuidValue space;
  final TestUser guardian;

  /// A 6 x 6 board in the circle, ready for tiles.
  final UuidValue board;
}

/// Makes users, circles and tiles for one `withServerpod` group.
class Circles {
  /// Call at the top of the group: the generated test tools build a plain
  /// Serverpod, so the sync engine is wired in here the way the generated
  /// class does it.
  Circles(this.sessionBuilder, this.endpoints) {
    sessionBuilder.build().serverpod.initializeOfflineSync(
      syncTables: syncTables,
    );
  }

  final TestSessionBuilder sessionBuilder;
  final TestEndpoints endpoints;

  /// A server session for direct reads and writes. Built after the engine
  /// is configured, so its database is the sync-aware one.
  late final Session session = sessionBuilder.build();

  /// A new signed-in user.
  TestUser user() {
    final id = const Uuid().v7obj();
    return TestUser(
      id,
      sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(id.uuid, {}),
      ),
    );
  }

  /// A new circle for [child] with an empty board.
  Future<TestCircle> create({String child = 'Maya'}) async {
    final guardian = user();
    final info = await endpoints.circle.createCircle(
      guardian.session,
      child,
      'Mum',
    );
    final board = const Uuid().v7obj();
    await _write(guardian.id, info.spaceUuid, (session, tx) async {
      await Board.db.insertRow(
        session,
        Board(
          id: board,
          circleId: info.spaceUuid,
          name: 'Home',
          rows: 6,
          cols: 6,
          isHome: true,
          createdAt: DateTime.now().toUtc(),
        ),
        transaction: tx,
      );
    });
    return TestCircle(info.spaceUuid, guardian, board);
  }

  /// A new member of [circle] with [role].
  Future<TestUser> member(TestCircle circle, CircleRole role) async {
    final who = user();
    final code = await endpoints.circle.createInvite(
      circle.guardian.session,
      circle.space,
      role,
    );
    await endpoints.circle.acceptInvite(who.session, code, role.name);
    return who;
  }

  /// Turns [circle]'s word log on as its guardian, dated [ago] back as if
  /// it had been on all that time: the log takes no word spoken before it
  /// was turned on, and tests send words from days ago.
  Future<void> logOn(
    TestCircle circle, {
    Duration ago = const Duration(days: 31),
  }) async {
    await endpoints.wordLog.setEnabled(
      circle.guardian.session,
      circle.space,
      true,
    );
    final setting = await WordLogSetting.db.findFirstRow(
      session,
      where: (t) => t.circleSpace.equals(circle.space),
    );
    await WordLogSetting.db.updateRow(
      session,
      setting!.copyWith(changedAt: DateTime.now().toUtc().subtract(ago)),
      columns: (t) => [t.changedAt],
    );
  }

  /// Tiles with [labels] on [circle]'s board, one per cell in row-major
  /// order, written by the guardian. Returns them in the same order.
  Future<List<Tile>> addTiles(
    TestCircle circle,
    List<String> labels, {
    DateTime? createdAt,
    bool noLog = false,
    int firstCell = 0,
  }) async {
    final made = <Tile>[];
    await _write(circle.guardian.id, circle.space, (session, tx) async {
      for (var i = 0; i < labels.length; i++) {
        final cell = firstCell + i;
        made.add(
          await Tile.db.insertRow(
            session,
            Tile(
              id: const Uuid().v7obj(),
              circleId: circle.space,
              boardId: circle.board,
              cellKey: placedKey(circle.board.uuid, cell ~/ 6, cell % 6),
              label: labels[i],
              colorKey: 'verb',
              noLog: noLog,
              createdBy: circle.guardian.id,
              createdByName: 'Mum',
              createdAt: (createdAt ?? DateTime.now()).toUtc(),
            ),
            transaction: tx,
          ),
        );
      }
    });
    return made;
  }

  /// Runs [body] as [user]'s write into [space], the way the app must make
  /// every write to a synced table.
  Future<void> _write(
    UuidValue user,
    UuidValue space,
    Future<void> Function(Session session, Transaction tx) body,
  ) => session.serverpod.withSession(
    (server) => server.offlineSyncDb.transactionForUser(
      user,
      (tx) => body(server, tx),
      spaceId: space,
    ),
    enableLogging: false,
  );
}
