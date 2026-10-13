/// The paper backup of a board: reading a published snapshot and rendering
/// it as a page that prints cleanly.
///
/// Pure Dart with no database, so the page can be tested as plain text.
///
/// The snapshot is JSON the client builds from its own replica:
///
/// ```json
/// {
///   "childName": "Ada",
///   "name": "Home", "rows": 6, "cols": 6,
///   "tiles": [{"row": 0, "col": 0, "label": "like", "colorKey": "verb"}]
/// }
/// ```
///
/// `name`, `rows` and `cols` may instead sit in a nested `"board"` object, and
/// a tile may give a placed `"cellKey"` (`<boardId>:<row>:<col>`) instead of
/// `row` and `col`. Tiles that are archived, have no cell, or fall outside
/// the grid are left off the page; everything else in the JSON is ignored.
library;

import 'dart:convert';

/// Largest snapshot the server stores, in UTF-8 bytes.
const int maxSnapshotBytes = 200 * 1024;

/// Largest grid side the page lays out.
const int maxGridSide = 12;

/// Most tiles read from one snapshot.
const int maxSnapshotTiles = 500;

/// Longest board name, child name or label printed, in characters.
const int maxPrintedText = 80;

/// Tile colours by part-of-speech key, as `#rrggbb`.
///
/// Mirrors `colorForKey` in `chorus_shared` (the server cannot depend on it
/// outside tests); a test holds the two together. Unknown keys print white.
const Map<String, String> printColours = {
  'verb': '#ccffaa',
  'pronoun': '#ffffaa',
  'question': '#ccaaff',
  'descriptor': '#aaccff',
  'determiner': '#cccccc',
  'negation': '#ccaa88',
};

/// The credit the starter vocabulary's licence asks for.
const String starterVocabularyCredit =
    'Starter words: the Universal Core vocabulary, Center for Literacy and '
    'Disability Studies, UNC-Chapel Hill, licensed CC BY-SA 4.0. Shown here '
    'as colour-coded text.';

/// One word on the printed grid.
class PrintTile {
  const PrintTile({required this.label, this.colorKey});

  final String label;

  /// Part-of-speech key; null or unknown prints white.
  final String? colorKey;
}

/// A board ready to print.
class PrintBoard {
  const PrintBoard({
    required this.name,
    required this.rows,
    required this.cols,
    required this.cells,
    this.childName,
  });

  final String name;
  final String? childName;
  final int rows;
  final int cols;

  /// Tiles by `(row, col)`; a cell with no entry prints empty.
  final Map<(int, int), PrintTile> cells;

  /// Reads a snapshot. Throws [FormatException] when [boardJson] is not
  /// JSON, is not an object, has no usable grid size, or has no tile list.
  factory PrintBoard.parse(String boardJson) {
    final Object? root;
    try {
      root = jsonDecode(boardJson);
    } on FormatException {
      rethrow;
    } catch (_) {
      // Pathologically deep input overflows the decoder's stack.
      throw const FormatException('snapshot cannot be read');
    }
    if (root is! Map) throw const FormatException('snapshot is not an object');
    final nested = root['board'];
    final board = nested is Map ? nested : root;

    final rows = _side(board['rows']);
    final cols = _side(board['cols']);
    if (rows == null || cols == null) {
      throw const FormatException('snapshot has no usable rows and cols');
    }
    final tiles = root['tiles'];
    if (tiles is! List) throw const FormatException('snapshot has no tiles');

    final cells = <(int, int), PrintTile>{};
    for (final tile in tiles.take(maxSnapshotTiles)) {
      if (tile is! Map || tile['archived'] == true) continue;
      final label = _text(tile['label']);
      if (label == null) continue;
      final at = _cell(tile);
      if (at == null || at.$1 >= rows || at.$2 >= cols) continue;
      // Two tiles never share a cell in a real replica; keep the first.
      cells.putIfAbsent(
        at,
        () => PrintTile(label: label, colorKey: _text(tile['colorKey'])),
      );
    }
    return PrintBoard(
      name: _text(board['name']) ?? _text(root['title']) ?? 'Board',
      childName: _text(root['childName']),
      rows: rows,
      cols: cols,
      cells: cells,
    );
  }
}

/// A grid side between 1 and [maxGridSide], or null.
int? _side(Object? value) =>
    value is int && value >= 1 && value <= maxGridSide ? value : null;

final RegExp _control = RegExp(r'[\u0000-\u001f\u007f-\u009f]');
final RegExp _index = RegExp(r'^(0|[1-9][0-9]*)$');

/// [value] as trimmed single-line text of at most [maxPrintedText]
/// characters, or null when it is not text or is blank.
String? _text(Object? value) {
  if (value is! String) return null;
  final clean = value.replaceAll(_control, ' ').trim();
  if (clean.isEmpty) return null;
  final runes = clean.runes;
  return runes.length <= maxPrintedText
      ? clean
      : String.fromCharCodes(runes.take(maxPrintedText));
}

/// The cell a snapshot tile sits in, or null when it has none: no `row` and
/// `col`, and a `cellKey` that is not the plain placed form (tray and
/// contested keys end in something that is not a number).
(int, int)? _cell(Map<dynamic, dynamic> tile) {
  final row = tile['row'];
  final col = tile['col'];
  if (row is int && col is int) {
    return row >= 0 && col >= 0 ? (row, col) : null;
  }
  final key = tile['cellKey'];
  if (key is! String) return null;
  final parts = key.split(':');
  if (parts.length != 3 || parts[0].isEmpty || parts[0] == 'tray') return null;
  if (!_index.hasMatch(parts[1]) || !_index.hasMatch(parts[2])) return null;
  final r = int.tryParse(parts[1]);
  final c = int.tryParse(parts[2]);
  return r == null || c == null ? null : (r, c);
}

const HtmlEscape _escape = HtmlEscape();

/// [text] made safe to place in HTML text or a quoted attribute.
String escapeHtml(String text) => _escape.convert(text);

const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// [when] as a plain date such as `13 October 2026`, in UTC.
String printDate(DateTime when) {
  final utc = when.toUtc();
  return '${utc.day} ${_months[utc.month - 1]} ${utc.year}';
}

/// The printable page for [board].
///
/// Every piece of text from the snapshot is escaped. Colours are chosen by
/// class from [printColours], so nothing from the snapshot reaches the
/// stylesheet. The page loads nothing from anywhere and runs no script.
String renderPrintPage(
  PrintBoard board, {
  required DateTime savedAt,
  required DateTime expiresAt,
}) {
  final heading = board.childName == null
      ? board.name
      : '${board.childName}: ${board.name}';
  // Landscape A4 or Letter leaves about 275 by 150 mm for the grid.
  final cellHeight = (150 / board.rows).clamp(10, 34).toDouble();
  final cellWidth = 275 / board.cols;
  final fontSize = [cellHeight * 0.32, cellWidth * 0.17].reduce(
    (a, b) => a < b ? a : b,
  );

  final out = StringBuffer()
    ..write('<!doctype html>\n<html lang="en">\n<head>\n')
    ..write('<meta charset="utf-8">\n')
    ..write('<meta name="viewport" content="width=device-width, ')
    ..write('initial-scale=1">\n')
    ..write('<meta name="robots" content="noindex, nofollow">\n')
    ..write('<title>${escapeHtml(heading)} (paper board)</title>\n')
    ..write('<style>\n')
    ..write(_stylesheet(cellHeight, fontSize))
    ..write('</style>\n</head>\n<body>\n')
    ..write('<h1>${escapeHtml(heading)}</h1>\n')
    ..write('<p class="hint">A paper copy for when the device is out of ')
    ..write('reach or out of battery. Use your browser&#39;s Print command; ')
    ..write('landscape fits best. Point to a word to say it.</p>\n')
    ..write('<table>\n');
  for (var row = 0; row < board.rows; row++) {
    out.write('<tr>');
    for (var col = 0; col < board.cols; col++) {
      final tile = board.cells[(row, col)];
      if (tile == null) {
        out.write('<td class="empty"></td>');
        continue;
      }
      final colour = printColours.containsKey(tile.colorKey)
          ? ' class="c-${tile.colorKey}"'
          : '';
      out.write('<td$colour>${escapeHtml(tile.label)}</td>');
    }
    out.write('</tr>\n');
  }
  out
    ..write('</table>\n<footer>\n')
    ..write('<p>Saved from the board on ${printDate(savedAt)}. Words added ')
    ..write('since then are not on this page.</p>\n')
    ..write('<p class="hint">This link stops working on ')
    ..write('${printDate(expiresAt)}.</p>\n')
    ..write('<p>${escapeHtml(starterVocabularyCredit)}</p>\n')
    ..write('</footer>\n</body>\n</html>\n');
  return out.toString();
}

/// The page shown when a link is unknown or has expired. The two cases look
/// the same, so a link reveals nothing about boards that once existed.
String renderMissingPage() =>
    '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
    '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
    '<meta name="robots" content="noindex, nofollow">\n'
    '<title>Board not found</title>\n'
    '<style>body{font-family:system-ui,sans-serif;margin:3rem auto;'
    'max-width:32rem;padding:0 1rem;color:#111}</style>\n</head>\n<body>\n'
    '<h1>This board is not here</h1>\n'
    '<p>The link is wrong or has expired. Links to a paper board last 30 '
    'days. Ask an adult in the circle to share the board again.</p>\n'
    '</body>\n</html>\n';

String _stylesheet(double cellHeightMm, double fontSizeMm) {
  final colours = StringBuffer();
  printColours.forEach((key, colour) {
    colours.write('td.c-$key{background:$colour}\n');
  });
  return '''
*{box-sizing:border-box}
body{font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;color:#000;background:#fff;margin:1rem}
h1{font-size:1.4rem;margin:0 0 .5rem}
p{margin:.25rem 0}
table{width:100%;border-collapse:collapse;table-layout:fixed;margin:.75rem 0}
td{border:2px solid #000;height:5.5rem;padding:.25rem;text-align:center;vertical-align:middle;font-size:1.5rem;font-weight:600;overflow-wrap:anywhere;background:#fff;-webkit-print-color-adjust:exact;print-color-adjust:exact}
td.empty{border-style:dashed;border-color:#999}
${colours}footer{font-size:.8rem;color:#333}
@page{size:landscape;margin:10mm}
@media print{
body{margin:0}
.hint{display:none}
h1{font-size:14pt;margin:0 0 2mm}
table{margin:0 0 2mm;page-break-inside:avoid;break-inside:avoid}
tr{page-break-inside:avoid;break-inside:avoid}
td{height:${cellHeightMm.toStringAsFixed(1)}mm;font-size:${fontSizeMm.toStringAsFixed(1)}mm;padding:1mm;border-width:.5mm}
footer{font-size:7pt;color:#000}
}
''';
}
