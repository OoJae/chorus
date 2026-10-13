/// The "Needs a home" tray, and the grid the editor and the tray's cell
/// picker both draw.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../contracts.dart';
import '../widgets/tile_view.dart';

/// One board drawn as a fixed grid: every tile in its own cell, every free
/// cell as a tappable gap. Offers no way to move a tile.
class EditorGrid extends StatelessWidget {
  const EditorGrid({
    super.key,
    required this.board,
    required this.cells,
    this.onTile,
    this.onEmpty,
    this.emptyHint = 'Add a word here',
    this.dimTiles = false,
  });

  final BoardFacts board;

  /// The board's occupied cells, as `gridOf` returns them.
  final Map<(int, int), TileFacts> cells;

  /// Null makes tiles inert.
  final ValueChanged<TileFacts>? onTile;

  /// Null makes empty cells inert.
  final void Function(int row, int col)? onEmpty;

  /// What a screen reader says tapping an empty cell does.
  final String emptyHint;

  /// Fades the tiles so the empty cells stand out.
  final bool dimTiles;

  @override
  Widget build(BuildContext context) {
    if (board.rows <= 0 || board.cols <= 0) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: board.cols / board.rows,
      child: Column(
        children: [
          for (var row = 0; row < board.rows; row++)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var col = 0; col < board.cols; col++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: _cell(row, col),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(int row, int col) {
    final tile = cells[(row, col)];
    if (tile == null) {
      final onEmpty = this.onEmpty;
      return _EmptyCell(
        row: row,
        col: col,
        hint: emptyHint,
        onTap: onEmpty == null ? null : () => onEmpty(row, col),
      );
    }
    final onTile = this.onTile;
    return TileView(
      key: ValueKey(tile.id),
      tile: tile,
      dimmed: dimTiles,
      onTap: onTile == null ? null : () => onTile(tile),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell({
    required this.row,
    required this.col,
    required this.hint,
    this.onTap,
  });

  final int row;
  final int col;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final where = 'Empty spot, row ${row + 1}, column ${col + 1}';
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: onTap == null ? where : '$where. $hint',
      onTap: onTap,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Material(
          color: scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: scheme.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: onTap == null
                  ? null
                  : Icon(Icons.add, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks before a word is removed. Completes with true only on "Remove".
Future<bool> confirmRemoveWord(
  BuildContext context, {
  required TileFacts tile,
  required String childName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Remove "${tile.label}"?'),
      content: Text(
        '$childName will no longer see this word. '
        'Every other word stays where it is.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Shown when placing a word failed because it changed underneath the adult.
const String wordChangedMessage =
    'That word changed on another device. Nothing was moved.';

/// Shown when any other write to the store failed.
const String notSavedMessage =
    'That could not be saved. Nothing was changed.';

/// Why [entry] is waiting, in words for a parent. [cells] is the grid of the
/// entry's board, used to name whose word holds the cell it wanted.
String trayReasonText(TrayEntry entry, Map<(int, int), TileFacts> cells) {
  final wanted = entry.wanted;
  final holder = wanted == null ? null : cells[(wanted.row, wanted.col)];
  final whose = (holder == null || holder.createdByName.isEmpty)
      ? "someone else's word"
      : "${holder.createdByName}'s word";
  return switch (entry.reason) {
    TrayReason.contested => 'Added while offline; $whose got this spot first',
    TrayReason.unplaced => 'Its spot was already taken when it was added',
    TrayReason.offGrid => 'Its spot is no longer on this board',
    TrayReason.duplicateCell => 'Shares a spot with $whose, which was there first',
  };
}

/// Lists the words of one board that need an adult to give them a home, with
/// the ways to place them. Rebuilds whenever [store] changes.
class TrayPanel extends StatelessWidget {
  const TrayPanel({super.key, required this.store, required this.boardId});

  final BoardStore store;
  final String boardId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final theme = Theme.of(context);
        final tiles = store.tiles;
        final boards = store.boards;
        final entries = [
          for (final entry in trayOf(tiles, boards))
            if (entry.tile.boardId == boardId) entry,
        ];
        final board = boards
            .where((b) => b.id == boardId && !b.archived)
            .firstOrNull;
        final cells = gridOf(boardId, tiles, boards);
        final free = board == null
            ? const <(int, int)>[]
            : emptyCells(board, tiles, boards);
        final canEdit = store.role.canEdit;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                entries.isEmpty
                    ? 'Needs a home'
                    : 'Needs a home (${entries.length})',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 4),
            if (entries.isEmpty)
              const Text('No words are waiting.')
            else if (free.isEmpty)
              const Text('The board is full. Remove a word to make room.'),
            for (final entry in entries)
              _TrayCard(
                key: ValueKey(entry.tile.id),
                entry: entry,
                reason: trayReasonText(entry, cells),
                onPlaceNext: canEdit && free.isNotEmpty
                    ? () => _place(context, entry.tile, free.first)
                    : null,
                onChoose: canEdit && free.isNotEmpty && board != null
                    ? () => _choose(context, board, entry.tile)
                    : null,
                onRemove: canEdit ? () => _remove(context, entry.tile) : null,
              ),
          ],
        );
      },
    );
  }

  Future<void> _place(
      BuildContext context, TileFacts tile, (int, int) cell) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final bool placed;
    try {
      placed = await store.placeTile(tile.id, row: cell.$1, col: cell.$2);
    } on Object {
      // A merge placed or removed the word, or the role changed, meanwhile.
      messenger?.showSnackBar(const SnackBar(content: Text(wordChangedMessage)));
      return;
    }
    messenger?.showSnackBar(SnackBar(
      content: Text(placed
          ? '"${tile.label}" is on the board.'
          : 'That spot was just taken. Choose another spot.'),
    ));
  }

  Future<void> _choose(
      BuildContext context, BoardFacts board, TileFacts tile) async {
    final cell = await showDialog<(int, int)>(
      context: context,
      builder: (dialogContext) => _CellPicker(
        store: store,
        board: board,
        tile: tile,
      ),
    );
    if (cell == null || !context.mounted) return;
    await _place(context, tile, cell);
  }

  Future<void> _remove(BuildContext context, TileFacts tile) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final confirmed = await confirmRemoveWord(context,
        tile: tile, childName: store.childName);
    if (!confirmed) return;
    try {
      await store.archiveTile(tile.id);
    } on Object {
      messenger?.showSnackBar(const SnackBar(content: Text(notSavedMessage)));
    }
  }
}

class _TrayCard extends StatelessWidget {
  const _TrayCard({
    super.key,
    required this.entry,
    required this.reason,
    this.onPlaceNext,
    this.onChoose,
    this.onRemove,
  });

  final TrayEntry entry;
  final String reason;
  final VoidCallback? onPlaceNext;
  final VoidCallback? onChoose;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = entry.tile;
    final by = tile.createdByName.isEmpty ? 'someone' : tile.createdByName;
    return Card.outlined(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  height: 56,
                  child: ExcludeSemantics(child: TileView(tile: tile)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tile.label, style: theme.textTheme.titleMedium),
                      Text('Added by $by'),
                      Text(reason),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilledButton(
                  onPressed: onPlaceNext,
                  child: const Text('Place in next free spot'),
                ),
                OutlinedButton(
                  onPressed: onChoose,
                  child: const Text('Choose a spot'),
                ),
                TextButton(
                  onPressed: onRemove,
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A dialog showing the board with its free cells tappable; pops with the
/// chosen (row, col). Follows the store, so a spot another device fills
/// while the dialog is open stops being offered.
class _CellPicker extends StatelessWidget {
  const _CellPicker({
    required this.store,
    required this.board,
    required this.tile,
  });

  final BoardStore store;
  final BoardFacts board;
  final TileFacts tile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A plain Dialog: AlertDialog measures intrinsic width, which a grid of
    // scaled-to-fit tiles should not be asked for.
    // Narrow insets and padding keep a 6-column cell at 48dp on a 360dp phone.
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Where should "${tile.label}" go?',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('Tap an empty spot. Words already placed stay put.'),
              const SizedBox(height: 12),
              Flexible(
                // Sizes to the grid and keeps it square on a short screen.
                child: Align(
                  heightFactor: 1,
                  child: ListenableBuilder(
                    listenable: store,
                    builder: (context, _) => EditorGrid(
                      board: board,
                      cells: gridOf(board.id, store.tiles, store.boards),
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
