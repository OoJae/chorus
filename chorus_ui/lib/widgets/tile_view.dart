/// One word on the board.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../brand/tokens.dart';
import '../contracts_media.dart';
import '../theme.dart';
import 'label_fit.dart';

/// A tile drawn as a coloured block with a large label.
///
/// Fills the space its parent gives it and never shrinks below 48dp. The label
/// scales down to fit rather than wrapping or clipping. Screen readers hear the
/// label only.
///
/// A grid passes [labelSize], the one size shared by every tile of its board
/// (see `TileLabelSizer`), so a short word is not drawn larger than a long
/// one. Scaling down is then only the fallback for a label that does not fit
/// even at the smallest size, and for the narrow strip under a picture.
///
/// With a [media] store, a tile that has a picture on this device shows it
/// above a smaller label. Until the picture arrives the tile is its label
/// alone, so a slow download never leaves a blank button.
class TileView extends StatelessWidget {
  const TileView({
    super.key,
    required this.tile,
    this.onTap,
    this.highlighted = false,
    this.dimmed = false,
    this.media,
    this.labelSize,
  });

  /// Font size of the label. Null sizes this tile by itself.
  final double? labelSize;

  final TileFacts tile;
  final VoidCallback? onTap;

  /// Draws a heavier border, e.g. for the tile just spoken or selected.
  final bool highlighted;

  /// Fades the tile, e.g. while another tile is being placed.
  final bool dimmed;

  /// Where the tile's picture comes from. Null draws the label only.
  final MediaStore? media;

  @override
  Widget build(BuildContext context) {
    final media = this.media;
    if (media == null || tile.imageHash == null) return _build(null);
    // The store notifies when the picture lands in the local cache.
    return ListenableBuilder(
      listenable: media,
      builder: (context, _) => _build(media.imageFor(tile.imageHash)),
    );
  }

  Widget _build(ImageProvider? image) {
    final background = tileColor(tile.colorKey);
    final ink = inkOn(background);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: tileLabelInk, width: highlighted ? 4 : 1.5),
    );
    final label = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        tile.label,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: labelSize ?? (image == null ? maxTileLabelSize : 22),
          fontWeight: tileLabelWeight,
          color: ink,
        ),
      ),
    );
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: tile.label,
      onTap: onTap,
      excludeSemantics: true,
      child: Opacity(
        opacity: dimmed ? 0.4 : 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Material(
            color: background,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(tileLabelPadding),
                child: image == null
                    ? Center(child: label)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image(
                                image: image,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                excludeFromSemantics: true,
                                // Bytes that will not decode: label only.
                                errorBuilder: (_, _, _) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Expanded(child: Center(child: label)),
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
