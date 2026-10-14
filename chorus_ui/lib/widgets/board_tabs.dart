/// Tabs for moving between a circle's boards.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../brand/tokens.dart';

/// Boards still in use, the home board first, then oldest first as given.
List<BoardFacts> liveBoards(Iterable<BoardFacts> boards) {
  final live = boards.where((board) => !board.archived).toList();
  return [
    ...live.where((board) => board.isHome),
    ...live.where((board) => !board.isHome),
  ];
}

/// One large tab per board. Shows nothing when there is only one board.
///
/// The tabs keep their order and size, like the tiles: a child finds a board
/// by where its tab is.
///
/// A tab in [attentionIds] that is not the one on show wears a ring: an adult
/// is pointing at a word on that board. The ring is drawn over the tab and
/// takes no space.
class BoardTabs extends StatelessWidget {
  const BoardTabs({
    super.key,
    required this.boards,
    required this.selectedId,
    required this.onSelect,
    this.attentionIds = const {},
    this.axis = Axis.horizontal,
  });

  /// Colour of the ring, the same as the glow round a pointed-at tile.
  static const Color attentionColor = Color(0xFF1F4E9C);

  /// Height of the horizontal row of tabs.
  static const double height = 48;

  /// Every board of the circle; archived ones are left out here.
  final List<BoardFacts> boards;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  /// Ids of the boards to draw attention to.
  final Set<String> attentionIds;

  /// Horizontal is a 48dp row of tabs side by side. Vertical stacks them in
  /// a column that fills the height it is given, for a short, wide screen
  /// where a row of tabs would take height from the board.
  final Axis axis;

  /// Whether tabs are drawn for [boards]: only when two or more are in use.
  static bool showFor(Iterable<BoardFacts> boards) =>
      liveBoards(boards).length > 1;

  @override
  Widget build(BuildContext context) {
    final live = liveBoards(boards);
    if (!showFor(live)) return const SizedBox.shrink();
    final vertical = axis == Axis.vertical;
    final tabs = [
      for (final board in live)
        Expanded(
          child: Padding(
            padding: vertical
                ? const EdgeInsets.symmetric(vertical: 3)
                : const EdgeInsets.symmetric(horizontal: 2),
            child: _Tab(
              label: board.name,
              selected: board.id == selectedId,
              attention:
                  board.id != selectedId && attentionIds.contains(board.id),
              onTap: () => onSelect(board.id),
            ),
          ),
        ),
    ];
    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: tabs,
      );
    }
    return SizedBox(
      height: height,
      child: Row(children: tabs),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
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
    return Semantics(
      button: true,
      selected: selected,
      label: attention
          ? 'Board: $label. An adult is pointing at a word here'
          : 'Board: $label',
      excludeSemantics: true,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: attention
                ? BoardTabs.attentionColor
                : BoardTabs.attentionColor.withValues(alpha: 0),
            width: 4,
          ),
        ),
        child: Material(
          color: selected ? colors.ink : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: colors.ink, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: selected ? null : onTap,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: selected ? colors.surface : colors.ink,
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
