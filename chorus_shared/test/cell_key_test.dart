import 'package:chorus_shared/src/cell_key.dart';
import 'package:test/test.dart';

const board = '3f2a9c1e-7b4d-4e8a-9c10-5d6e7f8a9b0c';
const tileId = '0b8f4a52-1c3d-4e5f-8a6b-7c8d9e0f1a2b';
const reserved = ['__conflict__', '__hidden__', '__park__'];

void main() {
  group('placed keys', () {
    test('format as board:row:col', () {
      expect(placedKey(board, 2, 5), '$board:2:5');
      expect(const PlacedCell(board, 0, 0).format(), '$board:0:0');
    });

    test('round trip', () {
      for (final (row, col) in [(0, 0), (2, 5), (11, 10), (0, 123)]) {
        final parsed = CellKey.parse(placedKey(board, row, col));
        expect(parsed, PlacedCell(board, row, col));
        expect((parsed as PlacedCell).format(), placedKey(board, row, col));
      }
    });

    test('reject fields that would not parse back', () {
      expect(() => placedKey('', 0, 0), throwsArgumentError);
      expect(() => placedKey('a:b', 0, 0), throwsArgumentError);
      expect(() => placedKey('tray', 0, 0), throwsArgumentError);
      expect(() => placedKey(board, -1, 0), throwsArgumentError);
      expect(() => placedKey(board, 0, -1), throwsArgumentError);
    });
  });

  group('tray keys', () {
    test('format as tray:tileId', () {
      expect(trayKey(tileId), 'tray:$tileId');
      expect(const TrayCell(tileId).format(), 'tray:$tileId');
    });

    test('round trip', () {
      final parsed = CellKey.parse(trayKey(tileId));
      expect(parsed, const TrayCell(tileId));
      expect((parsed as TrayCell).format(), trayKey(tileId));
    });

    test('reject ids that would not parse back', () {
      expect(() => trayKey(''), throwsArgumentError);
      expect(() => trayKey('a:b'), throwsArgumentError);
    });
  });

  group('engine-suffixed keys', () {
    test('parse into ContestedCell', () {
      final parsed = CellKey.parse('$board:1:4${conflictMarker}row7');
      expect(parsed, const ContestedCell(board, 1, 4, 'row7'));
      expect((parsed as ContestedCell).wanted, const PlacedCell(board, 1, 4));
    });

    test('keep a UUID row id with its dashes', () {
      final parsed = CellKey.parse('$board:3:0$conflictMarker$tileId');
      expect(parsed, isA<ContestedCell>());
      parsed as ContestedCell;
      expect(parsed.loserRowId, tileId);
      expect(parsed.wanted.format(), '$board:3:0');
    });

    test('are unknown when the suffix or the cell is malformed', () {
      for (final raw in [
        '$board:1:4$conflictMarker',
        '$board:1$conflictMarker$tileId',
        '$board:-1:4$conflictMarker$tileId',
        'tray:$tileId$conflictMarker$tileId',
        '$conflictMarker$tileId',
        '$board:1:4${conflictMarker}a${conflictMarker}b',
      ]) {
        expect(CellKey.parse(raw), UnknownCell(raw), reason: raw);
      }
    });
  });

  group('malformed keys become UnknownCell', () {
    final cases = {
      'empty string': '',
      'board id only': board,
      'missing col': '$board:1',
      'missing row and col values': '$board::',
      'missing board id': ':1:2',
      'negative row': '$board:-1:2',
      'negative col': '$board:1:-2',
      'non-numeric row': '$board:x:2',
      'non-numeric col': '$board:1:two',
      'fractional row': '$board:1.0:2',
      'signed row': '$board:+1:2',
      'leading zero': '$board:01:2',
      'padded col': '$board:1: 2',
      'extra colon at end': '$board:1:2:',
      'extra part': '$board:1:2:3',
      'extra colon at start': ':$board:1:2',
      'empty tray id': 'tray:',
      'tray id with colon': 'tray:a:b',
      'tray without colon': 'tray',
      'hidden marker': '$board:1:2__hidden__$tileId',
      'park marker': 'tray:${tileId}__park__',
    };
    cases.forEach((name, raw) {
      test(name, () {
        final parsed = CellKey.parse(raw);
        expect(parsed, UnknownCell(raw));
        expect((parsed as UnknownCell).raw, raw);
      });
    });
  });

  group('assertAuthorable', () {
    test('returns an ordinary value unchanged', () {
      expect(assertAuthorable('$board:1:2'), '$board:1:2');
      expect(assertAuthorable(''), '');
      expect(assertAuthorable('_conflict_'), '_conflict_');
    });

    for (final marker in reserved) {
      test('rejects $marker', () {
        expect(() => assertAuthorable(marker), throwsArgumentError);
        expect(() => assertAuthorable('$board:1:2$marker$tileId'),
            throwsArgumentError);
        expect(() => assertAuthorable('${marker}x'), throwsArgumentError);
      });
    }
  });

  group('placedKey and trayKey never emit a marker', () {
    for (final marker in reserved) {
      test(marker, () {
        expect(() => placedKey('$board$marker', 1, 2), throwsArgumentError);
        expect(() => placedKey('${marker}x', 1, 2), throwsArgumentError);
        expect(() => trayKey('$tileId$marker'), throwsArgumentError);
        expect(() => trayKey('$marker$tileId'), throwsArgumentError);
        expect(() => PlacedCell('$board$marker', 1, 2).format(),
            throwsArgumentError);
        expect(() => TrayCell('x$marker').format(), throwsArgumentError);
      });
    }

    test('valid keys contain none', () {
      for (final key in [placedKey(board, 5, 5), trayKey(tileId)]) {
        for (final marker in reserved) {
          expect(key.contains(marker), isFalse);
        }
      }
    });

    test('a contested tile cannot be re-authored at its lost key', () {
      final raw = '$board:1:4$conflictMarker$tileId';
      expect(() => assertAuthorable(raw), throwsArgumentError);
      final wanted = (CellKey.parse(raw) as ContestedCell).wanted;
      expect(wanted.format(), '$board:1:4');
    });
  });

  group('value semantics', () {
    test('equality and hashCode', () {
      expect(PlacedCell(board, 1, 2), PlacedCell(board, 1, 2));
      expect(PlacedCell(board, 1, 2).hashCode, PlacedCell(board, 1, 2).hashCode);
      expect(PlacedCell(board, 1, 2), isNot(PlacedCell(board, 2, 1)));
      expect(ContestedCell(board, 1, 2, 'a'), ContestedCell(board, 1, 2, 'a'));
      expect(ContestedCell(board, 1, 2, 'a'),
          isNot(ContestedCell(board, 1, 2, 'b')));
      expect(ContestedCell(board, 1, 2, 'a'), isNot(PlacedCell(board, 1, 2)));
      expect(TrayCell('a'), TrayCell('a'));
      expect(TrayCell('a'), isNot(TrayCell('b')));
      expect(TrayCell('a'), isNot(UnknownCell('a')));
      expect(UnknownCell('a'), UnknownCell('a'));
      expect({PlacedCell(board, 1, 2), PlacedCell(board, 1, 2)}, hasLength(1));
    });

    test('toString names the form and its fields', () {
      expect(PlacedCell(board, 1, 2).toString(), 'PlacedCell($board, 1, 2)');
      expect(ContestedCell(board, 1, 2, 'r').toString(), contains('loser r'));
      expect(TrayCell('t').toString(), 'TrayCell(t)');
      expect(UnknownCell('??').toString(), 'UnknownCell("??")');
    });
  });
}
