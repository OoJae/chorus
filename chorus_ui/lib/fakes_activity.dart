/// In-memory stand-ins for "What changed", suggested words and the
/// circle's members.
library;

import 'contracts.dart';
import 'contracts_activity.dart';
import 'contracts_edits.dart';
import 'fakes.dart';

/// A [FakeBoardStore] with an edit log the test supplies, whose undo is
/// recorded and written through the fake's own updates.
class FakeActivityStore extends FakeBoardStore
    implements EditLog, ActivityUndo {
  FakeActivityStore.seeded({
    super.role,
    super.childName,
    super.myName,
    super.leaveEmpty,
  }) : super.seeded();

  List<EditFacts> _edits = const [];

  @override
  List<EditFacts> get edits => _edits;

  /// Replaces the edit log, as a merge would.
  set edits(List<EditFacts> value) {
    _edits = List.unmodifiable(value);
    notifyListeners();
  }

  /// Every entry [undo] was asked for, in order.
  final List<ActivityEntry> undone = [];

  /// What [undo] reports for a put-away word.
  UndoOutcome bringBackOutcome = UndoOutcome.done;

  @override
  Future<void> restore(Overwrite overwrite) async {}

  @override
  Future<UndoOutcome> undo(ActivityEntry entry) async {
    if (!role.canEdit) throw StateError('A partner cannot undo.');
    final plan = undoPlanOf(entry, tiles);
    if (plan == null) throw StateError('Nothing to undo.');
    undone.add(entry);
    switch (plan) {
      case UndoSetValue(:final prop, :final value):
        await updateTile(
          entry.tileId,
          label: prop == 'label' ? value : null,
          speech: prop == 'speech' ? value : null,
          colorKey: prop == 'colorKey' ? value : null,
        );
        return UndoOutcome.done;
      case UndoPutAway():
        await archiveTile(entry.tileId);
        return UndoOutcome.done;
      case UndoBringBack():
        return bringBackOutcome;
    }
  }
}

/// Remembers the last look in memory.
class FakeActivitySeen implements ActivitySeen {
  FakeActivitySeen([this.last]);

  DateTime? last;

  @override
  Future<DateTime?> lastLooked() async => last;

  @override
  Future<void> markLooked(DateTime at) async => last = at;
}

/// Suggestions held in memory.
class FakeWordSuggestions implements WordSuggestions {
  FakeWordSuggestions([List<WordSuggestionItem>? items]) : items = items ?? [];

  final List<WordSuggestionItem> items;

  /// Words passed to [suggest].
  final List<String> suggested = [];

  /// Answers given, as (label, added).
  final List<(String, bool)> answers = [];

  /// When true every call throws, as with no network.
  bool offline = false;

  int _next = 1;

  @override
  Future<void> suggest(String label) async {
    if (offline) throw StateError('offline');
    suggested.add(label);
  }

  @override
  Future<List<WordSuggestionItem>> open() async {
    if (offline) throw StateError('offline');
    return List.of(items);
  }

  @override
  Future<void> resolve(WordSuggestionItem item, {required bool added}) async {
    if (offline) throw StateError('offline');
    answers.add((item.label, added));
    items.removeWhere((i) => i.id == item.id);
  }

  /// Adds an open suggestion.
  WordSuggestionItem add(String label, {String byName = 'Grandma'}) {
    final item = WordSuggestionItem(
      id: _next++,
      label: label,
      byName: byName,
      at: DateTime.utc(2026, 10, 14, 9),
    );
    items.add(item);
    return item;
  }
}

/// Members held in memory.
class FakeCircleMembers implements CircleMembers {
  FakeCircleMembers(this.members, {this.canRemove = true});

  final List<CircleMember> members;

  @override
  final bool canRemove;

  /// When true every call throws, as with no network.
  bool offline = false;

  @override
  Future<List<CircleMember>> list() async {
    if (offline) throw StateError('offline');
    return List.of(members);
  }

  @override
  Future<void> remove(CircleMember member) async {
    if (offline) throw StateError('offline');
    members.removeWhere((m) => m.userId == member.userId);
  }
}
