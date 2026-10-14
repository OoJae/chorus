/// "Needs a home" in plain words, for a word the sync parked because two
/// adults filled the same spot while offline: both words side by side, who
/// put each there and when, and what can be done. No choice ever moves the
/// word that holds the spot.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../activity/activity_text.dart' show clockOf;
import '../brand/tokens.dart';
import '../contracts_media.dart';
import '../widgets/tile_view.dart';

/// Gives a waiting word the next free spot.
const String placeNextLabel = 'Place in next free spot';

/// Lets the adult pick an empty spot.
const String chooseNewSpotLabel = 'Choose a new spot';

/// Archives the waiting word; it can be brought back from "What changed".
const String putAwayLabel = 'Put it away';

/// Caption over the word that holds the spot.
const String holdsSpotCaption = 'In the spot';

/// Caption over the word that is waiting.
const String waitingCaption = 'Waiting';

/// What happened, in a sentence for a parent. Never says which word "won":
/// both are kept.
String bothPutAWordText(TileFacts waiting, TileFacts? holder) {
  String nameOf(TileFacts tile) =>
      tile.createdByName.trim().isEmpty ? 'Someone' : tile.createdByName.trim();
  if (holder == null) {
    return '${nameOf(waiting)} put this word in a spot while offline, and '
        'another word got there first. Nothing was lost.';
  }
  final a = nameOf(holder);
  final b = nameOf(waiting);
  if (a == b) {
    return '$a put two words in this spot from two devices while offline. '
        'Nothing was lost.';
  }
  return '$a and $b both put a word in this spot while offline. Nothing was '
      'lost.';
}

/// "Mum · 18:04", or the name alone when the time is not known.
String byAndWhen(TileFacts tile) {
  final name = tile.createdByName.trim().isEmpty
      ? 'Someone'
      : tile.createdByName.trim();
  final at = tile.createdAt;
  return at == null ? name : '$name · ${clockOf(at)}';
}

/// The card of a contested tray entry.
class ContestedTrayCard extends StatefulWidget {
  const ContestedTrayCard({
    super.key,
    required this.waiting,
    required this.holder,
    this.media,
    this.onPlaceNext,
    this.onChoose,
    this.onRemove,
  });

  /// The word the sync parked.
  final TileFacts waiting;

  /// The word that holds the spot now, or null when the spot has since been
  /// freed.
  final TileFacts? holder;

  final MediaStore? media;

  /// Each is given where the waiting word is on screen, to fly from.
  final ValueChanged<Rect?>? onPlaceNext;
  final ValueChanged<Rect?>? onChoose;
  final VoidCallback? onRemove;

  @override
  State<ContestedTrayCard> createState() => _ContestedTrayCardState();
}

class _ContestedTrayCardState extends State<ContestedTrayCard> {
  final GlobalKey _waitingKey = GlobalKey();

  Rect? _waitingRect() {
    final box = _waitingKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final waiting = widget.waiting;
    final holder = widget.holder;
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
                  if (holder != null) ...[
                    Expanded(
                      child: _Side(
                        caption: holdsSpotCaption,
                        tile: holder,
                        media: widget.media,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: _Side(
                      caption: waitingCaption,
                      tile: waiting,
                      media: widget.media,
                      previewKey: _waitingKey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: onPlaceNext == null
                    ? null
                    : () => onPlaceNext(_waitingRect()),
                child: const Text(placeNextLabel),
              ),
              const SizedBox(height: 8),
              Text(
                bothPutAWordText(waiting, holder),
                style: ChorusType.body.copyWith(color: colors.ink),
              ),
              const SizedBox(height: ChorusSpace.targetGap),
              Wrap(
                spacing: ChorusSpace.targetGap,
                runSpacing: ChorusSpace.targetGap,
                children: [
                  OutlinedButton(
                    onPressed: onChoose == null
                        ? null
                        : () => onChoose(_waitingRect()),
                    child: const Text(chooseNewSpotLabel),
                  ),
                  TextButton(
                    onPressed: widget.onRemove,
                    child: const Text(putAwayLabel),
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

/// One of the two words: its caption, its tile and who put it there when.
class _Side extends StatelessWidget {
  const _Side({
    required this.caption,
    required this.tile,
    this.media,
    this.previewKey,
  });

  final String caption;
  final TileFacts tile;
  final MediaStore? media;
  final Key? previewKey;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption,
            style: ChorusType.status.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: 4),
          SizedBox(
            key: previewKey,
            width: 72,
            height: 56,
            child: ExcludeSemantics(
              child: TileView(tile: tile, media: media),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            byAndWhen(tile),
            style: ChorusType.body.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}
