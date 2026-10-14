/// An in-memory practice partner for the editor's "Try a clash".
library;

import 'contracts_clash.dart';

/// Answers [putWord] from [refusals] first, one per call, then with a word
/// from [labels] in turn. Remembers every spot it was asked for.
class FakeClashPartner implements ClashPartner {
  FakeClashPartner({
    List<PracticeRefusal> refusals = const [],
    this.labels = const ['bubbles', 'swing', 'puzzle'],
  }) : _refusals = [...refusals];

  final List<PracticeRefusal> _refusals;
  final List<String> labels;

  /// Every spot asked for, in order.
  final List<({String boardId, int row, int col})> asked = [];

  int _words = 0;

  @override
  Future<PartnerWord> putWord({
    required String boardId,
    required int row,
    required int col,
  }) async {
    asked.add((boardId: boardId, row: row, col: col));
    if (_refusals.isNotEmpty) throw PracticeRefused(_refusals.removeAt(0));
    final label = labels[_words % labels.length];
    _words++;
    return PartnerWord(
      tileId: 'practice-$_words',
      label: label,
      partnerName: 'Practice partner',
    );
  }
}
