/// One word on the board: a laminated tile.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../brand/pressable_surface.dart';
import '../brand/symbols.dart';
import '../brand/tokens.dart';
import '../contracts_media.dart';
import 'label_fit.dart';

/// Whether [tile] shows a picture: its own photo (with a [media] store to
/// fetch it from), or else a symbol for its word.
///
/// A photo counts before it reaches this device, so the board's label size
/// allows for it from the start and does not change when it lands.
bool tileHasPicture(TileFacts tile, {MediaStore? media}) =>
    (media != null && tile.imageHash != null) ||
    symbolAssetFor(tile.label) != null;

/// Whether any of [tiles] shows a picture: what a grid passes to
/// `TileLabelSizer.sizeFor` as `pictures`, so that a word with a picture and
/// a word without one get the same label size.
bool tilesHavePictures(Iterable<TileFacts> tiles, {MediaStore? media}) =>
    tiles.any((tile) => tileHasPicture(tile, media: media));

/// A tile drawn as laminated card: the word's family colour from the colour
/// key, a darker 3 dp edge along the bottom, and the label in tile ink.
///
/// A picture sits above the label, or beside it on a wide tile: the tile's
/// own photo once it is on this device, otherwise the symbol for its word
/// (see `symbolImageFor`). A word with no picture is its label alone,
/// centred, at the same size as its neighbours' labels.
///
/// With [onTap] it presses like a card on Velcro: it sinks 2 dp on the press
/// spring and back, with [haptic] felt on each tap (the child's board passes
/// [ChorusHaptic.wordTapped]). Enter and Space press it too. Without
/// [onTap] it is a picture of the word, not a button.
///
/// Fills the space its parent gives it and never shrinks below 48 dp. The
/// label scales down to fit rather than wrapping or clipping. Screen readers
/// hear the label only.
///
/// A grid passes [labelSize], the one size shared by every tile of its board
/// (see `TileLabelSizer`), so a short word is not drawn larger than a long
/// one. Scaling down is then only the fallback for a label that does not fit
/// even at the smallest size.
class TileView extends StatelessWidget {
  const TileView({
    super.key,
    required this.tile,
    this.onTap,
    this.highlighted = false,
    this.dimmed = false,
    this.media,
    this.labelSize,
    this.haptic,
    this.pictures,
    this.symbolLabel,
    this.semanticLabel,
  });

  /// The word whose symbol is drawn when [tile]'s label is not it, e.g.
  /// while the word shows in the circle's second language. Null draws the
  /// symbol for [tile]'s label.
  final String? symbolLabel;

  /// What a screen reader says for the tile. Null is its label.
  final String? semanticLabel;

  /// Font size of the label. Null sizes this tile by itself.
  final double? labelSize;

  /// Whether the board this tile is on has pictures (see
  /// [tilesHavePictures]), as told to `TileLabelSizer.sizeFor`. Then this
  /// tile's label keeps to the room a picture would leave it, even with no
  /// picture of its own, so that where large text has to be drawn smaller
  /// every label on the board is drawn smaller alike. Null is this tile's
  /// own answer.
  final bool? pictures;

  final TileFacts tile;
  final VoidCallback? onTap;

  /// Draws an ink outline round the face, e.g. for the tile an adult is
  /// pointing at or the one selected.
  final bool highlighted;

  /// Fades the tile, e.g. while another tile is being placed.
  final bool dimmed;

  /// Where the tile's photo comes from. Null draws its symbol, if any.
  final MediaStore? media;

  /// Felt on each tap. Null, the default, is none.
  final ChorusHaptic? haptic;

  /// The tile's own photo, for tests.
  @visibleForTesting
  static const Key photoKey = ValueKey('TileView.photo');

  /// The symbol for the tile's word, for tests.
  @visibleForTesting
  static const Key symbolKey = ValueKey('TileView.symbol');

  /// The outline drawn while [highlighted], for tests.
  @visibleForTesting
  static const Key highlightKey = ValueKey('TileView.highlight');

  @override
  Widget build(BuildContext context) {
    final media = this.media;
    if (media == null || tile.imageHash == null) return _build(context, null);
    // The store notifies when the picture lands in the local cache.
    return ListenableBuilder(
      listenable: media,
      builder: (context, _) => _build(context, media.imageFor(tile.imageHash)),
    );
  }

  Widget _build(BuildContext context, ImageProvider? photo) {
    final family = TileFamily.forKey(tile.colorKey);
    final colors = family.colorsFor(Theme.of(context).brightness);
    final symbol = photo == null
        ? symbolImageFor(symbolLabel ?? tile.label)
        : null;
    final picture = photo ?? symbol;
    // The label keeps to the room a picture leaves whenever the board has
    // pictures, the same room it was sized for.
    final labelRoom =
        picture != null || (pictures ?? tileHasPicture(tile, media: media));

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: ChorusSpace.minTarget,
        minHeight: ChorusSpace.minTarget,
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final bounded = box.hasBoundedWidth && box.hasBoundedHeight;
          final size = bounded
              ? box.biggest
              : const Size.square(ChorusSpace.minTarget * 2);
          final radius = ChorusSpace.tileRadiusFor(size.shortestSide);
          final share = pictureLabelShareFor(MediaQuery.textScalerOf(context));
          Widget content = _TileContent(
            label: tile.label,
            labelSize: labelSize ?? maxTileLabelSize,
            layout: TileLayout(
              size,
              picture: picture != null,
              labelShare: share,
            ),
            labelBox: TileLayout(
              size,
              picture: labelRoom,
              labelShare: share,
            ).labelBox,
            picture: picture,
            isPhoto: photo != null,
          );
          content = bounded
              ? SizedBox.expand(child: content)
              : SizedBox.fromSize(size: size, child: content);

          Widget face;
          final onTap = this.onTap;
          if (onTap != null) {
            face = PressableSurface(
              onTap: onTap,
              semanticLabel: semanticLabel ?? tile.label,
              color: colors.fill,
              edgeColor: colors.edge,
              foregroundColor: tileLabelInk,
              borderRadius: radius,
              haptic: haptic,
              child: content,
            );
          } else {
            face = Semantics(
              container: true,
              label: tile.label,
              excludeSemantics: true,
              child: _StillTile(colors: colors, radius: radius, child: content),
            );
          }
          // The outline is laid over the face, never round it, and the face
          // keeps its place in the tree, so a press under way survives the
          // outline coming and going.
          return Opacity(
            opacity: dimmed ? 0.4 : 1,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                face,
                if (highlighted)
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    bottom: ChorusSpace.edge,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: TileView.highlightKey,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(color: tileLabelInk, width: 3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A tile that is not a button: the same face and edge, never pressed.
class _StillTile extends StatelessWidget {
  const _StillTile({
    required this.colors,
    required this.radius,
    required this.child,
  });

  final TileColors colors;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final corner = BorderRadius.circular(radius);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          top: ChorusSpace.edge,
          child: DecoratedBox(
            decoration: BoxDecoration(color: colors.edge, borderRadius: corner),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: ChorusSpace.edge),
          child: DecoratedBox(
            decoration: BoxDecoration(color: colors.fill, borderRadius: corner),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// The label, with the picture above or beside it when there is one.
class _TileContent extends StatelessWidget {
  const _TileContent({
    required this.label,
    required this.labelSize,
    required this.layout,
    required this.labelBox,
    required this.picture,
    required this.isPhoto,
  });

  final String label;
  final double labelSize;
  final TileLayout layout;

  /// The most room the label may take: see [TileView.pictures].
  final Size labelBox;
  final ImageProvider? picture;
  final bool isPhoto;

  @override
  Widget build(BuildContext context) {
    final box = labelBox;
    // Not inherited, so it is drawn exactly as TileLabelSizer measured it,
    // whatever text style is around the grid.
    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      textAlign: TextAlign.center,
      style: ChorusType.tileLabel(
        labelSize,
      ).copyWith(color: tileLabelInk, inherit: false),
    );
    final fitted = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: box.width, maxHeight: box.height),
      child: FittedBox(fit: BoxFit.scaleDown, child: text),
    );

    final picture = this.picture;
    final pictureLayout = layout.pictureLayout;
    Widget content;
    if (picture == null || pictureLayout == null) {
      content = Center(child: fitted);
    } else {
      final image = _Picture(image: picture, isPhoto: isPhoto);
      content = switch (pictureLayout) {
        TilePictureLayout.above => Column(
          children: [
            Expanded(
              child: Center(child: AspectRatio(aspectRatio: 1, child: image)),
            ),
            const SizedBox(height: tilePictureGap),
            fitted,
          ],
        ),
        TilePictureLayout.beside => Row(
          children: [
            SizedBox.square(dimension: layout.besideSide, child: image),
            const SizedBox(width: tilePictureGap),
            Expanded(child: Center(child: fitted)),
          ],
        ),
      };
    }
    return Padding(padding: EdgeInsets.all(layout.padding), child: content);
  }
}

class _Picture extends StatelessWidget {
  const _Picture({required this.image, required this.isPhoto});

  final ImageProvider image;
  final bool isPhoto;

  @override
  Widget build(BuildContext context) {
    final drawn = Image(
      key: isPhoto ? TileView.photoKey : TileView.symbolKey,
      image: image,
      fit: isPhoto ? BoxFit.cover : BoxFit.contain,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      // Bytes that will not decode: the label alone.
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    if (!isPhoto) return drawn;
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: drawn);
  }
}
