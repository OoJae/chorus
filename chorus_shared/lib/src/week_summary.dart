/// "This week": what the word log says about one week, for the adults.
///
/// Pure, so the server can compute it from its `word_use` rows and the
/// tiles, and the tests can check the sums with no database.
library;

import 'facts.dart';
import 'modelling.dart' show ModelledCount;
import 'word_use.dart';

/// One word and how many times it was spoken.
class WordCount {
  const WordCount(this.label, this.count);

  final String label;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is WordCount && other.label == label && other.count == count;

  @override
  int get hashCode => Object.hash(label, count);

  @override
  String toString() => 'WordCount("$label", $count)';
}

/// One week of the word log. Words are told apart by label, ignoring case
/// and spaces, so "more" on two boards is one word.
class WeekSummary {
  const WeekSummary({
    required this.weekStart,
    required this.topWords,
    required this.firstTimeWords,
    required this.addedWords,
    required this.notUsedYet,
    required this.totalUses,
    required this.wordsUsed,
    this.modelled = const [],
  });

  /// Reads what [toJson] wrote. Throws [FormatException] for anything else.
  factory WeekSummary.fromJson(Map<String, Object?> json) {
    try {
      List<String> labels(String key) =>
          (json[key] as List<Object?>).cast<String>().toList();
      return WeekSummary(
        weekStart: DateTime.parse(json['weekStart'] as String),
        topWords: [
          for (final entry
              in (json['topWords'] as List<Object?>)
                  .cast<Map<String, Object?>>())
            WordCount(entry['label'] as String, entry['count'] as int),
        ],
        firstTimeWords: labels('firstTimeWords'),
        addedWords: labels('addedWords'),
        notUsedYet: labels('notUsedYet'),
        totalUses: json['totalUses'] as int,
        wordsUsed: json['wordsUsed'] as int,
        modelled: [
          for (final entry
              in ((json['modelled'] as List<Object?>?) ?? const [])
                  .cast<Map<String, Object?>>())
            ModelledCount(
              entry['label'] as String,
              modelled: entry['modelled'] as int,
              said: entry['said'] as int,
            ),
        ],
      );
    } on TypeError {
      throw const FormatException('Not a week summary');
    }
  }

  /// Start of the week, UTC. The week runs seven days from here.
  final DateTime weekStart;

  /// Most used first, ties by label.
  final List<WordCount> topWords;

  /// Spoken this week and never before it, by label.
  final List<String> firstTimeWords;

  /// Words added to a board this week and still on one, by label.
  final List<String> addedWords;

  /// Words on the boards that have never been spoken, by label.
  final List<String> notUsedYet;

  /// Taps this week.
  final int totalUses;

  /// Different words spoken this week.
  final int wordsUsed;

  /// Words an adult modelled this week, with how often the child said each.
  /// Empty when nothing was modelled, or the server is older.
  final List<ModelledCount> modelled;

  DateTime get weekEnd => weekStart.add(const Duration(days: 7));

  Map<String, Object?> toJson() => {
    'weekStart': weekStart.toUtc().toIso8601String(),
    'topWords': [
      for (final word in topWords) {'label': word.label, 'count': word.count},
    ],
    'firstTimeWords': firstTimeWords,
    'addedWords': addedWords,
    'notUsedYet': notUsedYet,
    'totalUses': totalUses,
    'wordsUsed': wordsUsed,
    'modelled': [
      for (final word in modelled)
        {'label': word.label, 'modelled': word.modelled, 'said': word.said},
    ],
  };
}

/// Most top words shown.
const int weekTopWords = 10;

/// Monday 00:00 UTC of the week [time] falls in.
DateTime weekStartOf(DateTime time) {
  final utc = time.toUtc();
  final day = DateTime.utc(utc.year, utc.month, utc.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

/// The week from [weekStart] (seven days) in [uses], read against [tiles]
/// (every tile of the circle, archived ones included, so a word spoken and
/// then removed still counts).
///
/// Uses of a tile not in [tiles], and uses after the week, are ignored.
/// "Not used yet" lists the words still on a board (not archived) that had
/// never been spoken by the end of the week.
WeekSummary summarizeWeek(
  Iterable<WordUse> uses,
  Iterable<TileFacts> tiles,
  DateTime weekStart, {
  int top = weekTopWords,
}) {
  final start = weekStart.toUtc();
  final end = start.add(const Duration(days: 7));
  final tileById = {for (final tile in tiles) tile.id: tile};

  // Per word: the label shown (the first tile's), uses this week, and
  // whether it was spoken before the week.
  final shown = <String, String>{};
  final thisWeek = <String, int>{};
  final before = <String>{};
  var total = 0;
  for (final use in uses) {
    final tile = tileById[use.tileId];
    if (tile == null || !use.spokenAt.isBefore(end)) continue;
    final word = _word(tile.label);
    shown.putIfAbsent(word, () => tile.label.trim());
    if (use.spokenAt.isBefore(start)) {
      before.add(word);
    } else {
      thisWeek[word] = (thisWeek[word] ?? 0) + 1;
      total++;
    }
  }

  int byLabel(String a, String b) {
    final c = a.toLowerCase().compareTo(b.toLowerCase());
    return c != 0 ? c : a.compareTo(b);
  }

  final counts =
      [
        for (final MapEntry(key: word, value: count) in thisWeek.entries)
          WordCount(shown[word]!, count),
      ]..sort(
        (a, b) => a.count != b.count
            ? b.count.compareTo(a.count)
            : byLabel(a.label, b.label),
      );

  final live = tiles.where(
    (tile) => !tile.archived && _word(tile.label).isNotEmpty,
  );
  List<String> labelsOf(Iterable<TileFacts> chosen) {
    final seen = <String, String>{};
    for (final tile in chosen) {
      seen.putIfAbsent(_word(tile.label), () => tile.label.trim());
    }
    return seen.values.toList()..sort(byLabel);
  }

  return WeekSummary(
    weekStart: start,
    topWords: counts.take(top).toList(),
    firstTimeWords: [
      for (final word in thisWeek.keys)
        if (!before.contains(word)) shown[word]!,
    ]..sort(byLabel),
    addedWords: labelsOf(
      live.where((tile) {
        final at = tile.createdAt?.toUtc();
        return at != null && !at.isBefore(start) && at.isBefore(end);
      }),
    ),
    notUsedYet: labelsOf(
      live.where((tile) {
        final word = _word(tile.label);
        return !before.contains(word) && !thisWeek.containsKey(word);
      }),
    ),
    totalUses: total,
    wordsUsed: thisWeek.length,
  );
}

String _word(String label) => label.trim().toLowerCase();
