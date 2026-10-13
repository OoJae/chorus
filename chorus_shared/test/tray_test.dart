import 'package:chorus_shared/src/cell_key.dart';
import 'package:chorus_shared/src/facts.dart';
import 'package:chorus_shared/src/tray.dart';
import 'package:test/test.dart';

const home = 'b0000000-0000-4000-8000-000000000001';
const food = 'b0000000-0000-4000-8000-000000000002';
const old = 'b0000000-0000-4000-8000-000000000003';
const gone = 'b0000000-0000-4000-8000-00000000dead';

const boards = [
  BoardFacts(id: home, name: 'Home', rows: 2, cols: 3, isHome: true),
  BoardFacts(id: food, name: 'Food', rows: 2, cols: 2),
  BoardFacts(id: old, name: 'Old', rows: 2, cols: 2, archived: true),
];

DateTime day(int d) => DateTime.utc(2026, 1, d);

TileFacts tile(String id, String cellKey,
        {DateTime? at, bool archived = false, String boardId = home}) =>
    TileFacts(
      id: id,
      boardId: boardId,
      cellKey: cellKey,
      label: id,
      archived: archived,
      createdAt: at,
    );

/// What the engine writes to the loser of a collision.
String lost(String boardId, int row, int col, String rowId) =>
    '$boardId:$row:$col$conflictMarker$rowId';

void main() {
  group('trayOf', () {
    test('is empty when every tile holds a cell', () {
      final tiles = [
        tile('a', placedKey(home, 0, 0), at: day(1)),
        tile('b', placedKey(food, 1, 1), at: day(2), boardId: food),
      ];
      expect(trayOf(tiles, boards), isEmpty);
    });

    test('contested: an engine-suffixed key, with the cell it lost', () {
      final t = tile('loser', lost(home, 1, 2, 'loser'), at: day(1));
      final tray = trayOf([tile('winner', placedKey(home, 1, 2)), t], boards);
      expect(tray, hasLength(1));
      expect(tray.single.tile, t);
      expect(tray.single.reason, TrayReason.contested);
      expect(tray.single.wanted, const PlacedCell(home, 1, 2));
    });

    test('unplaced: a tray key', () {
      final t = tile('a', trayKey('a'));
      final tray = trayOf([t], boards);
      expect(tray.single.tile, t);
      expect(tray.single.reason, TrayReason.unplaced);
      expect(tray.single.wanted, isNull);
    });

    test('offGrid: missing board, archived board, outside the grid, unknown',
        () {
      final tiles = [
        tile('1-missing', placedKey(gone, 0, 0)),
        tile('2-archived-board', placedKey(old, 0, 0)),
        tile('3-row-out', placedKey(home, 2, 0)),
        tile('4-col-out', placedKey(home, 0, 3)),
        tile('5-unknown', 'not a key'),
        tile('6-empty', ''),
        tile('7-hidden', '$home:0:0__hidden__x'),
      ];
      final tray = trayOf(tiles, boards);
      expect(tray.map((e) => e.tile.id), tiles.map((t) => t.id));
      expect(tray.map((e) => e.reason), everyElement(TrayReason.offGrid));
      expect(tray.map((e) => e.wanted), everyElement(isNull));
    });

    test('duplicateCell: the later of two tiles with one placed key', () {
      final first = tile('z', placedKey(home, 0, 1), at: day(1));
      final second = tile('a', placedKey(home, 0, 1), at: day(2));
      final tray = trayOf([second, first], boards);
      expect(tray, [
        TrayEntry(second, TrayReason.duplicateCell,
            wanted: const PlacedCell(home, 0, 1)),
      ]);
    });

    test('orders by createdAt, nulls last, then id', () {
      final tiles = [
        tile('n2', trayKey('n2')),
        tile('d', trayKey('d'), at: day(3)),
        tile('c2', lost(home, 0, 0, 'c2'), at: day(2)),
        tile('n1', 'junk'),
        tile('c1', placedKey(gone, 0, 0), at: day(2)),
        tile('e', trayKey('e'), at: day(1)),
      ];
      expect(trayOf(tiles, boards).map((e) => e.tile.id),
          ['e', 'c1', 'c2', 'd', 'n1', 'n2']);
      expect(trayOf(tiles.reversed, boards).map((e) => e.tile.id),
          ['e', 'c1', 'c2', 'd', 'n1', 'n2']);
    });

    test('excludes archived tiles whatever their key', () {
      final tiles = [
        tile('a', trayKey('a'), archived: true),
        tile('b', lost(home, 0, 0, 'b'), archived: true),
        tile('c', placedKey(gone, 0, 0), archived: true),
        tile('d', 'junk', archived: true),
        tile('e', placedKey(home, 0, 0), archived: true),
      ];
      expect(trayOf(tiles, boards), isEmpty);
    });

    test('an archived tile does not make a live one a duplicate', () {
      final tiles = [
        tile('a', placedKey(home, 0, 0), at: day(1), archived: true),
        tile('b', placedKey(home, 0, 0), at: day(2)),
      ];
      expect(trayOf(tiles, boards), isEmpty);
      expect(gridOf(home, tiles, boards)[(0, 0)]!.id, 'b');
    });
  });

  group('gridOf', () {
    test('keys the tiles of one board by (row, col)', () {
      final a = tile('a', placedKey(home, 0, 0));
      final b = tile('b', placedKey(home, 1, 2));
      final f = tile('f', placedKey(food, 0, 0), boardId: food);
      expect(gridOf(home, [a, b, f], boards), {(0, 0): a, (1, 2): b});
      expect(gridOf(food, [a, b, f], boards), {(0, 0): f});
    });

    test('excludes archived, tray, contested and off-grid tiles', () {
      final kept = tile('kept', placedKey(home, 0, 0));
      final tiles = [
        kept,
        tile('archived', placedKey(home, 0, 1), archived: true),
        tile('tray', trayKey('tray')),
        tile('contested', lost(home, 0, 2, 'contested')),
        tile('row-out', placedKey(home, 2, 0)),
        tile('col-out', placedKey(home, 1, 3)),
        tile('unknown', '$home:1'),
      ];
      expect(gridOf(home, tiles, boards), {(0, 0): kept});
    });

    test('is empty for a missing or archived board', () {
      final tiles = [
        tile('a', placedKey(gone, 0, 0), boardId: gone),
        tile('b', placedKey(old, 0, 0), boardId: old),
      ];
      expect(gridOf(gone, tiles, boards), isEmpty);
      expect(gridOf(old, tiles, boards), isEmpty);
    });

    group('duplicate cell tie-break', () {
      final key = placedKey(home, 1, 1);

      void expectHolder(List<TileFacts> tiles, String winner, String loser) {
        for (final order in [tiles, tiles.reversed.toList()]) {
          expect(gridOf(home, order, boards)[(1, 1)]!.id, winner);
          final tray = trayOf(order, boards);
          expect(tray.single.tile.id, loser);
          expect(tray.single.reason, TrayReason.duplicateCell);
          expect(tray.single.wanted, const PlacedCell(home, 1, 1));
        }
      }

      test('earliest createdAt holds the cell', () {
        expectHolder(
            [tile('a', key, at: day(5)), tile('z', key, at: day(4))], 'z', 'a');
      });

      test('a tile without createdAt loses to one with it', () {
        expectHolder([tile('a', key), tile('z', key, at: day(9))], 'z', 'a');
      });

      test('equal createdAt falls back to the smallest id', () {
        expectHolder(
            [tile('b', key, at: day(1)), tile('a', key, at: day(1))], 'a', 'b');
      });

      test('no createdAt on either falls back to the smallest id', () {
        expectHolder([tile('b', key), tile('a', key)], 'a', 'b');
      });

      test('three claimants leave two in the tray, oldest first', () {
        final tiles = [
          tile('c', key, at: day(3)),
          tile('a', key, at: day(1)),
          tile('b', key, at: day(2)),
        ];
        expect(gridOf(home, tiles, boards)[(1, 1)]!.id, 'a');
        expect(trayOf(tiles, boards).map((e) => e.tile.id), ['b', 'c']);
      });
    });
  });

  group('emptyCells', () {
    final homeBoard = boards[0];

    test('lists every cell of a bare board in row-major order', () {
      expect(emptyCells(homeBoard, const [], boards),
          [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2)]);
    });

    test('skips held cells and keeps row-major order', () {
      final tiles = [
        tile('a', placedKey(home, 1, 0)),
        tile('b', placedKey(home, 0, 1)),
        tile('f', placedKey(food, 0, 0), boardId: food),
      ];
      expect(emptyCells(homeBoard, tiles, boards),
          [(0, 0), (0, 2), (1, 1), (1, 2)]);
    });

    test('counts cells of tray, contested and archived tiles as empty', () {
      final tiles = [
        tile('a', trayKey('a')),
        tile('b', lost(home, 0, 0, 'b')),
        tile('c', placedKey(home, 0, 1), archived: true),
      ];
      expect(emptyCells(homeBoard, tiles, boards), hasLength(6));
    });

    test('is empty when the board is full or archived', () {
      final full = [
        for (var r = 0; r < 2; r++)
          for (var c = 0; c < 2; c++)
            tile('f$r$c', placedKey(food, r, c), boardId: food),
      ];
      expect(emptyCells(boards[1], full, boards), isEmpty);
      expect(emptyCells(boards[2], const [], boards), isEmpty);
    });

    test('is empty for a board absent from boards', () {
      const stray = BoardFacts(id: gone, name: 'Gone', rows: 2, cols: 2);
      expect(emptyCells(stray, const [], boards), isEmpty);
      expect(emptyCells(homeBoard, const [], const []), isEmpty);
    });

    test('uses the size and archived flag of the listed board', () {
      const stale = BoardFacts(id: home, name: 'Home', rows: 4, cols: 4);
      expect(emptyCells(stale, [tile('a', placedKey(home, 0, 0))], boards),
          [(0, 1), (0, 2), (1, 0), (1, 1), (1, 2)]);
      const staleOld = BoardFacts(id: old, name: 'Old', rows: 2, cols: 2);
      expect(emptyCells(staleOld, const [], boards), isEmpty);
    });
  });
}
