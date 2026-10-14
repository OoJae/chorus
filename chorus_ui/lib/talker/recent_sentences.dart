/// The sentences spoken on this device since the app opened, one list for
/// each child's circle: kept in memory only, and gone when the app closes
/// or the adult signs out.
library;

import 'package:flutter/foundation.dart';

/// The last sentences spoken, newest first.
class RecentSentences extends ChangeNotifier {
  RecentSentences({this.limit = 20});

  static final Map<String, RecentSentences> _byCircle = {};
  static String _circle = '';

  /// The list of the circle whose board was opened last (see [useCircle]),
  /// for this run of the app. Never saved anywhere.
  static RecentSentences get session =>
      _byCircle[_circle] ??= RecentSentences();

  /// From now on [session] is the list of the circle [circleId]: one
  /// child's sentences never show on another child's board.
  static void useCircle(String circleId) => _circle = circleId;

  /// Forgets every circle's list, as on sign-out: the next adult to sign
  /// in on this device sees none of them.
  static void clearAll() {
    for (final recent in _byCircle.values) {
      recent.clear();
    }
    _byCircle.clear();
    _circle = '';
  }

  /// How many are kept; the oldest goes first.
  final int limit;

  final List<String> _sentences = [];

  /// What the board said for each sentence, when not its words as read.
  final Map<String, String> _spoken = {};

  /// Newest first.
  List<String> get sentences => List.unmodifiable(_sentences);

  /// What the board said for [sentence]: a word an adult set to say more
  /// than its label says that again.
  String spokenOf(String sentence) => _spoken[sentence] ?? sentence;

  /// Notes [sentence] as just spoken, as the words read; [spoken] is what
  /// the board said, when that differs. Said again, it moves to the top
  /// rather than being listed twice.
  void add(String sentence, {String? spoken}) {
    final text = sentence.trim();
    if (text.isEmpty) return;
    _sentences
      ..remove(text)
      ..insert(0, text);
    final said = spoken?.trim();
    if (said == null || said.isEmpty || said == text) {
      _spoken.remove(text);
    } else {
      _spoken[text] = said;
    }
    if (_sentences.length > limit) {
      for (final gone in _sentences.sublist(limit)) {
        _spoken.remove(gone);
      }
      _sentences.removeRange(limit, _sentences.length);
    }
    notifyListeners();
  }

  void clear() {
    if (_sentences.isEmpty) return;
    _sentences.clear();
    _spoken.clear();
    notifyListeners();
  }
}
