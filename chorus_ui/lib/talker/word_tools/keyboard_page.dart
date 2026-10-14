/// The keyboard: big letter keys in ABC order or QWERTY, a line of text,
/// three predicted words that change with each letter, "Speak" and "Add to
/// sentence".
///
/// Predictions come from the bundled common words and from how often this
/// device has spoken each word (`predictWords`); the counts never leave the
/// device.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../brand/haptics.dart';
import '../../brand/pressable_surface.dart';
import '../../brand/tokens.dart';
import '../../contracts.dart';
import '../../contracts_quick_phrases.dart';
import '../talker_controller.dart';
import 'word_tools.dart';

/// Speaks the typed line without adding it to the sentence.
const String keyboardSpeakLabel = 'Speak';

/// Adds the typed line to the sentence and goes back to the board.
const String keyboardAddLabel = 'Add to sentence';

/// The space key.
const String keyboardSpaceLabel = 'Space';

/// Deletes the last letter.
const String keyboardDeleteLabel = 'Delete letter';

/// Switches the letters to ABC order.
const String keyboardAbcLabel = 'ABC';

/// Switches the letters to QWERTY.
const String keyboardQwertyLabel = 'QWERTY';

/// Shown in the empty text line.
const String keyboardHint = 'Type a word';

/// The letters in ABC order, row by row.
const List<String> abcRows = ['abcdefg', 'hijklmn', 'opqrstu', "vwxyz'"];

/// The letters as on a computer keyboard, row by row.
const List<String> qwertyRows = ['qwertyuiop', 'asdfghjkl', "zxcvbnm'"];

class KeyboardPage extends StatefulWidget {
  const KeyboardPage({
    super.key,
    required this.controller,
    required this.speech,
    required this.counts,
  });

  final TalkerController controller;
  final SpeechService speech;
  final SpokenWordCounts counts;

  /// The text line, for tests.
  @visibleForTesting
  static const Key textKey = ValueKey('KeyboardPage.text');

  /// Whether the letters were last shown as QWERTY, for this run of the app.
  static bool _qwerty = false;

  @override
  State<KeyboardPage> createState() => _KeyboardPageState();
}

class _KeyboardPageState extends State<KeyboardPage> {
  String _text = '';
  bool _qwerty = KeyboardPage._qwerty;
  final FocusNode _focus = FocusNode(debugLabel: 'KeyboardPage');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  List<String> get _predictions =>
      predictWords(wordBeingTyped(_text), counts: widget.counts.counts);

  void _type(String letter) => setState(() => _text += letter);

  void _space() {
    if (_text.isEmpty || _text.endsWith(' ')) return;
    setState(() => _text += ' ');
  }

  void _delete() {
    if (_text.isEmpty) return;
    setState(() => _text = _text.substring(0, _text.length - 1));
  }

  void _pick(String word) => setState(() => _text = completeWord(_text, word));

  void _toggleLayout() => setState(() {
    _qwerty = !_qwerty;
    KeyboardPage._qwerty = _qwerty;
  });

  List<String> get _words =>
      _text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  void _count() {
    if (widget.controller.private) return;
    try {
      widget.counts.noteSaid(_text);
    } catch (_) {}
  }

  Future<void> _speak() async {
    final text = _text.trim();
    if (text.isEmpty) return;
    ChorusHaptics.sentenceSpoken();
    _count();
    try {
      await widget.speech.speak(text);
    } catch (_) {}
  }

  void _add() {
    final words = _words;
    if (words.isEmpty) return;
    // The board counts what reaches the strip; counting here too would
    // count it twice.
    widget.controller.addWords([for (final w in words) stripWord(w)]);
    Navigator.of(context).pop();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      _delete();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      _space();
      return KeyEventResult.handled;
    }
    final char = event.character?.toLowerCase();
    if (char != null && RegExp(r"^[a-z']$").hasMatch(char)) {
      _type(char);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final predictions = _predictions;
    final rows = _qwerty ? qwertyRows : abcRows;
    const gap = SizedBox(width: ChorusSpace.targetGap, height: 6);
    // A phone on its side has no height for rows that share it out: the
    // keys keep a target's height and the page scrolls.
    final short = MediaQuery.sizeOf(context).height < 600;
    Widget fill(Widget child) =>
        short ? SizedBox(height: 52, child: child) : Expanded(child: child);
    Widget page(Widget column) =>
        short ? SingleChildScrollView(child: column) : column;
    Widget keys(Widget column) => short ? column : Expanded(child: column);
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: colors.card,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: page(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 64,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _TextLine(text: _text)),
                        gap,
                        SizedBox(
                          width: 64,
                          child: _Key(
                            label: backToBoardLabel,
                            onTap: () => Navigator.of(context).pop(),
                            child: Icon(Icons.close_rounded, color: colors.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                  gap,
                  // Three places, always: a prediction that goes leaves its
                  // place empty, so the others do not move under a finger.
                  SizedBox(
                    height: 64,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) gap,
                          Expanded(
                            child: i < predictions.length
                                ? _Key(
                                    label: predictions[i],
                                    onTap: () => _pick(predictions[i]),
                                    strong: true,
                                    text: predictions[i],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  gap,
                  keys(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final row in rows) ...[
                          fill(
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var i = 0; i < row.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 6),
                                  Expanded(
                                    child: _Key(
                                      label: row[i],
                                      text: row[i],
                                      onTap: () => _type(row[i]),
                                    ),
                                  ),
                                ],
                                // Short rows keep keys the size of the
                                // longest row's.
                                for (
                                  var i = row.length;
                                  i < rows.map((r) => r.length).reduce(_max);
                                  i++
                                ) ...[
                                  const SizedBox(width: 6),
                                  const Expanded(child: SizedBox.shrink()),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        SizedBox(
                          height: 56,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _Key(
                                  label: _qwerty
                                      ? keyboardAbcLabel
                                      : keyboardQwertyLabel,
                                  text: _qwerty
                                      ? keyboardAbcLabel
                                      : keyboardQwertyLabel,
                                  onTap: _toggleLayout,
                                  small: true,
                                ),
                              ),
                              gap,
                              Expanded(
                                flex: 4,
                                child: _Key(
                                  label: keyboardSpaceLabel,
                                  text: keyboardSpaceLabel,
                                  onTap: _space,
                                  small: true,
                                ),
                              ),
                              gap,
                              Expanded(
                                flex: 2,
                                child: _Key(
                                  label: keyboardDeleteLabel,
                                  onTap: _delete,
                                  child: Icon(
                                    Icons.backspace_rounded,
                                    color: colors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  gap,
                  SizedBox(
                    height: 64,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _Key(
                            label: keyboardSpeakLabel,
                            onTap: _speak,
                            primary: true,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.volume_up_rounded,
                                  color: colors.surface,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  keyboardSpeakLabel,
                                  style: ChorusType.label.copyWith(
                                    color: colors.surface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        gap,
                        Expanded(
                          child: _Key(
                            label: keyboardAddLabel,
                            onTap: _add,
                            small: true,
                            text: keyboardAddLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

int _max(int a, int b) => a > b ? a : b;

/// The typed line, ink on card in the tile face, with the newest letters in
/// view.
class _TextLine extends StatelessWidget {
  const _TextLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final empty = text.isEmpty;
    return Semantics(
      liveRegion: true,
      label: empty ? keyboardHint : text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
          border: Border.all(color: colors.ink, width: 2),
        ),
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Text(
            empty ? keyboardHint : '$text|',
            key: KeyboardPage.textKey,
            maxLines: 1,
            style: ChorusType.tileLabel(
              30,
            ).copyWith(color: empty ? colors.inkMuted : colors.ink),
          ),
        ),
      ),
    );
  }
}

/// A key: card grey on its laminated edge; [primary] is ink, [strong] (a
/// prediction) is the page's surface with an ink edge.
class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.onTap,
    this.text,
    this.child,
    this.primary = false,
    this.strong = false,
    this.small = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? text;
  final Widget? child;
  final bool primary;
  final bool strong;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final ink = primary ? colors.surface : colors.ink;
    final face = primary
        ? colors.ink
        : strong
        ? colors.surface
        : colors.line;
    return PressableSurface(
      onTap: onTap,
      semanticLabel: label,
      color: face,
      edgeColor: strong ? colors.ink : null,
      foregroundColor: ink,
      borderRadius: ChorusSpace.buttonRadius,
      child: SizedBox.expand(
        child: Center(
          child:
              child ??
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    text ?? label,
                    maxLines: 1,
                    style: small
                        ? ChorusType.label.copyWith(color: ink)
                        : ChorusType.tileLabel(
                            strong ? 26 : 28,
                          ).copyWith(color: ink, inherit: false),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
