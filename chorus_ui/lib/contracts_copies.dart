/// Named copies of a board, such as "Before the school trip", as the
/// screens see them.
///
/// Kept apart from `contracts.dart` so every screen works without it: "Save
/// a copy" and "Copies" appear only when a [BoardCopies] is given.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';

export 'package:chorus_shared/chorus_shared.dart'
    show
        CopyWordFacts,
        CopyWordState,
        copyNameProblem,
        copyWordState,
        maxCopyNameLength;

/// One copy of a board. [words] is empty in a list; [BoardCopies.get]
/// fills it.
@immutable
class BoardCopy {
  const BoardCopy({
    required this.id,
    required this.boardId,
    required this.boardName,
    required this.rows,
    required this.cols,
    required this.name,
    required this.takenByName,
    required this.takenAt,
    required this.wordCount,
    this.words = const [],
  });

  final String id;
  final String boardId;

  /// The board's name and size when the copy was taken.
  final String boardName;
  final int rows;
  final int cols;
  final String name;
  final String takenByName;
  final DateTime takenAt;
  final int wordCount;
  final List<CopyWordFacts> words;

  @override
  bool operator ==(Object other) =>
      other is BoardCopy &&
      other.id == id &&
      other.name == name &&
      other.takenAt == takenAt &&
      other.wordCount == wordCount &&
      listEquals(other.words, words);

  @override
  int get hashCode => Object.hash(id, name, takenAt, wordCount);

  @override
  String toString() => 'BoardCopy($id, "$name", $wordCount words)';
}

/// Thrown when a copy could not be taken, read or deleted, for example with
/// no connection. [message] is written for the adult.
class CopiesFailed implements Exception {
  const CopiesFailed(this.message);

  final String message;

  @override
  String toString() => 'CopiesFailed: $message';
}

/// Shown when a copy could not be reached.
const String copiesOfflineMessage =
    'Copies are kept online. Check the connection and try again.';

/// The circle's board copies, kept on the server. Each call needs the
/// network and throws [CopiesFailed] without it.
abstract class BoardCopies {
  /// Whether this adult may take and delete copies. Every member may look.
  bool get canEdit;

  /// Every copy of the circle, newest first, without words.
  Future<List<BoardCopy>> list();

  /// The copy with its words, or null when it is gone.
  Future<BoardCopy?> get(String copyId);

  /// Takes a copy of [board] as the circle holds it now, called [name].
  Future<BoardCopy> take(BoardFacts board, String name);

  /// Deletes the copy. The board is not touched.
  Future<void> delete(String copyId);
}

/// Adds a new word to a board's "Needs a home", never into a cell.
///
/// Implemented by the same object as the `BoardStore` when it can; "Put
/// back" in a copy appears only for a store that does.
abstract class TrayWordAdder {
  /// Adds a word with these properties to [boardId]'s "Needs a home", for
  /// an adult to give it a cell. Completes with the new word's id. Throws
  /// [StateError] for a read-only partner.
  Future<String> addToTray({
    required String boardId,
    required String label,
    String? speech,
    String? colorKey,
    String? imageHash,
  });
}
