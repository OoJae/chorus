/// A waiting word flying from the tray to the cell it was given.
library;

import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../brand/motion.dart';
import '../contracts_media.dart';
import '../widgets/tile_view.dart';

/// Draws [tile] over everything, moving from [from] to [to] (both in global
/// coordinates) on the [ChorusMotion.settle] spring, and completes when it
/// has landed and is gone.
///
/// Under reduced motion it does not travel: it fades in at [to] over
/// [ChorusMotion.reducedFade].
///
/// The flight is a picture: it takes no touches and says nothing to a
/// screen reader, which hears the placement from the editor instead.
Future<void> flyTile(
  OverlayState overlay, {
  required TileFacts tile,
  required Rect from,
  required Rect to,
  required bool reduced,
  MediaStore? media,
}) {
  final landed = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => TileFlight(
      tile: tile,
      from: from,
      to: to,
      reduced: reduced,
      media: media,
      onLanded: () {
        if (entry.mounted) entry.remove();
        entry.dispose();
        if (!landed.isCompleted) landed.complete();
      },
    ),
  );
  overlay.insert(entry);
  return landed.future;
}

/// One flight; see [flyTile].
@visibleForTesting
class TileFlight extends StatefulWidget {
  const TileFlight({
    super.key,
    required this.tile,
    required this.from,
    required this.to,
    required this.reduced,
    required this.onLanded,
    this.media,
  });

  final TileFacts tile;
  final Rect from;
  final Rect to;
  final bool reduced;
  final VoidCallback onLanded;
  final MediaStore? media;

  @override
  State<TileFlight> createState() => _TileFlightState();
}

class _TileFlightState extends State<TileFlight>
    with SingleTickerProviderStateMixin {
  // Unbounded, so the spring may carry the card a hair past the cell and
  // back, as a card dropped into place does.
  late final AnimationController _t = AnimationController.unbounded(
    vsync: this,
  );
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final TickerFuture run;
    if (widget.reduced) {
      run = _t.animateTo(
        1,
        duration: ChorusMotion.reducedFade,
        curve: Curves.linear,
      );
    } else {
      run = ChorusMotion.springTo(_t, ChorusMotion.settle, 1);
    }
    run.whenCompleteOrCancel(_land);
  }

  void _land() {
    if (_done) return;
    _done = true;
    // After this frame, so the cell it lands in is drawn before the card
    // over it goes.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLanded());
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = Material(
      type: MaterialType.transparency,
      child: TileView(tile: widget.tile, media: widget.media),
    );
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, child) {
            final t = _t.value;
            if (widget.reduced) {
              return Stack(
                children: [
                  Positioned.fromRect(
                    rect: widget.to,
                    child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                  ),
                ],
              );
            }
            return Stack(
              children: [
                Positioned.fromRect(
                  rect: Rect.lerp(widget.from, widget.to, t)!,
                  child: child!,
                ),
              ],
            );
          },
          child: card,
        ),
      ),
    );
  }
}
