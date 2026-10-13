/// One word on the board.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// A tile drawn as a coloured block with a large label.
///
/// Fills the space its parent gives it and never shrinks below 48dp. The label
/// scales down to fit rather than wrapping or clipping. Screen readers hear the
/// label only.
class TileView extends StatelessWidget {
  const TileView({
    super.key,
    required this.tile,
    this.onTap,
    this.highlighted = false,
    this.dimmed = false,
  });

  final TileFacts tile;
  final VoidCallback? onTap;

  /// Draws a heavier border, e.g. for the tile just spoken or selected.
  final bool highlighted;

  /// Fades the tile, e.g. while another tile is being placed.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final background = tileColor(tile.colorKey);
    final ink = inkOn(background);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.black, width: highlighted ? 4 : 1.5),
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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tile.label,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
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
