/// The words of "What changed": one plain line per change.
library;

import '../contracts_activity.dart';

/// Title of the feed screen and of its home entry.
const String activityTitle = 'What changed';

/// One line under the home entry.
const String activityEntryDetail = 'Who added, renamed or put away a word';

/// Shown when there is nothing in the feed yet.
const String activityEmpty =
    'Nothing has changed yet. When someone in the circle adds, renames or '
    'puts away a word, it shows here.';

/// Label of the button that undoes one line.
const String undoLabel = 'Undo';

/// Shown after an undo that put everything back.
const String undoneMessage = 'Undone. It is written as a new change.';

/// The home banner: "Since you last looked: 3 changes".
String sinceLastLookedText(int count) =>
    'Since you last looked: $count ${count == 1 ? 'change' : 'changes'}';

/// The banner's button.
const String sinceLastLookedAction = 'See';

/// Shown after undoing "put away" when the word's old spot is taken.
String undoWaitingMessage(String label) =>
    '"$label" is back. Its old spot has another word now, so it waits '
    'under "Needs a home".';

/// Who did it, as a line names them.
String actorOf(ActivityEntry entry) {
  if (entry.kind == ActivityKind.sitterTap) return 'Sitter';
  final name = entry.actorName.trim();
  return name.isEmpty ? 'Someone' : name;
}

/// The first letter of [name] for the badge.
String initialOf(String name) {
  final text = name.trim();
  return text.isEmpty ? '?' : text.characters.first.toUpperCase();
}

/// What [entry] says, without the time: "Dad added 'swing'".
String activityLine(ActivityEntry entry) {
  final who = actorOf(entry);
  final word = "'${entry.label}'";
  String quoted(String? value) => "'${value ?? ''}'";
  final empty = entry.newValue == null || entry.newValue!.isEmpty;
  return switch (entry.kind) {
    ActivityKind.added => '$who added $word',
    ActivityKind.renamed =>
      '$who renamed ${quoted(entry.oldValue)} to ${quoted(entry.newValue)}',
    ActivityKind.spoken =>
      empty
          ? '$who made $word say its own name'
          : '$who made $word say ${quoted(entry.newValue)}',
    ActivityKind.colour =>
      empty
          ? '$who took the colour off $word'
          : '$who changed the colour of $word',
    ActivityKind.picture =>
      empty
          ? '$who took the picture off $word'
          : '$who changed the picture of $word',
    ActivityKind.voice =>
      empty
          ? '$who took the recording off $word'
          : '$who recorded a voice for $word',
    ActivityKind.placed => '$who gave $word a spot on the board',
    ActivityKind.putAway => '$who put $word away',
    ActivityKind.broughtBack => '$who brought $word back',
    ActivityKind.sitterTap => '$who: $word',
  };
}

/// "18:04" in the device's time.
String clockOf(DateTime at) {
  final local = at.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}

const List<String> _weekdays = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// The day heading for [at], seen [now]: "Today", "Yesterday" or
/// "Mon 12 Oct".
String dayHeading(DateTime at, DateTime now) {
  final day = at.toLocal();
  final today = now.toLocal();
  final d = DateTime(day.year, day.month, day.day);
  final t = DateTime(today.year, today.month, today.day);
  final diff = t.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}

extension on String {
  Iterable<String> get characters => runes.map(String.fromCharCode);
}
