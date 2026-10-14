/// Rules for the adults who model words: finding a word on the boards,
/// turning what an adult says into the words on the board, and counting
/// "modelled" against "said".
///
/// Pure, so the app and the server agree, and the tests need nothing else.
library;

import 'facts.dart';
import 'tray.dart';
import 'word_use.dart';

// ---- Word finder ----------------------------------------------------------

/// Most results the word finder gives.
const int wordFinderLimit = 20;

/// A word found on one of the boards, with where it sits.
class WordFind {
  const WordFind({
    required this.tile,
    required this.board,
    required this.row,
    required this.col,
  });

  final TileFacts tile;
  final BoardFacts board;
  final int row;
  final int col;

  @override
  String toString() => 'WordFind("${tile.label}" on ${board.name} $row,$col)';
}

/// The placed words of every board still in use whose label or spoken text
/// matches [query], ignoring case and spaces at the ends.
///
/// A word that is the query comes first, then words that start with it,
/// then words that hold it; ties by home board first, then board name,
/// then position. Words waiting in the tray and archived boards are left
/// out: there is nowhere to point at. An empty query finds nothing.
List<WordFind> findWords(
  String query,
  Iterable<TileFacts> tiles,
  Iterable<BoardFacts> boards, {
  int limit = wordFinderLimit,
}) {
  final wanted = _plain(query);
  if (wanted.isEmpty) return const [];
  final found = <(int, WordFind)>[];
  for (final board in boards) {
    if (board.archived) continue;
    gridOf(board.id, tiles, boards).forEach((cell, tile) {
      final rank = _rank(wanted, [tile.label, tile.spokenText]);
      if (rank == null) return;
      found.add((
        rank,
        WordFind(tile: tile, board: board, row: cell.$1, col: cell.$2),
      ));
    });
  }
  found.sort((a, b) {
    if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
    final x = a.$2;
    final y = b.$2;
    if (x.board.isHome != y.board.isHome) return x.board.isHome ? -1 : 1;
    final byName = x.board.name.toLowerCase().compareTo(
      y.board.name.toLowerCase(),
    );
    if (byName != 0) return byName;
    if (x.board.id != y.board.id) return x.board.id.compareTo(y.board.id);
    if (x.row != y.row) return x.row.compareTo(y.row);
    return x.col.compareTo(y.col);
  });
  return [for (final (_, find) in found.take(limit)) find];
}

/// 0 for a word that is [wanted], 1 for one that starts with it, 2 for one
/// that holds it; null otherwise.
int? _rank(String wanted, List<String> texts) {
  int? best;
  for (final text in texts) {
    final plain = _plain(text);
    final rank = plain == wanted
        ? 0
        : plain.startsWith(wanted)
        ? 1
        : plain.contains(wanted)
        ? 2
        : null;
    if (rank != null && (best == null || rank < best)) best = rank;
  }
  return best;
}

String _plain(String text) =>
    text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

// ---- Speech to symbols ----------------------------------------------------

/// Most words one heard sentence lights up, so a long speech does not keep
/// the child's board glowing for minutes.
const int spokenMatchLimit = 8;

/// The tiles of [tiles] that [heard] names, in the order they were said.
///
/// Words are compared ignoring case and punctuation, by label or spoken
/// text, with simple endings forgiven: "cars" finds "car", "eating" finds
/// "eat", "making" finds "make". A label of several words ("all done") is
/// found when they are said together; the longest match wins. A word said
/// twice in a row glows once. Only [tiles] are searched, so pass the words
/// placed on the board the child is looking at.
List<TileFacts> matchSpokenWords(
  String heard,
  Iterable<TileFacts> tiles, {
  int limit = spokenMatchLimit,
}) {
  final said = _tokens(heard);
  if (said.isEmpty) return const [];
  // Each tile's forms, as lists of stems; longest first.
  final forms = <(List<String>, TileFacts)>[];
  for (final tile in tiles) {
    if (tile.archived) continue;
    final seen = <String>{};
    for (final text in [tile.label, tile.spokenText]) {
      final stems = [for (final token in _tokens(text)) wordStem(token)];
      if (stems.isEmpty || !seen.add(stems.join(' '))) continue;
      forms.add((stems, tile));
    }
  }
  forms.sort((a, b) => b.$1.length.compareTo(a.$1.length));

  final stems = [for (final token in said) wordStem(token)];
  final matched = <TileFacts>[];
  var i = 0;
  while (i < stems.length && matched.length < limit) {
    TileFacts? hit;
    var length = 1;
    for (final (form, tile) in forms) {
      if (i + form.length > stems.length) continue;
      var same = true;
      for (var j = 0; j < form.length; j++) {
        if (stems[i + j] != form[j]) {
          same = false;
          break;
        }
      }
      if (same) {
        hit = tile;
        length = form.length;
        break;
      }
    }
    if (hit != null && (matched.isEmpty || matched.last.id != hit.id)) {
      matched.add(hit);
    }
    i += length;
  }
  return matched;
}

/// [word] without a plural or "-ing" ending, lowercase, so "cars" and
/// "car", "eating" and "eat", "running" and "run", "making" and "make" are
/// one. Short words are left alone, so "is" is never "i".
String wordStem(String word) {
  var w = word.toLowerCase();
  if (w.endsWith('ing') && w.length - 3 >= 3) {
    w = w.substring(0, w.length - 3);
    // "running" -> "run": a doubled last letter is one.
    final n = w.length;
    if (n >= 3 && w[n - 1] == w[n - 2] && !'aeiouls'.contains(w[n - 1])) {
      w = w.substring(0, n - 1);
    }
  } else if (w.endsWith('ies') && w.length - 3 >= 2) {
    w = '${w.substring(0, w.length - 3)}y';
  } else if (w.endsWith('es') &&
      w.length - 2 >= 3 &&
      RegExp(r'(s|x|z|ch|sh)$').hasMatch(w.substring(0, w.length - 2))) {
    w = w.substring(0, w.length - 2);
  } else if (w.endsWith('s') && !w.endsWith('ss') && w.length - 1 >= 3) {
    w = w.substring(0, w.length - 1);
  }
  // "make" and "mak(ing)" meet at "mak".
  if (w.endsWith('e') && w.length - 1 >= 3) w = w.substring(0, w.length - 1);
  return w;
}

List<String> _tokens(String text) => [
  for (final match in RegExp(r"[a-z0-9']+").allMatches(text.toLowerCase()))
    if (match[0]!.replaceAll("'", '').isNotEmpty) match[0]!.replaceAll("'", ''),
];

// ---- Modelled versus said -------------------------------------------------

/// One word's week: how often an adult modelled it and how often the child
/// said it.
class ModelledCount {
  const ModelledCount(this.label, {required this.modelled, required this.said});

  final String label;
  final int modelled;
  final int said;

  @override
  bool operator ==(Object other) =>
      other is ModelledCount &&
      other.label == label &&
      other.modelled == modelled &&
      other.said == said;

  @override
  int get hashCode => Object.hash(label, modelled, said);

  @override
  String toString() =>
      'ModelledCount("$label", modelled $modelled, said $said)';
}

/// Most words in the "modelled and said" list.
const int modelledTop = 10;

/// Per word (by label, ignoring case), how often it was modelled and said
/// in the week from [weekStart], for the words modelled at least once.
/// Most modelled first, then by label. Uses of tiles not in [tiles] and
/// outside the week are ignored.
List<ModelledCount> modelledVersusSaid(
  Iterable<WordUse> said,
  Iterable<WordUse> modelled,
  Iterable<TileFacts> tiles,
  DateTime weekStart, {
  int top = modelledTop,
}) {
  final start = weekStart.toUtc();
  final end = start.add(const Duration(days: 7));
  final byId = {for (final tile in tiles) tile.id: tile};
  final shown = <String, String>{};
  Map<String, int> count(Iterable<WordUse> uses) {
    final counts = <String, int>{};
    for (final use in uses) {
      final tile = byId[use.tileId];
      if (tile == null) continue;
      if (use.spokenAt.isBefore(start) || !use.spokenAt.isBefore(end)) {
        continue;
      }
      final word = tile.label.trim().toLowerCase();
      if (word.isEmpty) continue;
      shown.putIfAbsent(word, () => tile.label.trim());
      counts[word] = (counts[word] ?? 0) + 1;
    }
    return counts;
  }

  final modelledCounts = count(modelled);
  final saidCounts = count(said);
  final rows = [
    for (final MapEntry(key: word, value: times) in modelledCounts.entries)
      ModelledCount(shown[word]!, modelled: times, said: saidCounts[word] ?? 0),
  ];
  rows.sort((a, b) {
    if (a.modelled != b.modelled) return b.modelled.compareTo(a.modelled);
    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  });
  return rows.take(top).toList();
}

/// "modelled 14 · said 3".
String modelledLine(int modelled, int said) =>
    'modelled $modelled · said $said';
