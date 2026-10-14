/// Named copies of a board, from the editor's board menu: "Save a copy",
/// the list of copies, and a read-only view of one, where a word no longer
/// on the board can be put back through "Needs a home".
library;

import 'package:chorus_shared/chorus_shared.dart'
    show BoardFacts, TileFacts, gridOf, tidyText;
import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_copies.dart';
import '../contracts_media.dart';
import '../editor/tray_panel.dart' show EditorGrid;
import '../features/flags/w8.dart';

/// The board menu's items.
const String saveCopyLabel = 'Save a copy';
const String copiesLabel = 'Copies';

/// The button that puts a word back.
const String putBackLabel = 'Put back';

/// The heading over the words a copy has that the board has not.
const String notOnBoardHeading = 'No longer on the board';

/// Shown when every word of a copy is on the board or waiting.
const String allWordsHereMessage =
    'Every word in this copy is on the board or waiting in "Needs a home".';

/// Shown when the circle has no copy yet.
const String noCopiesYetMessage =
    'No copies yet. Save a copy from the board menu before a big change, '
    'such as "Before the school trip".';

/// Said after a word was put back.
String putBackMessage(String label) =>
    '"$label" is in "Needs a home". Choose its spot from there.';

/// Said after a copy was saved.
String savedCopyMessage(String name) => 'Saved a copy called "$name".';

/// Whether the board menu offers copies: the flag is on and [copies] is
/// given.
bool offersCopies(BoardCopies? copies) => boardCopiesEnabled && copies != null;

/// Asks for a name and saves a copy of [board]. Completes with the copy, or
/// null when nothing was saved.
Future<BoardCopy?> saveCopyFrom(
  BuildContext context, {
  required BoardCopies copies,
  required BoardFacts board,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _CopyNameDialog(boardName: board.name),
  );
  if (name == null) return null;
  try {
    final copy = await copies.take(board, name);
    ChorusHaptics.wordAdded();
    messenger?.showSnackBar(
      SnackBar(content: Text(savedCopyMessage(copy.name))),
    );
    return copy;
  } on CopiesFailed catch (failure) {
    ChorusHaptics.failed();
    messenger?.showSnackBar(SnackBar(content: Text(failure.message)));
  } on Object {
    ChorusHaptics.failed();
    messenger?.showSnackBar(
      const SnackBar(content: Text(copiesOfflineMessage)),
    );
  }
  return null;
}

class _CopyNameDialog extends StatefulWidget {
  const _CopyNameDialog({required this.boardName});

  final String boardName;

  @override
  State<_CopyNameDialog> createState() => _CopyNameDialogState();
}

class _CopyNameDialogState extends State<_CopyNameDialog> {
  final TextEditingController _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final error = copyNameProblem(_name.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(tidyText(_name.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Save a copy of "${widget.boardName}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The copy keeps the words as they are now. The board does not '
            'change.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: maxCopyNameLength,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Name of the copy',
              hintText: 'Before the school trip',
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save copy')),
      ],
    );
  }
}

/// Opens the list of copies.
Future<void> openCopies(
  BuildContext context, {
  required BoardCopies copies,
  required BoardStore store,
  MediaStore? media,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CopiesScreen(copies: copies, store: store, media: media),
    ),
  );
}

/// "4 Oct 2026, 18:04", for a copy's subtitle.
String copyDate(DateTime at) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final local = at.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]} ${local.year}, '
      '${two(local.hour)}:${two(local.minute)}';
}

/// The circle's copies, newest first. An editor can delete one.
class CopiesScreen extends StatefulWidget {
  const CopiesScreen({
    super.key,
    required this.copies,
    required this.store,
    this.media,
  });

  final BoardCopies copies;
  final BoardStore store;
  final MediaStore? media;

  @override
  State<CopiesScreen> createState() => _CopiesScreenState();
}

class _CopiesScreenState extends State<CopiesScreen> {
  late Future<List<BoardCopy>> _list = widget.copies.list();

  void _reload() {
    final next = widget.copies.list();
    setState(() {
      _list = next;
    });
  }

  Future<void> _delete(BoardCopy copy) async {
    final messenger = ScaffoldMessenger.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${copy.name}"?'),
        content: const Text('Only the copy goes. The board does not change.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await widget.copies.delete(copy.id);
    } on Object {
      ChorusHaptics.failed();
      messenger.showSnackBar(
        const SnackBar(content: Text(copiesOfflineMessage)),
      );
    }
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(copiesLabel)),
      body: SafeArea(
        child: FutureBuilder<List<BoardCopy>>(
          future: _list,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(ChorusSpace.marginPhone),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copiesOfflineMessage,
                      style: ChorusType.body.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _reload,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              );
            }
            final list = snapshot.data ?? const [];
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(ChorusSpace.marginPhone),
                child: Text(
                  noCopiesYetMessage,
                  style: ChorusType.body.copyWith(color: colors.ink),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final copy in list)
                  ListTile(
                    key: ValueKey('copy-${copy.id}'),
                    leading: const Icon(Icons.history_rounded),
                    title: Text(copy.name),
                    subtitle: Text(
                      '${copy.boardName} · '
                      '${copy.wordCount == 1 ? '1 word' : '${copy.wordCount} words'}'
                      ' · ${copy.takenByName}, ${copyDate(copy.takenAt)}',
                    ),
                    trailing: widget.copies.canEdit
                        ? IconButton(
                            tooltip: 'Delete "${copy.name}"',
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => _delete(copy),
                          )
                        : null,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CopyScreen(
                          copies: widget.copies,
                          copyId: copy.id,
                          store: widget.store,
                          media: widget.media,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One copy, read-only: its grid as it was, and the words the board no
/// longer has, each with "Put back" for an editor whose store can add to
/// "Needs a home". Putting back never touches a cell: the word waits in the
/// tray until an adult chooses its spot.
class CopyScreen extends StatefulWidget {
  const CopyScreen({
    super.key,
    required this.copies,
    required this.copyId,
    required this.store,
    this.media,
  });

  final BoardCopies copies;
  final String copyId;
  final BoardStore store;
  final MediaStore? media;

  @override
  State<CopyScreen> createState() => _CopyScreenState();
}

class _CopyScreenState extends State<CopyScreen> {
  late final Future<BoardCopy?> _copy = widget.copies.get(widget.copyId);
  final Set<int> _putting = {};

  TrayWordAdder? get _adder {
    final Object store = widget.store;
    return store is TrayWordAdder && widget.store.role.canEdit ? store : null;
  }

  Future<void> _putBack(BoardCopy copy, int index) async {
    final adder = _adder;
    if (adder == null || !_putting.add(index)) return;
    setState(() {});
    final messenger = ScaffoldMessenger.of(context);
    final word = copy.words[index];
    try {
      await adder.addToTray(
        boardId: copy.boardId,
        label: word.label,
        speech: word.speech,
        colorKey: word.colorKey,
        imageHash: word.imageHash,
      );
      ChorusHaptics.wordAdded();
      messenger.showSnackBar(
        SnackBar(content: Text(putBackMessage(word.label))),
      );
    } on Object {
      ChorusHaptics.failed();
      messenger.showSnackBar(
        const SnackBar(content: Text('That word could not be put back.')),
      );
    } finally {
      _putting.remove(index);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return FutureBuilder<BoardCopy?>(
      future: _copy,
      builder: (context, snapshot) {
        final copy = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: Text(copy?.name ?? copiesLabel)),
          body: SafeArea(
            child: switch (snapshot.connectionState) {
              ConnectionState.done when snapshot.hasError => Padding(
                padding: const EdgeInsets.all(ChorusSpace.marginPhone),
                child: Text(copiesOfflineMessage, style: ChorusType.body),
              ),
              ConnectionState.done when copy == null => const Padding(
                padding: EdgeInsets.all(ChorusSpace.marginPhone),
                child: Text('This copy was deleted.'),
              ),
              ConnectionState.done => ListenableBuilder(
                listenable: widget.store,
                builder: (context, _) => _body(copy!, colors),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        );
      },
    );
  }

  Widget _body(BoardCopy copy, ChorusColors colors) {
    final board = BoardFacts(
      id: copy.boardId,
      name: copy.boardName,
      rows: copy.rows,
      cols: copy.cols,
    );
    final tiles = [
      for (var i = 0; i < copy.words.length; i++)
        TileFacts(
          id: 'copy-word-$i',
          boardId: copy.boardId,
          cellKey: copy.words[i].cellKey,
          label: copy.words[i].label,
          speech: copy.words[i].speech,
          colorKey: copy.words[i].colorKey,
          imageHash: copy.words[i].imageHash,
        ),
    ];
    final gone = [
      for (var i = 0; i < copy.words.length; i++)
        if (copyWordState(
              copy.words[i],
              copy.boardId,
              widget.store.tiles,
              widget.store.boards,
            ) ==
            CopyWordState.gone)
          i,
    ];
    final adder = _adder;
    return ListView(
      padding: const EdgeInsets.all(ChorusSpace.marginPhone),
      children: [
        Text(
          'A copy of "${copy.boardName}", saved by ${copy.takenByName} on '
          '${copyDate(copy.takenAt)}. It cannot be changed.',
          style: ChorusType.body.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: EditorGrid(
              board: board,
              cells: gridOf(copy.boardId, tiles, [board]),
              media: widget.media,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            notOnBoardHeading,
            style: ChorusType.headline.copyWith(color: colors.ink),
          ),
        ),
        const SizedBox(height: 8),
        if (gone.isEmpty)
          Text(
            allWordsHereMessage,
            style: ChorusType.body.copyWith(color: colors.ink),
          ),
        for (final index in gone)
          ListTile(
            key: ValueKey('gone-$index'),
            contentPadding: EdgeInsets.zero,
            title: Text(copy.words[index].label),
            subtitle: copy.words[index].speech == null
                ? null
                : Text('Says "${copy.words[index].speech}"'),
            trailing: adder == null
                ? null
                : FilledButton(
                    onPressed: _putting.contains(index)
                        ? null
                        : () => _putBack(copy, index),
                    child: const Text(putBackLabel),
                  ),
          ),
      ],
    );
  }
}
