/// "Quick phrases": where adults add, rename, remove and reorder the whole
/// sentences the child's board says at once.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart'
    show
        cleanQuickPhrases,
        defaultQuickPhrases,
        maxQuickPhraseLength,
        maxQuickPhrases;
import 'package:flutter/material.dart';

import '../brand/tokens.dart';
import '../contracts_quick_phrases.dart';

/// The page's title, and the label of its entry on home.
const String quickPhrasesTitle = 'Quick phrases';

/// Says what the page is for.
const String quickPhrasesIntro =
    'Whole sentences the board says with one tap. They open from the '
    'megaphone key beside the sentence.';

/// Adds a phrase.
const String addPhraseLabel = 'Add a phrase';

/// Renames a phrase.
const String renamePhraseLabel = 'Change';

/// Removes a phrase.
const String removePhraseLabel = 'Remove';

/// Moves a phrase one place up.
const String movePhraseUpLabel = 'Move up';

/// Saves the list for the whole circle.
const String savePhrasesLabel = 'Save for everyone';

/// Puts the six starting phrases back.
const String resetPhrasesLabel = 'Use the starting phrases';

/// Said once the list is saved.
const String phrasesSavedMessage =
    'Saved. Every board in the circle gets '
    'these.';

/// Said when the list could not be saved.
const String phrasesNotSavedMessage =
    'These could not be saved. Saving needs a connection: try again when '
    'this device is online.';

/// Said to a read-only partner.
const String phrasesReadOnlyMessage =
    'You can see these phrases. The other adults in the circle can change '
    'them.';

/// Said when the list is full.
const String phrasesFullMessage =
    'That is the most a board can have. Remove one to add another.';

/// The field's label in the add and change dialogs.
const String phraseFieldLabel = 'Phrase';

class QuickPhrasesScreen extends StatefulWidget {
  const QuickPhrasesScreen({super.key, required this.book});

  final QuickPhraseBook book;

  @override
  State<QuickPhrasesScreen> createState() => _QuickPhrasesScreenState();
}

class _QuickPhrasesScreenState extends State<QuickPhrasesScreen> {
  late List<String> _draft = List.of(widget.book.phrases);
  bool _changed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.book.addListener(_onBook);
    unawaited(widget.book.refresh().catchError((Object _) {}));
  }

  @override
  void dispose() {
    widget.book.removeListener(_onBook);
    super.dispose();
  }

  /// The circle's list changed: shown at once unless the adult is editing.
  void _onBook() {
    if (!mounted) return;
    setState(() {
      if (!_changed) _draft = List.of(widget.book.phrases);
    });
  }

  void _edit(void Function(List<String> draft) change) {
    setState(() {
      change(_draft);
      _changed = true;
    });
  }

  Future<String?> _ask({String initial = '', required String title}) =>
      showDialog<String>(
        context: context,
        builder: (_) => _PhraseDialog(title: title, initial: initial),
      );

  Future<void> _add() async {
    if (_draft.length >= maxQuickPhrases) {
      _say(phrasesFullMessage);
      return;
    }
    final text = (await _ask(title: addPhraseLabel))?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    _edit((draft) => draft.add(text));
  }

  Future<void> _rename(int index) async {
    final text = (await _ask(
      title: renamePhraseLabel,
      initial: _draft[index],
    ))?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    _edit((draft) => draft[index] = text);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.book.save(cleanQuickPhrases(_draft));
      if (!mounted) return;
      setState(() {
        _changed = false;
        _draft = List.of(widget.book.phrases);
      });
      _say(phrasesSavedMessage);
    } catch (_) {
      if (mounted) _say(phrasesNotSavedMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _say(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final canEdit = widget.book.canEdit;
    final margin = ChorusSpace.marginOf(context);
    return Scaffold(
      backgroundColor: colors.card,
      appBar: AppBar(title: const Text(quickPhrasesTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(margin, 12, margin, 8),
                  child: Text(
                    canEdit ? quickPhrasesIntro : phrasesReadOnlyMessage,
                    style: ChorusType.body.copyWith(color: colors.inkMuted),
                  ),
                ),
                Expanded(
                  child: canEdit
                      ? ReorderableListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: margin),
                          itemCount: _draft.length,
                          onReorderItem: (from, to) => _edit((draft) {
                            draft.insert(to, draft.removeAt(from));
                          }),
                          itemBuilder: (context, i) => _PhraseRow(
                            key: ValueKey('phrase-$i-${_draft[i]}'),
                            text: _draft[i],
                            onRename: () => _rename(i),
                            onRemove: _draft.length > 1
                                ? () => _edit((draft) => draft.removeAt(i))
                                : null,
                            onMoveUp: i > 0
                                ? () => _edit((draft) {
                                    draft.insert(i - 1, draft.removeAt(i));
                                  })
                                : null,
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.symmetric(horizontal: margin),
                          children: [
                            for (final phrase in _draft)
                              ListTile(title: Text(phrase)),
                          ],
                        ),
                ),
                if (canEdit)
                  Padding(
                    padding: EdgeInsets.fromLTRB(margin, 8, margin, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _add,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(addPhraseLabel),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => _edit((draft) {
                                  draft
                                    ..clear()
                                    ..addAll(defaultQuickPhrases);
                                }),
                          child: const Text(resetPhrasesLabel),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _saving || !_changed ? null : _save,
                          child: const Text(savePhrasesLabel),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhraseRow extends StatelessWidget {
  const _PhraseRow({
    super.key,
    required this.text,
    required this.onRename,
    required this.onRemove,
    required this.onMoveUp,
  });

  final String text;
  final VoidCallback onRename;
  final VoidCallback? onRemove;
  final VoidCallback? onMoveUp;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 4, right: 40),
      title: Text(text),
      onTap: onRename,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: movePhraseUpLabel,
            onPressed: onMoveUp,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
          IconButton(
            tooltip: renamePhraseLabel,
            onPressed: onRename,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: removePhraseLabel,
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

/// Asks for one phrase. Owns its field, so the field outlives the dialog's
/// closing animation.
class _PhraseDialog extends StatefulWidget {
  const _PhraseDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_PhraseDialog> createState() => _PhraseDialogState();
}

class _PhraseDialogState extends State<_PhraseDialog> {
  late final TextEditingController _field = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _field,
        autofocus: true,
        maxLength: maxQuickPhraseLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: phraseFieldLabel),
        onSubmitted: (text) => Navigator.of(context).pop(text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_field.text),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
