/// Where adults change the board.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../contracts.dart';
import '../contracts_live.dart';
import '../contracts_media.dart';
import '../contracts_suggest.dart';
import '../widgets/sync_chip.dart';
import 'add_word_sheet.dart';
import 'model_mode_bar.dart';
import 'replaced_changes_panel.dart';
import 'tray_panel.dart';

/// Shown to a read-only partner in place of the editing hint.
const String readOnlyMessage =
    'You can view this board. Only the family and therapist can change it.';

/// Popped by the edit sheet when the adult chose "Remove from board".
const Object _removeRequested = Object();

/// The home board in the same positions the child sees, with the ways to
/// add, change and remove a word, and the "Needs a home" tray.
///
/// There is deliberately no way to move a placed word to another cell: a
/// button the child already uses never changes place.
///
/// Everything beyond [store] and [sync] is optional: with [media] and
/// [capture] a word can carry a photo and a recording, with [live] an adult
/// can point at words on the other devices, with [suggester] a picked photo
/// can be sent for a suggested word, and a store that keeps an edit log
/// gets the "Replaced changes" panel.
class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.store,
    required this.sync,
    this.media,
    this.capture,
    this.speaker,
    this.live,
    this.suggester,
  });

  final BoardStore store;
  final SyncStatus sync;

  /// The circle's pictures and clips; null draws and edits words only.
  final MediaStore? media;

  /// Camera, photo library and microphone; null for a read-only partner.
  final MediaCapture? capture;

  /// Plays a tile's recording back in the edit sheet.
  final TileSpeaker? speaker;

  /// The circle's live session; null hides model mode.
  final LiveSession? live;

  /// Suggests a word for a picked photo; null hides the offer.
  final WordSuggester? suggester;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  BoardStore get _store => widget.store;

  /// While on, a tap on a word points at it instead of opening it.
  bool _modelling = false;

  /// The home board, or failing that the first board still in use.
  BoardFacts? _currentBoard() {
    final live = _store.boards.where((board) => !board.archived);
    return live.where((board) => board.isHome).firstOrNull ?? live.firstOrNull;
  }

  Future<void> _editTile(TileFacts tile) async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => WordForm(
        title: 'Change this word',
        submitLabel: 'Save',
        initial: tile,
        media: (_store as Object) is TileMediaWriter ? widget.media : null,
        capture: widget.capture,
        speaker: widget.speaker,
        suggester: widget.suggester,
        onSubmit: (draft) => Navigator.of(sheetContext).pop(draft),
        onRemove: () => Navigator.of(sheetContext).pop(_removeRequested),
      ),
    );
    if (result == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    // A merge may have removed the word while the sheet was open.
    final current = _store.tiles
        .where((t) => t.id == tile.id && !t.archived)
        .firstOrNull;
    if (current == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('That word was removed on another device.'),
      ));
      return;
    }
    if (identical(result, _removeRequested)) {
      final confirmed = await confirmRemoveWord(context,
          tile: current, childName: _store.childName);
      if (!confirmed) return;
      try {
        await _store.archiveTile(current.id);
      } on Object {
        messenger.showSnackBar(const SnackBar(content: Text(notSavedMessage)));
      }
    } else if (result is WordDraft) {
      try {
        await _save(current, result);
      } on Object {
        messenger.showSnackBar(const SnackBar(content: Text(notSavedMessage)));
      }
    }
  }

  /// Writes only the properties the adult changed, so an edit made elsewhere
  /// to a different property survives the merge.
  Future<void> _save(TileFacts tile, WordDraft draft) async {
    // Media first: the early return below would skip it.
    await saveDraftMedia(_store, tile, draft);
    final label = draft.label == tile.label ? null : draft.label;
    final speech = draft.speech == (tile.speech ?? '') ? null : draft.speech;
    final colorKey = draft.colorKey == tile.colorKey ? null : draft.colorKey;
    if (label == null && speech == null && colorKey == null) return;
    await _store.updateTile(tile.id,
        label: label, speech: speech, colorKey: colorKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${_store.childName}'s board")),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final board = _currentBoard();
            if (board == null) {
              return const Center(child: Text('There is no board yet.'));
            }
            final canEdit = _store.role.canEdit;
            final header = _Header(
              sync: widget.sync,
              canEdit: canEdit,
              childName: _store.childName,
            );
            final live = widget.live;
            final modelling = live != null && _modelling;
            final grid = EditorGrid(
              board: board,
              cells: gridOf(board.id, _store.tiles, _store.boards),
              media: widget.media,
              // Model mode points at words and changes nothing, so a
              // read-only partner may use it too.
              onTile: modelling
                  ? (tile) => live.sendPulse(tile.id)
                  : (canEdit ? _editTile : null),
              onEmpty: canEdit && !modelling
                  ? (row, col) => showAddWordSheet(
                        context,
                        store: _store,
                        boardId: board.id,
                        row: row,
                        col: col,
                        media: widget.media,
                        capture: widget.capture,
                        suggester: widget.suggester,
                      )
                  : null,
            );
            final modelBar = live == null
                ? null
                : ModelModeBar(
                    live: live,
                    enabled: _modelling,
                    onChanged: (value) => setState(() => _modelling = value),
                    labelFor: (id) => _store.tiles
                        .where((tile) => tile.id == id)
                        .firstOrNull
                        ?.label,
                  );
            final tray = TrayPanel(store: _store, boardId: board.id);
            // Draws nothing for a store with no edit log or no overwrites.
            final replaced = ReplacedChangesPanel(store: _store);
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 900) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      header,
                      if (modelBar != null) ...[
                        const SizedBox(height: 12),
                        modelBar,
                      ],
                      const SizedBox(height: 12),
                      grid,
                      const SizedBox(height: 24),
                      tray,
                      const SizedBox(height: 24),
                      replaced,
                    ],
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            header,
                            if (modelBar != null) ...[
                              const SizedBox(height: 12),
                              modelBar,
                            ],
                            const SizedBox(height: 12),
                            // Align loosens the constraints so the grid keeps
                            // its shape when the window is short.
                            Expanded(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: grid,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 360,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              tray,
                              const SizedBox(height: 24),
                              replaced,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Sync chip, then either the editing hint or the read-only banner.
class _Header extends StatelessWidget {
  const _Header({
    required this.sync,
    required this.canEdit,
    required this.childName,
  });

  final SyncStatus sync;
  final bool canEdit;
  final String childName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SyncChip(sync: sync),
        ),
        const SizedBox(height: 12),
        if (canEdit)
          Text(
            'Tap an empty spot to add a word. Tap a word to change or remove '
            'it. Words never move, so $childName always finds them in the '
            'same place.',
          )
        else
          Semantics(
            container: true,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined,
                      color: scheme.onSecondaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      readOnlyMessage,
                      style: TextStyle(color: scheme.onSecondaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
