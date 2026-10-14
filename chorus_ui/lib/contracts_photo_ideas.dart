/// Several ideas for one photo, as the add-word sheet sees them.
///
/// Kept apart from `contracts_suggest.dart` so a suggester may offer it or
/// not: the sheet asks for ideas only from a `WordSuggester` that also
/// implements [PhotoIdeasSuggester], and otherwise works as before.
library;

import 'package:flutter/foundation.dart';

import 'contracts_suggest.dart';

export 'contracts_suggest.dart' show WordIdea;

/// Asks the server for 3 to 6 words across word types for a photo.
abstract class PhotoIdeasSuggester {
  /// Sends [photo] and completes with the ideas, best first, each with a
  /// part-of-speech colour key. Empty when there are none for any reason
  /// (a timeout included). Never throws: the adult simply types the word.
  Future<List<WordIdea>> ideasFromPhoto(Uint8List photo);
}
