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
///   "tiles": [{"row": 0, "col": 0, "label": "like", "colorKey": "verb"},
///             {"row": 0, "col": 1, "label": "Grandma", "speech": "Nana"}]
/// }
/// ```
///
/// `speech` is optional: what the tile says when it is not its label. The
/// paper copy ignores it; the view-only page and the .obf export say it.
///
/// `name`, `rows` and `cols` may instead sit in a nested `"board"` object, and
/// a tile may give a placed `"cellKey"` (`<boardId>:<row>:<col>`) instead of
/// `row` and `col`. Tiles that are archived, have no cell, or fall outside
/// the grid are left off the page; everything else in the JSON is ignored.
library;

import 'dart:convert';

import 'package:chorus_shared/chorus_shared.dart'
    show colorForKey, symbolSvgFor;

/// Largest snapshot the server stores, in UTF-8 bytes.
const int maxSnapshotBytes = 200 * 1024;

/// Largest grid side the page lays out.
const int maxGridSide = 12;

/// Most tiles read from one snapshot.
const int maxSnapshotTiles = 500;

/// Longest board name, child name or label printed, in characters.
const int maxPrintedText = 80;

/// Tile colours by part-of-speech key, as `#rrggbb`: the light fills of the
/// tile families, read from `colorForKey` so paper and screen agree.
/// Unknown keys print white.
final Map<String, String> printColours = {
  for (final MapEntry(:key, :value) in colorForKey.entries) key: cssHex(value),
};

/// [argb] (`0xAARRGGBB`) as `#rrggbb`, ignoring alpha.
String cssHex(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// The credit the symbols' and the starter vocabulary's licences ask for.
const String boardCredit =
    'Pictures: Mulberry Symbols, Steve Lee, and the Chorus authors, '
    'CC BY-SA 4.0. Words: Universal Core, CLDS UNC-Chapel Hill, CC BY-SA 4.0.';

/// The Chorus mark: four laminated tiles in the colours of the key, two by
/// two, the top-left one raised a little. Each tile is its darker edge drawn
/// whole with the face over it. The same drawing as `docs/brand/mark.svg`,
/// which the app icons and the app's own mark follow. Decorative, so screen
/// readers skip it.
String brandMarkSvg({int size = 28}) =>
    '<svg class="mark" xmlns="http://www.w3.org/2000/svg" '
    'viewBox="0 0 64 64" width="$size" height="$size" aria-hidden="true" '
    'focusable="false">'
    '${_markTile(3, 1.5, '#c7efb2', '#7db863')}'
    '${_markTile(36, 4.5, '#ffefa0', '#d6b53f')}'
    '${_markTile(3, 37.5, '#c0dbff', '#6e9fe0')}'
    '${_markTile(36, 37.5, '#ddcbff', '#9b7bdf')}'
    '</svg>';

String _markTile(num x, num y, String fill, String edge) =>
    '<rect x="$x" y="$y" width="25" height="25" rx="6" fill="$edge"/>'
    '<rect x="$x" y="$y" width="25" height="22" rx="6" fill="$fill"/>';

/// One word on the printed grid.
class PrintTile {
  const PrintTile({required this.label, this.colorKey, this.speech});

  final String label;

  /// Part-of-speech key; null or unknown prints white.
  final String? colorKey;

  /// What the tile says when it is not [label]; null means the label.
  final String? speech;

  /// What the tile says.
  String get spokenText => speech ?? label;
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
        () => PrintTile(
          label: label,
          colorKey: _text(tile['colorKey']),
          speech: _text(tile['speech']),
        ),
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
/// class from [printColours], and pictures by label from the symbols built
/// into the server, so nothing from the snapshot reaches the stylesheet or
/// the markup. The page loads nothing from anywhere and runs no script.
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
  // Smaller than a text-only tile needs, to leave room for a picture.
  final fontSize = [cellHeight * 0.28, cellWidth * 0.17].reduce(
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
    ..write('<header><span class="brand">${brandMarkSvg()}')
    ..write('<span class="word">chorus</span></span>')
    ..write('<h1>${escapeHtml(heading)}</h1></header>\n')
    ..write('<p class="hint">A paper copy for when the device is out of ')
    ..write('reach or out of battery. Use your browser&#39;s Print command; ')
    ..write('landscape fits best. Point to a word to say it.</p>\n')
    ..write('<table>\n');
  for (var row = 0; row < board.rows; row++) {
    out.write('<tr>');
    for (var col = 0; col < board.cols; col++) {
      final tile = board.cells[(row, col)];
      if (tile == null) {
        // The empty box keeps the row at full height: a row of empty cells
        // would otherwise collapse to a thin line on the page.
        out.write('<td class="empty"><div class="cell"></div></td>');
        continue;
      }
      final colour = printColours.containsKey(tile.colorKey)
          ? ' class="c-${tile.colorKey}"'
          : '';
      out.write('<td$colour><div class="cell">${tileFace(tile)}</div></td>');
    }
    out.write('</tr>\n');
  }
  out
    ..write('</table>\n<footer>\n')
    ..write('<p>Saved from the board on ${printDate(savedAt)}. Words added ')
    ..write('since then are not on this page.</p>\n')
    ..write('<p class="hint">This link stops working on ')
    ..write('${printDate(expiresAt)}.</p>\n')
    ..write('<p>${escapeHtml(boardCredit)}</p>\n')
    ..write('</footer>\n</body>\n</html>\n');
  return out.toString();
}

/// What a tile shows: its Mulberry picture above the label when the word
/// has one, else the label alone. The picture is decoration; the label is
/// what a screen reader reads.
String tileFace(PrintTile tile) {
  final symbol = symbolSvgFor(tile.label);
  final label = '<span class="label">${escapeHtml(tile.label)}</span>';
  if (symbol == null) return label;
  return '<span class="sym" aria-hidden="true">$symbol</span>$label';
}

/// The page shown when a link is unknown or has expired. The two cases look
/// the same, so a link reveals nothing about boards that once existed.
String renderMissingPage() => renderNoticePage(
  title: 'Board not found',
  heading: 'This board is not here',
  text:
      'The link is wrong or has expired. Links to a paper board last 30 '
      'days. Ask an adult in the circle to share the board again.',
);

/// A short page in the house style that says one thing: the mark, a
/// heading and a line of text. Light or dark, as the reader's device is.
String renderNoticePage({
  required String title,
  required String heading,
  required String text,
}) =>
    '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
    '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
    '<meta name="robots" content="noindex, nofollow">\n'
    '<meta name="color-scheme" content="light dark">\n'
    '<title>${escapeHtml(title)}</title>\n'
    '<style>body{font-family:system-ui,-apple-system,"Segoe UI",Roboto,'
    'sans-serif;margin:3rem auto;max-width:32rem;padding:0 1.25rem;'
    'background:#f6f2ea;color:#15171a;line-height:1.5}'
    '.brand{display:flex;align-items:center;gap:.5rem;font-weight:700;'
    'font-size:1.25rem}h1{font-size:1.5rem;margin:2rem 0 .5rem}'
    '@media (prefers-color-scheme:dark){body{background:#101214;'
    'color:#eee9e0}}</style>\n</head>\n<body>\n'
    '<div class="brand">${brandMarkSvg()}<span>chorus</span></div>\n'
    '<h1>${escapeHtml(heading)}</h1>\n'
    '<p>${escapeHtml(text)}</p>\n'
    '</body>\n</html>\n';

/// The print rules size each row to [cellHeightMm] in all: the cell's
/// content box, 1 mm of padding above and below, and the 0.5 mm border.
String _stylesheet(double cellHeightMm, double fontSizeMm) {
  final colours = StringBuffer();
  printColours.forEach((key, colour) {
    colours.write('td.c-$key{background:$colour}\n');
  });
  return '''
*{box-sizing:border-box}
body{font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;color:#15171a;background:#f6f2ea;margin:1rem}
header{display:flex;align-items:center;gap:1rem;flex-wrap:wrap;margin:0 0 .5rem}
.brand{display:flex;align-items:center;gap:.4rem;font-weight:700;font-size:1.1rem}
h1{font-size:1.4rem;margin:0}
p{margin:.25rem 0}
table{width:100%;border-collapse:collapse;table-layout:fixed;margin:.75rem 0}
td{border:2px solid #15171a;padding:.25rem;text-align:center;vertical-align:middle;background:#fff;-webkit-print-color-adjust:exact;print-color-adjust:exact}
td.empty{border-style:dashed;border-color:#a9a8a3}
.cell{height:6.5rem;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:.15rem;overflow:hidden}
.sym{flex:1 1 auto;min-height:0;width:100%}
.sym svg{display:block;width:100%;height:100%}
.label{flex:none;font-size:1.4rem;font-weight:700;line-height:1.1;overflow-wrap:anywhere}
${colours}footer{font-size:.8rem;color:#5a5f67}
@page{size:landscape;margin:10mm}
@media print{
body{margin:0;background:#fff}
.hint{display:none}
header{margin:0 0 2mm}
h1{font-size:14pt}
table{margin:0 0 2mm;page-break-inside:avoid;break-inside:avoid}
tr{page-break-inside:avoid;break-inside:avoid}
td{padding:1mm;border-width:.5mm}
.cell{height:${(cellHeightMm - 2.5).toStringAsFixed(1)}mm}
.label{font-size:${fontSizeMm.toStringAsFixed(1)}mm}
footer{font-size:7pt;color:#000}
}
''';
}
