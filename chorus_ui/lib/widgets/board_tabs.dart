/// Tabs for moving between a circle's boards.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

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
class BoardTabs extends StatelessWidget {
  const BoardTabs({
    super.key,
    required this.boards,
    required this.selectedId,
    required this.onSelect,
  });

  /// Every board of the circle; archived ones are left out here.
  final List<BoardFacts> boards;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final live = liveBoards(boards);
    if (live.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          for (final board in live)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _Tab(
                  label: board.name,
                  selected: board.id == selectedId,
                  onTap: () => onSelect(board.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Board: $label',
      excludeSemantics: true,
      child: Material(
        color: selected ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: selected ? null : onTap,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
