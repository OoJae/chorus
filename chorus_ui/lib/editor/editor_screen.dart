/// Where adults change the board.
library;

import 'dart:math' as math;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../brand/haptics.dart';
import '../brand/motion.dart';
import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_boards.dart';
import '../contracts_clash.dart';
import '../contracts_live.dart';
import '../contracts_media.dart';
import '../contracts_modelling.dart';
import '../contracts_suggest.dart';
import '../features/clash/clash_guide.dart';
import '../features/trust/presence_line.dart';
import '../features/flags/w6.dart';
import '../modelling/focus_words_screen.dart' show focusIdsOf;
import '../modelling/modelling_tools.dart';
import '../modelling/word_finder.dart';
import '../widgets/board_tabs.dart';
import '../widgets/sync_chip.dart';
import 'add_word_sheet.dart';
import 'board_actions.dart';
import 'model_mode_bar.dart';
import 'obf_picker.dart';
import 'ready_boards.dart';
import 'replaced_changes_panel.dart';
import 'tray_panel.dart';

/// Shown to a read-only partner in place of the editing hint.
const String readOnlyMessage =
    'You can view this board. Only the family and therapist can change it.';

/// Tooltip of the action that makes a printable page of the board on show.
const String printThisBoardLabel = 'Print a paper copy of this board';

/// Tooltip of the menu with the board actions.
const String boardMenuLabel = 'More for this board';

/// The board menu's entry that exports the board on show as an .obf file.
const String exportBoardLabel = 'Export this board (.obf)';

/// Popped by the edit sheet when the adult chose "Remove from board".
const Object _removeRequested = Object();

/// The board chosen with the tabs (the home board to begin with) in the same
/// positions the child sees, as a flat grid, with the ways to add, change
/// and remove a word, and the "Needs a home" tray.
///
/// There is deliberately no way to move a placed word to another cell: a
/// button the child already uses never changes place. There is no 3D here
/// either: this is where precision matters.
///
/// On a phone the tray is a sheet along the bottom, "Needs a home · 2",
/// that is dragged up; a clash that arrives lifts it once, and is felt. On a
/// wide screen, or a phone on its side, the tray is the column beside the
/// board.
///
/// Everything beyond [store] and [sync] is optional: with [media] and
/// [capture] a word can carry a photo and a recording, with [live] an adult
/// can point at words on the other devices, with [suggester] a picked photo
/// can be sent for a suggested word, and a store that keeps an edit log
/// gets the "Replaced changes" panel. A store that is also a [BoardManager]
/// gets the "+" tab, the long press on a tab to rename or archive it, and
/// "Import a board (.obf)" where a file can be picked. With [onExport] the
/// board menu also exports the board on show.
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
    this.onPrint,
    this.pickObfFile,
    this.onExport,
    this.clash,
    this.modelling,
    this.speech,
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

  /// Makes a paper copy of the given board: the one chosen with the tabs.
  /// Null hides the action.
  final ValueChanged<BoardFacts>? onPrint;

  /// Picks an .obf file to import. Null uses the platform's
  /// ([platformObfPicker]), which only the browser has; with neither,
  /// import is not offered.
  final ObfFilePicker? pickObfFile;

  /// Exports the given board (the one chosen with the tabs) as an Open
  /// Board Format file. Null hides the action.
  final ValueChanged<BoardFacts>? onExport;

  /// The practice partner behind "Try a clash" in the board menu. Null
  /// hides it.
  final ClashPartner? clash;
  /// Modelled taps, focus words and the word finder's extras; null leaves
  /// them out.
  final ModellingSource? modelling;

  /// The browser's speech recognition for "Listen" in model mode; null, or
  /// one that is not available, hides it.
  final SpeechListener? speech;

  /// The column beside the board on a wide screen, for tests.
  @visibleForTesting
  static const Key sideColumnKey = ValueKey('EditorScreen.sideColumn');

  /// The tray's sheet on a phone, for tests.
  @visibleForTesting
  static const Key traySheetKey = ValueKey('EditorScreen.traySheet');

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  /// Width of the column beside the board.
  static const double _sideWidth = 360;

  /// Space between the board and the column beside it.
  static const double _between = 24;

  /// The drag handle's band at the top of the phone's sheet.
  static const double _handleBand = 20;

  /// The most of the screen the phone's sheet covers.
  static const double _sheetMax = 0.9;

  BoardStore get _store => widget.store;

  /// The store's board management, when it offers it.
  BoardManager? get _manager {
    final Object store = _store;
    return store is BoardManager ? store : null;
  }

  ObfFilePicker? get _picker => widget.pickObfFile ?? platformObfPicker;

  /// While on, a tap on a word points at it instead of opening it.
  bool _modelling = false;

  /// The board chosen with the tabs; null means the home board.
  String? _selectedBoardId;

  final GlobalKey<EditorGridState> _gridKey = GlobalKey();

  late final TrayFlights _flights = TrayFlights(
    cellRect: (boardId, row, col) => boardId == _currentBoard()?.id
        ? _gridKey.currentState?.cellRect(row, col)
        : null,
    onPlacing: _lowerSheet,
  );

  /// The phone's sheet, and the spring that moves it when the editor does.
  final DraggableScrollableController _sheet = DraggableScrollableController();
  late final AnimationController _sheetSpring = AnimationController.unbounded(
    vsync: this,
  )..addListener(_followSpring);

  /// The sheet's resting size, as a share of the body; set as it is laid
  /// out. Zero while there is no sheet (side by side).
  double _peek = 0;
  bool _sheetOpen = false;

  /// The height the phone's sheet is a share of.
  double _sheetRoom = 0;

  /// "Try a clash", while its guide is open.
  ClashGuide? _guide;

  /// The clashes seen so far, so each lifts the sheet only once. Those
  /// already waiting when the editor opens are not news.
  Set<String> _knownClashes = const {};

  @override
  void initState() {
    super.initState();
    _knownClashes = _clashIds();
    _store.addListener(_onStoreChanged);
    _sheet.addListener(_onSheetMoved);
  }

  @override
  void didUpdateWidget(EditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.store, widget.store)) {
      oldWidget.store.removeListener(_onStoreChanged);
      widget.store.addListener(_onStoreChanged);
      _knownClashes = _clashIds();
    }
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _sheet.removeListener(_onSheetMoved);
    _sheetSpring.dispose();
    _sheet.dispose();
    _flights.dispose();
    _leaveClash();
    super.dispose();
  }

  /// The chosen board, else the home board, else the first still in use.
  BoardFacts? _currentBoard() {
    final live = _store.boards.where((board) => !board.archived);
    return live.where((board) => board.id == _selectedBoardId).firstOrNull ??
        live.where((board) => board.isHome).firstOrNull ??
        live.firstOrNull;
  }

  // ---- Clashes and the sheet ---------------------------------------------

  /// Every tile that lost its cell to another adult's word.
  Set<String> _clashIds() => {
    for (final entry in trayOf(_store.tiles, _store.boards))
      if (entry.reason == TrayReason.contested ||
          entry.reason == TrayReason.duplicateCell)
        entry.tile.id,
  };

  void _onStoreChanged() {
    final clashes = _clashIds();
    final arrived = clashes.difference(_knownClashes);
    _knownClashes = {..._knownClashes, ...clashes};
    if (arrived.isEmpty) return;
    final board = _currentBoard();
    final here = _store.tiles.any(
      (tile) => arrived.contains(tile.id) && tile.boardId == board?.id,
    );
    if (!here) return;
    ChorusHaptics.clashArrived();
    _liftSheet();
  }

  void _onSheetMoved() {
    if (!mounted || !_sheet.isAttached) return;
    final open = _sheet.size > _peek + 0.01;
    if (open == _sheetOpen) return;
    // The sheet may move while it is laid out: say so after the frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onSheetMoved());
      return;
    }
    setState(() => _sheetOpen = open);
  }

  void _followSpring() {
    if (!_sheet.isAttached || _peek <= 0) return;
    _sheet.jumpTo(_sheetSpring.value.clamp(_peek, _sheetMax));
  }

  /// Moves the phone's sheet to [size] on the settle spring, or at once
  /// under reduced motion.
  void _moveSheet(double size) {
    if (!mounted || !_sheet.isAttached || _peek <= 0) return;
    final target = size.clamp(_peek, _sheetMax);
    if (ChorusMotion.reduced(context)) {
      _sheetSpring.stop();
      _sheet.jumpTo(target);
      return;
    }
    if (!_sheetSpring.isAnimating) _sheetSpring.value = _sheet.size;
    ChorusMotion.springTo(_sheetSpring, ChorusMotion.settle, target);
  }

  /// How far a clash lifts the sheet: enough to show its card.
  double get _liftSize {
    if (_sheetRoom <= 0) return 0.5;
    return math.max(0.5, math.min(_sheetMax, _peek + 300 / _sheetRoom));
  }

  void _liftSheet() {
    if (!_sheet.isAttached || _sheet.size >= _liftSize) return;
    _moveSheet(_liftSize);
  }

  void _lowerSheet() => _moveSheet(_peek);

  void _toggleSheet() => _sheetOpen ? _lowerSheet() : _moveSheet(_liftSize);

  // ---- Boards ------------------------------------------------------------

  void _select(String boardId) => setState(() => _selectedBoardId = boardId);

  Future<void> _addBoard(BoardManager manager) async {
    final id = await addBoardFrom(context, store: _store, manager: manager);
    if (id != null && mounted) _select(id);
  }

  Future<void> _importBoard(BoardManager manager, ObfFilePicker pick) async {
    final id = await importBoardFrom(
      context,
      store: _store,
      manager: manager,
      pick: pick,
    );
    if (id != null && mounted) _select(id);
  }

  // ---- Try a clash -------------------------------------------------------

  void _startClash(ClashPartner partner) {
    final old = _guide;
    final guide = ClashGuide(
      store: _store,
      sync: widget.sync,
      partner: partner,
      preferBoard: _currentBoard()?.id,
    )..addListener(_followClash);
    setState(() => _guide = guide);
    old?.dispose();
    guide.start();
  }

  /// Shows the board the guide's spot is on.
  void _followClash() {
    if (!mounted) return;
    final board = _guide?.spot?.boardId;
    if (board != null && board != _currentBoard()?.id) _select(board);
  }

  void _endClash() {
    final guide = _guide;
    if (guide == null) return;
    setState(() => _guide = null);
    guide.close().whenComplete(guide.dispose);
  }

  /// Leaving the editor part way puts the device back online, as closing
  /// the guide does.
  void _leaveClash() {
    final guide = _guide;
    if (guide == null) return;
    _guide = null;
    guide.removeListener(_followClash);
    guide.close().whenComplete(guide.dispose);
  }

  Future<void> _addReadyBoard(BoardManager manager) async {
    final id = await addReadyBoardFrom(
      context,
      store: _store,
      manager: manager,
    );
    if (id != null && mounted) _select(id);
  }

  // ---- Words -------------------------------------------------------------

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
      messenger.showSnackBar(
        const SnackBar(
          content: Text('That word was removed on another device.'),
        ),
      );
      return;
    }
    if (identical(result, _removeRequested)) {
      final confirmed = await confirmRemoveWord(
        context,
        tile: current,
        childName: _store.childName,
      );
      if (!confirmed) return;
      try {
        await _store.archiveTile(current.id);
      } on Object {
        ChorusHaptics.failed();
        messenger.showSnackBar(const SnackBar(content: Text(notSavedMessage)));
      }
    } else if (result is WordDraft) {
      try {
        await _save(current, result);
      } on Object {
        ChorusHaptics.failed();
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
    await _store.updateTile(
      tile.id,
      label: label,
      speech: speech,
      colorKey: colorKey,
    );
  }

  // ---- Layout ------------------------------------------------------------

  /// Side by side from 900dp, and on a phone on its side: there the board
  /// keeps its height and the tray has the room beside it.
  static bool _sideBySide(Size body) =>
      body.width >= 900 ||
      (body.width >= ChorusSpace.wideFrom && body.width > body.height * 1.2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    // The size the body is laid out in: SafeArea takes the sides off.
    final body = Size(
      media.size.width - media.padding.horizontal,
      media.size.height - media.padding.vertical,
    );
    final sideBySide = _sideBySide(body);
    final margin = ChorusSpace.margin(body.width);
    return Theme(
      // Side by side, the board reaches the bottom of the window, so a
      // message ("... is on the board.") floats over the column beside it
      // instead of covering the board's last row.
      data: sideBySide
          ? theme.copyWith(
              snackBarTheme: theme.snackBarTheme.copyWith(
                behavior: SnackBarBehavior.floating,
                insetPadding: EdgeInsets.fromLTRB(
                  math.max(margin, body.width - margin - _sideWidth),
                  0,
                  margin,
                  margin,
                ),
              ),
            )
          : theme,
      child: _scaffold(sideBySide: sideBySide, margin: margin),
    );
  }

  Widget _scaffold({required bool sideBySide, required double margin}) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${_store.childName}'s board"),
        actions: [
          ListenableBuilder(
            listenable: _store,
            builder: (context, _) =>
                Row(mainAxisSize: MainAxisSize.min, children: _actions()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_store, _flights, ?widget.modelling]),
          builder: (context, _) {
            final board = _currentBoard();
            if (board == null) return _NoBoardYet(margin: margin);
            return sideBySide
                ? _sideBySideBody(board, margin)
                : _phoneBody(board, margin);
          },
        ),
      ),
    );
  }

  List<Widget> _actions() {
    final onPrint = widget.onPrint;
    final onExport = widget.onExport;
    final manager = _store.role.canEdit ? _manager : null;
    final picker = manager == null ? null : _picker;
    final board = _currentBoard();
    final clash = offersClash(widget.clash, _store) ? widget.clash : null;
    return [
      if (wordFinderEnabled)
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: findWordLabel,
          onPressed: () =>
              openWordFinder(context, store: _store, live: widget.live),
        ),
      if (onPrint != null)
        IconButton(
          icon: const Icon(Icons.print_rounded),
          tooltip: printThisBoardLabel,
          onPressed: () {
            // The board on show now, not the one shown when this was
            // built.
            final board = _currentBoard();
            if (board != null) onPrint(board);
          },
        ),
      if ((manager != null || onExport != null || clash != null) &&
          board != null)
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          tooltip: boardMenuLabel,
          onSelected: (choice) {
            // The board on show now, not the one shown when this was built.
            final current = _currentBoard();
            switch (choice) {
              case 'import':
                if (manager != null && picker != null) {
                  _importBoard(manager, picker);
                }
              case readyBoardsMenuValue when manager != null:
                _addReadyBoard(manager);
              case 'export' when current != null:
                onExport?.call(current);
              case 'rename' when current != null && manager != null:
                renameBoardFrom(
                  context,
                  store: _store,
                  manager: manager,
                  board: current,
                );
              case 'archive' when current != null && manager != null:
                archiveBoardFrom(
                  context,
                  store: _store,
                  manager: manager,
                  board: current,
                );
              case 'clash' when clash != null:
                _startClash(clash);
            }
          },
          itemBuilder: (context) => [
            if (manager != null) ...[
              const PopupMenuItem(
                value: 'rename',
                child: Text(renameBoardLabel),
              ),
              PopupMenuItem(
                value: 'archive',
                enabled: canArchive(board, _store.boards),
                child: const Text(archiveBoardLabel),
              ),
            ],
            if (manager != null &&
                (picker != null ||
                    onExport != null ||
                    offerReadyBoards(canAddBoards: true)))
              const PopupMenuDivider(),
            if (picker != null)
              const PopupMenuItem(
                value: 'import',
                child: Text(importBoardLabel),
              ),
            if (offerReadyBoards(canAddBoards: manager != null))
              const PopupMenuItem(
                value: readyBoardsMenuValue,
                child: Text(readyBoardsLabel),
              ),
            if (onExport != null)
              const PopupMenuItem(
                value: 'export',
                child: Text(exportBoardLabel),
              ),
            if (clash != null) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'clash', child: Text(tryAClashLabel)),
            ],
          ],
        ),
    ];
  }

  /// The parts both layouts are made of.
  ({
    Widget header,
    Widget? modelBar,
    Widget tabs,
    bool hasTabs,
    Widget grid,
    Widget replaced,
  })
  _parts(BoardFacts board) {
    final canEdit = _store.role.canEdit;
    final manager = canEdit ? _manager : null;
    final live = widget.live;
    final modelling = live != null && _modelling;
    final grid = EditorGrid(
      key: _gridKey,
      board: board,
      cells: gridOf(board.id, _store.tiles, _store.boards),
      media: widget.media,
      hiddenIds: _flights.flying,
      ringedIds: focusIdsOf(widget.modelling),
      // Model mode points at words and changes nothing, so a read-only
      // partner may use it too.
      onTile: modelling
          ? (tile) {
              live.sendPulse(tile.id);
              if (modelledWordsEnabled) widget.modelling?.noteModelled(tile);
            }
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
            labelFor: (id) =>
                _store.tiles.where((tile) => tile.id == id).firstOrNull?.label,
            extra:
                !(wordFinderEnabled ||
                    speechToSymbolsEnabled ||
                    focusWordsEnabled)
                ? null
                : ModellingTools(
                    store: _store,
                    live: live,
                    modelling: widget.modelling,
                    speech: widget.speech,
                    boardTiles: () =>
                        gridOf(board.id, _store.tiles, _store.boards).values,
                  ),
          );
    return (
      header: withClashGuide(
        withPresenceLine(
          _Header(
            sync: widget.sync,
            canEdit: canEdit,
            childName: _store.childName,
          ),
          live: live,
        ),
        guide: _guide,
        onClose: _endClash,
      ),
      modelBar: modelBar,
      tabs: BoardTabs(
        boards: _store.boards,
        selectedId: board.id,
        onSelect: _select,
        onAdd: manager == null ? null : () => _addBoard(manager),
        onLongPress: manager == null
            ? null
            : (tabBoard) => showBoardActions(
                context,
                store: _store,
                manager: manager,
                board: tabBoard,
              ),
      ),
      hasTabs: BoardTabs.showFor(_store.boards, canAdd: manager != null),
      grid: withClashGlow(grid, guide: _guide, board: board),
      // Draws nothing for a store with no edit log or no overwrites.
      replaced: ReplacedChangesPanel(store: _store, boardId: board.id),
    );
  }

  /// A phone: the board on a page that scrolls, the tray a sheet over the
  /// bottom of it.
  Widget _phoneBody(BoardFacts board, double margin) {
    final parts = _parts(board);
    final colors = ChorusColors.of(context);
    final peekHeight = _handleBand + TrayPanel.headingHeight(context) + 4;
    return LayoutBuilder(
      builder: (context, box) {
        final height = box.maxHeight;
        _sheetRoom = height;
        _peek = height <= 0 ? 0.1 : (peekHeight / height).clamp(0.05, 0.5);
        final modelBar = parts.modelBar;
        return Stack(
          children: [
            Positioned.fill(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  margin,
                  12,
                  margin,
                  peekHeight + 24,
                ),
                children: [
                  parts.header,
                  if (modelBar != null) ...[
                    const SizedBox(height: 16),
                    modelBar,
                  ],
                  if (parts.hasTabs) ...[
                    const SizedBox(height: 16),
                    parts.tabs,
                  ],
                  const SizedBox(height: 12),
                  parts.grid,
                  const SizedBox(height: 24),
                  parts.replaced,
                ],
              ),
            ),
            DraggableScrollableSheet(
              key: EditorScreen.traySheetKey,
              controller: _sheet,
              initialChildSize: _peek,
              minChildSize: _peek,
              maxChildSize: _sheetMax,
              builder: (context, scroll) => Listener(
                // A finger on the sheet takes it from the spring.
                onPointerDown: (_) => _sheetSpring.stop(),
                child: Material(
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(ChorusSpace.sheetRadius),
                    ),
                    side: BorderSide(color: colors.line),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomScrollView(
                    controller: scroll,
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: _handleBand,
                          child: Center(
                            child: Container(
                              width: 32,
                              height: 4,
                              decoration: BoxDecoration(
                                color: colors.inkMuted,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(margin, 0, margin, 24),
                        sliver: SliverToBoxAdapter(
                          child: TrayPanel(
                            store: _store,
                            boardId: board.id,
                            media: widget.media,
                            flights: _flights,
                            onHeadingTap: _toggleSheet,
                            expanded: _sheetOpen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// A wide screen: the board as tall as the window allows under its tabs,
  /// the hint, the chip, model mode and the tray in the column beside it.
  Widget _sideBySideBody(BoardFacts board, double margin) {
    _peek = 0;
    final parts = _parts(board);
    final colors = ChorusColors.of(context);
    final modelBar = parts.modelBar;
    return Padding(
      padding: EdgeInsets.all(margin),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, room) {
                final tabsHeight = parts.hasTabs ? BoardTabs.height + 12 : 0.0;
                // As wide as the board can be at its full height, so the
                // tabs above it are its width too; never so narrow that a
                // tile is under 48dp, when the column scrolls instead.
                final least =
                    board.cols * ChorusSpace.minTarget +
                    (board.cols - 1) * ChorusSpace.targetGap;
                final fit =
                    (room.maxHeight - tabsHeight) * board.cols / board.rows;
                final width = math.min(room.maxWidth, math.max(fit, least));
                return Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: width,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (parts.hasTabs) ...[
                            parts.tabs,
                            const SizedBox(height: 12),
                          ],
                          parts.grid,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: _between),
          SizedBox(
            key: EditorScreen.sideColumnKey,
            width: _sideWidth,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  parts.header,
                  if (modelBar != null) ...[
                    const SizedBox(height: 16),
                    modelBar,
                  ],
                  const SizedBox(height: 24),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(
                        ChorusSpace.panelRadius,
                      ),
                      border: Border.all(color: colors.line),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: TrayPanel(
                        store: _store,
                        boardId: board.id,
                        media: widget.media,
                        flights: _flights,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  parts.replaced,
                ],
              ),
            ),
          ),
        ],
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
    final colors = ChorusColors.of(context);
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
            style: ChorusType.body.copyWith(color: colors.inkMuted),
          )
        else
          Semantics(
            container: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
                border: Border.all(color: colors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.visibility_rounded, color: colors.ink),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        readOnlyMessage,
                        style: ChorusType.body.copyWith(color: colors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Before any board is on this device: a grey board holding its place, and
/// a line saying why it is empty.
class _NoBoardYet extends StatelessWidget {
  const _NoBoardYet({required this.margin});

  final double margin;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return ListView(
      padding: EdgeInsets.all(margin),
      children: [
        Text(
          'There is no board yet.',
          style: ChorusType.headline.copyWith(color: colors.ink),
        ),
        const SizedBox(height: 4),
        Text(
          'It shows here as soon as this device has it.',
          style: ChorusType.body.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: const ExcludeSemantics(
              child: SkeletonBoard(rows: starterRows, cols: starterCols),
            ),
          ),
        ),
      ],
    );
  }
}

/// Grey laminated tiles where a board will be: loading that holds its
/// space.
class SkeletonBoard extends StatelessWidget {
  const SkeletonBoard({super.key, required this.rows, required this.cols});

  final int rows;
  final int cols;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return AspectRatio(
      aspectRatio: cols / rows,
      child: LayoutBuilder(
        builder: (context, box) {
          final geometry = GridGeometry(
            rows: rows,
            cols: cols,
            size: box.biggest,
          );
          final radius = BorderRadius.circular(
            ChorusSpace.tileRadiusFor(geometry.tile.shortestSide),
          );
          return Stack(
            children: [
              for (var row = 0; row < rows; row++)
                for (var col = 0; col < cols; col++)
                  Positioned.fromRect(
                    rect: geometry.cell(row, col),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.line,
                        borderRadius: radius,
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
