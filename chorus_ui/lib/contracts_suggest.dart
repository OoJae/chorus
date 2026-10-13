/// The optional word suggestion as the add-word sheet sees it.
///
/// Kept apart from `contracts.dart` so the sheet works exactly as before
/// without it: a suggestion only ever fills in the form, and the adult
/// still decides what goes on the board.
library;

import 'package:flutter/foundation.dart';

/// A word proposed for a photo. Nothing here is on the board yet.
class WordIdea {
  const WordIdea({
    required this.label,
    this.speech = '',
    this.colorKey,
    this.alternatives = const [],
  });

  /// The proposed word.
  final String label;

  /// What to say when it differs from [label]; empty otherwise.
  final String speech;

  /// A part-of-speech key. May be one the tiles have no colour for; the
  /// form then leaves the word plain.
  final String? colorKey;

  /// Other words the adult may prefer, best first.
  final List<String> alternatives;
}

/// Asks the server for a word that fits a photo.
abstract class WordSuggester {
  /// True while a suggestion can be asked for: the device is online and the
  /// service is set up. The sheet shows its button only then.
  ValueListenable<bool> get available;

  /// Sends [photo] to the server and completes with a word for it, or with
  /// null when there is none for any reason. Never throws: the adult simply
  /// types the word.
  Future<WordIdea?> fromPhoto(Uint8List photo);
}
