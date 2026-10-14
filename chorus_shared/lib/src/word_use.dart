/// The opt-in word log: which tile was spoken, and when. Never sentences,
/// never who was nearby.
///
/// The child's device keeps uses in a queue that survives a restart and
/// sends them in batches when it is online. These are the queue's rules.
library;

import 'dart:convert';

/// Most uses kept on the device while it cannot send them. About two weeks
/// of busy use; past that the oldest go first, so the newest are kept.
const int wordLogQueueCap = 2000;

/// Most uses sent in one call.
const int wordLogBatchSize = 200;

/// One spoken tile.
class WordUse {
  WordUse({
    required this.tileId,
    required this.boardId,
    required DateTime spokenAt,
  }) : spokenAt = spokenAt.toUtc();

  /// Reads what [toJson] wrote. Throws [FormatException] for anything else.
  factory WordUse.fromJson(Map<String, Object?> json) {
    final tileId = json['tileId'];
    final boardId = json['boardId'];
    final spokenAt = json['spokenAt'];
    if (tileId is! String || tileId.isEmpty) {
      throw const FormatException('A word use needs a tileId');
    }
    if (boardId is! String || boardId.isEmpty) {
      throw const FormatException('A word use needs a boardId');
    }
    if (spokenAt is! String) {
      throw const FormatException('A word use needs a spokenAt time');
    }
    return WordUse(
      tileId: tileId,
      boardId: boardId,
      spokenAt: DateTime.parse(spokenAt),
    );
  }

  final String tileId;
  final String boardId;

  /// Always UTC.
  final DateTime spokenAt;

  Map<String, Object?> toJson() => {
    'tileId': tileId,
    'boardId': boardId,
    'spokenAt': spokenAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is WordUse &&
      other.tileId == tileId &&
      other.boardId == boardId &&
      other.spokenAt == spokenAt;

  @override
  int get hashCode => Object.hash(tileId, boardId, spokenAt);

  @override
  String toString() => 'WordUse($tileId on $boardId at $spokenAt)';
}

/// [queue] with [uses] added at the end, oldest first, keeping only the
/// newest [cap].
List<WordUse> enqueueWordUses(
  List<WordUse> queue,
  Iterable<WordUse> uses, {
  int cap = wordLogQueueCap,
}) {
  final all = [...queue, ...uses];
  return all.length <= cap ? all : all.sublist(all.length - cap);
}

/// The next uses to send: the oldest [wordLogBatchSize] in [queue].
List<WordUse> nextWordUseBatch(
  List<WordUse> queue, {
  int size = wordLogBatchSize,
}) => queue.take(size).toList();

/// [queue] once the server has kept the first [sent] uses.
List<WordUse> afterWordUsesSent(List<WordUse> queue, int sent) =>
    queue.skip(sent.clamp(0, queue.length)).toList();

/// [queue] as text, to keep on the device.
String encodeWordUses(List<WordUse> queue) =>
    jsonEncode([for (final use in queue) use.toJson()]);

/// Reads what [encodeWordUses] wrote. A damaged entry is skipped rather than
/// losing the whole queue; text that is not a list gives an empty queue.
List<WordUse> decodeWordUses(String text) {
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    return [];
  }
  if (json is! List<Object?>) return [];
  final uses = <WordUse>[];
  for (final entry in json) {
    if (entry is! Map<String, Object?>) continue;
    try {
      uses.add(WordUse.fromJson(entry));
    } on FormatException {
      continue;
    }
  }
  return enqueueWordUses(const [], uses);
}
