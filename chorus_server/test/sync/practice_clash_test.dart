/// "Try a clash": the practice partner's word and a paused device's word in
/// the same cell, end to end through the real endpoint and real replicas.
///
/// Run with `dart test test/sync/practice_clash_test.dart --concurrency=1`.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

import 'replicas.dart';

/// Matches a [PracticeException] carrying [failure].
Matcher practiceFails(PracticeFailure failure) => throwsA(
  isA<PracticeException>().having((e) => e.failure, 'failure', failure),
);

/// Matches a [CircleException] carrying [failure].
Matcher circleFails(CircleFailure failure) => throwsA(
  isA<CircleException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  withSyncWorld('Given a circle trying a clash,', (world) {
    test(
      'when the practice partner fills a cell on the server and a paused '
      'device puts its own word in the same cell, then both words survive: '
      'one holds the cell, the other is parked by the engine, everywhere.',
      () async {
        final [guardian, teacher] = await world.users(['Guardian', 'Teacher']);
        final circle = await world.circle(
          guardian,
          members: {teacher: CircleRole.teacher},
        );
        final board = await world.emptyBoard(circle, guardian, [
          guardian,
          teacher,
        ]);
        final cell = placedKey(board.id, 2, 3);

        // The guardian's device has "Work offline" on: it does not sync from
        // here until the end.
        final word = await guardian.client.practice.partnerWord(
          circle,
          UuidValue.fromString(board.id),
          cell,
        );
        expect(word.cellKey, cell);
        expect(word.partnerName, 'Practice partner');
        expect(word.label, 'bubbles');

        await Future<void>.delayed(tick);
        final mine = await guardian.insertTile(
          circle,
          guardian.newTile(circle, board, 'juice', cellKey: cell),
        );
        // Before syncing, the paused device holds only its own word.
        expect(
          (await guardian.tiles(circle)).map((t) => t.label),
          unorderedEquals(['juice']),
        );

        final rounds = await world.converge(circle, [guardian, teacher]);
        note('practice', 'rounds to converge', rounds);

        final views = {
          'server': await world.serverTiles(circle),
          'guardian': await guardian.tiles(circle),
          'teacher': await teacher.tiles(circle),
        };
        for (final MapEntry(key: where, value: tiles) in views.entries) {
          expect(tiles, hasLength(2), reason: where);
          final partner = tiles.singleWhere((t) => t.id == word.tileId.uuid);
          final own = tiles.singleWhere((t) => t.id == mine.id!.uuid);
          expect(partner.label, 'bubbles', reason: where);
          expect(partner.createdByName, 'Practice partner', reason: where);
          final keys = {partner.cellKey, own.cellKey};
          note('practice', 'keys on $where', keys.toList());
          // Exactly one holds the cell, and the other waits with the
          // engine's suffix; nothing is lost.
          expect(keys, contains(cell), reason: where);
          final parked = keys.singleWhere((k) => k != cell);
          expect(parked, startsWith('$cell$conflictMarker'), reason: where);
          expect(CellKey.parse(parked), isA<ContestedCell>(), reason: where);

          final tray = trayOf(tiles, [board]);
          expect(tray, hasLength(1), reason: where);
          expect(tray.single.reason, TrayReason.contested, reason: where);
          expect(tray.single.wanted, PlacedCell(board.id, 2, 3), reason: where);
          expect(gridOf(board.id, tiles, [board]), hasLength(1), reason: where);
        }
        // The partner wrote first, so here the earlier claim is the partner's.
        final server = views['server']!;
        expect(
          server.singleWhere((t) => t.cellKey == cell).id,
          word.tileId.uuid,
        );
      },
    );

    test(
      'when the partner adds a word then every device that syncs sees it '
      'in that cell, and its next word avoids labels on the board.',
      () async {
        final [guardian] = await world.users(['Guardian']);
        final circle = await world.circle(guardian);
        final board = await world.emptyBoard(circle, guardian, [guardian]);
        await guardian.insertTile(
          circle,
          guardian.newTile(
            circle,
            board,
            'Bubbles',
            cellKey: placedKey(board.id, 0, 0),
          ),
        );
        await world.converge(circle, [guardian]);

        final word = await guardian.client.practice.partnerWord(
          circle,
          UuidValue.fromString(board.id),
          placedKey(board.id, 0, 1),
        );
        expect(word.label, 'swing');
        await world.converge(circle, [guardian]);
        final tiles = await guardian.tiles(circle);
        expect(
          gridOf(board.id, tiles, [board])[(0, 1)]?.label,
          'swing',
        );
        // It logs its first values as `add` edits, as a device does, so
        // "What changed" names the partner.
        final adds = [
          for (final edit in await guardian.edits(circle))
            if (edit.tileId == word.tileId) edit,
        ];
        expect(
          {for (final edit in adds) edit.prop: edit.newValue},
          {
            'label': 'swing',
            'cellKey': placedKey(board.id, 0, 1),
            'colorKey': 'noun',
          },
        );
        for (final edit in adds) {
          expect(edit.reason, 'add');
          expect(edit.actorName, 'Practice partner');
          expect(edit.oldValue, isNull);
        }
      },
    );

    test('when the cell already holds a word on the server then the partner '
        'refuses with cellTaken and writes nothing.', () async {
      final [guardian] = await world.users(['Guardian']);
      final circle = await world.circle(guardian);
      final board = await world.emptyBoard(circle, guardian, [guardian]);
      final cell = placedKey(board.id, 1, 1);
      await guardian.insertTile(
        circle,
        guardian.newTile(circle, board, 'juice', cellKey: cell),
      );
      await world.converge(circle, [guardian]);

      await expectLater(
        guardian.client.practice.partnerWord(
          circle,
          UuidValue.fromString(board.id),
          cell,
        ),
        practiceFails(PracticeFailure.cellTaken),
      );
      expect(await world.serverTiles(circle), hasLength(1));
    });

    test('when the cell is not a cell of a board in this circle then the '
        'partner refuses with noSuchCell.', () async {
      final [guardian] = await world.users(['Guardian']);
      final circle = await world.circle(guardian);
      final board = await world.emptyBoard(circle, guardian, [guardian]);
      final id = UuidValue.fromString(board.id);
      for (final key in [
        trayKey('x'),
        'nonsense',
        placedKey(board.id, board.rows, 0),
        placedKey(board.id, 0, board.cols),
        '${placedKey(board.id, 0, 0)}${conflictMarker}abc',
      ]) {
        await expectLater(
          guardian.client.practice.partnerWord(circle, id, key),
          practiceFails(PracticeFailure.noSuchCell),
          reason: key,
        );
      }
      final other = const Uuid().v7obj();
      await expectLater(
        guardian.client.practice.partnerWord(
          circle,
          other,
          placedKey(other.uuid, 0, 0),
        ),
        practiceFails(PracticeFailure.noSuchCell),
      );
      expect(await world.serverTiles(circle), isEmpty);
    });

    test('when a circle has had thirty practice words in the hour then the '
        'next is refused with tooMany.', () async {
      final [guardian] = await world.users(['Guardian']);
      final circle = await world.circle(guardian);
      final board = await world.emptyBoard(circle, guardian, [guardian]);
      final id = UuidValue.fromString(board.id);
      for (var i = 0; i < 30; i++) {
        await guardian.client.practice.partnerWord(
          circle,
          id,
          placedKey(board.id, i ~/ 6, i % 6),
        );
      }
      await expectLater(
        guardian.client.practice.partnerWord(
          circle,
          id,
          placedKey(board.id, 5, 0),
        ),
        practiceFails(PracticeFailure.tooMany),
      );
      expect(await world.serverTiles(circle), hasLength(30));
    });

    test(
      'when a read-only partner or someone outside the circle asks then '
      'they are refused, and the partner never joins the circle list.',
      () async {
        final [guardian, viewer, stranger] = await world.users([
          'Guardian',
          'Viewer',
          'Stranger',
        ]);
        final circle = await world.circle(
          guardian,
          members: {viewer: CircleRole.partner},
        );
        final board = await world.emptyBoard(circle, guardian, [guardian]);
        final id = UuidValue.fromString(board.id);
        final cell = placedKey(board.id, 0, 0);
        await expectLater(
          viewer.client.practice.partnerWord(circle, id, cell),
          circleFails(CircleFailure.notAllowed),
        );
        await expectLater(
          stranger.client.practice.partnerWord(circle, id, cell),
          circleFails(CircleFailure.notAMember),
        );

        await guardian.client.practice.partnerWord(circle, id, cell);
        final circles = await guardian.client.circle.myCircles();
        final members = circles
            .singleWhere((c) => c.spaceUuid == circle)
            .members;
        expect(
          members.map((m) => m.displayName),
          isNot(contains('Practice partner')),
        );
      },
    );
  });
}
