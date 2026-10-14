/// Hidden words, "Show everything" and the second language on the child's
/// board (engineer W5). The talker screen hooks these in; everything about
/// them lives here.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_hidden.dart';
import '../contracts_language.dart';
import '../contracts_media.dart';
import '../features/flags/w5.dart';

/// Label of the control that shows every hidden word for now.
const String showEverythingLabel = 'Show everything';

/// Said of "Show everything" while it is off.
const String showEverythingOffMessage =
    'Show the words hidden for now, until you leave the board';

/// Said of "Show everything" while it is on.
const String showEverythingOnMessage =
    'Every word is showing until you leave the board';

/// Said of the language switch while it shows the first language.
String languageOffMessage(String name) => 'Show the words in $name';

/// Said of the language switch while it shows [name].
String languageOnMessage(String name) =>
    'Showing the words in $name. Tap to go back';

/// What the child's board adds for hidden words and the second language.
///
/// Hidden words are held like the board itself: a word hidden or shown
/// again on another device changes here only at a safe moment ([isSafe]:
/// the board idle, nothing playing, the strip empty and two seconds
/// without a touch), the same moment "1 waiting" words arrive. "Show
/// everything" and the language switch are an adult's own act on this
/// device and apply at once; both last until the board is left.
class TalkerExtras extends ChangeNotifier {
  TalkerExtras({
    required this.isSafe,
    HiddenWords? hidden,
    HomeLanguages? languages,
    this.voice,
    Duration recheck = const Duration(milliseconds: 500),
  }) : hidden = hideWordsEnabled ? hidden : null,
       languages = homeLanguageEnabled ? languages : null {
    final source = this.hidden;
    if (source != null) {
      _held = {...source.hiddenIds};
      source.addListener(_onHiddenChanged);
    }
    this.languages?.addListener(_onLanguageChanged);
    if (this.hidden != null) {
      _timer = Timer.periodic(recheck, (_) => checkSafePoint());
    }
  }

  /// Makes the extras when there is anything to add, else null.
  static TalkerExtras? maybe({
    required bool Function() isSafe,
    HiddenWords? hidden,
    HomeLanguages? languages,
    LanguageVoice? voice,
  }) {
    final hides = hideWordsEnabled && hidden != null;
    final speaks = homeLanguageEnabled && languages != null;
    if (!hides && !speaks) return null;
    return TalkerExtras(
      isSafe: isSafe,
      hidden: hidden,
      languages: languages,
      voice: voice,
    );
  }

  /// True when what the child sees may change now.
  final bool Function() isSafe;
  final HiddenWords? hidden;
  final HomeLanguages? languages;

  /// The device's voices for other languages; null speaks every word as
  /// before.
  final LanguageVoice? voice;

  Timer? _timer;
  bool _disposed = false;

  /// The hidden words the child's board shows as hidden now.
  Set<String> _held = const {};

  /// True while [hidden] says something other than [_held].
  bool _waiting = false;

  bool _showEverything = false;
  bool _languageOn = false;

  /// True while every hidden word is shown, until the board is left.
  bool get showEverything => _showEverything;

  /// True when the board offers "Show everything": some word is hidden, or
  /// it is on.
  bool get offersShowEverything =>
      hidden != null &&
      (_showEverything || _held.isNotEmpty || hidden!.hiddenIds.isNotEmpty);

  void setShowEverything(bool value) {
    if (_showEverything == value) return;
    _showEverything = value;
    notifyListeners();
  }

  /// Whether the cell of [tileId] is shown blank.
  bool hides(String tileId) => !_showEverything && _held.contains(tileId);

  /// The ids the child's board shows as hidden, "Show everything" aside.
  @visibleForTesting
  Set<String> get heldHidden => Set.unmodifiable(_held);

  /// The circle's second language when the board offers it.
  HomeLanguage? get language => languages?.language;

  /// True when the board offers the language switch.
  bool get offersLanguage => language != null;

  /// True while the words show in [language].
  bool get languageOn => _languageOn && language != null;

  void setLanguageOn(bool value) {
    if (_languageOn == value) return;
    _languageOn = value;
    notifyListeners();
  }

  /// [tile] as the board shows it: in the second language while
  /// [languageOn] and the word has one, otherwise [tile] itself.
  TileFacts shownTile(TileFacts tile) {
    if (!languageOn) return tile;
    final word = languages?.wordFor(tile.id);
    if (word == null) return tile;
    return TileFacts(
      id: tile.id,
      boardId: tile.boardId,
      cellKey: tile.cellKey,
      label: word.label,
      speech: word.spokenText,
      imageHash: tile.imageHash,
      audioHash: tile.audioHash,
      colorKey: tile.colorKey,
      archived: tile.archived,
      createdBy: tile.createdBy,
      createdByName: tile.createdByName,
      createdAt: tile.createdAt,
    );
  }

  /// Whether [words] are all shown in the second language, so a sentence
  /// of them is said with its voice. A quick phrase, a typed word, a scene's
  /// spot, a word with a new ending or a word put on the strip before the
  /// switch came on is in the first language.
  bool speaksInLanguage(Iterable<TileFacts> words) {
    if (!languageOn || words.isEmpty) return false;
    return words.every((tile) {
      final word = languages?.wordFor(tile.id);
      return word != null &&
          tile.label == word.label &&
          tile.spokenText == word.spokenText;
    });
  }

  /// Says [text] with the device's voice for the second language while
  /// [languageOn]. False when it did not: the switch is off, or there is no
  /// voice for it.
  Future<bool> speakInLanguage(String text) async {
    final code = language?.code;
    final voice = this.voice;
    if (!languageOn || code == null || voice == null) return false;
    try {
      return await voice.speakIn(code, text);
    } catch (_) {
      return false;
    }
  }

  /// The speaker the board's controller should use: [base] (or [speech]
  /// when it plays clips itself, else [speech]'s voice) for a word in the
  /// first language; for a word shown in the second language, the
  /// device's voice for it, else the word's recorded voice, else the word
  /// in the first language. [original] finds a tile as the store has it.
  /// Null when there is no second language to speak.
  TileSpeaker? speakerFor(
    TileSpeaker? base,
    SpeechService speech,
    TileFacts? Function(String tileId) original,
  ) {
    if (languages == null) return null;
    return _LanguageTileSpeaker(this, base, speech, original);
  }

  /// The speech the board's controller should use for whole sentences:
  /// the device's voice for the second language while every word of
  /// [strip] is shown in it (see [speaksInLanguage]) and the device has
  /// one, otherwise [speech]. Null when there is no second language.
  SpeechService? speechFor(
    SpeechService speech, {
    required List<TileFacts> Function() strip,
  }) {
    if (languages == null) return null;
    return _LanguageSpeech(this, speech, strip);
  }

  /// Applies a change to the hidden words if this is a safe moment.
  /// Returns true when what the child sees changed. A timer calls this.
  @visibleForTesting
  bool checkSafePoint() {
    final source = hidden;
    if (_disposed || source == null || !_waiting) return false;
    if (!isSafe()) return false;
    _held = {...source.hiddenIds};
    _waiting = false;
    notifyListeners();
    return true;
  }

  void _onHiddenChanged() {
    final source = hidden;
    if (_disposed || source == null) return;
    _waiting = !setEquals(source.hiddenIds, _held);
    // Says whether "Show everything" is offered, even when nothing moves.
    if (!checkSafePoint()) notifyListeners();
  }

  void _onLanguageChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    hidden?.removeListener(_onHiddenChanged);
    languages?.removeListener(_onLanguageChanged);
    super.dispose();
  }
}

/// A word's cell while it is hidden: blank and silent like an empty cell,
/// but the word keeps it.
class HiddenWordCell extends StatelessWidget {
  const HiddenWordCell({super.key});

  @override
  Widget build(BuildContext context) =>
      const ExcludeSemantics(child: SizedBox.expand());
}

/// The controls the talker's status row adds: "Show everything" while some
/// word is hidden, and the language switch while the circle has a second
/// language. Empty without [extras].
List<Widget> talkerExtraControls(
  TalkerExtras? extras, {
  required bool compact,
}) {
  if (extras == null) return const [];
  final language = extras.language;
  return [
    if (extras.offersShowEverything) ...[
      const SizedBox(width: ChorusSpace.targetGap),
      TalkerChromeToggle(
        key: TalkerChromeToggle.showEverythingKey,
        icon: Icons.visibility_rounded,
        label: showEverythingLabel,
        on: extras.showEverything,
        compact: compact,
        message: extras.showEverything
            ? showEverythingOnMessage
            : showEverythingOffMessage,
        onChanged: extras.setShowEverything,
      ),
    ],
    if (language != null) ...[
      const SizedBox(width: ChorusSpace.targetGap),
      TalkerChromeToggle(
        key: TalkerChromeToggle.languageKey,
        icon: Icons.translate_rounded,
        label: language.name,
        on: extras.languageOn,
        compact: compact,
        message: extras.languageOn
            ? languageOnMessage(language.name)
            : languageOffMessage(language.name),
        onChanged: extras.setLanguageOn,
      ),
    ],
  ];
}

/// A switch in the talker's chrome, drawn like "Private": an ink outline,
/// filled ink while on. Compact shows the icon alone while off.
class TalkerChromeToggle extends StatelessWidget {
  const TalkerChromeToggle({
    super.key,
    required this.icon,
    required this.label,
    required this.on,
    required this.compact,
    required this.message,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool on;
  final bool compact;
  final String message;
  final ValueChanged<bool> onChanged;

  /// "Show everything", for tests.
  @visibleForTesting
  static const Key showEverythingKey = ValueKey('TalkerExtras.showEverything');

  /// The language switch, for tests.
  @visibleForTesting
  static const Key languageKey = ValueKey('TalkerExtras.language');

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final ink = on ? colors.surface : colors.ink;
    final words = !compact || on;
    return Semantics(
      container: true,
      button: true,
      toggled: on,
      label: label,
      hint: message,
      onTap: () => onChanged(!on),
      excludeSemantics: true,
      child: Tooltip(
        message: message,
        child: InkWell(
          onTap: () => onChanged(!on),
          // Nothing spreads or moves on the child's board.
          splashFactory: NoSplash.splashFactory,
          borderRadius: BorderRadius.circular(ChorusSpace.minTarget / 2),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: ChorusSpace.minTarget,
              minHeight: ChorusSpace.minTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: Container(
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.symmetric(horizontal: words ? 12 : 0),
                decoration: BoxDecoration(
                  color: on ? colors.ink : colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.ink, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: ink),
                    if (words) ...[
                      const SizedBox(width: 6),
                      Text(
                        label,
                        maxLines: 1,
                        style: ChorusType.label.copyWith(color: ink),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Speaks a word shown in the second language with the device's voice for
/// it, else the word's recording, else the word in the first language.
class _LanguageTileSpeaker implements TileSpeaker {
  _LanguageTileSpeaker(this._extras, this._base, this._speech, this._original);

  final TalkerExtras _extras;
  final TileSpeaker? _base;
  final SpeechService _speech;
  final TileFacts? Function(String tileId) _original;

  @override
  Future<void> speakTile(TileFacts tile) async {
    try {
      final language = _extras.language;
      final word = _extras.languageOn && language != null
          ? _extras.languages?.wordFor(tile.id)
          : null;
      if (word == null || language == null) return await _plain(tile);
      final voice = _extras.voice;
      if (voice != null &&
          await voice.speakIn(language.code, word.spokenText)) {
        return;
      }
      // No voice for the language: the recording, else the first language.
      await _plain(_original(tile.id) ?? tile);
    } catch (_) {
      // Speech must never break the board.
    }
  }

  /// As the board speaks a word without this.
  Future<void> _plain(TileFacts tile) async {
    final Object speech = _speech;
    final base = _base ?? (speech is TileSpeaker ? speech : null);
    if (base != null) return base.speakTile(tile);
    await _speech.speak(tile.spokenText);
  }
}

/// [SpeechService] that says sentences with the second language's voice
/// while the board shows it.
class _LanguageSpeech implements SpeechService {
  _LanguageSpeech(this._extras, this._base, this._strip);

  final TalkerExtras _extras;
  final SpeechService _base;

  /// The words on the strip: every word the board says is on it.
  final List<TileFacts> Function() _strip;

  @override
  Future<void> speak(String text) async {
    if (_extras.speaksInLanguage(_strip()) &&
        await _extras.speakInLanguage(text)) {
      return;
    }
    await _base.speak(text);
  }

  @override
  Future<void> warmUp() => _base.warmUp();

  @override
  Future<void> stop() => _base.stop();

  @override
  ValueListenable<bool> get speaking => _base.speaking;

  @override
  ValueListenable<bool> get offlineVoiceReady => _base.offlineVoiceReady;
}
