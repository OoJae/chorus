/// Quick phrases: the few whole sentences a child may need at once, kept
/// per circle. The rules the app and the server share.
library;

/// What every circle starts with, and what a device shows while it has
/// nothing of its own.
const List<String> defaultQuickPhrases = [
  'Stop',
  'Help',
  "I'm hurt",
  'Toilet',
  'All done',
  'I need a break',
];

/// Most phrases a circle keeps.
const int maxQuickPhrases = 24;

/// Longest phrase, in characters.
const int maxQuickPhraseLength = 80;

/// [phrases] made fit to keep: spaces trimmed and collapsed, empty ones
/// and repeats (ignoring case) dropped, each cut to
/// [maxQuickPhraseLength], and at most [maxQuickPhrases] kept, in order.
List<String> cleanQuickPhrases(Iterable<String> phrases) {
  final seen = <String>{};
  final kept = <String>[];
  for (final raw in phrases) {
    var text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.length > maxQuickPhraseLength) {
      text = text.substring(0, maxQuickPhraseLength).trimRight();
    }
    if (text.isEmpty || !seen.add(text.toLowerCase())) continue;
    kept.add(text);
    if (kept.length == maxQuickPhrases) break;
  }
  return kept;
}
