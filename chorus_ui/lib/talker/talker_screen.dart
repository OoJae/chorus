/// The child's screen: the board, the sentence strip and nothing else.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand/haptics.dart';
import '../brand/motion.dart';
import '../brand/pressable_surface.dart';
import '../brand/tokens.dart';
import '../contracts.dart';
import '../contracts_hidden.dart';
import '../contracts_language.dart';
import '../contracts_live.dart';
import '../contracts_media.dart';
import '../contracts_wordlog.dart';
import '../widgets/label_fit.dart';
import '../widgets/sync_chip.dart';
import '../widgets/tile_view.dart';
import 'talker_controller.dart';
import 'talker_extras.dart';
import 'talker_tabs.dart';

/// Shown to adults when speech would need a network.
const String noOfflineVoiceMessage = 'No offline voice on this device';

/// Shown on the child's board for as long as spoken sentences are shared.
const String sharingSaidMessage = 'Sharing what is said';

/// Shown in place of [sharingSaidMessage] while the board is private.
const String sharingPausedMessage = 'Not shared while private';

/// Shown beside the status chip for as long as this board is joined to the
/// circle's live session.
const String liveConnectedMessage = 'Connected to the circle';

/// Label on the control that pauses the word log and sharing.
const String privateLabel = 'Private';

/// Said of the private control while it is off.
const String privateOffMessage =
    'Private is off. Turn it on to pause the word log and sharing on this '
    'device';

/// Said of the private control while it is on: the mark that it is.
const String privateOnMessage =
    'Private is on. Nothing is logged or shared from this device';

/// How long the leave control and the waiting pill must be held.
const Duration _holdToConfirm = Duration(seconds: 2);

/// Label on the control that leaves the board.
const String leaveLabel = 'Hold to leave';

/// Shown when system back is pressed: back is blocked on purpose.
const String howToLeaveMessage =
    'To leave the board, press and hold "Hold to leave" for 2 seconds.';

/// What a screen reader adds to a control that is held, for the keyboard.
const String holdWithKeyboardHint =
    'With a keyboard, hold Enter or Space for 2 seconds, then let go';

/// How the top of the child's screen is arranged for the room there is.
enum TalkerLayout {
  /// A tablet or a desktop window: the strip beside its three buttons, the
  /// status row under it, then the board tabs.
  roomy,

  /// A phone held upright: the strip on a row of its own, the three buttons
  /// in a row beneath it, then a compact status row and the board tabs.
  narrow,

  /// A phone on its side: strip, buttons and status in one row, and the
  /// board tabs in a column beside the grid, so the grid keeps the height.
  short,
}

/// The arrangement for a screen of [size], measured inside the safe area.
TalkerLayout talkerLayoutFor(Size size) {
  if (size.height < 480 && size.width >= 560) return TalkerLayout.short;
  if (size.width < 600) return TalkerLayout.narrow;
  return TalkerLayout.roomy;
}

/// Full-screen talking board.
///
/// It stays still. Nothing on it tilts, slides, bounces or follows a
/// scroll: a tile sinks on the press spring under the finger (felt as
/// [ChorusHaptic.wordTapped]), and a word an adult adds fades in where it
/// lands over [ChorusMotion.wordFade]. That is all the motion there is.
///
/// Every cell keeps its row and column whatever the screen size; an empty
/// cell is a blank gap. Every label on a board is drawn at one size. The
/// strip, its buttons and the status marks are rearranged for a phone held
/// upright or on its side; see [TalkerLayout]. Leaving takes a 2-second
/// hold on the leave control, which calls [onExit].
///
/// With a [live] session, a tile an adult taps in model mode on another
/// device glows here, and while a guardian has sharing on a bar says so; a
/// tap on the bar turns sharing off. While the session is connected a small
/// mark in the status row says so.
///
/// With a [wordLog] each tapped word is offered to the log. With a word log
/// or a live session the status row has a "Private" control: it pauses the
/// log and the sharing of sentences for the session, and shows while it is
/// on.
///
/// With a [media] store a tile shows its family photo once it is on this
/// device; with a [speaker] a single tapped word plays its recorded clip.
///
/// With a [heroTag] the board is the landing place of a shared-element
/// move from a screen whose board carries the same tag (home passes
/// `'board-<boardId>'`). Under reduced motion there is no such move.
class TalkerScreen extends StatefulWidget {
  const TalkerScreen({
    super.key,
    required this.store,
    required this.speech,
    required this.sync,
    this.live,
    this.media,
    this.speaker,
    this.wordLog,
    this.heroTag,
    this.onExit,
    this.hiddenWords,
    this.languages,
    this.languageVoice,
  });

  final BoardStore store;
  final SpeechService speech;
  final SyncStatus sync;

  /// The circle's live session, or null to run the board without one.
  final LiveSession? live;

  /// The circle's pictures and clips, or null to show labels and symbols
  /// only.
  final MediaStore? media;

  /// Plays a tile's recorded clip; null speaks every word with [speech].
  final TileSpeaker? speaker;

  /// The circle's opt-in word log, or null to log nothing.
  final WordLog? wordLog;

  /// The tag of the [Hero] the board grid is wrapped in, or null for none.
  final Object? heroTag;

  final VoidCallback? onExit;

  /// Words hidden for now: their cells are blank, and "Show everything"
  /// shows them until the board is left. Null hides nothing.
  final HiddenWords? hiddenWords;

  /// The circle's second language: a switch shows the words in it. Null
  /// offers no switch.
  final HomeLanguages? languages;

  /// The device's voices for the second language. Null speaks a word in
  /// it with its recording, else in the first language.
  final LanguageVoice? languageVoice;

  /// The face of the "Private" control, for tests.
  @visibleForTesting
  static const Key privateKey = ValueKey('TalkerScreen.private');

  @override
  State<TalkerScreen> createState() => _TalkerScreenState();
}

class _TalkerScreenState extends State<TalkerScreen> {
  late TalkerController _controller;

  /// Hidden words and the second language; null without either.
  TalkerExtras? _extras;

  @override
  void initState() {
    super.initState();
    _warmUp();
    _extras = _newExtras();
    _controller = _newController();
  }

  TalkerExtras? _newExtras() => TalkerExtras.maybe(
    isSafe: () => _controller.atSafePoint,
    hidden: widget.hiddenWords,
    languages: widget.languages,
    voice: widget.languageVoice,
  );

  TalkerController _newController() => TalkerController(
    store: widget.store,
    speech: _extras?.speechFor(widget.speech) ?? widget.speech,
    speaker:
        _extras?.speakerFor(
          widget.speaker,
          widget.speech,
          (id) => widget.store.tiles.where((t) => t.id == id).firstOrNull,
        ) ??
        widget.speaker,
    live: widget.live,
    wordLog: widget.wordLog,
  );

  @override
  void didUpdateWidget(TalkerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final extrasChanged =
        oldWidget.hiddenWords != widget.hiddenWords ||
        oldWidget.languages != widget.languages ||
        oldWidget.languageVoice != widget.languageVoice;
    if (extrasChanged) {
      _extras?.dispose();
      _extras = _newExtras();
    }
    if (extrasChanged ||
        oldWidget.store != widget.store ||
        oldWidget.speech != widget.speech ||
        oldWidget.speaker != widget.speaker ||
        oldWidget.live != widget.live ||
        oldWidget.wordLog != widget.wordLog) {
      _controller.dispose();
      _warmUp();
      _controller = _newController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _extras?.dispose();
    super.dispose();
  }

  /// A failed warm-up only makes the first word slower.
  void _warmUp() {
    widget.speech.warmUp().catchError((Object _) {});
  }

  /// Speaks the sentence; felt only when there is one to speak.
  void _speak() {
    if (_controller.strip.isNotEmpty) ChorusHaptics.sentenceSpoken();
    unawaited(_controller.speakStrip());
  }

  /// Reached only by holding the waiting pill; asks before moving anything.
  Future<void> _confirmAdultChanges() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update the board?'),
        content: const Text(
          'Another adult changed words that are showing here. Updating will '
          'move or replace some of them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ChorusHaptics.wordPlaced();
      _controller.applyAdultChanges();
    }
  }

  @override
  Widget build(BuildContext context) {
    // System back is blocked: only the held lock leaves the board. A pop
    // made by [onExit] itself still goes through.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text(howToLeaveMessage)));
      },
      child: Scaffold(
        // The board's own card, as on the home screen's miniature of it.
        backgroundColor: ChorusColors.of(context).surface,
        body: SafeArea(
          // Any finger anywhere counts as activity, whatever handles it.
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _controller.touchDown(),
            onPointerUp: (_) => _controller.touchUp(),
            onPointerCancel: (_) => _controller.touchUp(),
            child: ListenableBuilder(
              listenable: Listenable.merge([_controller, _extras]),
              builder: (context, _) => LayoutBuilder(
                builder: (context, box) => Padding(
                  padding: const EdgeInsets.all(_edge),
                  child: _layout(
                    talkerLayoutFor(box.biggest),
                    box.biggest.width - 2 * _edge,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Round the whole screen: the board needs every bit of it.
  static const double _edge = 6;

  /// Between rows of controls: the space between touch targets.
  static const double _rowGap = ChorusSpace.targetGap;

  Widget _layout(TalkerLayout layout, double width) {
    final controller = _controller;
    final snapshot = controller.snapshot;
    final colors = ChorusColors.of(context);
    Widget grid = snapshot == null
        ? const _NoBoard()
        : _BoardGrid(
            snapshot: snapshot,
            media: widget.media,
            pulsing: controller.pulsing,
            onTap: controller.tapTile,
            gap: layout == TalkerLayout.short ? 3 : 4,
            extras: _extras,
          );
    final heroTag = widget.heroTag;
    if (heroTag != null && !ChorusMotion.reduced(context)) {
      // The card the home screen's board flies in as; the same colour as
      // the page once it lands. No shuttle of its own: home's draws the
      // flight both ways. Linear, because the route already moves on the
      // settle spring.
      grid = Hero(
        tag: heroTag,
        curve: Curves.linear,
        child: Material(color: colors.surface, child: grid),
      );
    }
    final status = _StatusRow(
      controller: controller,
      speech: widget.speech,
      sync: widget.sync,
      onExit: widget.onExit,
      onAdultUpdate: _confirmAdultChanges,
      layout: layout,
      extras: _extras,
    );
    final hasTabs = controller.showsTabs;
    Widget tabs(Axis axis) => TalkerBoardTabs(
      boards: controller.tabs,
      selectedId: controller.boardId,
      onSelect: controller.showBoard,
      attentionIds: controller.pulsingBoardIds,
      axis: axis,
    );
    final sharing = controller.sharingOn
        ? [
            _SharingBar(
              paused: controller.private,
              onStop: controller.stopSharingSaid,
            ),
            const SizedBox(height: _rowGap),
          ]
        : const <Widget>[];
    Widget strip({double fontSize = 32}) => _SentenceBox(
      controller: controller,
      onSpeak: _speak,
      fontSize: fontSize,
    );

    switch (layout) {
      case TalkerLayout.roomy:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 72,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: strip()),
                  ..._stripButtons(controller, _speak, width: 64),
                ],
              ),
            ),
            const SizedBox(height: _rowGap),
            status,
            if (hasTabs) ...[
              const SizedBox(height: _rowGap),
              tabs(Axis.horizontal),
            ],
            const SizedBox(height: _rowGap),
            ...sharing,
            Expanded(child: grid),
          ],
        );
      case TalkerLayout.narrow:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The whole width for the sentence.
            SizedBox(height: 64, child: strip()),
            const SizedBox(height: _rowGap),
            SizedBox(
              height: 52,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _stripButtons(controller, _speak, leadingGap: false),
              ),
            ),
            const SizedBox(height: _rowGap),
            status,
            if (hasTabs) ...[
              const SizedBox(height: _rowGap),
              tabs(Axis.horizontal),
            ],
            const SizedBox(height: _rowGap),
            ...sharing,
            Expanded(child: grid),
          ],
        );
      case TalkerLayout.short:
        // What the strip's buttons and the gaps round them take. The status
        // marks get half of what is left, always the same half: sized to
        // what they show, they would push Speak, Delete last word and Clear
        // sideways each time a pill came or "Private" turned on.
        const buttons = 3 * 52 + 4 * _rowGap;
        final statusRoom = math.max(0.0, (width - buttons) / 2);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // One row for everything that is not the board.
            SizedBox(
              height: 52,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: strip(fontSize: 26)),
                  ..._stripButtons(controller, _speak, width: 52),
                  const SizedBox(width: _rowGap),
                  SizedBox(
                    width: statusRoom,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: status,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sharing is a pill in the row above here, so the grid keeps
            // its height.
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Beside the grid, where a row of tabs would cost height.
                  if (hasTabs) ...[
                    SizedBox(width: 92, child: tabs(Axis.vertical)),
                    const SizedBox(width: 4),
                  ],
                  Expanded(child: grid),
                ],
              ),
            ),
          ],
        );
    }
  }
}

/// Speak, delete the last word, clear. With a [width] each button is that
/// wide; without, the three share the row equally.
List<Widget> _stripButtons(
  TalkerController controller,
  VoidCallback onSpeak, {
  double? width,
  bool leadingGap = true,
}) {
  const gap = SizedBox(width: ChorusSpace.targetGap);
  Widget sized(Widget button) => width == null
      ? Expanded(child: button)
      : SizedBox(width: width, child: button);
  return [
    if (leadingGap) gap,
    sized(
      _StripButton(
        icon: Icons.volume_up_rounded,
        label: 'Speak',
        primary: true,
        onPressed: onSpeak,
      ),
    ),
    gap,
    sized(
      _StripButton(
        icon: Icons.backspace_rounded,
        label: 'Delete last word',
        onPressed: controller.backspace,
      ),
    ),
    gap,
    sized(
      _StripButton(
        icon: Icons.clear_rounded,
        label: 'Clear',
        onPressed: controller.clearStrip,
      ),
    ),
  ];
}

/// Shown in place of the board until the circle has one: grey laminated
/// tiles holding the board's space, and a line saying why.
class _NoBoard extends StatelessWidget {
  const _NoBoard();

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final corner = BorderRadius.circular(ChorusSpace.tileRadius);
    Widget tile() => Padding(
      padding: const EdgeInsets.all(4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: ChorusSpace.edge),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: edgeFor(colors.line),
                borderRadius: corner,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: ChorusSpace.edge),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.line,
                borderRadius: corner,
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: 'No board yet. It shows here as soon as this device has it',
      excludeSemantics: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                for (var row = 0; row < starterRows; row++)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var col = 0; col < starterCols; col++)
                          Expanded(child: tile()),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(ChorusSpace.marginPhone),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(ChorusSpace.panelRadius),
                  border: Border.all(color: colors.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No board yet',
                        textAlign: TextAlign.center,
                        style: ChorusType.headline.copyWith(color: colors.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'It shows here as soon as this device has it.',
                        textAlign: TextAlign.center,
                        style: ChorusType.body.copyWith(color: colors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The grid: equal cells, each at its own row and column, every label at
/// the one size the board's longest label allows.
///
/// A word that was not on this board a moment ago fades in where it lands;
/// nothing else on the grid ever moves by itself.
class _BoardGrid extends StatefulWidget {
  const _BoardGrid({
    required this.snapshot,
    required this.pulsing,
    required this.onTap,
    required this.gap,
    this.media,
    this.extras,
  });

  final BoardSnapshot snapshot;
  final MediaStore? media;

  /// Hidden words and the second language; null for neither.
  final TalkerExtras? extras;

  /// Ids of the tiles an adult is pointing at.
  final Set<String> pulsing;
  final ValueChanged<TileFacts> onTap;

  /// Space round each cell.
  final double gap;

  @override
  State<_BoardGrid> createState() => _BoardGridState();
}

class _BoardGridState extends State<_BoardGrid> {
  /// Remembers the size until the layout or the labels change.
  final TileLabelSizer _sizer = TileLabelSizer();

  /// Tiles new to the board on show since the last snapshot: they fade in.
  /// A board the child has just switched to is shown at once.
  Set<String> _arriving = const {};

  @override
  void didUpdateWidget(_BoardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.snapshot;
    final now = widget.snapshot;
    if (identical(before, now) || before.board.id != now.board.id) {
      _arriving = const {};
      return;
    }
    final known = {for (final tile in before.cells.values) tile.id};
    _arriving = {
      for (final tile in now.cells.values)
        if (!known.contains(tile.id)) tile.id,
    };
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final board = snapshot.board;
    final gap = widget.gap;
    if (board.rows <= 0 || board.cols <= 0) return const SizedBox.expand();
    final pictures = tilesHavePictures(
      snapshot.cells.values,
      media: widget.media,
    );
    return LayoutBuilder(
      builder: (context, box) {
        final tileSize = Size(
          box.maxWidth / board.cols - 2 * gap,
          box.maxHeight / board.rows - 2 * gap,
        );
        final labelSize = _sizer.sizeFor(
          labels: snapshot.cells.values.map(
            (tile) => (widget.extras?.shownTile(tile) ?? tile).label,
          ),
          tile: tileSize,
          scaler: MediaQuery.textScalerOf(context),
          direction: Directionality.of(context),
          pictures: pictures,
        );
        final radius = ChorusSpace.tileRadiusFor(tileSize.shortestSide);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var row = 0; row < board.rows; row++)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var col = 0; col < board.cols; col++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(gap),
                          child: _cell(
                            snapshot.cells[(row, col)],
                            labelSize,
                            radius,
                            pictures,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _cell(
    TileFacts? tile,
    double labelSize,
    double radius,
    bool pictures,
  ) {
    if (tile == null) return const SizedBox.expand();
    final extras = widget.extras;
    // A hidden word keeps its cell, blank and silent.
    if (extras != null && extras.hides(tile.id)) {
      return HiddenWordCell(key: ValueKey('hidden-${tile.id}'));
    }
    final shown = extras?.shownTile(tile) ?? tile;
    final glowing = widget.pulsing.contains(tile.id);
    // The glow wraps the tile and is always in the tree, so a tile keeps
    // its state and its place when a pulse starts or ends.
    return _Glow(
      key: ValueKey(tile.id),
      active: glowing,
      radius: radius,
      child: _Arrival(
        fade: _arriving.contains(tile.id),
        child: TileView(
          tile: shown,
          symbolLabel: identical(shown, tile) ? null : tile.label,
          media: widget.media,
          highlighted: glowing,
          labelSize: labelSize,
          pictures: pictures,
          haptic: ChorusHaptic.wordTapped,
          onTap: () => widget.onTap(shown),
        ),
      ),
    );
  }
}

/// A word arriving on the board: it fades in where it lands, over
/// [ChorusMotion.wordFade], and never slides. Any other tile is drawn at
/// once.
class _Arrival extends StatefulWidget {
  const _Arrival({required this.fade, required this.child});

  /// Read once, when the tile first appears.
  final bool fade;
  final Widget child;

  @override
  State<_Arrival> createState() => _ArrivalState();
}

class _ArrivalState extends State<_Arrival>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    value: 1,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _fade,
    curve: ChorusMotion.entrance,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.fade) {
      _fade.duration = ChorusMotion.duration(context, ChorusMotion.wordFade);
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}

/// An ink ring that breathes over a tile while an adult is pointing at it.
///
/// It is drawn over the tile and takes no space, so nothing on the board
/// moves. It is in tile ink, which reads on every family's fill in both
/// modes. With animations turned off on the device the ring is steady.
class _Glow extends StatefulWidget {
  const _Glow({
    super.key,
    required this.active,
    required this.radius,
    required this.child,
  });

  final bool active;
  final double radius;
  final Widget child;

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = ChorusMotion.reduced(context);
    _sync();
  }

  @override
  void didUpdateWidget(_Glow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _sync();
  }

  void _sync() {
    if (widget.active && !_still) {
      if (!_breath.isAnimating) _breath.repeat(reverse: true);
    } else {
      _breath.stop();
      _breath.value = 1;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final strength = widget.active
            ? 0.45 + 0.55 * Curves.easeInOut.transform(_breath.value)
            : 0.0;
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: tileLabelInk.withValues(alpha: strength),
              width: 4,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Says that spoken sentences are being sent to the circle, for as long as
/// a guardian has that on. A tap stops it; only a guardian can start it
/// again, elsewhere. While the board is private it says that nothing is
/// being sent, and keeps its place, so the board under it does not move.
class _SharingBar extends StatelessWidget {
  const _SharingBar({required this.paused, required this.onStop});

  /// The board is private: nothing is sent until it is not.
  final bool paused;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final words = Row(
      children: [
        Icon(
          paused ? Icons.visibility_off_rounded : Icons.podcasts_rounded,
          size: 20,
          color: paused ? colors.ink : colors.surface,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            paused ? sharingPausedMessage : sharingSaidMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ChorusType.label.copyWith(
              color: paused ? colors.ink : colors.surface,
            ),
          ),
        ),
        if (!paused)
          Text(
            'Tap to stop',
            maxLines: 1,
            style: ChorusType.status.copyWith(color: colors.surface),
          ),
      ],
    );
    if (paused) {
      return Semantics(
        container: true,
        label: '$sharingSaidMessage is paused while the board is private',
        excludeSemantics: true,
        child: Container(
          height: ChorusSpace.minTarget,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
            border: Border.all(color: colors.ink, width: 1.5),
          ),
          child: words,
        ),
      );
    }
    return SizedBox(
      height: ChorusSpace.minTarget,
      child: PressableSurface(
        onTap: onStop,
        semanticLabel: '$sharingSaidMessage. Tap to stop',
        foregroundColor: colors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox.expand(child: words),
      ),
    );
  }
}

/// [_SharingBar] as a pill in the status row of a phone on its side, where
/// a bar would take height from the board.
class _SharingPill extends StatelessWidget {
  const _SharingPill({required this.paused, required this.onStop});

  final bool paused;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final ink = paused ? colors.ink : colors.surface;
    final pill = Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: paused ? null : colors.ink,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.ink, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            paused ? Icons.visibility_off_rounded : Icons.podcasts_rounded,
            size: 18,
            color: ink,
          ),
          const SizedBox(width: 6),
          Text(
            paused ? 'Not shared' : 'Sharing',
            maxLines: 1,
            style: ChorusType.label.copyWith(color: ink),
          ),
        ],
      ),
    );
    if (paused) {
      return Semantics(
        container: true,
        label: '$sharingSaidMessage is paused while the board is private',
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: ChorusSpace.minTarget),
          child: Center(widthFactor: 1, child: pill),
        ),
      );
    }
    return Semantics(
      container: true,
      button: true,
      label: '$sharingSaidMessage. Tap to stop',
      onTap: onStop,
      excludeSemantics: true,
      child: Tooltip(
        message: '$sharingSaidMessage. Tap to stop',
        child: InkWell(
          onTap: onStop,
          splashFactory: NoSplash.splashFactory,
          borderRadius: BorderRadius.circular(ChorusSpace.minTarget / 2),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: ChorusSpace.minTarget),
            child: Center(widthFactor: 1, child: pill),
          ),
        ),
      ),
    );
  }
}

/// The sentence so far. A tap speaks it.
///
/// A sentence that fits starts at the left edge, so its first word is the
/// first thing read; one that is too long scrolls, with the newest word kept
/// in view. Its words are in the tile-label face, ink on card.
class _SentenceBox extends StatelessWidget {
  const _SentenceBox({
    required this.controller,
    required this.onSpeak,
    this.fontSize = 32,
  });

  final TalkerController controller;
  final VoidCallback onSpeak;
  final double fontSize;

  /// The ink line round the strip.
  static const double _line = 2;

  @override
  Widget build(BuildContext context) {
    // From the strip's edge to its first word.
    const side = 12.0;
    final colors = ChorusColors.of(context);
    final words = controller.strip;
    final sentence = words.map((t) => t.label).join(' ');
    final radius = BorderRadius.circular(ChorusSpace.buttonRadius);
    return PressableSurface(
      onTap: onSpeak,
      semanticLabel: words.isEmpty ? 'Sentence, empty' : 'Sentence: $sentence',
      color: colors.card,
      edgeColor: colors.ink,
      foregroundColor: colors.ink,
      borderRadius: ChorusSpace.buttonRadius,
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.ink, width: _line),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: LayoutBuilder(
              builder: (context, box) {
                // Large text grows only as far as the strip is tall, so a
                // word is never cut through.
                final line = fontSize * 1.3;
                final room = math.max(1.0, (box.maxHeight - 8) / line);
                final scaler = MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: math.max(1.0, room));
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  // Reversed so the newest word of a long sentence is in
                  // view.
                  reverse: true,
                  // The ink line is drawn over the first of this.
                  padding: const EdgeInsets.symmetric(horizontal: side),
                  child: ConstrainedBox(
                    // At least the width on show, so a short sentence sits
                    // at the left and is not pushed to the right by the
                    // reversal.
                    constraints: BoxConstraints(
                      minWidth: box.maxWidth.isFinite && box.maxWidth > 2 * side
                          ? box.maxWidth - 2 * side
                          : 0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        sentence,
                        maxLines: 1,
                        softWrap: false,
                        textScaler: scaler,
                        style: ChorusType.tileLabel(
                          fontSize,
                        ).copyWith(color: colors.ink, inherit: false),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the strip's three buttons: Speak is ink, the other two are
/// card-grey. Each stands on its laminated edge and sinks when pressed.
class _StripButton extends StatelessWidget {
  const _StripButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final ink = primary ? colors.surface : colors.ink;
    return PressableSurface(
      onTap: onPressed,
      semanticLabel: label,
      color: primary ? colors.ink : colors.line,
      foregroundColor: ink,
      borderRadius: ChorusSpace.buttonRadius,
      child: SizedBox.expand(
        child: Center(child: Icon(icon, size: 30, color: ink)),
      ),
    );
  }
}

/// Waiting pill, the private control, the no-offline-voice warning, sync
/// chip and the exit lock.
///
/// Roomy: a full row with the chip in words. Narrow: a full row with the
/// chip as an icon and shorter pills. Short: the same compact marks, against
/// the right edge of a space of fixed width at the end of the strip's row,
/// so nothing before them moves when they change. Where the row is
/// too narrow for all of it (large text on a small phone) it is drawn
/// smaller as a whole, never cut.
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.controller,
    required this.speech,
    required this.sync,
    required this.onExit,
    required this.onAdultUpdate,
    required this.layout,
    this.extras,
  });

  final TalkerController controller;
  final SpeechService speech;
  final SyncStatus sync;
  final VoidCallback? onExit;
  final VoidCallback onAdultUpdate;
  final TalkerLayout layout;

  /// Adds "Show everything" and the language switch; null adds nothing.
  final TalkerExtras? extras;

  @override
  Widget build(BuildContext context) {
    final waiting = controller.waitingCount;
    final compact = layout != TalkerLayout.roomy;
    const gap = SizedBox(width: ChorusSpace.targetGap);
    final pill = waiting > 0
        ? _WaitingPill(
            count: waiting,
            needsAdult: controller.needsAdult,
            onAdultUpdate: onAdultUpdate,
            compact: compact,
          )
        : null;
    final trailing = <Widget>[
      if (compact)
        SyncChip(sync: sync, compact: true)
      else
        // Room for its longest words, so the row round it may be measured
        // at its natural width and drawn smaller when that is too wide.
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.textScalerOf(context).scale(420),
          ),
          child: SyncChip(sync: sync),
        ),
      // Anything live is shown: this board is joined to the circle and
      // the other adults can see that it is here.
      if (controller.liveConnected)
        const _Mark(icon: Icons.sensors_rounded, message: liveConnectedMessage),
      // For the adult: without an offline voice the board is silent
      // whenever there is no network.
      ValueListenableBuilder<bool>(
        valueListenable: speech.offlineVoiceReady,
        builder: (context, ready, _) => ready
            ? const SizedBox.shrink()
            : const _Mark(
                icon: Icons.volume_off_rounded,
                message: noOfflineVoiceMessage,
              ),
      ),
      ...talkerExtraControls(extras, compact: compact),
      if (controller.offersPrivate) ...[
        gap,
        _PrivateToggle(
          on: controller.private,
          compact: compact,
          onChanged: controller.setPrivate,
        ),
      ],
      gap,
      _HoldTarget(
        semanticsLabel: 'Hold for 2 seconds to leave the board',
        onHeld: onExit,
        haptic: ChorusHaptic.leftBoard,
        square: false,
        child: _LeavePill(compact: compact),
      ),
    ];
    if (layout == TalkerLayout.short) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pill != null) ...[pill, gap],
          if (controller.sharingOn) ...[
            _SharingPill(
              paused: controller.private,
              onStop: controller.stopSharingSaid,
            ),
            gap,
          ],
          ...trailing,
        ],
      );
    }
    return SizedBox(
      // Fixed, so the board under it never moves when "Sync now" comes and
      // goes: the chip in words is a little taller than a target.
      height: layout == TalkerLayout.roomy ? 52 : ChorusSpace.minTarget,
      child: LayoutBuilder(
        builder: (context, box) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: box.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (pill != null) pill else const SizedBox.shrink(),
                Padding(
                  padding: EdgeInsets.only(
                    left: pill == null ? 0 : ChorusSpace.targetGap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: trailing,
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

/// A small ink sign in the status row, with its words for a screen reader
/// and as a tooltip.
class _Mark extends StatelessWidget {
  const _Mark({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: message,
        child: Icon(
          icon,
          size: 24,
          color: ChorusColors.of(context).ink,
          semanticLabel: message,
        ),
      ),
    );
  }
}

/// "Private": pauses the word log and the sharing of sentences for the
/// session. While on it is filled ink and names itself, so it shows from
/// across the room that nothing is being logged or shared.
class _PrivateToggle extends StatelessWidget {
  const _PrivateToggle({
    required this.on,
    required this.compact,
    required this.onChanged,
  });

  final bool on;

  /// The icon alone while off.
  final bool compact;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final ink = on ? colors.surface : colors.ink;
    final words = !compact || on;
    return Semantics(
      container: true,
      button: true,
      toggled: on,
      label: privateLabel,
      hint: on ? privateOnMessage : privateOffMessage,
      onTap: () => onChanged(!on),
      excludeSemantics: true,
      child: Tooltip(
        message: on ? privateOnMessage : privateOffMessage,
        child: InkWell(
          onTap: () => onChanged(!on),
          // Nothing spreads or moves on the child's board.
          splashFactory: NoSplash.splashFactory,
          borderRadius: BorderRadius.circular(ChorusSpace.minTarget / 2),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: ChorusSpace.minTarget,
              minHeight: ChorusSpace.minTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: Container(
                key: TalkerScreen.privateKey,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.symmetric(horizontal: words ? 12 : 0),
                decoration: BoxDecoration(
                  color: on ? colors.ink : colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.ink, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility_off_rounded, size: 18, color: ink),
                    if (words) ...[
                      const SizedBox(width: 6),
                      Text(
                        privateLabel,
                        maxLines: 1,
                        style: ChorusType.label.copyWith(color: ink),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "N words waiting", in the status face. When an adult is needed, holding
/// it for 2 seconds offers the update.
class _WaitingPill extends StatelessWidget {
  const _WaitingPill({
    required this.count,
    required this.needsAdult,
    required this.onAdultUpdate,
    this.compact = false,
  });

  final int count;
  final bool needsAdult;
  final VoidCallback onAdultUpdate;

  /// Shows "N waiting"; a screen reader still hears the whole phrase.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = count == 1 ? '1 word waiting' : '$count words waiting';
    final colors = ChorusColors.of(context);
    final pill = Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (needsAdult) ...[
            Icon(
              Icons.supervisor_account_rounded,
              size: 18,
              color: colors.surface,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            compact ? '$count waiting' : text,
            maxLines: 1,
            style: ChorusType.status.copyWith(color: colors.surface),
          ),
        ],
      ),
    );
    if (!needsAdult) {
      return Semantics(
        liveRegion: true,
        label: text,
        child: ExcludeSemantics(child: pill),
      );
    }
    return _HoldTarget(
      semanticsLabel: '$text. An adult can hold for 2 seconds to update',
      onHeld: onAdultUpdate,
      square: false,
      child: pill,
    );
  }
}

/// Fires [onHeld] after an unbroken 2-second press, showing progress.
/// Lifting the finger early starts over.
///
/// The keyboard reaches it with Tab, and Enter or Space held for the same
/// 2 seconds fills the same bar; that hold fires when the key is let go.
class _HoldTarget extends StatefulWidget {
  const _HoldTarget({
    required this.semanticsLabel,
    required this.onHeld,
    required this.child,
    this.haptic,
    this.square = true,
  });

  final String semanticsLabel;
  final VoidCallback? onHeld;
  final Widget child;

  /// Felt when the hold completes. Null is none.
  final ChorusHaptic? haptic;

  /// A 48dp square with a progress ring; otherwise wraps [child] with a
  /// progress bar beneath it.
  final bool square;

  @override
  State<_HoldTarget> createState() => _HoldTargetState();
}

class _HoldTargetState extends State<_HoldTarget>
    with SingleTickerProviderStateMixin {
  /// The keys that hold: the ones that press any other button.
  static final Set<LogicalKeyboardKey> _holdKeys = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
  };

  /// Draws the progress only. The hold itself completes on [_timer], so it
  /// still works when the platform is not drawing frames (a background tab).
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: _holdToConfirm,
  );
  Timer? _timer;

  /// Whether the keyboard is on this control.
  bool _focused = false;

  /// The key that started the hold under way; null for a finger or a mouse.
  LogicalKeyboardKey? _key;

  /// A key hold that has lasted its 2 seconds and fires when the key is let
  /// go.
  bool _keyHeld = false;

  void _start({LogicalKeyboardKey? key}) {
    _timer?.cancel();
    _key = key;
    _keyHeld = false;
    _hold.forward(from: 0);
    _timer = Timer(_holdToConfirm, _complete);
  }

  void _complete() {
    _timer = null;
    if (!mounted) return;
    if (_key != null) {
      // A key that is still down keeps repeating, and once this screen is
      // gone the repeats go to whatever has the keyboard next: the button
      // that opened the board, which would open it again. So a key hold
      // fires when the key is let go, and the bar stays full until then.
      _keyHeld = true;
      _hold.value = 1;
      return;
    }
    _fire();
  }

  void _fire() {
    _hold.value = 0;
    ChorusHaptics.play(widget.haptic);
    widget.onHeld?.call();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (!_holdKeys.contains(key)) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      _start(key: key);
    } else if (event is KeyUpEvent && key == _key) {
      final held = _keyHeld;
      _cancel();
      if (held) _fire();
    }
    // The repeats of a held key change nothing.
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    // The Focus is outside the Semantics, which drops everything under it,
    // so a screen reader is still told that this can take the keyboard.
    return Focus(
      onFocusChange: (focused) {
        if (!focused) _cancel();
        setState(() => _focused = focused);
      },
      onKeyEvent: _onKey,
      child: Semantics(
        label: widget.semanticsLabel,
        hint: holdWithKeyboardHint,
        button: true,
        // A screen reader cannot deliver a timed raw press; its long-press
        // action stands in for the hold.
        onLongPress: widget.onHeld,
        excludeSemantics: true,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _start(),
          onPointerUp: (_) => _cancel(),
          onPointerCancel: (_) => _cancel(),
          child: AnimatedBuilder(
            animation: _hold,
            builder: (context, child) => widget.square
                ? SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_hold.value > 0)
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              value: _hold.value,
                              strokeWidth: 3,
                              color: colors.ink,
                            ),
                          ),
                        child!,
                      ],
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          child!,
                          SizedBox(
                            height: 4,
                            child: _hold.value > 0
                                ? LinearProgressIndicator(
                                    value: _hold.value,
                                    color: colors.ink,
                                    backgroundColor: colors.line,
                                    borderRadius: BorderRadius.circular(2),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
            // Always in the tree, so the control keeps its shape and size
            // whether or not the keyboard is on it.
            child: CustomPaint(
              foregroundPainter: _focused
                  ? _FocusRing(outer: colors.ink, inner: colors.surface)
                  : null,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    _key = null;
    _keyHeld = false;
    if (_hold.value > 0) _hold.value = 0;
  }
}

/// The mark on a hold control the keyboard is on: a thick ink line round
/// its edge and a thin line of the page's colour just inside it, so it shows
/// on the outlined leave pill and on the ink waiting pill alike. It is
/// painted over the control and takes no space.
class _FocusRing extends CustomPainter {
  const _FocusRing({required this.outer, required this.inner});

  final Color outer;
  final Color inner;

  @override
  void paint(Canvas canvas, Size size) {
    final edge = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.shortestSide / 2),
    );
    final line = Paint()..style = PaintingStyle.stroke;
    canvas.drawRRect(
      edge.deflate(2),
      line
        ..color = outer
        ..strokeWidth = 4,
    );
    canvas.drawRRect(
      edge.deflate(4.75),
      line
        ..color = inner
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_FocusRing oldDelegate) =>
      oldDelegate.outer != outer || oldDelegate.inner != inner;
}

/// The visible way out of the talker: a labelled control an adult holds.
class _LeavePill extends StatelessWidget {
  const _LeavePill({this.compact = false});

  /// Smaller type and padding; the words stay.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ink = ChorusColors.of(context).ink;
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
      decoration: BoxDecoration(
        border: Border.all(color: ink, width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: compact ? 16 : 18, color: ink),
          SizedBox(width: compact ? 4 : 6),
          Text(
            leaveLabel,
            maxLines: 1,
            style: ChorusType.label.copyWith(
              fontSize: compact ? 13 : null,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}
