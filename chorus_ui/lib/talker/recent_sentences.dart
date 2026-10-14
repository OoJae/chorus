/// The sentences spoken on this device since the app opened: kept in
/// memory only, and gone when the app closes.
library;

import 'package:flutter/foundation.dart';

/// The last sentences spoken, newest first.
class RecentSentences extends ChangeNotifier {
  RecentSentences({this.limit = 20});

  /// The list for this run of the app. Never saved anywhere.
  static final RecentSentences session = RecentSentences();

  /// How many are kept; the oldest goes first.
  final int limit;

  final List<String> _sentences = [];

  /// Newest first.
  List<String> get sentences => List.unmodifiable(_sentences);

  /// Notes [sentence] as just spoken. Said again, it moves to the top
  /// rather than being listed twice.
  void add(String sentence) {
    final text = sentence.trim();
    if (text.isEmpty) return;
    _sentences
      ..remove(text)
      ..insert(0, text);
    if (_sentences.length > limit) {
      _sentences.removeRange(limit, _sentences.length);
    }
    notifyListeners();
  }

  void clear() {
    if (_sentences.isEmpty) return;
    _sentences.clear();
    notifyListeners();
  }
}
