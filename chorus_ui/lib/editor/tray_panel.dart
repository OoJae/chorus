/// The "Needs a home" tray, and the grid the editor and the tray's cell
/// picker both draw.
library;

import 'dart:math' as math;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../brand/motion.dart';
import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_media.dart';
import '../features/flags/w2.dart' as w2;
import '../modelling/focus_words_screen.dart' show FocusRing;
import '../widgets/label_fit.dart';
import '../widgets/tile_view.dart';
import 'contested_tray_card.dart';
import 'tile_flight.dart';
import 'word_suggestions_tray.dart';

/// Where every cell of a board drawn [size] big sits: the same equal cells
/// the grid lays out, with the widest gap between them, up to 8dp, that
/// still leaves every tile 48dp across.
@immutable
class GridGeometry {
  GridGeometry({required this.rows, required this.cols, required this.size})
    : gap = cols <= 1
          ? _maxGap
          : ((size.width - cols * ChorusSpace.minTarget) / (cols - 1)).clamp(
              _minGap,
              _maxGap,
            );

  static const double _minGap = 4;
  static const double _maxGap = ChorusSpace.targetGap;

  final int rows;
  final int cols;
  final Size size;

  /// Space between two cells, across and down.
  final double gap;

  Size get tile => Size(
    math.max(0, (size.width - gap * (cols - 1)) / cols),
    math.max(0, (size.height - gap * (rows - 1)) / rows),
  );

  /// Cell ([row], [col]) within the grid.
  Rect cell(int row, int col) {
    final tile = this.tile;
    return Rect.fromLTWH(
      col * (tile.width + gap),
      row * (tile.height + gap),
      tile.width,
      tile.height,
    );
  }
}

/// One board drawn as a fixed, flat grid: every tile in its own cell, every
/// free cell as a tappable gap. Offers no way to move a tile.
///
/// There is no 3D here: this is where precision matters.
class EditorGrid extends StatefulWidget {
  const EditorGrid({
    super.key,
    required this.board,
    required this.cells,
    this.onTile,
    this.onEmpty,
    this.emptyHint = 'Add a word here',
    this.dimTiles = false,
    this.media,
    this.hiddenIds = const {},
    this.ringedIds = const {},
    this.decorateTile,
  });

  final BoardFacts board;

  /// Tiles that wear a quiet ring, drawn over them and taking no space:
  /// the focus words of the week.
  final Set<String> ringedIds;

  /// Where the tiles' pictures come from. Null draws labels only.
  final MediaStore? media;

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

  /// Tiles kept out of sight in their cells, while a card flies to them.
  final Set<String> hiddenIds;

  /// Draws marks on a tile, e.g. a word hidden for now. Null draws none.
  final Widget Function(TileFacts tile, Widget view)? decorateTile;

  @override
  State<EditorGrid> createState() => EditorGridState();
}

/// The state of an [EditorGrid], which knows where its cells are on screen.
class EditorGridState extends State<EditorGrid> {
  /// One label size for the whole board, as on the child's screen.
  final TileLabelSizer _sizer = TileLabelSizer();

  /// Cell ([row], [col]) in global coordinates, or null before the grid is
  /// laid out.
  Rect? cellRect(int row, int col) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final board = widget.board;
    if (!board.contains(row, col)) return null;
    final geometry = GridGeometry(
      rows: board.rows,
      cols: board.cols,
      size: box.size,
    );
    return geometry.cell(row, col).shift(box.localToGlobal(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    if (board.rows <= 0 || board.cols <= 0) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: board.cols / board.rows,
      child: LayoutBuilder(
        builder: (context, box) {
          final geometry = GridGeometry(
            rows: board.rows,
            cols: board.cols,
            size: box.biggest,
          );
          // Measured and drawn with the same room for the label, so a word
          // with a picture is the same size as one without.
          final pictures = tilesHavePictures(
            widget.cells.values,
            media: widget.media,
          );
          final labelSize = _sizer.sizeFor(
            labels: widget.cells.values.map((tile) => tile.label),
            tile: geometry.tile,
            scaler: MediaQuery.textScalerOf(context),
            direction: Directionality.of(context),
            pictures: pictures,
          );
          final gap = geometry.gap;
          // Equal Expanded cells with fixed gaps: the cells are exactly
          // where [GridGeometry.cell] says.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var row = 0; row < board.rows; row++) ...[
                if (row > 0) SizedBox(height: gap),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < board.cols; col++) ...[
                        if (col > 0) SizedBox(width: gap),
                        Expanded(child: _cell(row, col, labelSize, pictures)),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _cell(int row, int col, double labelSize, bool pictures) {
    final tile = widget.cells[(row, col)];
    if (tile == null) {
      final onEmpty = widget.onEmpty;
      return _EmptyCell(
        row: row,
        col: col,
        hint: widget.emptyHint,
        onTap: onEmpty == null ? null : () => onEmpty(row, col),
      );
    }
    final onTile = widget.onTile;
    final view = TileView(
      key: ValueKey(tile.id),
      tile: tile,
      media: widget.media,
      dimmed: widget.dimTiles,
      labelSize: labelSize,
      pictures: pictures,
      onTap: onTile == null ? null : () => onTile(tile),
    );
    final marked = widget.decorateTile?.call(tile, view) ?? view;
    final shown = widget.ringedIds.contains(tile.id)
        ? FocusRing(child: marked)
        : marked;
    if (!widget.hiddenIds.contains(tile.id)) return shown;
    return Opacity(opacity: 0, child: shown);
  }
}

/// A free cell: a hairline outline on the card, with a "+" where a word can
/// go.
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
    final colors = ChorusColors.of(context);
    final where = 'Empty spot, row ${row + 1}, column ${col + 1}';
    return LayoutBuilder(
      builder: (context, box) {
        final radius = BorderRadius.circular(
          ChorusSpace.tileRadiusFor(box.biggest.shortestSide),
        );
        return Semantics(
          button: onTap != null,
          enabled: onTap != null,
          label: onTap == null ? where : '$where. $hint',
          onTap: onTap,
          excludeSemantics: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: ChorusSpace.minTarget,
              minHeight: ChorusSpace.minTarget,
            ),
            child: Material(
              color: colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(color: colors.line, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Center(
                  child: onTap == null
                      ? null
                      : Icon(Icons.add_rounded, color: colors.inkMuted),
                ),
              ),
            ),
          ),
        );
      },
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
const String notSavedMessage = 'That could not be saved. Nothing was changed.';

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
    TrayReason.duplicateCell =>
      'Shares a spot with $whose, which was there first',
  };
}

/// The tray's heading for [count] waiting words: "Needs a home", and with a
/// count once any are waiting, "Needs a home · 2".
String trayTitle(int count) =>
    count == 0 ? 'Needs a home' : 'Needs a home · $count';

/// The tray entries of the board [boardId], oldest first.
List<TrayEntry> trayEntriesFor(BoardStore store, String boardId) => [
  for (final entry in trayOf(store.tiles, store.boards))
    if (entry.tile.boardId == boardId) entry,
];

/// Lets the tray fly a placed word to its cell, and hide the cell's tile
/// until it lands. The editor owns one and gives it to its [TrayPanel] and
/// [EditorGrid].
class TrayFlights extends ChangeNotifier {
  TrayFlights({required this.cellRect, this.onPlacing});

  /// Where cell ([row], [col]) of [boardId] is on screen, or null when it
  /// is not drawn.
  final Rect? Function(String boardId, int row, int col) cellRect;

  /// Called as a word is about to be placed: the phone's sheet gets out of
  /// the way of the board.
  final VoidCallback? onPlacing;

  final Set<String> _flying = {};

  /// Tiles on their way to a cell.
  Set<String> get flying => Set.unmodifiable(_flying);

  void _start(String tileId) {
    if (_flying.add(tileId)) notifyListeners();
  }

  void _end(String tileId) {
    if (_flying.remove(tileId)) notifyListeners();
  }
}

/// Lists the words of one board that need an adult to give them a home, with
/// the ways to place them. Rebuilds whenever [store] changes.
///
/// "Place in next free spot" and "Choose a spot" place the word and, with
/// [flights], fly its card into the cell on the settle spring. Placing is
/// felt ([ChorusHaptic.wordPlaced]).
///
/// The heading reads "Needs a home · 2" in the status face. With
/// [onHeadingTap] the heading is a button, as on a phone's sheet, where it
/// opens and closes the sheet ([expanded] says which it does).
class TrayPanel extends StatelessWidget {
  const TrayPanel({
    super.key,
    required this.store,
    required this.boardId,
    this.media,
    this.flights,
    this.onHeadingTap,
    this.expanded = false,
  });

  final BoardStore store;
  final String boardId;

  /// Where the words' pictures come from. Null draws labels only.
  final MediaStore? media;

  final TrayFlights? flights;

  final VoidCallback? onHeadingTap;
  final bool expanded;

  /// The "Needs a home" heading, for tests.
  @visibleForTesting
  static const Key headingKey = ValueKey('TrayPanel.heading');

  /// The height of the heading row at the text scale around [context].
  static double headingHeight(BuildContext context) => math.max(
    ChorusSpace.minTarget,
    MediaQuery.textScalerOf(context).scale(ChorusType.status.fontSize!) *
            ChorusType.status.height! +
        16,
  );

  @override
  Widget build(BuildContext context) => _SuggestedCount(builder: _build);

  Widget _build(BuildContext context, ValueNotifier<int> suggested) {
    return ListenableBuilder(
      listenable: Listenable.merge([store, suggested]),
      builder: (context, _) {
        final colors = ChorusColors.of(context);
        final tiles = store.tiles;
        final boards = store.boards;
        final entries = trayEntriesFor(store, boardId);
        final board = boards
            .where((b) => b.id == boardId && !b.archived)
            .firstOrNull;
        final cells = gridOf(boardId, tiles, boards);
        final free = board == null
            ? const <(int, int)>[]
            : emptyCells(board, tiles, boards);
        final canEdit = store.role.canEdit;
        final suggestions = WordSuggestionsScope.maybeOf(context);
        final showSuggestions =
            w2.suggestWordEnabled && canEdit && suggestions != null;
        // Suggested words wait under this heading too, so they count in
        // it: on a phone the heading is all the resting sheet shows.
        final suggestedCount = showSuggestions ? suggested.value : 0;
        // Words two adults put in one spot offline, shown side by side.
        final plain = [
          for (final entry in entries)
            if (w2.plainTrayEnabled &&
                entry.reason == TrayReason.contested &&
                entry.wanted != null)
              entry,
        ];
        final note = entries.isEmpty
            ? (suggestedCount == 0 ? 'No words are waiting.' : null)
            : free.isEmpty
            ? 'The board is full. Remove a word to make room.'
            : null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Heading(
              key: headingKey,
              count: entries.length + suggestedCount,
              height: headingHeight(context),
              onTap: onHeadingTap,
              expanded: expanded,
            ),
            if (showSuggestions)
              SuggestionsTray(
                suggestions: suggestions,
                store: store,
                boardId: boardId,
                media: media,
                onCount: (count) => suggested.value = count,
              ),
            if (note != null)
              Text(
                note,
                style: ChorusType.body.copyWith(color: colors.inkMuted),
              ),
            for (final entry in plain)
              ContestedTrayCard(
                key: ValueKey(entry.tile.id),
                waiting: entry.tile,
                holder: cells[(entry.wanted!.row, entry.wanted!.col)],
                media: media,
                onPlaceNext: canEdit && free.isNotEmpty
                    ? (from) => _place(context, entry.tile, free.first, from)
                    : null,
                onChoose: canEdit && free.isNotEmpty && board != null
                    ? (from) => _choose(context, board, entry.tile, from)
                    : null,
                onRemove: canEdit ? () => _remove(context, entry.tile) : null,
              ),
            for (final entry in entries.where((e) => !plain.contains(e)))
              _TrayCard(
                key: ValueKey(entry.tile.id),
                entry: entry,
                media: media,
                reason: trayReasonText(entry, cells),
                onPlaceNext: canEdit && free.isNotEmpty
                    ? (from) => _place(context, entry.tile, free.first, from)
                    : null,
                onChoose: canEdit && free.isNotEmpty && board != null
                    ? (from) => _choose(context, board, entry.tile, from)
                    : null,
                onRemove: canEdit ? () => _remove(context, entry.tile) : null,
              ),
          ],
        );
      },
    );
  }

  Future<void> _place(
    BuildContext context,
    TileFacts tile,
    (int, int) cell,
    Rect? from,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final reduced = ChorusMotion.reduced(context);
    final flights = this.flights;
    // Hidden from the start, so the word never shows in its cell before
    // its card gets there.
    flights?._start(tile.id);
    final bool placed;
    try {
      placed = await store.placeTile(tile.id, row: cell.$1, col: cell.$2);
    } on Object {
      flights?._end(tile.id);
      ChorusHaptics.failed();
      // A merge placed or removed the word, or the role changed, meanwhile.
      messenger?.showSnackBar(
        const SnackBar(content: Text(wordChangedMessage)),
      );
      return;
    }
    if (!placed) {
      flights?._end(tile.id);
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('That spot was just taken. Choose another spot.'),
        ),
      );
      return;
    }
    ChorusHaptics.wordPlaced();
    messenger?.showSnackBar(
      SnackBar(content: Text('"${tile.label}" is on the board.')),
    );
    if (flights == null) return;
    flights.onPlacing?.call();
    final to = flights.cellRect(boardId, cell.$1, cell.$2);
    if (overlay != null && overlay.mounted && to != null && from != null) {
      await flyTile(
        overlay,
        tile: tile,
        from: from,
        to: to,
        reduced: reduced,
        media: media,
      );
    }
    flights._end(tile.id);
  }

  Future<void> _choose(
    BuildContext context,
    BoardFacts board,
    TileFacts tile,
    Rect? from,
  ) async {
    final cell = await showDialog<(int, int)>(
      context: context,
      builder: (dialogContext) =>
          _CellPicker(store: store, board: board, tile: tile, media: media),
    );
    if (cell == null || !context.mounted) return;
    await _place(context, tile, cell, from);
  }

  Future<void> _remove(BuildContext context, TileFacts tile) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final confirmed = await confirmRemoveWord(
      context,
      tile: tile,
      childName: store.childName,
    );
    if (!confirmed) return;
    try {
      await store.archiveTile(tile.id);
    } on Object {
      ChorusHaptics.failed();
      messenger?.showSnackBar(const SnackBar(content: Text(notSavedMessage)));
    }
  }
}

/// "Needs a home · 2" in the status face: the machine's voice, counting.
/// Holds how many suggested words [SuggestionsTray] shows, for the
/// heading above it.
class _SuggestedCount extends StatefulWidget {
  const _SuggestedCount({required this.builder});

  final Widget Function(BuildContext context, ValueNotifier<int> count) builder;

  @override
  State<_SuggestedCount> createState() => _SuggestedCountState();
}

class _SuggestedCountState extends State<_SuggestedCount> {
  final ValueNotifier<int> _count = ValueNotifier(0);

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _count);
}

class _Heading extends StatelessWidget {
  const _Heading({
    super.key,
    required this.count,
    required this.height,
    required this.expanded,
    this.onTap,
  });

  final int count;
  final double height;
  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final title = trayTitle(count);
    final text = Text(
      title,
      style: ChorusType.status.copyWith(color: colors.ink),
    );
    final onTap = this.onTap;
    if (onTap == null) {
      return Semantics(
        header: true,
        child: SizedBox(
          height: height,
          child: Align(alignment: Alignment.centerLeft, child: text),
        ),
      );
    }
    return Semantics(
      header: true,
      button: true,
      label: title,
      hint: expanded ? 'Hide the waiting words' : 'Show the waiting words',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              Expanded(child: text),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                color: colors.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrayCard extends StatefulWidget {
  const _TrayCard({
    super.key,
    required this.entry,
    required this.reason,
    this.media,
    this.onPlaceNext,
    this.onChoose,
    this.onRemove,
  });

  final TrayEntry entry;
  final String reason;
  final MediaStore? media;

  /// Each is given where the card's tile is on screen, to fly from.
  final ValueChanged<Rect?>? onPlaceNext;
  final ValueChanged<Rect?>? onChoose;
  final VoidCallback? onRemove;

  @override
  State<_TrayCard> createState() => _TrayCardState();
}

class _TrayCardState extends State<_TrayCard> {
  final GlobalKey _preview = GlobalKey();

  /// The card's tile in global coordinates.
  Rect? _previewRect() {
    final box = _preview.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final tile = widget.entry.tile;
    final by = tile.createdByName.isEmpty ? 'someone' : tile.createdByName;
    final onPlaceNext = widget.onPlaceNext;
    final onChoose = widget.onChoose;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    key: _preview,
                    width: 72,
                    height: 64,
                    child: ExcludeSemantics(
                      child: TileView(tile: tile, media: widget.media),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tile.label,
                          style: ChorusType.headline.copyWith(
                            color: colors.ink,
                          ),
                        ),
                        Text(
                          'Added by $by',
                          style: ChorusType.body.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                        Text(
                          widget.reason,
                          style: ChorusType.body.copyWith(color: colors.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onPlaceNext == null
                    ? null
                    : () => onPlaceNext(_previewRect()),
                child: const Text('Place in next free spot'),
              ),
              const SizedBox(height: ChorusSpace.targetGap),
              Wrap(
                spacing: ChorusSpace.targetGap,
                runSpacing: ChorusSpace.targetGap,
                children: [
                  OutlinedButton(
                    onPressed: onChoose == null
                        ? null
                        : () => onChoose(_previewRect()),
                    child: const Text('Choose a spot'),
                  ),
                  TextButton(
                    onPressed: widget.onRemove,
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
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
    this.media,
  });

  final BoardStore store;
  final BoardFacts board;
  final TileFacts tile;
  final MediaStore? media;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    // A plain Dialog: AlertDialog measures intrinsic width, which a grid of
    // scaled-to-fit tiles should not be asked for.
    // Narrow insets and padding keep a 6-column cell at 48dp on a 360dp phone.
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
                  'Where should "${tile.label}" go?',
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
                // Sizes to the grid and keeps it square on a short screen.
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
