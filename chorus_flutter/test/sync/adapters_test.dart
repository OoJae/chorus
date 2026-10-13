import 'package:chorus_client/chorus_client.dart' as api;
import 'package:chorus_flutter/src/sync/adapters.dart';
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final circle = api.UuidValue.fromString(
    '0198F0AA-1111-7222-8333-444455556666',
  );
  final boardId = api.UuidValue.fromString(
    '0198F0AA-AAAA-7BBB-8CCC-DDDDEEEEFFFF',
  );
  final tileId = api.UuidValue.fromString(
    '0198F0AA-0000-7000-8000-00000000ABCD',
  );
  final author = api.UuidValue.fromString(
    '0198F0AA-9999-7999-8999-99999999FFFF',
  );
  final at = DateTime.utc(2026, 10, 13, 12);

  api.Tile tile({String? cellKey, DateTime? archivedAt}) => api.Tile(
    id: tileId,
    circleId: circle,
    boardId: boardId,
    cellKey: cellKey ?? placedKey(idOf(boardId), 2, 3),
    label: 'more',
    speech: 'more please',
    colorKey: 'descriptor',
    imageHash: 'img',
    audioHash: 'aud',
    noLog: false,
    archivedAt: archivedAt,
    createdBy: author,
    createdByName: 'Ada',
    createdAt: at,
  );

  group('ids', () {
    test('idOf lowercases', () {
      expect(idOf(circle), '0198f0aa-1111-7222-8333-444455556666');
    });

    test('uuidOf accepts either case and round-trips', () {
      expect(
        idOf(uuidOf('0198F0AA-1111-7222-8333-444455556666')),
        idOf(circle),
      );
      expect(uuidOf(idOf(circle)), uuidOf(circle.uuid));
    });
  });

  group('roleOf', () {
    test('maps every role by name', () {
      for (final role in api.CircleRole.values) {
        expect(roleOf(role).name, role.name);
      }
    });

    test('only the partner is read-only', () {
      expect(roleOf(api.CircleRole.partner).canEdit, isFalse);
      expect(roleOf(api.CircleRole.guardian), CircleRole.guardian);
      expect(roleOf(api.CircleRole.therapist).canEdit, isTrue);
      expect(roleOf(api.CircleRole.teacher).canEdit, isTrue);
    });
  });

  group('boardFacts', () {
    api.Board board({DateTime? archivedAt}) => api.Board(
      id: boardId,
      circleId: circle,
      name: 'Home',
      rows: 6,
      cols: 5,
      isHome: true,
      archivedAt: archivedAt,
      createdAt: at,
    );

    test('copies the fields with a lowercase id', () {
      expect(
        boardFacts(board()),
        BoardFacts(
          id: '0198f0aa-aaaa-7bbb-8ccc-ddddeeeeffff',
          name: 'Home',
          rows: 6,
          cols: 5,
          isHome: true,
        ),
      );
    });

    test('archived means archivedAt is set', () {
      expect(boardFacts(board()).archived, isFalse);
      expect(boardFacts(board(archivedAt: at)).archived, isTrue);
    });
  });

  group('tileFacts', () {
    test('copies the fields with lowercase ids', () {
      final facts = tileFacts(tile());
      expect(facts.id, '0198f0aa-0000-7000-8000-00000000abcd');
      expect(facts.boardId, '0198f0aa-aaaa-7bbb-8ccc-ddddeeeeffff');
      expect(facts.cellKey, '0198f0aa-aaaa-7bbb-8ccc-ddddeeeeffff:2:3');
      expect(facts.label, 'more');
      expect(facts.speech, 'more please');
      expect(facts.spokenText, 'more please');
      expect(facts.colorKey, 'descriptor');
      expect(facts.imageHash, 'img');
      expect(facts.audioHash, 'aud');
      expect(facts.createdBy, '0198f0aa-9999-7999-8999-99999999ffff');
      expect(facts.createdByName, 'Ada');
      expect(facts.createdAt, at);
      expect(facts.archived, isFalse);
    });

    test('archived means archivedAt is set', () {
      expect(tileFacts(tile(archivedAt: at)).archived, isTrue);
    });

    test('a key the engine suffixed is passed through untouched', () {
      final raw =
          '${placedKey(idOf(boardId), 2, 3)}$conflictMarker'
          '${idOf(tileId)}';
      final facts = tileFacts(tile(cellKey: raw));
      expect(facts.cellKey, raw);
      expect(CellKey.parse(facts.cellKey), isA<ContestedCell>());
    });

    test('the placed key built from a mapped board id parses back', () {
      final facts = tileFacts(tile());
      expect(
        CellKey.parse(facts.cellKey),
        PlacedCell(facts.boardId, 2, 3),
      );
    });
  });

  group('starter rows', () {
    final circleId = idOf(circle);

    test('the board row carries the deterministic id and the circle', () {
      final row = starterBoardRow(
        starterBoard(circleId),
        circleId: circle,
        createdAt: at,
      );
      expect(idOf(row.id!), starterBoardId(circleId));
      expect(row.circleId, circle);
      expect(row.isHome, isTrue);
      expect((row.rows, row.cols), (starterRows, starterCols));
      expect(row.archivedAt, isNull);
      expect(boardFacts(row), starterBoard(circleId));
    });

    test('tile rows map back to the facts they came from', () {
      final facts = starterTiles(
        circleId: circleId,
        createdBy: idOf(author),
        createdByName: 'Ada',
        createdAt: at,
      );
      final rows = [
        for (final tile in facts)
          starterTileRow(tile, circleId: circle, createdAt: at),
      ];
      expect(rows, hasLength(36));
      expect([for (final row in rows) tileFacts(row)], facts);
      expect({for (final row in rows) row.cellKey}, hasLength(36));
      expect(rows.every((row) => row.circleId == circle), isTrue);
    });

    test('a tile without a creation time gets the seeding time', () {
      final facts = starterTiles(
        circleId: circleId,
        createdBy: idOf(author),
        createdByName: 'Ada',
      ).first;
      final row = starterTileRow(facts, circleId: circle, createdAt: at);
      expect(row.createdAt, at);
    });
  });

  group('authoredKey', () {
    final board = idOf(boardId);

    test('rebuilds placed and tray keys', () {
      expect(authoredKey('$board:0:5'), placedKey(board, 0, 5));
      expect(authoredKey('tray:${idOf(tileId)}'), trayKey(idOf(tileId)));
    });

    test('refuses a contested or unknown key', () {
      expect(
        () => authoredKey('$board:0:5$conflictMarker${idOf(tileId)}'),
        throwsArgumentError,
      );
      expect(() => authoredKey('nonsense'), throwsArgumentError);
      expect(() => authoredKey('$board:0:5__hidden__x'), throwsArgumentError);
    });
  });

  group('loggedKey', () {
    final board = idOf(boardId);

    test('placed and tray keys are logged as they are', () {
      expect(loggedKey('$board:1:2'), '$board:1:2');
      expect(loggedKey('tray:${idOf(tileId)}'), 'tray:${idOf(tileId)}');
    });

    test('a contested key is logged as the cell it asked for', () {
      final logged = loggedKey('$board:1:2$conflictMarker${idOf(tileId)}');
      expect(logged, '$board:1:2');
      expect(logged, isNot(contains(conflictMarker)));
    });

    test('an unknown key is logged as null', () {
      expect(loggedKey('nonsense'), isNull);
    });
  });
}
