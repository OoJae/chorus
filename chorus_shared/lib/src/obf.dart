/// Open Board Format 0.1 (https://www.openboardformat.org/docs): reading an
/// .obf file another AAC app exported, and writing a Chorus board as one.
///
/// Only what a Chorus tile can hold is read: the grid, and each button's
/// label, spoken text and colours. Pictures, sounds and links to other
/// boards are left behind.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'facts.dart';
import 'starter_board.dart';
import 'tile_text.dart';
import 'tray.dart';

/// The format string Chorus writes.
const String obfFormat = 'open-board-0.1';

/// Why a file could not be read as a board. [message] is written for the
/// adult who picked the file.
sealed class ObfError implements Exception {
  const ObfError(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The file is not JSON at all.
final class ObfNotJson extends ObfError {
  const ObfNotJson()
    : super('This file could not be read. Choose a board saved as .obf.');
}

/// The file is JSON but does not say it is an Open Board Format board.
final class ObfWrongFormat extends ObfError {
  const ObfWrongFormat(this.found)
    : super('This file is not an Open Board Format board.');

  /// The `format` value the file carried, or null when it had none.
  final Object? found;
}

/// The grid is missing, or its rows and columns do not match its order.
final class ObfBadGrid extends ObfError {
  const ObfBadGrid(String detail)
    : super('The board in this file has a broken grid: $detail.');
}

/// The buttons are missing, or one has no id or the same id as another.
final class ObfBadButtons extends ObfError {
  const ObfBadButtons(String detail)
    : super('The words in this file could not be read: $detail.');
}

/// The grid names a button the file does not contain.
final class ObfUnknownButton extends ObfError {
  const ObfUnknownButton(this.buttonId)
    : super('The board in this file points to a word that is missing.');

  final String buttonId;
}

/// One button of an OBF board.
class ObfButton {
  const ObfButton({
    required this.id,
    this.label,
    this.vocalization,
    this.backgroundColor,
    this.borderColor,
    this.imageId,
    this.action,
  });

  final String id;
  final String? label;

  /// What is spoken when it differs from [label].
  final String? vocalization;

  /// CSS colour strings as written in the file, e.g. `rgb(204, 255, 170)`.
  final String? backgroundColor;
  final String? borderColor;

  final String? imageId;

  /// A special action such as `:clear` or `:backspace`; null for a word.
  final String? action;

  @override
  String toString() => 'ObfButton($id, "$label")';
}

/// An OBF board: a grid of button ids, row by row, null for an empty cell.
class ObfBoard {
  ObfBoard({
    required this.id,
    required this.name,
    required this.rows,
    required this.columns,
    required this.order,
    required this.buttons,
  }) : _byId = {for (final button in buttons.reversed) button.id: button};

  final String id;
  final String name;
  final int rows;
  final int columns;

  /// [rows] lists of [columns] button ids each.
  final List<List<String?>> order;
  final List<ObfButton> buttons;

  // Built once, so placing a large board is not a search per cell. Read in
  // reverse so the first of two buttons with one id wins, as a search would.
  final Map<String, ObfButton> _byId;

  /// The button with [id], or null.
  ObfButton? button(String id) => _byId[id];

  @override
  String toString() => 'ObfBoard($id, "$name", ${rows}x$columns)';
}

/// Reads an .obf file. Throws an [ObfError] saying what is wrong with it.
ObfBoard parseObf(String source) {
  final Object? json;
  try {
    json = jsonDecode(source);
  } on FormatException {
    throw const ObfNotJson();
  }
  if (json is! Map<String, Object?>) throw const ObfWrongFormat(null);
  final format = json['format'];
  // Later 0.x files keep the 0.1 fields, so any open-board version is read.
  if (format is! String || !format.startsWith('open-board-')) {
    throw ObfWrongFormat(format);
  }

  final rawButtons = json['buttons'];
  if (rawButtons is! List<Object?>) {
    throw const ObfBadButtons('there is no list of words');
  }
  final buttons = <ObfButton>[];
  final ids = <String>{};
  for (final raw in rawButtons) {
    if (raw is! Map<String, Object?>) {
      throw const ObfBadButtons('a word is not written as a button');
    }
    final id = _id(raw['id']);
    if (id == null) throw const ObfBadButtons('a word has no id');
    if (!ids.add(id)) throw ObfBadButtons('two words share the id "$id"');
    buttons.add(
      ObfButton(
        id: id,
        label: _text(raw['label']),
        vocalization: _text(raw['vocalization']),
        backgroundColor: _text(raw['background_color']),
        borderColor: _text(raw['border_color']),
        imageId: _id(raw['image_id']),
        action: _text(raw['action']),
      ),
    );
  }

  final grid = json['grid'];
  if (grid is! Map<String, Object?>) throw const ObfBadGrid('it is missing');
  final rows = _count(grid['rows']);
  final columns = _count(grid['columns']);
  if (rows == null || columns == null) {
    throw const ObfBadGrid('it has no rows or no columns');
  }
  final rawOrder = grid['order'];
  if (rawOrder is! List<Object?> || rawOrder.length != rows) {
    throw ObfBadGrid('it should have $rows rows');
  }
  final order = <List<String?>>[];
  for (final rawRow in rawOrder) {
    if (rawRow is! List<Object?> || rawRow.length != columns) {
      throw ObfBadGrid('every row should have $columns cells');
    }
    final row = <String?>[];
    for (final cell in rawRow) {
      if (cell == null) {
        row.add(null);
        continue;
      }
      final id = _id(cell);
      if (id == null) throw const ObfBadGrid('a cell is not a word id');
      if (!ids.contains(id)) throw ObfUnknownButton(id);
      row.add(id);
    }
    order.add(row);
  }

  return ObfBoard(
    id: _id(json['id']) ?? '',
    name: _text(json['name'])?.trim() ?? '',
    rows: rows,
    columns: columns,
    order: order,
    buttons: buttons,
  );
}

/// Ids are strings in the spec; some apps write numbers.
String? _id(Object? value) => switch (value) {
  String s when s.isNotEmpty => s,
  int n => '$n',
  _ => null,
};

String? _text(Object? value) => value is String ? value : null;

/// A positive whole number, written as an int or as `6.0`. A number too
/// large for JSON to hold (`1e999` reads as infinity) is none.
int? _count(Object? value) => switch (value) {
  int n when n > 0 => n,
  double d when d > 0 && d.isFinite && d == d.roundToDouble() => d.toInt(),
  _ => null,
};

/// One word of an OBF board, where Chorus would put it.
class ObfPlacement {
  const ObfPlacement({
    required this.row,
    required this.col,
    required this.label,
    this.speech,
    this.colorKey,
  });

  /// The cell the word had in the file.
  final int row;
  final int col;

  final String label;

  /// What to say; null when it is the label.
  final String? speech;

  /// The colour family nearest the button's background; null for a plain
  /// (white) tile.
  final String? colorKey;

  @override
  bool operator ==(Object other) =>
      other is ObfPlacement &&
      other.row == row &&
      other.col == col &&
      other.label == label &&
      other.speech == speech &&
      other.colorKey == colorKey;

  @override
  int get hashCode => Object.hash(row, col, label, speech, colorKey);

  @override
  String toString() =>
      'ObfPlacement($row:$col, "$label"${speech == null ? '' : ' says "$speech"'}'
      '${colorKey == null ? '' : ', $colorKey'})';
}

/// The words of [board] in row-major order, split into those that fit a
/// [rows] x [cols] Chorus board in the cell they had, and those outside it.
///
/// Buttons with no words (no label and nothing spoken) and special actions
/// such as `:clear` are not words and are left out of both lists: the child's
/// board has its own Clear and Delete.
///
/// Labels and spoken text are tidied onto one line (see [tidyText]) and cut
/// to what the add-word sheet allows, [maxTileLabelLength] and
/// [maxTileSpeechLength]: a file's word becomes a tile on every device in
/// the circle, and one very long label would shrink every label on the
/// board.
({List<ObfPlacement> fitted, List<ObfPlacement> leftOver}) obfPlacements(
  ObfBoard board, {
  int rows = starterRows,
  int cols = starterCols,
}) {
  final fitted = <ObfPlacement>[];
  final leftOver = <ObfPlacement>[];
  for (var row = 0; row < board.rows; row++) {
    for (var col = 0; col < board.columns; col++) {
      final id = board.order[row][col];
      final button = id == null ? null : board.button(id);
      if (button == null || button.action != null) continue;
      final vocalization = button.vocalization ?? '';
      final said = tidyText(vocalization, maxLength: maxTileSpeechLength);
      var label = tidyText(button.label ?? '', maxLength: maxTileLabelLength);
      // A button that only speaks is labelled with the start of what it says.
      if (label.isEmpty) {
        label = tidyText(vocalization, maxLength: maxTileLabelLength);
      }
      if (label.isEmpty) continue;
      final word = ObfPlacement(
        row: row,
        col: col,
        label: label,
        speech: said.isEmpty || said == label ? null : said,
        colorKey: nearestColorKey(button.backgroundColor),
      );
      (row < rows && col < cols ? fitted : leftOver).add(word);
    }
  }
  return (fitted: fitted, leftOver: leftOver);
}

/// The [colorForKey] family nearest a CSS colour, or null when it is nearest
/// plain white, is transparent, or cannot be read.
///
/// A translucent colour is first laid over white, as it would show on a
/// plain tile.
String? nearestColorKey(String? css) {
  final rgba = parseCssColor(css);
  if (rgba == null) return null;
  final (r, g, b, a) = rgba;
  final shown = (
    (r * a + 255 * (1 - a)).round(),
    (g * a + 255 * (1 - a)).round(),
    (b * a + 255 * (1 - a)).round(),
  );
  String? best;
  var bestDistance = _distance(shown, (255, 255, 255));
  for (final MapEntry(:key, :value) in colorForKey.entries) {
    final d = _distance(shown, _rgbOf(value));
    if (d < bestDistance) {
      best = key;
      bestDistance = d;
    }
  }
  return best;
}

/// Reads `rgb(r, g, b)`, `rgba(r, g, b, a)`, `#rgb` or `#rrggbb` into
/// channels of 0 to 255 and an alpha of 0 to 1. Null for anything else,
/// including a number that is not finite (`1e999`, `Infinity`, `NaN`).
(int, int, int, double)? parseCssColor(String? css) {
  final text = css?.trim().toLowerCase();
  if (text == null || text.isEmpty) return null;
  final hex = RegExp(r'^#([0-9a-f]{3}|[0-9a-f]{6})$').firstMatch(text);
  if (hex != null) {
    var digits = hex[1]!;
    if (digits.length == 3) digits = digits.split('').map((d) => '$d$d').join();
    int channel(int i) => int.parse(digits.substring(i, i + 2), radix: 16);
    return (channel(0), channel(2), channel(4), 1.0);
  }
  final fn = RegExp(r'^rgba?\(([^)]*)\)$').firstMatch(text);
  if (fn == null) return null;
  final parts = fn[1]!.split(',').map((p) => p.trim()).toList();
  if (parts.length != 3 && parts.length != 4) return null;
  final channels = <int>[];
  for (final part in parts.take(3)) {
    final value = num.tryParse(part);
    if (value == null || !value.isFinite) return null;
    channels.add(value.round().clamp(0, 255));
  }
  var alpha = 1.0;
  if (parts.length == 4) {
    final value = num.tryParse(parts[3]);
    if (value == null || !value.isFinite) return null;
    alpha = value.toDouble().clamp(0.0, 1.0);
  }
  return (channels[0], channels[1], channels[2], alpha);
}

(int, int, int) _rgbOf(int argb) =>
    ((argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF);

/// Weighted RGB distance ("redmean"), closer to what the eye sees than a
/// plain one, and enough to tell the six families apart.
double _distance((int, int, int) a, (int, int, int) b) {
  final mean = (a.$1 + b.$1) / 2;
  final dr = (a.$1 - b.$1).toDouble();
  final dg = (a.$2 - b.$2).toDouble();
  final db = (a.$3 - b.$3).toDouble();
  return math.sqrt(
    (2 + mean / 256) * dr * dr +
        4 * dg * dg +
        (2 + (255 - mean) / 256) * db * db,
  );
}

String _cssOf(int argb) {
  final (r, g, b) = _rgbOf(argb);
  return 'rgb($r, $g, $b)';
}

/// [board] as an OBF 0.1 document: the words holding its cells (as
/// `gridOf` decides), each with its spoken text when that differs from the
/// label and its colour. Photos and recordings stay in Chorus.
///
/// The licence block credits the Universal Core vocabulary the starter
/// board is made of; see STARTER_BOARD_LICENSE.md.
String obfJsonOf(BoardFacts board, Iterable<TileFacts> tiles) {
  final grid = gridOf(board.id, tiles, [board]);
  final cells = grid.keys.toList()
    ..sort(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
  return jsonEncode({
    'format': obfFormat,
    'id': board.id,
    'locale': 'en',
    'name': board.name,
    'buttons': [
      for (final cell in cells)
        {
          'id': grid[cell]!.id,
          'label': grid[cell]!.label,
          if (grid[cell]!.spokenText != grid[cell]!.label)
            'vocalization': grid[cell]!.spokenText,
          'background_color': _cssOf(
            colorForKey[grid[cell]!.colorKey] ?? 0xFFFFFFFF,
          ),
        },
    ],
    'grid': {
      'rows': board.rows,
      'columns': board.cols,
      'order': [
        for (var row = 0; row < board.rows; row++)
          [for (var col = 0; col < board.cols; col++) grid[(row, col)]?.id],
      ],
    },
    'images': <Object>[],
    'sounds': <Object>[],
    'license': {
      'type': 'CC By-SA',
      'copyright_notice_url': 'https://creativecommons.org/licenses/by-sa/4.0/',
      'author_name':
          'Center for Literacy and Disability Studies, UNC-Chapel Hill',
      'author_url': 'https://www.project-core.com',
    },
  });
}
