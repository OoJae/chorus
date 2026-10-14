/// Adding, renaming, archiving and importing boards, from the editor.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_boards.dart';
import '../contracts_copies.dart' show BoardCopies;
import '../copies/copies_screens.dart';
import 'obf_picker.dart';
import 'tray_panel.dart' show notSavedMessage;

/// The menu item that imports a board from a file.
const String importBoardLabel = 'Import a board (.obf)';

/// The menu items that act on the board on show, for a keyboard or a screen
/// reader as well as the long press on its tab.
const String renameBoardLabel = 'Rename this board';
const String archiveBoardLabel = 'Archive this board';

/// Shown for a picked file larger than [maxObfFileBytes].
const String fileTooLargeMessage = 'This file is too large to be a board.';

/// What is wrong with [name] for a board, counting a name another board in
/// use already has; null when it can be used. [exceptId] is the board being
/// renamed, which may keep its own name.
String? boardNameError(
  String name,
  Iterable<BoardFacts> boards, {
  String? exceptId,
}) {
  final problem = boardNameProblem(name);
  if (problem != null) return problem;
  final others = boards.where((board) => board.id != exceptId);
  if (boardNameTaken(name, others)) {
    return 'Another board is already called "${tidyBoardName(name)}".';
  }
  return null;
}

/// Asks for a board name, starting from [initial]. Completes with the name
/// as typed, or null when the adult cancelled.
Future<String?> askBoardName(
  BuildContext context, {
  required String title,
  required String submitLabel,
  required String initial,
  required Iterable<BoardFacts> boards,
  String? exceptId,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _BoardNameDialog(
      title: title,
      submitLabel: submitLabel,
      initial: initial,
      boards: boards.toList(),
      exceptId: exceptId,
    ),
  );
}

class _BoardNameDialog extends StatefulWidget {
  const _BoardNameDialog({
    required this.title,
    required this.submitLabel,
    required this.initial,
    required this.boards,
    this.exceptId,
  });

  final String title;
  final String submitLabel;
  final String initial;
  final List<BoardFacts> boards;
  final String? exceptId;

  @override
  State<_BoardNameDialog> createState() => _BoardNameDialogState();
}

class _BoardNameDialogState extends State<_BoardNameDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initial.length,
        );
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final error = boardNameError(
      _name.text,
      widget.boards,
      exceptId: widget.exceptId,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(tidyBoardName(_name.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _name,
        autofocus: true,
        maxLength: maxBoardNameLength,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(labelText: 'Board name', errorText: _error),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
      ],
    );
  }
}

/// Asks for a name and adds an empty board with it. Completes with the new
/// board's id, or null when nothing was added.
Future<String?> addBoardFrom(
  BuildContext context, {
  required BoardStore store,
  required BoardManager manager,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final name = await askBoardName(
    context,
    title: 'Add a board',
    submitLabel: 'Add board',
    initial: defaultBoardName(store.boards),
    boards: store.boards,
  );
  if (name == null) return null;
  try {
    return await manager.addBoard(name);
  } on Object {
    ChorusHaptics.failed();
    messenger?.showSnackBar(const SnackBar(content: Text(notSavedMessage)));
    return null;
  }
}

/// Asks for a new name for [board] and renames it.
Future<void> renameBoardFrom(
  BuildContext context, {
  required BoardStore store,
  required BoardManager manager,
  required BoardFacts board,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final name = await askBoardName(
    context,
    title: 'Rename "${board.name}"',
    submitLabel: 'Save',
    initial: board.name,
    boards: store.boards,
    exceptId: board.id,
  );
  if (name == null || name == board.name) return;
  try {
    await manager.renameBoard(board.id, name);
  } on Object {
    ChorusHaptics.failed();
    messenger?.showSnackBar(const SnackBar(content: Text(notSavedMessage)));
  }
}

/// Asks before [board] is archived, then archives it. The home board and
/// the last board are refused in plain words, without asking.
Future<bool> archiveBoardFrom(
  BuildContext context, {
  required BoardStore store,
  required BoardManager manager,
  required BoardFacts board,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final problem = archiveProblem(board, store.boards);
  if (problem != null) {
    messenger?.showSnackBar(SnackBar(content: Text(problem)));
    return false;
  }
  final words = gridOf(board.id, store.tiles, store.boards).length;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Archive "${board.name}"?'),
      content: Text(
        words == 0
            ? '${store.childName} will no longer see this board. Nothing is '
                  'deleted.'
            : '${store.childName} will no longer see this board or its '
                  '${words == 1 ? 'word' : '$words words'}. Nothing is '
                  'deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Archive'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  try {
    await manager.archiveBoard(board.id);
    return true;
  } on Object {
    ChorusHaptics.failed();
    // Refused meanwhile (another device archived the other boards), or not
    // written at all.
    final now = store.boards.where((b) => b.id == board.id).firstOrNull;
    final reason = now == null ? null : archiveProblem(now, store.boards);
    messenger?.showSnackBar(SnackBar(content: Text(reason ?? notSavedMessage)));
    return false;
  }
}

/// What can be done to [board] from its tab: rename it, and archive it
/// unless [archiveProblem] says no, in which case the reason is shown in
/// place of the action. With [copies], also "Save a copy" and "Copies".
Future<void> showBoardActions(
  BuildContext context, {
  required BoardStore store,
  required BoardManager manager,
  required BoardFacts board,
  BoardCopies? copies,
}) async {
  final offered = offersCopies(copies) ? copies : null;
  final colors = ChorusColors.of(context);
  final problem = archiveProblem(board, store.boards);
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Semantics(
                header: true,
                child: Text(
                  board.name,
                  style: ChorusType.headline.copyWith(color: colors.ink),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text(renameBoardLabel),
              onTap: () => Navigator.of(sheetContext).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_rounded),
              title: const Text(archiveBoardLabel),
              subtitle: Text(
                problem ??
                    'It leaves the tabs with its words. Nothing is '
                        'deleted.',
              ),
              enabled: problem == null,
              onTap: () => Navigator.of(sheetContext).pop('archive'),
            ),
            if (offered != null) ...[
              if (offered.canEdit)
                ListTile(
                  leading: const Icon(Icons.bookmark_add_rounded),
                  title: const Text(saveCopyLabel),
                  subtitle: const Text(
                    'Keeps the words as they are now, under a name.',
                  ),
                  onTap: () => Navigator.of(sheetContext).pop('save-copy'),
                ),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text(copiesLabel),
                onTap: () => Navigator.of(sheetContext).pop('copies'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  if (!context.mounted) return;
  switch (choice) {
    case 'rename':
      await renameBoardFrom(
        context,
        store: store,
        manager: manager,
        board: board,
      );
    case 'archive':
      await archiveBoardFrom(
        context,
        store: store,
        manager: manager,
        board: board,
      );
    case 'save-copy' when offered != null:
      await saveCopyFrom(context, copies: offered, board: board);
    case 'copies' when offered != null:
      await openCopies(context, copies: offered, store: store);
  }
}

/// Picks an .obf file, reads it and adds it as a new board, then says which
/// words did not fit. Completes with the new board's id, or null when
/// nothing was imported.
Future<String?> importBoardFrom(
  BuildContext context, {
  required BoardStore store,
  required BoardManager manager,
  required ObfFilePicker pick,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  PickedFile? file;
  String? problem;
  try {
    file = await pick();
  } on PickedFileTooLarge {
    problem = fileTooLargeMessage;
  } on Object {
    problem = const ObfNotJson().message;
  }
  if (!context.mounted) return null;
  if (problem == null && file == null) return null;
  ObfBoard? parsed;
  if (problem == null) {
    try {
      parsed = parseObf(file!.text);
    } on ObfError catch (error) {
      problem = error.message;
    }
  }
  if (parsed == null) {
    ChorusHaptics.failed();
    await _tell(
      context,
      title: 'This board could not be imported',
      body: [Text(problem ?? const ObfNotJson().message)],
    );
    return null;
  }
  final BoardImport result;
  try {
    result = await manager.importBoard(parsed);
  } on Object {
    ChorusHaptics.failed();
    messenger?.showSnackBar(const SnackBar(content: Text(notSavedMessage)));
    return null;
  }
  if (!context.mounted) return result.boardId;
  final board = store.boards.where((b) => b.id == result.boardId).firstOrNull;
  final placed = gridOf(result.boardId, store.tiles, store.boards).length;
  final leftOut = result.leftOut;
  await _tell(
    context,
    title: 'Imported "${board?.name ?? parsed.name}"',
    body: [
      Text(
        placed == 1
            ? '1 word is on the new board.'
            : '$placed words are on the new board.',
      ),
      if (leftOut.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          leftOut.length == 1
              ? 'This word did not fit on a $starterRows by $starterCols '
                    'board, so it was left out:'
              : 'These ${leftOut.length} words did not fit on a '
                    '$starterRows by $starterCols board, so they were left '
                    'out:',
        ),
        const SizedBox(height: 8),
        for (final word in leftOut)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${word.label} (row ${word.row + 1}, column ${word.col + 1})',
              key: ValueKey('left-out-${word.row}-${word.col}'),
            ),
          ),
      ],
    ],
  );
  return result.boardId;
}

/// A dialog with [title], a scrolling [body] and "Done".
Future<void> _tell(
  BuildContext context, {
  required String title,
  required List<Widget> body,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: body,
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}
