/// Hiding a word for now and its second language, in the editor (engineer
/// W5). The editor hooks these in; everything about them lives here.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../brand/tokens.dart';
import '../contracts_hidden.dart';
import '../contracts_language.dart';
import '../features/flags/w5.dart';

/// The word sheet's action that hides a word for now.
const String hideForNowLabel = 'Hide for now';

/// The word sheet's action that shows a hidden word again.
const String showAgainLabel = 'Show on the board again';

/// The word sheet's action that opens the second language sheet.
const String secondLanguageLabel = 'Second language';

/// What the mark on a hidden word says.
const String hiddenForNowMark = 'Hidden for now';

/// Said when a word was hidden.
String hiddenMessage(String label) =>
    '"$label" is hidden for now. Its spot stays the same.';

/// Said when a word was shown again.
String shownAgainMessage(String label) => '"$label" is back on the board.';

/// Said when a change could not be kept.
const String notKeptMessage = 'That could not be saved. Try again.';

/// Title of the second language sheet.
String secondLanguageTitle(String label) => '"$label" in a second language';

/// Label of the language picker.
const String languagePickerLabel = 'Language';

/// Label of the word field.
const String languageWordLabel = 'Word';

/// Label of the optional speech field.
const String languageSpeechLabel = 'Says something different (optional)';

/// Helper under the word field.
const String languageWordHelper =
    'Leave empty to show the word in the first language.';

/// Label of the save button.
const String languageSaveLabel = 'Save';

/// The editor grid's mark for [tile]: dimmed with an "eye off" mark while
/// [hidden] says it is hidden, [view] as it is otherwise.
Widget editorWordMark(HiddenWords? hidden, TileFacts tile, Widget view) {
  if (!hideWordsEnabled || hidden == null) return view;
  return ListenableBuilder(
    listenable: hidden,
    builder: (context, _) {
      if (!hidden.hiddenIds.contains(tile.id)) return view;
      return HiddenWordMark(child: view);
    },
  );
}

/// A word hidden for now, as the editor shows it: dimmed, with an "eye off"
/// mark in its corner.
class HiddenWordMark extends StatelessWidget {
  const HiddenWordMark({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Opacity(opacity: 0.4, child: child),
        Positioned(
          top: 4,
          right: 4,
          child: IgnorePointer(
            child: Tooltip(
              message: hiddenForNowMark,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.ink, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    Icons.visibility_off_rounded,
                    size: 16,
                    color: colors.ink,
                    semanticLabel: hiddenForNowMark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// [form], the word's sheet, with "Hide for now" (or "Show on the board
/// again") and "Second language" under it, for an adult who may use them.
/// Each closes the sheet ([sheetContext]) and acts from [context], the
/// editor's. Without either it is [form] alone.
Widget wordSheetWithExtras({
  required BuildContext context,
  required BuildContext sheetContext,
  required TileFacts tile,
  required Widget form,
  HiddenWords? hidden,
  HomeLanguages? languages,
}) {
  final hides = hideWordsEnabled && hidden != null && hidden.canChange;
  final speaks =
      homeLanguageEnabled && languages != null && languages.canChange;
  if (!hides && !speaks) return form;
  final isHidden = hides && hidden.hiddenIds.contains(tile.id);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Flexible(child: form),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ChorusSpace.marginPhone,
            0,
            ChorusSpace.marginPhone,
            16,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: ChorusSpace.targetGap,
            children: [
              if (hides)
                TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  icon: Icon(
                    isHidden
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  label: Text(isHidden ? showAgainLabel : hideForNowLabel),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(
                      setWordHidden(context, hidden, tile, hidden: !isHidden),
                    );
                  },
                ),
              if (speaks)
                TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  icon: const Icon(Icons.translate_rounded),
                  label: const Text(secondLanguageLabel),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(
                      showSecondLanguageSheet(
                        context,
                        tile: tile,
                        languages: languages,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// Hides or shows [tile] and says so.
Future<void> setWordHidden(
  BuildContext context,
  HiddenWords words,
  TileFacts tile, {
  required bool hidden,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await words.setHidden(tile.id, hidden);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          hidden ? hiddenMessage(tile.label) : shownAgainMessage(tile.label),
        ),
      ),
    );
  } on Object {
    ChorusHaptics.failed();
    messenger?.showSnackBar(const SnackBar(content: Text(notKeptMessage)));
  }
}

/// The sheet where an adult types [tile] in the circle's second language,
/// choosing the language first when the circle has none.
Future<void> showSecondLanguageSheet(
  BuildContext context, {
  required TileFacts tile,
  required HomeLanguages languages,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) =>
        SecondLanguageForm(tile: tile, languages: languages),
  );
}

/// The second language sheet's content.
class SecondLanguageForm extends StatefulWidget {
  const SecondLanguageForm({
    super.key,
    required this.tile,
    required this.languages,
  });

  final TileFacts tile;
  final HomeLanguages languages;

  /// The language picker, for tests.
  @visibleForTesting
  static const Key pickerKey = ValueKey('SecondLanguageForm.picker');

  /// The word field, for tests.
  @visibleForTesting
  static const Key wordKey = ValueKey('SecondLanguageForm.word');

  @override
  State<SecondLanguageForm> createState() => _SecondLanguageFormState();
}

class _SecondLanguageFormState extends State<SecondLanguageForm> {
  late HomeLanguage _language;
  late final TextEditingController _word;
  late final TextEditingController _speech;
  bool _saving = false;

  /// The circle's language, then the picker's choices.
  List<HomeLanguage> get _choices {
    final current = widget.languages.language;
    return [
      ?current,
      for (final choice in homeLanguageChoices)
        if (choice.code != current?.code) choice,
    ];
  }

  @override
  void initState() {
    super.initState();
    _language = widget.languages.language ?? homeLanguageChoices.first;
    final word = widget.languages.wordFor(widget.tile.id);
    _word = TextEditingController(text: word?.label ?? '');
    _speech = TextEditingController(text: word?.speech ?? '');
  }

  @override
  void dispose() {
    _word.dispose();
    _speech.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final languages = widget.languages;
    try {
      if (languages.language != _language) {
        await languages.setLanguage(_language);
      }
      await languages.setWord(
        widget.tile.id,
        label: _word.text,
        speech: _speech.text,
      );
      navigator.pop();
    } on Object {
      ChorusHaptics.failed();
      messenger?.showSnackBar(const SnackBar(content: Text(notKeptMessage)));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    const margin = ChorusSpace.marginPhone;
    final current = widget.languages.language;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(margin, 0, margin, 16 + keyboard),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  secondLanguageTitle(widget.tile.label),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<HomeLanguage>(
                key: SecondLanguageForm.pickerKey,
                initialValue: _language,
                decoration: InputDecoration(
                  labelText: languagePickerLabel,
                  helperText: current == null
                      ? 'One second language for the whole board.'
                      : null,
                ),
                items: [
                  for (final choice in _choices)
                    DropdownMenuItem(value: choice, child: Text(choice.name)),
                ],
                onChanged: _saving
                    ? null
                    : (choice) {
                        if (choice != null) setState(() => _language = choice);
                      },
              ),
              const SizedBox(height: 8),
              TextField(
                key: SecondLanguageForm.wordKey,
                controller: _word,
                autofocus: true,
                maxLength: 80,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: languageWordLabel,
                  helperText: languageWordHelper,
                  helperMaxLines: 3,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _speech,
                maxLength: 80,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: languageSpeechLabel,
                ),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text(languageSaveLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
