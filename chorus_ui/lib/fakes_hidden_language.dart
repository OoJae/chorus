/// In-memory hidden words, second language and language voices, for the
/// screens to run and be tested without a server.
library;

import 'contracts_hidden.dart';
import 'contracts_language.dart';

/// [HiddenWords] held in memory.
class FakeHiddenWords extends HiddenWords {
  FakeHiddenWords({Set<String>? hidden, this._canChange = true})
    : _hidden = {...?hidden};

  final Set<String> _hidden;
  bool _canChange;

  @override
  Set<String> get hiddenIds => Set.unmodifiable(_hidden);

  @override
  bool get canChange => _canChange;

  set canChange(bool value) {
    if (_canChange == value) return;
    _canChange = value;
    notifyListeners();
  }

  @override
  Future<void> setHidden(String tileId, bool hidden) async {
    if (!_canChange) throw StateError('Only an editor may hide words.');
    final changed = hidden ? _hidden.add(tileId) : _hidden.remove(tileId);
    if (changed) notifyListeners();
  }
}

/// [HomeLanguages] held in memory, words kept per language.
class FakeHomeLanguages extends HomeLanguages {
  FakeHomeLanguages({
    HomeLanguage? language,
    Map<String, WordInLanguage>? words,
    this._canChange = true,
  }) : _language = language {
    if (language != null && words != null) _words[language.code] = {...words};
  }

  HomeLanguage? _language;
  final bool _canChange;

  /// Words by language code, then by tile id.
  final Map<String, Map<String, WordInLanguage>> _words = {};

  @override
  HomeLanguage? get language => _language;

  @override
  bool get canChange => _canChange;

  @override
  Future<void> setLanguage(HomeLanguage? language) async {
    if (!_canChange) throw StateError('Only an editor may set the language.');
    if (_language == language) return;
    _language = language;
    notifyListeners();
  }

  @override
  WordInLanguage? wordFor(String tileId) {
    final code = _language?.code;
    return code == null ? null : _words[code]?[tileId];
  }

  @override
  Future<void> setWord(
    String tileId, {
    required String label,
    String? speech,
  }) async {
    final code = _language?.code;
    if (!_canChange || code == null) {
      throw StateError('No language, or only an editor may set words.');
    }
    final words = _words.putIfAbsent(code, () => {});
    final text = label.trim();
    if (text.isEmpty) {
      words.remove(tileId);
    } else {
      final said = speech?.trim();
      words[tileId] = WordInLanguage(
        tileId: tileId,
        label: text,
        speech: (said == null || said.isEmpty) ? null : said,
      );
    }
    notifyListeners();
  }
}

/// A [LanguageVoice] with voices for [codes] only. Records what it said.
class FakeLanguageVoice implements LanguageVoice {
  FakeLanguageVoice({Set<String> codes = const {}}) : codes = {...codes};

  /// The languages this device has a voice for.
  final Set<String> codes;

  /// What was said, as `code: text`.
  final List<String> said = [];

  @override
  Future<bool> speakIn(String languageCode, String text) async {
    if (!codes.contains(languageCode)) return false;
    said.add('$languageCode: $text');
    return true;
  }
}
