/// "What changed", "Suggest a word" and "People in this circle" as the
/// screens see them.
///
/// Kept apart from `contracts.dart` so each is optional: a store that does
/// not implement [ActivityUndo] shows the feed without Undo, and a screen
/// given no [WordSuggestions] or [CircleMembers] leaves those parts out.
library;

import 'package:chorus_shared/chorus_shared.dart';

export 'package:chorus_shared/chorus_shared.dart'
    show
        ActivityEntry,
        ActivityKind,
        UndoPlan,
        UndoBringBack,
        UndoPutAway,
        UndoSetValue,
        activityOf,
        changesSince,
        undoPlanOf,
        undoReason;

/// Where an undone change went.
enum UndoOutcome {
  /// The old value, or the word, is back where it was.
  done,

  /// A put-away word came back, but its old spot had been filled since, so
  /// it waits under "Needs a home".
  waiting,
}

/// Writes the undo of a feed entry, as a newer edit with reason
/// [undoReason], through the store's normal write path.
///
/// Implemented by the same object as the `BoardStore`.
abstract class ActivityUndo {
  /// Undoes [entry] as [undoPlanOf] plans it. Throws when there is nothing
  /// to undo or the store refuses the write (a read-only partner).
  Future<UndoOutcome> undo(ActivityEntry entry);
}

/// When the adult last opened "What changed" on this device, per circle.
abstract class ActivitySeen {
  /// Null when the feed was never opened here.
  Future<DateTime?> lastLooked();

  /// Remembers [at] as the last look. Never throws.
  Future<void> markLooked(DateTime at);
}

/// A word tapped on the view-only page, reported back to the circle.
class SitterTap {
  const SitterTap({required this.label, required this.at});
  final String label;
  final DateTime at;
}

/// A word suggested for the board by someone in the circle.
class WordSuggestionItem {
  const WordSuggestionItem({
    required this.id,
    required this.label,
    required this.byName,
    required this.at,
    this.speech,
    this.colorKey,
    this.fromPhoto = false,
  });

  final int id;
  final String label;
  final String? speech;
  final String? colorKey;
  final String byName;
  final DateTime at;
  final bool fromPhoto;
}

/// Suggested words: anyone in the circle may suggest one; editors list and
/// answer them. Needs the network.
abstract class WordSuggestions {
  /// Sends a suggestion. Throws when it could not be sent.
  Future<void> suggest(String label);

  /// The open suggestions, oldest first. Throws when they could not be
  /// read.
  Future<List<WordSuggestionItem>> open();

  /// Answers [item]: [added] when it went on the board. Throws when the
  /// answer could not be sent.
  Future<void> resolve(WordSuggestionItem item, {required bool added});
}

/// One adult in the circle.
class CircleMember {
  const CircleMember({
    required this.userId,
    required this.name,
    required this.roleName,
    this.isMe = false,
  });

  final String userId;
  final String name;

  /// "Guardian", "Therapist", "Teacher" or "Partner (view only)".
  final String roleName;
  final bool isMe;
}

/// The people in the circle, and a guardian's way to remove someone.
abstract class CircleMembers {
  /// True when the signed-in adult may remove others (a guardian).
  bool get canRemove;

  /// Everyone in the circle. Throws when it could not be read.
  Future<List<CircleMember>> list();

  /// Removes [member]: they lose the board at once. Throws when it could
  /// not be done.
  Future<void> remove(CircleMember member);
}
