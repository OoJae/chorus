/// A circle's second (home) language, as the screens see it.
///
/// Kept apart from `contracts.dart` so every screen works exactly as before
/// without it.
library;

import 'package:flutter/foundation.dart';

/// A language: its BCP 47 code (`yo`, `es`, `fr`) and its name.
@immutable
class HomeLanguage {
  const HomeLanguage({required this.code, required this.name});

  /// A BCP 47 language code, e.g. `yo`.
  final String code;

  /// Its name, e.g. "Yoruba".
  final String name;

  @override
  bool operator ==(Object other) =>
      other is HomeLanguage && other.code == code && other.name == name;

  @override
  int get hashCode => Object.hash(code, name);

  @override
  String toString() => 'HomeLanguage($code, $name)';
}

/// The languages an adult picks from for the circle's second language.
const List<HomeLanguage> homeLanguageChoices = [
  HomeLanguage(code: 'yo', name: 'Yoruba'),
  HomeLanguage(code: 'ig', name: 'Igbo'),
  HomeLanguage(code: 'ha', name: 'Hausa'),
  HomeLanguage(code: 'es', name: 'Spanish'),
  HomeLanguage(code: 'fr', name: 'French'),
  HomeLanguage(code: 'pt', name: 'Portuguese'),
  HomeLanguage(code: 'de', name: 'German'),
  HomeLanguage(code: 'it', name: 'Italian'),
  HomeLanguage(code: 'pl', name: 'Polish'),
  HomeLanguage(code: 'ar', name: 'Arabic'),
  HomeLanguage(code: 'ur', name: 'Urdu'),
  HomeLanguage(code: 'hi', name: 'Hindi'),
  HomeLanguage(code: 'zh', name: 'Chinese'),
];

/// One word in the circle's second language.
@immutable
class WordInLanguage {
  const WordInLanguage({
    required this.tileId,
    required this.label,
    this.speech,
  });

  final String tileId;
  final String label;

  /// What is spoken; null says [label].
  final String? speech;

  String get spokenText =>
      (speech == null || speech!.trim().isEmpty) ? label : speech!;
}

/// The circle's second language and its words in it.
///
/// Kept on this device, so the child's board shows it with no network.
/// Notifies listeners whenever any getter's answer changes.
abstract class HomeLanguages extends ChangeNotifier {
  /// The circle's second language; null when it has none.
  HomeLanguage? get language;

  /// True when the signed-in adult may change the language and the words:
  /// every role but a read-only partner.
  bool get canChange;

  /// Sets the circle's second language, or clears it with null. Words kept
  /// in another language stay kept. Throws [StateError] unless [canChange].
  Future<void> setLanguage(HomeLanguage? language);

  /// The word [tileId] in [language]; null when it has none, or there is no
  /// language.
  WordInLanguage? wordFor(String tileId);

  /// Sets the word [tileId] in [language]. An empty [label] removes it, so
  /// the word shows in the first language again. Throws [StateError] unless
  /// [canChange] and there is a language.
  Future<void> setWord(String tileId, {required String label, String? speech});
}

/// The device's voices for other languages.
abstract class LanguageVoice {
  /// Speaks [text] with this device's voice for [languageCode]. Completes
  /// with false, having said nothing, when the device has no voice for it.
  /// Never throws.
  Future<bool> speakIn(String languageCode, String text);
}
