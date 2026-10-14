/// Endpoint tests for named board copies: editing roles take and delete
/// them, every member lists and reads them, a copy keeps the board's placed
/// words as the server held them, and taking one never changes the board.
library;

import 'package:chorus_server/src/generated/protocol.dart';
import 'package:chorus_shared/chorus_shared.dart' show placedKey;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_offline_sync_server/serverpod_offline_sync_server.dart';
import 'package:test/test.dart';

import 'test_circles.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given the board copy endpoint,',
    databaseInterceptor: offlineSyncDatabaseInterceptor,
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final circles = Circles(sessionBuilder, endpoints);
      final session = circles.session;
      final copies = endpoints.boardCopy;

      test('when nobody is signed in then every method is refused.', () async {
        final space = const Uuid().v7obj();
        final board = const Uuid().v7obj();
        await expectLater(
          copies.take(sessionBuilder, space, board, 'Trip'),
          unauthenticated,
        );
        await expectLater(copies.list(sessionBuilder, space), unauthenticated);
        await expectLater(copies.get(sessionBuilder, space, 1), unauthenticated);
        await expectLater(
          copies.delete(sessionBuilder, space, 1),
          unauthenticated,
        );
      });

      test('when a guardian takes a copy then it keeps the placed words with '
          'their cells, and the board is left as it was.', () async {
        final circle = await circles.create();
        final tiles = await circles.addTiles(circle, ['eat', 'drink', 'more']);
        final before = await Tile.db.find(
          session,
          where: (t) => t.circleId.equals(circle.space),
        );

        final copy = await copies.take(
          circle.guardian.session,
          circle.space,
          circle.board,
          '  Before the  school trip ',
        );

        expect(copy.name, 'Before the school trip');
        expect(copy.boardId, circle.board);
        expect(copy.boardName, 'Home');
        expect((copy.rows, copy.cols), (6, 6));
        expect(copy.takenByName, 'Mum');
        expect(copy.wordCount, 3);
        expect(copy.words.map((w) => w.label), ['eat', 'drink', 'more']);
        expect(copy.words[1].cellKey, placedKey(circle.board.uuid, 0, 1));
        expect(copy.words[1].colorKey, 'verb');
        expect(copy.words.first.cellKey, tiles.first.cellKey);

        final after = await Tile.db.find(
          session,
          where: (t) => t.circleId.equals(circle.space),
        );
        expect(
          after.map((t) => (t.id, t.cellKey, t.label)),
          before.map((t) => (t.id, t.cellKey, t.label)),
        );
      });

      test('when a word was archived or never placed then the copy leaves it '
          'out.', () async {
        final circle = await circles.create();
        final tiles = await circles.addTiles(circle, ['eat', 'old']);
        await session.serverpod.withSession(
          (server) => server.offlineSyncDb.transactionForUser(
            circle.guardian.id,
            (tx) => Tile.db.updateRow(
              server,
              tiles[1].copyWith(
                archivedAt: DateTime.now().toUtc(),
                cellKey: 'tray:${tiles[1].id!.uuid}',
              ),
              columns: (t) => [t.archivedAt, t.cellKey],
              transaction: tx,
            ),
            spaceId: circle.space,
          ),
          enableLogging: false,
        );

        final copy = await copies.take(
          circle.guardian.session,
          circle.space,
          circle.board,
          'Now',
        );
        expect(copy.words.map((w) => w.label), ['eat']);
      });

      test('when copies are listed then every member sees them newest first '
          'without words, and gets one with its words.', () async {
        final circle = await circles.create();
        await circles.addTiles(circle, ['go']);
        final mum = circle.guardian.session;
        final first = await copies.take(mum, circle.space, circle.board, 'One');
        final second = await copies.take(
          mum,
          circle.space,
          circle.board,
          'Two',
        );

        final partner = await circles.member(circle, CircleRole.partner);
        final listed = await copies.list(partner.session, circle.space);
        expect(listed.map((c) => c.id), [second.id, first.id]);
        expect(listed.first.words, isEmpty);
        expect(listed.first.wordCount, 1);

        final got = await copies.get(partner.session, circle.space, first.id);
        expect(got!.name, 'One');
        expect(got.words.single.label, 'go');
        expect(await copies.get(partner.session, circle.space, -1), isNull);
      });

      test('when a copy is deleted then it is gone, and deleting again says '
          'so.', () async {
        final circle = await circles.create();
        final mum = circle.guardian.session;
        final copy = await copies.take(mum, circle.space, circle.board, 'Old');
        expect(await copies.delete(mum, circle.space, copy.id), isTrue);
        expect(await copies.delete(mum, circle.space, copy.id), isFalse);
        expect(await copies.list(mum, circle.space), isEmpty);
      });

      test('when a partner or a stranger takes or deletes then it is refused; '
          'a stranger cannot read either.', () async {
        final circle = await circles.create();
        final copy = await copies.take(
          circle.guardian.session,
          circle.space,
          circle.board,
          'Kept',
        );
        final teacher = await circles.member(circle, CircleRole.teacher);
        expect(
          (await copies.take(
            teacher.session,
            circle.space,
            circle.board,
            'Teacher',
          )).name,
          'Teacher',
        );
        final partner = await circles.member(circle, CircleRole.partner);
        await expectLater(
          copies.take(partner.session, circle.space, circle.board, 'Mine'),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          copies.delete(partner.session, circle.space, copy.id),
          refusedWith(CircleFailure.notAllowed),
        );
        final stranger = circles.user();
        await expectLater(
          copies.list(stranger.session, circle.space),
          refusedWith(CircleFailure.notAMember),
        );
        await expectLater(
          copies.get(stranger.session, circle.space, copy.id),
          refusedWith(CircleFailure.notAMember),
        );
      });

      test('when a copy belongs to another circle, or the board does not, '
          'then it is refused or not found.', () async {
        final ours = await circles.create();
        final theirs = await circles.create(child: 'Sam');
        final theirCopy = await copies.take(
          theirs.guardian.session,
          theirs.space,
          theirs.board,
          'Theirs',
        );
        final mum = ours.guardian.session;
        expect(await copies.get(mum, ours.space, theirCopy.id), isNull);
        expect(await copies.delete(mum, ours.space, theirCopy.id), isFalse);
        await expectLater(
          copies.take(mum, ours.space, theirs.board, 'Steal'),
          refusedWith(CircleFailure.notAllowed),
        );
        await expectLater(
          copies.take(mum, ours.space, ours.board, ' '),
          refusedWith(CircleFailure.notAllowed),
        );
        expect(
          (await copies.list(theirs.guardian.session, theirs.space)).single.id,
          theirCopy.id,
        );
      });
    },
  );
}
