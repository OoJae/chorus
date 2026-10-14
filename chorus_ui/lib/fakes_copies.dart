/// An in-memory stand-in for named board copies.
///
/// It keeps the contract's rules: only an editor takes or deletes a copy,
/// names the shared rules refuse are refused, and while
/// [FakeBoardCopies.online] is off every call fails as the real one would.
library;

import 'package:chorus_shared/chorus_shared.dart';

import 'contracts.dart';
import 'contracts_copies.dart';

/// A [BoardCopies] held in memory, taking copies of [store]'s boards.
class FakeBoardCopies extends BoardCopies {
  FakeBoardCopies(this.store, {this.online = true, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final BoardStore store;
  final DateTime Function() _now;

  /// Stands in for the connection: while off, every call fails.
  bool online;
  final List<BoardCopy> _copies = [];
  int _sequence = 0;

  @override
  bool get canEdit => store.role.canEdit;

  void _check({bool editing = false}) {
    if (editing && !canEdit) {
      throw StateError('A read-only partner takes or deletes no copy.');
    }
    if (!online) throw const CopiesFailed(copiesOfflineMessage);
  }

  BoardCopy _summary(BoardCopy copy) => BoardCopy(
    id: copy.id,
    boardId: copy.boardId,
    boardName: copy.boardName,
    rows: copy.rows,
    cols: copy.cols,
    name: copy.name,
    takenByName: copy.takenByName,
    takenAt: copy.takenAt,
    wordCount: copy.wordCount,
  );

  @override
  Future<List<BoardCopy>> list() async {
    _check();
    return [for (final copy in _copies.reversed) _summary(copy)];
  }

  @override
  Future<BoardCopy?> get(String copyId) async {
    _check();
    return _copies.where((copy) => copy.id == copyId).firstOrNull;
  }

  @override
  Future<BoardCopy> take(BoardFacts board, String name) async {
    _check(editing: true);
    if (copyNameProblem(name) != null) {
      throw ArgumentError.value(name, 'name', copyNameProblem(name));
    }
    final words = copyWordsOf(board.id, store.tiles, store.boards);
    final copy = BoardCopy(
      id: 'copy-${++_sequence}',
      boardId: board.id,
      boardName: board.name,
      rows: board.rows,
      cols: board.cols,
      name: tidyText(name),
      takenByName: store.myName,
      takenAt: _now().toUtc(),
      wordCount: words.length,
      words: List.unmodifiable(words),
    );
    _copies.add(copy);
    return copy;
  }

  @override
  Future<void> delete(String copyId) async {
    _check(editing: true);
    _copies.removeWhere((copy) => copy.id == copyId);
  }
}
