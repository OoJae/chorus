/// The sheet an adult fills in to add a word, and the form it shares with
/// the edit sheet.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../contracts.dart';
import '../theme.dart';

/// Shown when the cell was filled between opening the sheet and saving.
const String spotTakenMessage =
    'That spot was just taken. Your word is waiting in Needs a home.';

/// Shown when the store refused the new word.
const String wordNotAddedMessage =
    'That word could not be added. Nothing was changed.';

/// One choice in the colour picker: a plain-words [name] for a colour [key].
class WordColour {
  const WordColour(this.name, this.key);

  final String name;

  /// The `colorKey` stored on the tile.
  final String key;
}

/// The colour picker's choices, in the order shown.
final List<WordColour> wordColours = [
  WordColour('Action', _knownKey(const ['verb', 'action'])),
  WordColour('Person', _knownKey(const ['pronoun', 'person'])),
  WordColour('Question', _knownKey(const ['question'])),
  WordColour('Describing', _knownKey(const ['descriptor', 'adjective'])),
  WordColour('Other', _knownKey(const ['determiner', 'other'])),
];

/// The first of [candidates] that [colorForKey] has a colour for; the first
/// candidate if none has, which then draws white.
String _knownKey(List<String> candidates) => candidates.firstWhere(
      colorForKey.containsKey,
      orElse: () => candidates.first,
    );

/// What an adult typed into a [WordForm].
class WordDraft {
  const WordDraft({required this.label, required this.speech, this.colorKey});

  /// Trimmed, never empty.
  final String label;

  /// Trimmed; empty means "say the word as written".
  final String speech;

  /// Null when no colour was picked.
  final String? colorKey;
}

/// Opens the sheet for a new word in the empty cell ([row], [col]) and adds
/// it to [store]. Does nothing for a read-only role.
///
/// If the cell was filled in the meantime the word goes to the tray and a
/// snackbar says so.
Future<void> showAddWordSheet(
  BuildContext context, {
  required BoardStore store,
  required String boardId,
  required int row,
  required int col,
}) async {
  if (!store.role.canEdit) return;
  // Looked up now: the caller's context may be gone once the sheet closes.
  final messenger = ScaffoldMessenger.maybeOf(context);
  final draft = await showModalBottomSheet<WordDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => WordForm(
      title: 'Add a word',
      submitLabel: 'Add to board',
      onSubmit: (draft) => Navigator.of(sheetContext).pop(draft),
    ),
  );
  if (draft == null) return;
  final bool placed;
  try {
    placed = await store.addTile(
      boardId: boardId,
      row: row,
      col: col,
      label: draft.label,
      speech: draft.speech.isEmpty ? null : draft.speech,
      colorKey: draft.colorKey,
    );
  } on Object {
    // The board was resized or removed, or the role changed, meanwhile.
    messenger?.showSnackBar(const SnackBar(content: Text(wordNotAddedMessage)));
    return;
  }
  if (!placed) {
    messenger?.showSnackBar(const SnackBar(content: Text(spotTakenMessage)));
  }
}

/// Label, optional spoken text and colour for one word.
///
/// Sized for a bottom sheet: it pads itself above the keyboard.
class WordForm extends StatefulWidget {
  const WordForm({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    this.initial,
    this.onRemove,
  });

  final String title;
  final String submitLabel;

  /// Called with a valid draft; an empty label never reaches it.
  final ValueChanged<WordDraft> onSubmit;

  /// The tile being edited; null for a new word.
  final TileFacts? initial;

  /// When set, a "Remove from board" action is shown.
  final VoidCallback? onRemove;

  @override
  State<WordForm> createState() => _WordFormState();
}

class _WordFormState extends State<WordForm> {
  late final TextEditingController _label =
      TextEditingController(text: widget.initial?.label ?? '');
  late final TextEditingController _speech =
      TextEditingController(text: widget.initial?.speech ?? '');
  late String? _colorKey = widget.initial?.colorKey;
  String? _labelError;

  @override
  void dispose() {
    _label.dispose();
    _speech.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _label.text.trim();
    if (label.isEmpty) {
      setState(() => _labelError = 'Type the word first.');
      return;
    }
    widget.onSubmit(WordDraft(
      label: label,
      speech: _speech.text.trim(),
      colorKey: _colorKey,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + keyboard),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _label,
                autofocus: widget.initial == null,
                maxLength: 30,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Word',
                  errorText: _labelError,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_labelError != null) setState(() => _labelError = null);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _speech,
                maxLength: 80,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Says something different (optional)',
                  helperText: 'Leave empty to say the word as written.',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              Text('Colour', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  for (final colour in wordColours)
                    ChoiceChip(
                      avatar: _Swatch(tileColor(colour.key)),
                      label: Text(colour.name),
                      showCheckmark: false,
                      selected: _colorKey == colour.key,
                      onSelected: (_) =>
                          setState(() => _colorKey = colour.key),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(widget.submitLabel),
              ),
              if (widget.onRemove != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: widget.onRemove,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove from board'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The colour dot on a picker chip, outlined so white still shows.
class _Swatch extends StatelessWidget {
  const _Swatch(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black54),
      ),
    );
  }
}
