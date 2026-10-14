/// "Suggest a word": read-only members suggest, and editors see the
/// suggestions at the top of "Needs a home", where they add each to the
/// board (choosing its spot) or say no thanks. No suggestion ever reaches
/// the board without an editor.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_activity.dart';
import '../contracts_media.dart';
import '../features/flags/w2.dart' as w2;
import 'tray_panel.dart' show EditorGrid, notSavedMessage;

/// The action a read-only member taps.
const String suggestWordLabel = 'Suggest a word';

/// One line under it.
const String suggestWordDetail = 'An editor adds it to the board';

/// The suggest dialog's explanation.
const String suggestWordIntro =
    'Type a word you would like on the board. Someone who edits the board '
    'chooses where it goes.';

/// Shown once a suggestion is sent.
const String suggestionSentMessage =
    'Sent. It waits for an editor under "Needs a home".';

/// Shown when a suggestion could not be sent.
const String suggestionNotSentMessage =
    'That could not be sent. Check the connection and try again.';

/// The heading over the suggestions in the tray.
String suggestionsTitle(int count) => 'Suggested words · $count';

/// Adds a suggestion to the board.
const String addToBoardLabel = 'Add to the board';

/// Declines a suggestion.
const String noThanksLabel = 'No thanks';

/// Who suggested it.
String suggestedByText(WordSuggestionItem item) => item.fromPhoto
    ? 'Suggested from a photo by ${item.byName}'
    : 'Suggested by ${item.byName}';

/// Shown when the board has no empty spot for a suggestion.
const String boardFullMessage =
    'The board is full. Remove a word to make room.';

/// Gives the screens under it the circle's suggested words. Put above the
/// editor so its "Needs a home" can show them.
class WordSuggestionsScope extends InheritedWidget {
  const WordSuggestionsScope({
    super.key,
    required this.suggestions,
    required super.child,
  });

  final WordSuggestions suggestions;

  static WordSuggestions? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<WordSuggestionsScope>()
      ?.suggestions;

  @override
  bool updateShouldNotify(WordSuggestionsScope oldWidget) =>
      oldWidget.suggestions != suggestions;
}

/// Asks a read-only member for a word and sends it.
Future<void> showSuggestWordDialog(
  BuildContext context,
  WordSuggestions suggestions,
) async {
  if (!w2.suggestWordEnabled) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final label = await showDialog<String>(
    context: context,
    builder: (_) => const _SuggestDialog(),
  );
  if (label == null || label.trim().isEmpty) return;
  try {
    await suggestions.suggest(label.trim());
    messenger?.showSnackBar(
      const SnackBar(content: Text(suggestionSentMessage)),
    );
  } on Object {
    ChorusHaptics.failed();
    messenger?.showSnackBar(
      const SnackBar(content: Text(suggestionNotSentMessage)),
    );
  }
}

class _SuggestDialog extends StatefulWidget {
  const _SuggestDialog();

  @override
  State<_SuggestDialog> createState() => _SuggestDialogState();
}

class _SuggestDialogState extends State<_SuggestDialog> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() => Navigator.of(context).pop(_text.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(suggestWordLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(suggestWordIntro),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            autofocus: true,
            maxLength: 40,
            textInputAction: TextInputAction.send,
            decoration: const InputDecoration(labelText: 'Word'),
            onSubmitted: (_) => _send(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _send, child: const Text('Send')),
      ],
    );
  }
}

/// The suggestions at the top of "Needs a home", for an editor. Shows
/// nothing while there are none, and nothing at all when they cannot be
/// read (no network): the tray works as before.
class SuggestionsTray extends StatefulWidget {
  const SuggestionsTray({
    super.key,
    required this.suggestions,
    required this.store,
    required this.boardId,
    this.media,
    this.onCount,
  });

  final WordSuggestions suggestions;
  final BoardStore store;
  final String boardId;
  final MediaStore? media;

  /// Told how many suggestions are shown, each time that changes.
  final ValueChanged<int>? onCount;

  @override
  State<SuggestionsTray> createState() => _SuggestionsTrayState();
}

class _SuggestionsTrayState extends State<SuggestionsTray> {
  List<WordSuggestionItem> _items = const [];
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final items = await widget.suggestions.open();
      if (!mounted) return;
      setState(() => _items = items);
      widget.onCount?.call(items.length);
    } on Object {
      // Offline: no suggestions shown, nothing alarming.
    }
  }

  Future<void> _answer(WordSuggestionItem item, {required bool add}) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final store = widget.store;
    if (add) {
      final board = store.boards
          .where((b) => b.id == widget.boardId && !b.archived)
          .firstOrNull;
      if (board == null) return;
      final free = emptyCells(board, store.tiles, store.boards);
      if (free.isEmpty) {
        messenger?.showSnackBar(
          const SnackBar(content: Text(boardFullMessage)),
        );
        return;
      }
      final cell = await showDialog<(int, int)>(
        context: context,
        builder: (dialogContext) => _SpotPicker(
          store: store,
          board: board,
          label: item.label,
          media: widget.media,
        ),
      );
      if (cell == null || !mounted) return;
      setState(() => _busy.add(item.id));
      try {
        final placed = await store.addTile(
          boardId: board.id,
          row: cell.$1,
          col: cell.$2,
          label: item.label,
          speech: item.speech,
          colorKey: item.colorKey,
        );
        ChorusHaptics.wordPlaced();
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              placed
                  ? '"${item.label}" is on the board.'
                  : 'That spot was just taken, so "${item.label}" waits '
                        'under "Needs a home".',
            ),
          ),
        );
      } on Object {
        ChorusHaptics.failed();
        messenger?.showSnackBar(const SnackBar(content: Text(notSavedMessage)));
        if (mounted) setState(() => _busy.remove(item.id));
        return;
      }
    } else {
      setState(() => _busy.add(item.id));
    }
    try {
      await widget.suggestions.resolve(item, added: add);
    } on Object {
      // The word is on the board either way; the answer is sent again the
      // next time the list is read and answered.
    }
    if (!mounted) return;
    setState(() {
      _busy.remove(item.id);
      _items = [
        for (final i in _items)
          if (i.id != item.id) i,
      ];
    });
    widget.onCount?.call(_items.length);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final colors = ChorusColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              suggestionsTitle(_items.length),
              style: ChorusType.status.copyWith(color: colors.ink),
            ),
          ),
        ),
        for (final item in _items)
          Padding(
            key: ValueKey('suggestion-${item.id}'),
            padding: const EdgeInsets.only(top: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
                border: Border.all(color: colors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.label,
                      style: ChorusType.headline.copyWith(color: colors.ink),
                    ),
                    Text(
                      suggestedByText(item),
                      style: ChorusType.body.copyWith(color: colors.inkMuted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: ChorusSpace.targetGap,
                      runSpacing: ChorusSpace.targetGap,
                      children: [
                        FilledButton(
                          onPressed: _busy.contains(item.id)
                              ? null
                              : () => _answer(item, add: true),
                          child: const Text(addToBoardLabel),
                        ),
                        TextButton(
                          onPressed: _busy.contains(item.id)
                              ? null
                              : () => _answer(item, add: false),
                          child: const Text(noThanksLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// The board with its empty spots tappable; pops with the chosen cell.
class _SpotPicker extends StatelessWidget {
  const _SpotPicker({
    required this.store,
    required this.board,
    required this.label,
    this.media,
  });

  final BoardStore store;
  final BoardFacts board;
  final String label;
  final MediaStore? media;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Where should "$label" go?',
                  style: ChorusType.headline.copyWith(color: colors.ink),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Tap an empty spot. Words already placed stay put.',
                  style: ChorusType.body.copyWith(color: colors.inkMuted),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Align(
                  heightFactor: 1,
                  child: ListenableBuilder(
                    listenable: store,
                    builder: (context, _) => EditorGrid(
                      board: board,
                      cells: gridOf(board.id, store.tiles, store.boards),
                      media: media,
                      dimTiles: true,
                      emptyHint: 'Put the word here',
                      onEmpty: (row, col) =>
                          Navigator.of(context).pop((row, col)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
