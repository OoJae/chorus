/// In-memory quick phrases and word counts, for tests, the gallery and a
/// talker opened without the app's own.
library;

import 'package:chorus_shared/chorus_shared.dart';

import 'contracts_quick_phrases.dart';

/// Quick phrases held in memory. [failSaves] makes [save] throw, as an
/// offline device does.
class FakeQuickPhraseBook extends QuickPhraseBook {
  FakeQuickPhraseBook({List<String>? phrases, bool canEdit = true})
    : _phrases = phrases == null || phrases.isEmpty
          ? defaultQuickPhrases
          : List.unmodifiable(phrases),
      _editable = canEdit;

  List<String> _phrases;
  bool _editable;

  /// When true, [save] throws and nothing changes.
  bool failSaves = false;

  /// What each [save] was called with, in order.
  final List<List<String>> saved = [];

  /// How many times [refresh] was called.
  int refreshes = 0;

  @override
  List<String> get phrases => _phrases;

  @override
  bool get canEdit => _editable;

  set canEdit(bool value) {
    _editable = value;
    notifyListeners();
  }

  @override
  Future<void> refresh() async {
    refreshes++;
  }

  @override
  Future<void> save(List<String> phrases) async {
    if (failSaves) throw StateError('offline');
    if (!_editable) throw StateError('not allowed');
    saved.add(List.of(phrases));
    final kept = cleanQuickPhrases(phrases);
    _phrases = kept.isEmpty ? defaultQuickPhrases : List.unmodifiable(kept);
    notifyListeners();
  }
}

/// Word counts held in memory for as long as this object lives.
class MemorySpokenWordCounts implements SpokenWordCounts {
  MemorySpokenWordCounts([Map<String, int>? counts])
    : _counts = Map.of(counts ?? const {});

  Map<String, int> _counts;

  @override
  Map<String, int> get counts => Map.unmodifiable(_counts);

  @override
  void noteSaid(String text) {
    _counts = countSpokenWords(_counts, text);
  }
}
