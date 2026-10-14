/// The talker's word tools: the "word endings", "quick phrases" and
/// keyboard keys beside the sentence strip, and what each opens.
///
/// The keys sit in the strip's own row, between the strip and Speak: they
/// take width from the strip only, so Speak, Delete last word and Clear
/// keep their places and the grid keeps its height. Each key is behind its
/// flag in `features/flags/w4.dart`; with every flag off the row is as it
/// was.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../../brand/haptics.dart';
import '../../brand/pressable_surface.dart';
import '../../brand/tokens.dart';
import '../../contracts.dart';
import '../../contracts_quick_phrases.dart';
import '../../fakes_quick_phrases.dart';
import '../../features/flags/w4.dart';
import '../talker_controller.dart';
import 'keyboard_page.dart';
import 'quick_phrases_panel.dart';

/// Label of the key that opens the endings of the last word.
const String wordEndingsLabel = 'Word endings';

/// Label of the key that opens the quick phrases.
const String quickPhrasesLabel = 'Quick phrases';

/// Label of the key that opens the keyboard.
const String keyboardLabel = 'Keyboard';

/// What the endings panel says while the sentence is empty.
const String endingsEmptyMessage = 'Add a word first, then choose its ending.';

/// What the endings panel says for a word that takes none.
String endingsNoneMessage(String word) => 'No endings for "$word".';

/// Closes a word tool and goes back to the board.
const String backToBoardLabel = 'Back to the board';

/// The circle's quick phrases and this device's word counts, for the word
/// tools of the talker under it. Without one the talker uses the default
/// phrases and counts words in memory only.
class WordToolsScope extends InheritedWidget {
  const WordToolsScope({
    super.key,
    this.phrases,
    this.counts,
    required super.child,
  });

  final QuickPhraseBook? phrases;
  final SpokenWordCounts? counts;

  static WordToolsScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WordToolsScope>();

  /// The nearest scope, read once without depending on it: for callbacks.
  static WordToolsScope? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<WordToolsScope>();

  @override
  bool updateShouldNotify(WordToolsScope oldWidget) =>
      oldWidget.phrases != phrases || oldWidget.counts != counts;
}

/// Counts kept for a talker with no [WordToolsScope]: in memory, for as
/// long as the app runs.
final SpokenWordCounts _memoryCounts = MemorySpokenWordCounts();

/// Phrases for a talker with no [WordToolsScope]: the defaults.
final QuickPhraseBook _defaultPhrases = FakeQuickPhraseBook(canEdit: false);

/// A word on the strip that is not a tile of the board: a quick phrase, a
/// typed word or a word with a new ending. [kind] starts its id.
TileFacts stripWord(String text, {String kind = 'typed', String? colorKey}) =>
    TileFacts(
      id: '$kind:$text',
      boardId: '',
      cellKey: '',
      label: text,
      colorKey: colorKey,
    );

/// The word tool keys for the strip's row, each [width] wide, each with
/// the gap before it. Empty when every word tool is switched off, and on a
/// [phone] layout unless `w4WordToolsOnPhones`.
List<Widget> wordToolKeys({
  required TalkerController controller,
  required SpeechService speech,
  required double width,
  bool phone = false,
}) {
  if (!w4AnyWordTool || (phone && !w4WordToolsOnPhones)) return const [];
  return [_WordToolKeys(controller: controller, speech: speech, width: width)];
}

/// [strip] with the word tool keys after it, for a row of its own (a
/// phone held upright). [strip] alone when every word tool is off.
Widget stripWithWordTools({
  required Widget strip,
  required TalkerController controller,
  required SpeechService speech,
  required double width,
}) {
  if (!w4AnyWordTool || !w4WordToolsOnPhones) return strip;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: strip),
      ...wordToolKeys(controller: controller, speech: speech, width: width),
    ],
  );
}

/// Opens the endings of the last word of [controller]'s strip.
void openWordEndings(BuildContext context, TalkerController controller) {
  if (!w4WordEndings) return;
  showDialog<void>(
    context: context,
    builder: (_) => WordEndingsPanel(controller: controller),
  );
}

/// Opens the quick phrases over the whole screen.
void openQuickPhrases(BuildContext context, TalkerController controller) {
  if (!w4QuickPhrases) return;
  final book = WordToolsScope.read(context)?.phrases ?? _defaultPhrases;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => QuickPhrasesPanel(book: book, controller: controller),
    ),
  );
}

/// Opens the keyboard over the whole screen.
void openKeyboard(
  BuildContext context,
  TalkerController controller,
  SpeechService speech,
) {
  if (!w4Keyboard) return;
  final counts = WordToolsScope.read(context)?.counts ?? _memoryCounts;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) =>
          KeyboardPage(controller: controller, speech: speech, counts: counts),
    ),
  );
}

/// Wraps the sentence strip: counts each word that reaches it on this
/// device (for the keyboard's predictions), and on a long press offers the
/// word tools, which is how a phone reaches them. [child] alone when every
/// word tool is off.
Widget wordToolsHold({
  required TalkerController controller,
  required SpeechService speech,
  required Widget child,
}) {
  if (!w4AnyWordTool) return child;
  return WordToolsHold(controller: controller, speech: speech, child: child);
}

class WordToolsHold extends StatefulWidget {
  const WordToolsHold({
    super.key,
    required this.controller,
    required this.speech,
    required this.child,
  });

  final TalkerController controller;
  final SpeechService speech;
  final Widget child;

  @override
  State<WordToolsHold> createState() => _WordToolsHoldState();
}

class _WordToolsHoldState extends State<WordToolsHold> {
  /// How long the strip was when last seen, to count each new word once.
  int _seen = 0;

  @override
  void initState() {
    super.initState();
    _seen = widget.controller.strip.length;
    widget.controller.addListener(_onStrip);
  }

  @override
  void didUpdateWidget(WordToolsHold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onStrip);
      _seen = widget.controller.strip.length;
      widget.controller.addListener(_onStrip);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStrip);
    super.dispose();
  }

  /// Counts each word added to the strip on this device. Quick phrases are
  /// not words to predict; nothing is counted while the board is private.
  void _onStrip() {
    final strip = widget.controller.strip;
    if (strip.length > _seen && !widget.controller.private) {
      final counts = WordToolsScope.read(context)?.counts ?? _memoryCounts;
      for (final word in strip.skip(_seen)) {
        if (word.id.startsWith('phrase:')) continue;
        try {
          counts.noteSaid(word.label);
        } catch (_) {}
      }
    }
    _seen = strip.length;
  }

  void _choose() {
    final controller = widget.controller;
    final speech = widget.speech;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        void then(void Function() open) {
          Navigator.of(dialogContext).pop();
          open();
        }

        return WordToolsChooser(
          onEndings: () => then(() => openWordEndings(context, controller)),
          onPhrases: () => then(() => openQuickPhrases(context, controller)),
          onKeyboard: () =>
              then(() => openKeyboard(context, controller, speech)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) =>
      GestureDetector(onLongPress: _choose, child: widget.child);
}

/// The word tools as three large choices, for a phone, where they have no
/// keys of their own.
class WordToolsChooser extends StatelessWidget {
  const WordToolsChooser({
    super.key,
    required this.onEndings,
    required this.onPhrases,
    required this.onKeyboard,
  });

  final VoidCallback onEndings;
  final VoidCallback onPhrases;
  final VoidCallback onKeyboard;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    Widget choice(String label, Widget mark, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(top: ChorusSpace.targetGap),
      child: SizedBox(
        height: 64,
        child: PressableSurface(
          onTap: onTap,
          semanticLabel: label,
          color: colors.line,
          foregroundColor: colors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(width: 40, child: Center(child: mark)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: ChorusType.label.copyWith(
                    color: colors.ink,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChorusSpace.panelRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (w4WordEndings)
                choice(wordEndingsLabel, const _EndingsGlyph(), onEndings),
              if (w4QuickPhrases)
                choice(
                  quickPhrasesLabel,
                  Icon(Icons.campaign_rounded, color: colors.ink),
                  onPhrases,
                ),
              if (w4Keyboard)
                choice(
                  keyboardLabel,
                  Icon(Icons.keyboard_rounded, color: colors.ink),
                  onKeyboard,
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(backToBoardLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordToolKeys extends StatelessWidget {
  const _WordToolKeys({
    required this.controller,
    required this.speech,
    required this.width,
  });

  final TalkerController controller;
  final SpeechService speech;
  final double width;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: ChorusSpace.targetGap);
    Widget sized(Widget key) => SizedBox(width: width, child: key);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (w4WordEndings) ...[
          gap,
          sized(
            WordToolKey(
              label: wordEndingsLabel,
              onPressed: () => openWordEndings(context, controller),
              child: const _EndingsGlyph(),
            ),
          ),
        ],
        if (w4QuickPhrases) ...[
          gap,
          sized(
            WordToolKey(
              label: quickPhrasesLabel,
              onPressed: () => openQuickPhrases(context, controller),
              icon: Icons.campaign_rounded,
            ),
          ),
        ],
        if (w4Keyboard) ...[
          gap,
          sized(
            WordToolKey(
              label: keyboardLabel,
              onPressed: () => openKeyboard(context, controller, speech),
              icon: Icons.keyboard_rounded,
            ),
          ),
        ],
      ],
    );
  }
}

/// "+s" in the tile face: the mark of the word endings key.
class _EndingsGlyph extends StatelessWidget {
  const _EndingsGlyph();

  @override
  Widget build(BuildContext context) {
    final ink = ChorusColors.of(context).ink;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '+s',
        maxLines: 1,
        style: ChorusType.tileLabel(
          24,
        ).copyWith(color: ink, fontWeight: FontWeight.w800, inherit: false),
      ),
    );
  }
}

/// One word tool key: card grey on its laminated edge, like Delete last
/// word and Clear, so it reads as part of the strip's controls.
class WordToolKey extends StatelessWidget {
  const WordToolKey({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.child,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Tooltip(
      message: label,
      child: PressableSurface(
        onTap: onPressed,
        semanticLabel: label,
        color: colors.line,
        foregroundColor: colors.ink,
        borderRadius: ChorusSpace.buttonRadius,
        child: SizedBox.expand(
          child: Center(
            child: child ?? Icon(icon, size: 28, color: colors.ink),
          ),
        ),
      ),
    );
  }
}

/// The endings of the last word of the sentence, as words to tap: each
/// replaces the last word and is spoken. Only the endings that make sense
/// for the word are offered (see `wordFormsFor`).
class WordEndingsPanel extends StatelessWidget {
  const WordEndingsPanel({super.key, required this.controller});

  final TalkerController controller;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final strip = controller.strip;
    final last = strip.isEmpty ? null : strip.last;
    // A quick phrase is a whole sentence: it takes no ending.
    final forms = last == null || last.id.startsWith('phrase:')
        ? const <EndingForm>[]
        : wordFormsFor(last.label, colorKey: last.colorKey);
    final family = TileFamily.forKey(
      last?.colorKey,
    ).colorsFor(Theme.of(context).brightness);
    final message = last == null
        ? endingsEmptyMessage
        : forms.isEmpty
        ? endingsNoneMessage(last.label)
        : null;
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChorusSpace.panelRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                wordEndingsLabel,
                style: ChorusType.headline.copyWith(color: colors.ink),
              ),
              const SizedBox(height: 12),
              if (message != null)
                Text(
                  message,
                  style: ChorusType.body.copyWith(color: colors.inkMuted),
                )
              else
                Wrap(
                  spacing: ChorusSpace.targetGap,
                  runSpacing: ChorusSpace.targetGap,
                  children: [
                    for (final form in forms)
                      SizedBox(
                        height: 72,
                        child: PressableSurface(
                          onTap: () {
                            final word = last!;
                            controller.replaceLastWord(
                              TileFacts(
                                id: 'ending:${word.id}',
                                boardId: word.boardId,
                                cellKey: word.cellKey,
                                label: form.text,
                                colorKey: word.colorKey,
                              ),
                            );
                            Navigator.of(context).pop();
                          },
                          semanticLabel: form.text,
                          haptic: ChorusHaptic.wordTapped,
                          color: family.fill,
                          edgeColor: family.edge,
                          foregroundColor: tileLabelInk,
                          borderRadius: ChorusSpace.tileRadius,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              form.text,
                              maxLines: 1,
                              style: ChorusType.tileLabel(
                                30,
                              ).copyWith(color: tileLabelInk, inherit: false),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(backToBoardLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
