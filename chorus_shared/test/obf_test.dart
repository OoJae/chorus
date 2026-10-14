import 'dart:convert';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

void main() {
  const circle = '6f1d2c3a-0b4e-4c5d-8e9f-a1b2c3d4e5f6';
  final home = starterBoard(circle);
  final starter = starterTiles(
    circleId: circle,
    createdBy: '11111111-2222-4333-8444-555555555555',
    createdByName: 'Mum',
    createdAt: DateTime.utc(2026, 10, 13),
  );

  /// The example board in the OBF 0.1 spec: a 1 x 2 grid, a translucent
  /// colour, a picture and a link to another board.
  const specExample = '''
{
  "format": "open-board-0.1",
  "id": "1",
  "locale": "en",
  "url": "http://www.myboards.com/boards/1",
  "name": "Example Board",
  "description_html": "This is just a simple example board I put together.",
  "buttons": [
    {
      "id": "1",
      "label": "happy",
      "image_id": "2",
      "border_color": "rgb(0, 0, 55)",
      "background_color": "rgba(100, 5, 23, 0)"
    },
    {
      "id": "2",
      "label": "drinks",
      "image_id": "2",
      "load_board": {
        "id": "2",
        "url": "http://www.myboards.com/boards/2",
        "data_url": "http://www.myboards.com/api/boards/2",
        "path": "boards/2.obf"
      }
    }
  ],
  "grid": {
    "rows": 1,
    "columns": 2,
    "order": [["1", "2"]]
  },
  "images": [
    {
      "id": "2",
      "url": "http://www.example.com/images/happy.png",
      "width": 300,
      "height": 300,
      "content_type": "image/png"
    }
  ],
  "sounds": [],
  "license": {"type": "private"}
}
''';

  /// A square OBF board of [size], every cell a word "w<row>-<col>".
  String square(int size) => jsonEncode({
    'format': 'open-board-0.1',
    'id': 'big',
    'name': 'Big',
    'buttons': [
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++) {'id': '$r-$c', 'label': 'w$r-$c'},
    ],
    'grid': {
      'rows': size,
      'columns': size,
      'order': [
        for (var r = 0; r < size; r++) [for (var c = 0; c < size; c++) '$r-$c'],
      ],
    },
  });

  group('round trip', () {
    test('the starter board comes back with every word, cell and colour', () {
      final obf = parseObf(obfJsonOf(home, starter));
      expect(obf.name, 'Home');
      expect(obf.rows, 6);
      expect(obf.columns, 6);
      final (:fitted, :leftOver) = obfPlacements(obf);
      expect(leftOver, isEmpty);
      expect(fitted, [
        for (final word in universalCore36)
          ObfPlacement(
            row: word.row,
            col: word.col,
            label: word.label,
            colorKey: word.colorKey,
          ),
      ]);
    });

    test('spoken text, plain tiles and empty cells survive', () {
      const board = BoardFacts(id: 'b', name: 'Family', rows: 2, cols: 3);
      final tiles = [
        TileFacts(
          id: 't1',
          boardId: 'b',
          cellKey: placedKey('b', 0, 0),
          label: 'Grandma',
          speech: 'Nana',
          imageHash: 'a' * 64,
        ),
        TileFacts(
          id: 't2',
          boardId: 'b',
          cellKey: placedKey('b', 1, 2),
          label: 'juice',
          colorKey: 'negation',
        ),
        TileFacts(
          id: 't3',
          boardId: 'b',
          cellKey: trayKey('t3'),
          label: 'waiting',
        ),
      ];
      final json = jsonDecode(obfJsonOf(board, tiles)) as Map<String, Object?>;
      expect(json['format'], 'open-board-0.1');
      expect(json['grid'], {
        'rows': 2,
        'columns': 3,
        'order': [
          ['t1', null, null],
          [null, null, 't2'],
        ],
      });
      expect(json['buttons'], [
        {
          'id': 't1',
          'label': 'Grandma',
          'vocalization': 'Nana',
          'background_color': 'rgb(255, 255, 255)',
        },
        {
          'id': 't2',
          'label': 'juice',
          'background_color': 'rgb(255, 210, 174)',
        },
      ]);
      expect(jsonEncode(json), isNot(contains('a' * 64)));

      final (:fitted, :leftOver) = obfPlacements(parseObf(jsonEncode(json)));
      expect(fitted, const [
        ObfPlacement(row: 0, col: 0, label: 'Grandma', speech: 'Nana'),
        ObfPlacement(row: 1, col: 2, label: 'juice', colorKey: 'negation'),
      ]);
      expect(leftOver, isEmpty);
    });

    test('carries the Universal Core licence block', () {
      final json = jsonDecode(obfJsonOf(home, starter)) as Map<String, Object?>;
      expect(json['license'], {
        'type': 'CC By-SA',
        'copyright_notice_url':
            'https://creativecommons.org/licenses/by-sa/4.0/',
        'author_name':
            'Center for Literacy and Disability Studies, UNC-Chapel Hill',
        'author_url': 'https://www.project-core.com',
      });
    });

    test('every tile colour is written as rgb()', () {
      final json = jsonDecode(obfJsonOf(home, starter)) as Map<String, Object?>;
      final colours = {
        for (final b in (json['buttons'] as List).cast<Map<String, Object?>>())
          b['label']: b['background_color'],
      };
      expect(colours['want'], 'rgb(199, 239, 178)');
      expect(colours['I'], 'rgb(255, 239, 160)');
      expect(colours['what'], 'rgb(221, 203, 255)');
      expect(colours['good'], 'rgb(192, 219, 255)');
      expect(colours['not'], 'rgb(255, 210, 174)');
      expect(colours['all'], 'rgb(229, 228, 224)');
    });
  });

  group('reading', () {
    test("the spec's example board", () {
      final obf = parseObf(specExample);
      expect(obf.id, '1');
      expect(obf.name, 'Example Board');
      expect(obf.rows, 1);
      expect(obf.columns, 2);
      expect(obf.order, [
        ['1', '2'],
      ]);
      final happy = obf.button('1')!;
      expect(happy.label, 'happy');
      expect(happy.imageId, '2');
      expect(happy.borderColor, 'rgb(0, 0, 55)');
      expect(happy.backgroundColor, 'rgba(100, 5, 23, 0)');
      expect(obf.button('2')!.label, 'drinks');

      final (:fitted, :leftOver) = obfPlacements(obf);
      // A fully transparent colour shows as a plain tile.
      expect(fitted, const [
        ObfPlacement(row: 0, col: 0, label: 'happy'),
        ObfPlacement(row: 0, col: 1, label: 'drinks'),
      ]);
      expect(leftOver, isEmpty);
    });

    test('numeric ids, empty cells and spoken text', () {
      final obf = parseObf(
        jsonEncode({
          'format': 'open-board-0.1',
          'id': 7,
          'name': '  Snacks ',
          'buttons': [
            {'id': 1, 'label': 'crisps', 'vocalization': 'I want crisps'},
            {'id': 2, 'vocalization': 'apple'},
            {'id': 3, 'label': 'clear', 'action': ':clear'},
            {'id': 4},
          ],
          'grid': {
            'rows': 2,
            'columns': 2.0,
            'order': [
              [1, null],
              [2, 3],
            ],
          },
        }),
      );
      expect(obf.id, '7');
      expect(obf.name, 'Snacks');
      expect(obf.order, [
        ['1', null],
        ['2', '3'],
      ]);
      expect(obfPlacements(obf).fitted, const [
        ObfPlacement(row: 0, col: 0, label: 'crisps', speech: 'I want crisps'),
        ObfPlacement(row: 1, col: 0, label: 'apple'),
      ]);
    });

    test('an 8 x 8 grid keeps the top-left 6 x 6 and lists the rest', () {
      final (:fitted, :leftOver) = obfPlacements(parseObf(square(8)));
      expect(fitted, hasLength(36));
      expect(leftOver, hasLength(64 - 36));
      expect(fitted.every((w) => w.row < 6 && w.col < 6), isTrue);
      expect(leftOver.every((w) => w.row >= 6 || w.col >= 6), isTrue);
      expect(fitted.first.label, 'w0-0');
      expect(fitted.last.label, 'w5-5');
      expect(leftOver.first, const ObfPlacement(row: 0, col: 6, label: 'w0-6'));
      expect(leftOver.last.label, 'w7-7');
    });

    test('labels and spoken text come onto one line, cut to what the '
        'add-word sheet allows', () {
      final obf = parseObf(
        jsonEncode({
          'format': 'open-board-0.1',
          'buttons': [
            {'id': 'long', 'label': 'a' * 50000, 'vocalization': 'b' * 50000},
            {
              'id': 'lines',
              'label': ' juice\n\nbox\t',
              'vocalization': 'x\u0000y',
            },
            {
              'id': 'controls',
              'label': 'go\u0085now\u007F',
              'vocalization': '',
            },
            {
              'id': 'speaks',
              'vocalization': 'I would like a drink of water please',
            },
            {'id': 'blank', 'label': '\n\u0001 ', 'vocalization': '\t'},
          ],
          'grid': {
            'rows': 1,
            'columns': 5,
            'order': [
              ['long', 'lines', 'controls', 'speaks', 'blank'],
            ],
          },
        }),
      );
      final words = obfPlacements(obf).fitted;
      expect(words, [
        ObfPlacement(
          row: 0,
          col: 0,
          label: 'a' * maxTileLabelLength,
          speech: 'b' * maxTileSpeechLength,
        ),
        const ObfPlacement(row: 0, col: 1, label: 'juice box', speech: 'x y'),
        const ObfPlacement(row: 0, col: 2, label: 'go now'),
        // Labelled with the start of what it says.
        const ObfPlacement(
          row: 0,
          col: 3,
          label: 'I would like a drink of water',
          speech: 'I would like a drink of water please',
        ),
      ]);
      expect(maxTileLabelLength, 30);
      expect(maxTileSpeechLength, 80);
    });

    test('a large board is placed without a search per cell', () {
      // 40,000 cells: searching the buttons for each one takes seconds.
      final board = parseObf(square(200));
      final watch = Stopwatch()..start();
      final (:fitted, :leftOver) = obfPlacements(board);
      watch.stop();
      expect(fitted, hasLength(36));
      expect(leftOver, hasLength(200 * 200 - 36));
      expect(leftOver.last.label, 'w199-199');
      expect(watch.elapsed, lessThan(const Duration(milliseconds: 500)));
    });

    test('a button id used twice reads as its first button', () {
      final board = ObfBoard(
        id: 'b',
        name: 'Twice',
        rows: 1,
        columns: 1,
        order: const [
          ['1'],
        ],
        buttons: const [
          ObfButton(id: '1', label: 'first'),
          ObfButton(id: '1', label: 'second'),
        ],
      );
      expect(board.button('1')!.label, 'first');
      expect(board.button('2'), isNull);
    });

    test('a smaller target grid fits fewer', () {
      final (:fitted, :leftOver) = obfPlacements(
        parseObf(square(3)),
        rows: 2,
        cols: 2,
      );
      expect(
        [for (final w in fitted) w.label],
        ['w0-0', 'w0-1', 'w1-0', 'w1-1'],
      );
      expect(leftOver, hasLength(5));
    });
  });

  group('bad files', () {
    Map<String, Object?> valid() =>
        jsonDecode(square(2)) as Map<String, Object?>;

    test('not JSON', () {
      expect(
        () => parseObf('PK\u0003\u0004 zip bytes'),
        throwsA(isA<ObfNotJson>()),
      );
      expect(() => parseObf(''), throwsA(isA<ObfNotJson>()));
    });

    test('the wrong format string', () {
      expect(
        () => parseObf(jsonEncode(valid()..['format'] = 'gridset-1')),
        throwsA(
          isA<ObfWrongFormat>().having((e) => e.found, 'found', 'gridset-1'),
        ),
      );
      expect(
        () => parseObf(jsonEncode(valid()..remove('format'))),
        throwsA(isA<ObfWrongFormat>()),
      );
      expect(() => parseObf('[1, 2]'), throwsA(isA<ObfWrongFormat>()));
    });

    test('a grid that does not match its rows and columns', () {
      Map<String, Object?> withGrid(Map<String, Object?> grid) =>
          valid()..['grid'] = grid;
      for (final grid in <Map<String, Object?>>[
        {
          'rows': 3,
          'columns': 2,
          'order': [
            ['0-0', '0-1'],
            ['1-0', '1-1'],
          ],
        },
        {
          'rows': 2,
          'columns': 3,
          'order': [
            ['0-0', '0-1'],
            ['1-0', '1-1'],
          ],
        },
        {'rows': 0, 'columns': 2, 'order': <Object>[]},
        {'rows': 2, 'columns': 2},
      ]) {
        expect(
          () => parseObf(jsonEncode(withGrid(grid))),
          throwsA(isA<ObfBadGrid>()),
          reason: '$grid',
        );
      }
      expect(
        () => parseObf(jsonEncode(valid()..remove('grid'))),
        throwsA(isA<ObfBadGrid>()),
      );
    });

    test('a grid naming a button that is not there', () {
      final json = valid();
      (json['buttons'] as List).removeAt(0);
      expect(
        () => parseObf(jsonEncode(json)),
        throwsA(isA<ObfUnknownButton>().having((e) => e.buttonId, 'id', '0-0')),
      );
    });

    test('buttons that are missing, without ids or sharing one', () {
      expect(
        () => parseObf(jsonEncode(valid()..remove('buttons'))),
        throwsA(isA<ObfBadButtons>()),
      );
      final noId = valid();
      (noId['buttons'] as List).add({'label': 'lost'});
      expect(() => parseObf(jsonEncode(noId)), throwsA(isA<ObfBadButtons>()));
      final twice = valid();
      (twice['buttons'] as List).add({'id': '0-0', 'label': 'again'});
      expect(() => parseObf(jsonEncode(twice)), throwsA(isA<ObfBadButtons>()));
    });

    test('rows or columns too large to hold are a broken grid, not a '
        'crash', () {
      // JSON cannot write infinity, so the number goes in as text.
      final text = jsonEncode(valid());
      for (final huge in [
        text.replaceFirst('"rows":2', '"rows":1e999'),
        text.replaceFirst('"columns":2', '"columns":1e999'),
        text.replaceFirst('"rows":2', '"rows":-1e999'),
      ]) {
        expect(huge, contains('e999'));
        expect(() => parseObf(huge), throwsA(isA<ObfBadGrid>()), reason: huge);
      }
    });

    test('a colour too large to hold is read as no colour', () {
      final json = valid();
      final buttons = (json['buttons'] as List).cast<Map<String, Object?>>();
      buttons[0]['background_color'] = 'rgb(1e999, 0, 0)';
      buttons[1]['background_color'] = 'rgba(204, 255, 170, NaN)';
      buttons[2]['background_color'] = 'rgb(Infinity, 255, 170)';
      final (:fitted, :leftOver) = obfPlacements(parseObf(jsonEncode(json)));
      expect(fitted, hasLength(4));
      expect(fitted.take(3).map((w) => w.colorKey), [null, null, null]);
      expect(leftOver, isEmpty);
    });

    test('every error has words for the adult', () {
      try {
        parseObf('not json');
        fail('should throw');
      } on ObfError catch (e) {
        expect(e.message, isNotEmpty);
        expect(e.message, isNot(contains('!')));
      }
    });
  });

  group('colours', () {
    test('each family is nearest itself, and white is plain', () {
      for (final MapEntry(:key, :value) in colorForKey.entries) {
        final hex = (value & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
        expect(nearestColorKey('#$hex'), key);
      }
      expect(nearestColorKey('rgb(255, 255, 255)'), isNull);
      expect(nearestColorKey('#fff'), isNull);
      expect(nearestColorKey(null), isNull);
      expect(nearestColorKey('papayawhip'), isNull);
    });

    test('common Fitzgerald colours from other apps find a family', () {
      expect(nearestColorKey('rgb(204, 255, 170)'), 'verb');
      expect(nearestColorKey('rgb(255, 255, 170)'), 'pronoun');
      expect(nearestColorKey('rgb(170, 204, 255)'), 'descriptor');
      expect(nearestColorKey('rgb(204, 170, 255)'), 'question');
      expect(nearestColorKey('rgb(255, 204, 170)'), 'negation');
      expect(nearestColorKey('rgb(204, 204, 204)'), 'determiner');
    });

    test('a translucent colour is judged as it shows over white', () {
      expect(nearestColorKey('rgba(204, 255, 170, 1)'), 'verb');
      expect(nearestColorKey('rgba(204, 255, 170, 0)'), isNull);
    });

    test('reads rgb, rgba and hex', () {
      expect(parseCssColor('rgb(1, 2, 3)'), (1, 2, 3, 1.0));
      expect(parseCssColor(' RGBA(10,20,30,0.5) '), (10, 20, 30, 0.5));
      expect(parseCssColor('#0a0B0c'), (10, 11, 12, 1.0));
      expect(parseCssColor('#abc'), (0xaa, 0xbb, 0xcc, 1.0));
      expect(parseCssColor('rgb(1, 2)'), isNull);
      expect(parseCssColor('#abcd'), isNull);
    });
  });
}
