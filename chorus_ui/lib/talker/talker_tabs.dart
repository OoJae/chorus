/// The board tabs on the child's screen.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../brand/haptics.dart';
import '../brand/pressable_surface.dart';
import '../brand/tokens.dart';

/// One large tab per board, like the tabs of a communication book. Shows
/// nothing when there are fewer than two places.
///
/// The tabs keep their order and size, like the tiles: a child finds a board
/// by where its tab is. [boards] are the places in order, as
/// `TalkerController.tabs` holds them; a null place is left empty, so the
/// tabs round it stay where they were. The board on show is an ink tab
/// pressed flat; the others stand up on their laminated edge and press like
/// a tile, and changing board is felt ([ChorusHaptic.tabChanged]).
///
/// Only boards and taps: the child's tabs never offer adding, renaming or
/// archiving a board.
///
/// A tab in [attentionIds] that is not the one on show wears an ink ring:
/// an adult is pointing at a word on that board. The ring is drawn over the
/// tab and takes no space.
class TalkerBoardTabs extends StatelessWidget {
  const TalkerBoardTabs({
    super.key,
    required this.boards,
    required this.selectedId,
    required this.onSelect,
    this.attentionIds = const {},
    this.axis = Axis.horizontal,
  });

  /// Height of the horizontal row of tabs.
  static const double height = 48;

  /// Width of the ring round a tab that needs attention.
  static const double ringWidth = 4;

  /// The places, in order: a board, or null for an empty place. Drawn as
  /// given, archived or not; the controller decides what is in them.
  final List<BoardFacts?> boards;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  /// Ids of the boards to draw attention to.
  final Set<String> attentionIds;

  /// Horizontal is a 48dp row of tabs side by side. Vertical stacks them in
  /// a column that fills the height it is given, for a short, wide screen
  /// where a row of tabs would take height from the board.
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    if (boards.length < 2) return const SizedBox.shrink();
    final vertical = axis == Axis.vertical;
    const gap = ChorusSpace.targetGap;
    final tabs = <Widget>[
      for (final (i, board) in boards.indexed) ...[
        if (i > 0) const SizedBox(width: gap, height: gap),
        Expanded(
          child: board == null
              // A board left this place: it stays empty, so no tab moves.
              ? const SizedBox.shrink()
              : _Tab(
                  key: ValueKey(board.id),
                  label: board.name,
                  selected: board.id == selectedId,
                  attention:
                      board.id != selectedId && attentionIds.contains(board.id),
                  onTap: () {
                    ChorusHaptics.tabChanged();
                    onSelect(board.id);
                  },
                ),
        ),
      ],
    ];
    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: tabs,
      );
    }
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: tabs,
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.label,
    required this.selected,
    required this.attention,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool attention;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    const radius = ChorusSpace.buttonRadius;
    Widget text(Color color) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      // Large text shrinks to fit rather than being cut.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: ChorusType.label.copyWith(
            fontSize: 18,
            height: 24 / 18,
            letterSpacing: 0.02 * 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );

    // The board on show: pressed flat onto a thin edge, as a held-down
    // button is.
    final Widget face = selected
        ? Padding(
            padding: const EdgeInsets.only(top: ChorusSpace.pressSink),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: edgeFor(colors.ink),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: ChorusSpace.edgePressed),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.ink,
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: Center(child: text(colors.surface)),
                ),
              ),
            ),
          )
        : PressableSurface(
            onTap: onTap,
            color: colors.line,
            foregroundColor: colors.ink,
            borderRadius: radius,
            child: SizedBox.expand(child: Center(child: text(colors.ink))),
          );

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: attention
          ? 'Board: $label. An adult is pointing at a word here'
          : 'Board: $label',
      onTap: selected ? null : onTap,
      excludeSemantics: true,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: colors.ink.withValues(alpha: attention ? 1 : 0),
            width: TalkerBoardTabs.ringWidth,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: ChorusSpace.minTarget,
            minHeight: ChorusSpace.minTarget,
          ),
          child: face,
        ),
      ),
    );
  }
}
