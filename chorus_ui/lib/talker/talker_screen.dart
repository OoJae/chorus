/// The child's screen: the board, the sentence strip and nothing else.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../contracts.dart';
import '../widgets/sync_chip.dart';
import '../widgets/tile_view.dart';
import 'talker_controller.dart';

/// Shown to adults when speech would need a network.
const String noOfflineVoiceMessage = 'No offline voice on this phone';

/// How long the leave control and the waiting pill must be held.
const Duration _holdToConfirm = Duration(seconds: 2);

/// Label on the control that leaves the board.
const String leaveLabel = 'Hold to leave';

/// Shown when system back is pressed: back is blocked on purpose.
const String howToLeaveMessage =
    'To leave the board, press and hold "Hold to leave" for 2 seconds.';

/// Full-screen talking board.
///
/// Every cell keeps its row and column whatever the screen size; an empty
/// cell is a blank gap. Leaving takes a 2-second hold on the leave control, which
/// calls [onExit].
class TalkerScreen extends StatefulWidget {
  const TalkerScreen({
    super.key,
    required this.store,
    required this.speech,
    required this.sync,
    this.onExit,
  });

  final BoardStore store;
  final SpeechService speech;
  final SyncStatus sync;
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
    _controller = TalkerController(store: widget.store, speech: widget.speech);
  }

  @override
  void didUpdateWidget(TalkerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store || oldWidget.speech != widget.speech) {
      _controller.dispose();
      _warmUp();
      _controller = TalkerController(
        store: widget.store,
        speech: widget.speech,
      );
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
              builder: (context, _) {
                final snapshot = _controller.snapshot;
                return Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      _SentenceStrip(controller: _controller),
                      const SizedBox(height: 4),
                      _StatusRow(
                        controller: _controller,
                        speech: widget.speech,
                        sync: widget.sync,
                        onExit: widget.onExit,
                        onAdultUpdate: _confirmAdultChanges,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: snapshot == null
                            ? const Center(
                                child: Text(
                                  'No board yet',
                                  style: TextStyle(fontSize: 24),
                                ),
                              )
                            : _BoardGrid(snapshot: snapshot, onTap: _tap),
                      ),
                    ],
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

/// The grid: equal cells, each at its own row and column.
class _BoardGrid extends StatelessWidget {
  const _BoardGrid({required this.snapshot, required this.onTap});

  final BoardSnapshot snapshot;
  final ValueChanged<TileFacts> onTap;

  @override
  Widget build(BuildContext context) {
    final board = snapshot.board;
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
                      padding: const EdgeInsets.all(3),
                      child: _cell(snapshot.cells[(row, col)]),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(TileFacts? tile) {
    if (tile == null) return const SizedBox.expand();
    return TileView(
      key: ValueKey(tile.id),
      tile: tile,
      onTap: () => onTap(tile),
    );
  }
}

/// The sentence so far, with speak, backspace and clear.
class _SentenceStrip extends StatelessWidget {
  const _SentenceStrip({required this.controller});

  final TalkerController controller;

  @override
  Widget build(BuildContext context) {
    final words = controller.strip;
    final sentence = words.map((t) => t.label).join(' ');
    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Semantics(
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
                  // Reversed so the newest word is always in view.
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        sentence,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 32,
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
          const SizedBox(width: 6),
          _StripButton(
            icon: Icons.volume_up,
            label: 'Speak',
            filled: true,
            onPressed: controller.speakStrip,
          ),
          const SizedBox(width: 6),
          _StripButton(
            icon: Icons.backspace_outlined,
            label: 'Delete last word',
            onPressed: controller.backspace,
          ),
          const SizedBox(width: 6),
          _StripButton(
            icon: Icons.clear,
            label: 'Clear',
            onPressed: controller.clearStrip,
          ),
        ],
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
      child: SizedBox(
        width: 64,
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
      ),
    );
  }
}

/// Waiting pill, the no-offline-voice warning, sync chip and the exit lock.
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.controller,
    required this.speech,
    required this.sync,
    required this.onExit,
    required this.onAdultUpdate,
  });

  final TalkerController controller;
  final SpeechService speech;
  final SyncStatus sync;
  final VoidCallback? onExit;
  final VoidCallback onAdultUpdate;

  @override
  Widget build(BuildContext context) {
    final waiting = controller.waitingCount;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          if (waiting > 0) ...[
            _WaitingPill(
              count: waiting,
              needsAdult: controller.needsAdult,
              onAdultUpdate: onAdultUpdate,
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SyncChip(sync: sync),
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
            child: const _LeavePill(),
          ),
        ],
      ),
    );
  }
}

/// "N words waiting". When an adult is needed, holding it for 2 seconds
/// offers the update.
class _WaitingPill extends StatelessWidget {
  const _WaitingPill({
    required this.count,
    required this.needsAdult,
    required this.onAdultUpdate,
  });

  final int count;
  final bool needsAdult;
  final VoidCallback onAdultUpdate;

  @override
  Widget build(BuildContext context) {
    final text = count == 1 ? '1 word waiting' : '$count words waiting';
    final pill = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
            text,
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

/// Fires [onHeld] after an unbroken 3-second press, showing progress.
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
  const _LeavePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 18, color: Colors.black),
          SizedBox(width: 6),
          Text(
            leaveLabel,
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
