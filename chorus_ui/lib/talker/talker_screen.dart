/// The child's screen: the board, the sentence strip and nothing else.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../contracts.dart';
import '../contracts_live.dart';
import '../contracts_media.dart';
import '../widgets/board_tabs.dart';
import '../widgets/label_fit.dart';
import '../widgets/sync_chip.dart';
import '../widgets/tile_view.dart';
import 'talker_controller.dart';

/// Shown to adults when speech would need a network.
const String noOfflineVoiceMessage = 'No offline voice on this phone';

/// Shown on the child's board for as long as spoken sentences are shared.
const String sharingSaidMessage = 'Sharing what is said';

/// Shown beside the status chip for as long as this board is joined to the
/// circle's live session.
const String liveConnectedMessage = 'Connected to the circle';

/// How long the leave control and the waiting pill must be held.
const Duration _holdToConfirm = Duration(seconds: 2);

/// Label on the control that leaves the board.
const String leaveLabel = 'Hold to leave';

/// Shown when system back is pressed: back is blocked on purpose.
const String howToLeaveMessage =
    'To leave the board, press and hold "Hold to leave" for 2 seconds.';

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
/// Every cell keeps its row and column whatever the screen size; an empty
/// cell is a blank gap. Every label on a board is drawn at one size. The
/// strip, its buttons and the status marks are rearranged for a phone held
/// upright or on its side; see [TalkerLayout]. Leaving takes a 2-second hold on the leave control,
/// which calls [onExit].
///
/// With a [live] session, a tile an adult taps in model mode on another
/// device glows here, and while a guardian has sharing on a bar says so; a
/// tap on the bar turns sharing off. While the session is connected a small
/// mark in the status row says so.
///
/// With a [media] store a tile shows its family photo once it is on this
/// device; with a [speaker] a single tapped word plays its recorded clip.
class TalkerScreen extends StatefulWidget {
  const TalkerScreen({
    super.key,
    required this.store,
    required this.speech,
    required this.sync,
    this.live,
    this.media,
    this.speaker,
    this.onExit,
  });

  final BoardStore store;
  final SpeechService speech;
  final SyncStatus sync;

  /// The circle's live session, or null to run the board without one.
  final LiveSession? live;

  /// The circle's pictures and clips, or null to show labels only.
  final MediaStore? media;

  /// Plays a tile's recorded clip; null speaks every word with [speech].
  final TileSpeaker? speaker;
  final VoidCallback? onExit;

  @override
  State<TalkerScreen> createState() => _TalkerScreenState();
}

class _TalkerScreenState extends State<TalkerScreen> {
  late TalkerController _controller;

  @override
  void initState() {
    super.initState();
    _warmUp();
    _controller = _newController();
  }

  TalkerController _newController() => TalkerController(
    store: widget.store,
    speech: widget.speech,
    speaker: widget.speaker,
    live: widget.live,
  );

  @override
  void didUpdateWidget(TalkerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store ||
        oldWidget.speech != widget.speech ||
        oldWidget.speaker != widget.speaker ||
        oldWidget.live != widget.live) {
      _controller.dispose();
      _warmUp();
      _controller = _newController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// A failed warm-up only makes the first word slower.
  void _warmUp() {
    widget.speech.warmUp().catchError((Object _) {});
  }

  void _tap(TileFacts tile) {
    HapticFeedback.selectionClick();
    _controller.tapTile(tile);
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
    if (ok == true && mounted) _controller.applyAdultChanges();
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
        backgroundColor: Colors.white,
        body: SafeArea(
          // Any finger anywhere counts as activity, whatever handles it.
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _controller.touchDown(),
            onPointerUp: (_) => _controller.touchUp(),
            onPointerCancel: (_) => _controller.touchUp(),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => LayoutBuilder(
                builder: (context, box) => Padding(
                  padding: const EdgeInsets.all(6),
                  child: _layout(talkerLayoutFor(box.biggest)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _layout(TalkerLayout layout) {
    final controller = _controller;
    final snapshot = controller.snapshot;
    const gap = SizedBox(height: 4);
    final grid = snapshot == null
        ? const Center(
            child: Text('No board yet', style: TextStyle(fontSize: 24)),
          )
        : _BoardGrid(
            snapshot: snapshot,
            media: widget.media,
            pulsing: controller.pulsing,
            onTap: _tap,
          );
    Widget status() => _StatusRow(
      controller: controller,
      speech: widget.speech,
      sync: widget.sync,
      onExit: widget.onExit,
      onAdultUpdate: _confirmAdultChanges,
      layout: layout,
    );
    Widget tabs(Axis axis) => BoardTabs(
      boards: controller.boards,
      selectedId: controller.boardId,
      onSelect: controller.showBoard,
      attentionIds: controller.pulsingBoardIds,
      axis: axis,
    );
    final sharing = controller.sharingSaid
        ? [_SharingBar(onStop: controller.stopSharingSaid), gap]
        : const <Widget>[];

    switch (layout) {
      case TalkerLayout.roomy:
        return Column(
          children: [
            SizedBox(
              height: 72,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _SentenceBox(controller: controller)),
                  ..._stripButtons(controller, width: 64),
                ],
              ),
            ),
            gap,
            status(),
            gap,
            tabs(Axis.horizontal),
            gap,
            ...sharing,
            Expanded(child: grid),
          ],
        );
      case TalkerLayout.narrow:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The whole width for the sentence.
            SizedBox(height: 64, child: _SentenceBox(controller: controller)),
            gap,
            SizedBox(
              height: 52,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _stripButtons(controller, leadingGap: false),
              ),
            ),
            gap,
            status(),
            gap,
            tabs(Axis.horizontal),
            gap,
            ...sharing,
            Expanded(child: grid),
          ],
        );
      case TalkerLayout.short:
        final manyBoards = liveBoards(controller.boards).length > 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // One row for everything that is not the board.
            SizedBox(
              height: 52,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SentenceBox(controller: controller, fontSize: 26),
                  ),
                  ..._stripButtons(controller, width: 52),
                  const SizedBox(width: 6),
                  status(),
                ],
              ),
            ),
            gap,
            ...sharing,
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Beside the grid, where a row of tabs would cost height.
                  if (manyBoards) ...[
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
  TalkerController controller, {
  double? width,
  bool leadingGap = true,
}) {
  Widget sized(Widget button) => width == null
      ? Expanded(child: button)
      : SizedBox(width: width, child: button);
  return [
    if (leadingGap) const SizedBox(width: 6),
    sized(
      _StripButton(
        icon: Icons.volume_up,
        label: 'Speak',
        filled: true,
        onPressed: controller.speakStrip,
      ),
    ),
    const SizedBox(width: 6),
    sized(
      _StripButton(
        icon: Icons.backspace_outlined,
        label: 'Delete last word',
        onPressed: controller.backspace,
      ),
    ),
    const SizedBox(width: 6),
    sized(
      _StripButton(
        icon: Icons.clear,
        label: 'Clear',
        onPressed: controller.clearStrip,
      ),
    ),
  ];
}

/// The grid: equal cells, each at its own row and column, every label at
/// the one size the board's longest label allows.
class _BoardGrid extends StatefulWidget {
  const _BoardGrid({
    required this.snapshot,
    required this.pulsing,
    required this.onTap,
    this.media,
  });

  final BoardSnapshot snapshot;
  final MediaStore? media;

  /// Ids of the tiles an adult is pointing at.
  final Set<String> pulsing;
  final ValueChanged<TileFacts> onTap;

  @override
  State<_BoardGrid> createState() => _BoardGridState();
}

class _BoardGridState extends State<_BoardGrid> {
  /// Space round each cell.
  static const double _gap = 3;

  /// Remembers the size until the layout or the labels change.
  final TileLabelSizer _sizer = TileLabelSizer();

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final board = snapshot.board;
    if (board.rows <= 0 || board.cols <= 0) return const SizedBox.expand();
    return LayoutBuilder(
      builder: (context, box) {
        final labelSize = _sizer.sizeFor(
          labels: snapshot.cells.values.map((tile) => tile.label),
          tile: Size(
            box.maxWidth / board.cols - 2 * _gap,
            box.maxHeight / board.rows - 2 * _gap,
          ),
          style: DefaultTextStyle.of(context).style,
          scaler: MediaQuery.textScalerOf(context),
          direction: Directionality.of(context),
        );
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
                          padding: const EdgeInsets.all(_gap),
                          child: _cell(snapshot.cells[(row, col)], labelSize),
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

  Widget _cell(TileFacts? tile, double labelSize) {
    if (tile == null) return const SizedBox.expand();
    final glowing = widget.pulsing.contains(tile.id);
    // The glow wraps the tile and is always in the tree, so a tile keeps
    // its state and its place when a pulse starts or ends.
    return _Glow(
      key: ValueKey(tile.id),
      active: glowing,
      child: TileView(
        tile: tile,
        media: widget.media,
        highlighted: glowing,
        labelSize: labelSize,
        onTap: () => widget.onTap(tile),
      ),
    );
  }
}

/// A ring that breathes around a tile while an adult is pointing at it.
///
/// It is drawn over the tile and takes no space, so nothing on the board
/// moves. With animations turned off on the device the ring is steady.
class _Glow extends StatefulWidget {
  const _Glow({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  static const Color _ring = Color(0xFF1F4E9C);

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _ring.withValues(alpha: strength),
              width: 6,
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
/// they are. A tap stops it; only a guardian can start it again, elsewhere.
class _SharingBar extends StatelessWidget {
  const _SharingBar({required this.onStop});

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$sharingSaidMessage. Tap to stop',
      excludeSemantics: true,
      onTap: onStop,
      child: SizedBox(
        height: 48,
        child: Material(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onStop,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.podcasts, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sharingSaidMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'Tap to stop',
                    maxLines: 1,
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
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
/// in view.
class _SentenceBox extends StatelessWidget {
  const _SentenceBox({required this.controller, this.fontSize = 32});

  final TalkerController controller;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    const side = 12.0;
    final words = controller.strip;
    final sentence = words.map((t) => t.label).join(' ');
    return Semantics(
      button: true,
      label: words.isEmpty ? 'Sentence, empty' : 'Sentence: $sentence',
      excludeSemantics: true,
      onTap: controller.speakStrip,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: controller.speakStrip,
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Reversed so the newest word of a long sentence is in view.
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: side),
              child: ConstrainedBox(
                // At least the width on show, so a short sentence sits at
                // the left and is not pushed to the right by the reversal.
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
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StripButton extends StatelessWidget {
  const _StripButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: filled ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          child: Center(
            child: Icon(
              icon,
              size: 32,
              color: filled ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

/// Waiting pill, the no-offline-voice warning, sync chip and the exit lock.
///
/// Roomy: a full row with the chip in words. Narrow: a full row with the
/// chip as an icon and shorter pills. Short: the same compact marks, only as
/// wide as they need, to sit at the end of the strip's row.
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.controller,
    required this.speech,
    required this.sync,
    required this.onExit,
    required this.onAdultUpdate,
    required this.layout,
  });

  final TalkerController controller;
  final SpeechService speech;
  final SyncStatus sync;
  final VoidCallback? onExit;
  final VoidCallback onAdultUpdate;
  final TalkerLayout layout;

  @override
  Widget build(BuildContext context) {
    final waiting = controller.waitingCount;
    final compact = layout != TalkerLayout.roomy;
    final pill = waiting > 0
        ? _WaitingPill(
            count: waiting,
            needsAdult: controller.needsAdult,
            onAdultUpdate: onAdultUpdate,
            compact: compact,
          )
        : null;
    final marks = [
      // Anything live is shown: this board is joined to the circle and
      // the other adults can see that it is here.
      if (controller.liveConnected)
        const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Tooltip(
            message: liveConnectedMessage,
            child: Icon(
              Icons.sensors,
              color: Colors.black,
              semanticLabel: liveConnectedMessage,
            ),
          ),
        ),
      // For the adult: without an offline voice the board is silent
      // whenever there is no network.
      ValueListenableBuilder<bool>(
        valueListenable: speech.offlineVoiceReady,
        builder: (context, ready, _) => ready
            ? const SizedBox.shrink()
            : const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Tooltip(
                  message: noOfflineVoiceMessage,
                  child: Icon(
                    Icons.volume_off,
                    color: Colors.black,
                    semanticLabel: noOfflineVoiceMessage,
                  ),
                ),
              ),
      ),
      const SizedBox(width: 6),
      _HoldTarget(
        semanticsLabel: 'Hold for 2 seconds to leave the board',
        onHeld: onExit,
        square: false,
        child: _LeavePill(compact: compact),
      ),
    ];
    switch (layout) {
      case TalkerLayout.roomy:
        return SizedBox(
          height: 48,
          child: Row(
            children: [
              if (pill != null) ...[pill, const SizedBox(width: 6)],
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SyncChip(sync: sync),
                ),
              ),
              ...marks,
            ],
          ),
        );
      case TalkerLayout.narrow:
        return SizedBox(
          height: 48,
          child: Row(
            children: [
              // Shrinks rather than overflows on the narrowest phones.
              Expanded(
                child: pill == null
                    ? const SizedBox.shrink()
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: pill,
                      ),
              ),
              const SizedBox(width: 6),
              SyncChip(sync: sync, compact: true),
              ...marks,
            ],
          ),
        );
      case TalkerLayout.short:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pill != null) ...[pill, const SizedBox(width: 6)],
            SyncChip(sync: sync, compact: true),
            ...marks,
          ],
        );
    }
  }
}

/// "N words waiting". When an adult is needed, holding it for 2 seconds
/// offers the update.
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
    final pill = Container(
      height: 36,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (needsAdult) ...[
            const Icon(Icons.supervisor_account, size: 18, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            compact ? '$count waiting' : text,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
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
class _HoldTarget extends StatefulWidget {
  const _HoldTarget({
    required this.semanticsLabel,
    required this.onHeld,
    required this.child,
    this.square = true,
  });

  final String semanticsLabel;
  final VoidCallback? onHeld;
  final Widget child;

  /// A 48dp square with a progress ring; otherwise wraps [child] with a
  /// progress bar beneath it.
  final bool square;

  @override
  State<_HoldTarget> createState() => _HoldTargetState();
}

class _HoldTargetState extends State<_HoldTarget>
    with SingleTickerProviderStateMixin {
  /// Draws the progress only. The hold itself completes on [_timer], so it
  /// still works when the platform is not drawing frames (a background tab).
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: _holdToConfirm,
  );
  Timer? _timer;

  void _start() {
    _timer?.cancel();
    _hold.forward(from: 0);
    _timer = Timer(_holdToConfirm, _complete);
  }

  void _complete() {
    _timer = null;
    if (!mounted) return;
    _hold.value = 0;
    HapticFeedback.mediumImpact();
    widget.onHeld?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
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
                            color: Colors.black,
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
                                  color: Colors.black,
                                  backgroundColor: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
          child: widget.child,
        ),
      ),
    );
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    if (_hold.value > 0) _hold.value = 0;
  }
}

/// The visible way out of the talker: a labelled control an adult holds.
class _LeavePill extends StatelessWidget {
  const _LeavePill({this.compact = false});

  /// Smaller type and padding; the words stay.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: compact ? 16 : 18,
            color: Colors.black,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            leaveLabel,
            maxLines: 1,
            style: TextStyle(
              fontSize: compact ? 13 : null,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
