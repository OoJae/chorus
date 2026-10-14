/// Tabs for moving between a circle's boards.
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../brand/haptics.dart';
import '../brand/motion.dart';
import '../brand/pressable_surface.dart';
import '../brand/tokens.dart';

/// Boards still in use, the home board first, then oldest first as given.
List<BoardFacts> liveBoards(Iterable<BoardFacts> boards) {
  final live = boards.where((board) => !board.archived).toList();
  return [
    ...live.where((board) => board.isHome),
    ...live.where((board) => !board.isHome),
  ];
}

/// One laminated tab per board, like the tabs of a communication book.
///
/// The tabs keep their order and their size, like the tiles: a child finds a
/// board by where its tab is. A tab's size comes from the room the row has,
/// never from how many boards there are, so adding a board adds a tab at the
/// end and moves nothing. When there are more tabs than fit, the row scrolls
/// sideways (or down, for [Axis.vertical]) and shows a scroll bar.
///
/// The child's board passes neither [onAdd] nor [onLongPress]: its tabs only
/// switch boards. The editor passes both: a "+" tab after the last one adds a
/// board, and a long press (or a right click) on a tab offers to rename or
/// archive it. A screen reader hears the long press as an action of the tab.
///
/// A tab in [attentionIds] that is not the one on show wears a ring: an adult
/// is pointing at a word on that board. The ring is drawn over the tab and
/// takes no space.
class BoardTabs extends StatefulWidget {
  const BoardTabs({
    super.key,
    required this.boards,
    required this.selectedId,
    required this.onSelect,
    this.attentionIds = const {},
    this.axis = Axis.horizontal,
    this.onAdd,
    this.onLongPress,
  });

  /// Colour of the ring on light card: ink, as on the child's tabs and the
  /// glow round a pointed-at tile. Colour on a Chorus screen belongs to
  /// words.
  static final Color attentionColor = ChorusColors.light.ink;

  /// Colour of the ring on slate: the dark palette's ink.
  static final Color attentionColorDark = ChorusColors.dark.ink;

  /// The ring's colour for the theme around [context]: its ink.
  static Color attentionColorOf(BuildContext context) =>
      ChorusColors.of(context).ink;

  /// Height of the horizontal row of tabs.
  static const double height = 48;

  /// What a screen reader says for the "+" tab.
  static const String addLabel = 'Add a board';

  /// What a screen reader says a long press on a tab does.
  static const String longPressHint = 'Rename or archive';

  /// The "+" tab, for tests.
  static const Key addKey = ValueKey('BoardTabs.add');

  /// Every board of the circle; archived ones are left out here.
  final List<BoardFacts> boards;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  /// Ids of the boards to draw attention to.
  final Set<String> attentionIds;

  /// Horizontal is a 48dp row of tabs side by side. Vertical stacks them in
  /// a column as tall as it is given, for a short, wide screen where a row
  /// of tabs would take height from the board.
  final Axis axis;

  /// Adds a board; null shows no "+" tab.
  final VoidCallback? onAdd;

  /// Called with a board whose tab was long-pressed; null for none.
  final ValueChanged<BoardFacts>? onLongPress;

  /// Whether tabs are drawn for [boards]: when two or more are in use, or
  /// when a board can be added ([canAdd]), so the "+" tab is there.
  static bool showFor(Iterable<BoardFacts> boards, {bool canAdd = false}) =>
      canAdd || liveBoards(boards).length > 1;

  @override
  State<BoardTabs> createState() => _BoardTabsState();
}

class _BoardTabsState extends State<BoardTabs> {
  /// The least a tab may be along the row, before the row scrolls instead.
  static const double _minWidth = 104;
  static const double _minHeight = 56;

  /// The most tabs one row is divided into: past this the tabs would be
  /// wide for nothing.
  static const int _maxSlots = 5;

  /// Space between two tabs: two targets are at least this far apart.
  static const double _gap = ChorusSpace.targetGap;

  /// Length of the "+" tab along the row.
  static const double _addLength = 56;

  final ScrollController _scroll = ScrollController();

  /// One key per board, kept while the board is, so a tab is found again
  /// after the row rebuilds.
  final Map<String, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void didUpdateWidget(BoardTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId ||
        oldWidget.boards.length != widget.boards.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls just far enough to show the chosen tab, as after a board was
  /// added at the end. The child's tabs jump; an adult's glide.
  void _revealSelected() {
    if (!mounted || !_scroll.hasClients) return;
    final object = _keys[widget.selectedId]?.currentContext?.findRenderObject();
    final viewport = object == null
        ? null
        : RenderAbstractViewport.maybeOf(object);
    if (object == null || viewport == null) return;
    final position = _scroll.position;
    final toEnd = viewport.getOffsetToReveal(object, 1).offset;
    final toStart = viewport.getOffsetToReveal(object, 0).offset;
    var target = position.pixels;
    if (target < toEnd) {
      target = toEnd;
    } else if (target > toStart) {
      target = toStart;
    }
    target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if (target == position.pixels) return;
    final glide =
        (widget.onAdd != null || widget.onLongPress != null) &&
        !ChorusMotion.reduced(context);
    if (glide) {
      _scroll.animateTo(
        target,
        duration: ChorusMotion.entranceShort,
        curve: ChorusMotion.entrance,
      );
    } else {
      _scroll.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = liveBoards(widget.boards);
    if (!BoardTabs.showFor(live, canAdd: widget.onAdd != null)) {
      return const SizedBox.shrink();
    }
    final vertical = widget.axis == Axis.vertical;
    final row = LayoutBuilder(
      builder: (context, constraints) {
        final along = vertical ? constraints.maxHeight : constraints.maxWidth;
        final length = _tabLength(along);
        final onAdd = widget.onAdd;
        final children = <Widget>[];
        for (final board in live) {
          if (children.isNotEmpty) children.add(_spacer(vertical));
          final selected = board.id == widget.selectedId;
          final onLongPress = widget.onLongPress;
          children.add(
            SizedBox(
              key: _keys.putIfAbsent(board.id, GlobalKey.new),
              width: vertical ? null : length,
              height: vertical ? length : null,
              child: _Tab(
                label: board.name,
                selected: selected,
                attention: !selected && widget.attentionIds.contains(board.id),
                onTap: () => widget.onSelect(board.id),
                onLongPress: onLongPress == null
                    ? null
                    : () => onLongPress(board),
              ),
            ),
          );
        }
        if (onAdd != null) {
          children
            ..add(_spacer(vertical))
            ..add(
              SizedBox(
                width: vertical ? null : _addLength,
                height: vertical ? _addLength : null,
                child: _AddTab(onTap: onAdd),
              ),
            );
        }
        final total =
            live.length * length +
            (live.length - 1) * _gap +
            (onAdd == null ? 0 : _gap + _addLength);
        final overflows = along.isFinite && total > along + 0.5;
        // Clamped: the child's board never bounces.
        final list = SingleChildScrollView(
          controller: _scroll,
          scrollDirection: widget.axis,
          physics: const ClampingScrollPhysics(),
          child: Flex(
            direction: widget.axis,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        );
        return Scrollbar(
          controller: _scroll,
          thumbVisibility: overflows,
          child: list,
        );
      },
    );
    if (vertical) return row;
    return SizedBox(height: BoardTabs.height, child: row);
  }

  Widget _spacer(bool vertical) =>
      SizedBox(width: vertical ? null : _gap, height: vertical ? _gap : null);

  /// The length of every tab in a row [along] long: the row divided into as
  /// many equal slots as fit tabs of at least the least length, at most
  /// [_maxSlots]. It does not depend on how many boards there are.
  double _tabLength(double along) {
    final vertical = widget.axis == Axis.vertical;
    final least = vertical ? _minHeight : _minWidth;
    if (!along.isFinite) return least;
    final room = along - (widget.onAdd == null ? 0 : _addLength + _gap);
    final slots = ((room + _gap) / (least + _gap)).floor().clamp(1, _maxSlots);
    final length = (room - _gap * (slots - 1)) / slots;
    return length < ChorusSpace.minTarget ? ChorusSpace.minTarget : length;
  }
}

/// One board's tab: ink when it is the board on show, card otherwise.
class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.attention,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final bool selected;
  final bool attention;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final radius = BorderRadius.circular(ChorusSpace.tileRadius);
    final ring = BoardTabs.attentionColorOf(context);
    Widget tab = PressableSurface(
      // The board on show stays pressable for a long press, but a tap on it
      // changes nothing and is not felt.
      onTap: selected ? () {} : onTap,
      haptic: selected ? null : ChorusHaptic.tabChanged,
      color: selected ? colors.ink : colors.surface,
      edgeColor: selected ? null : colors.line,
      foregroundColor: selected ? colors.card : colors.ink,
      borderRadius: ChorusSpace.tileRadius,
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: selected
                ? null
                : Border.all(color: colors.inkMuted, width: 1.5),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                // The tab is 48dp tall: past this the line would not fit
                // it. The whole name is still what is read out.
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.5),
                style: ChorusType.label.copyWith(
                  fontSize: 18,
                  height: 24 / 18,
                  letterSpacing: 0.02 * 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (onLongPress != null) {
      tab = GestureDetector(
        onLongPress: onLongPress,
        onSecondaryTap: onLongPress,
        child: tab,
      );
    }
    // One node for a screen reader, in place of the surface's own: a
    // button named by its board, selected when on show, with the long
    // press as an action of its own where there is one.
    tab = Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: true,
      label: attention
          ? 'Board: $label. An adult is pointing at a word here'
          : 'Board: $label',
      onTap: selected
          ? null
          : () {
              ChorusHaptics.tabChanged();
              onTap();
            },
      onLongPress: onLongPress,
      onLongPressHint: onLongPress == null ? null : BoardTabs.longPressHint,
      excludeSemantics: true,
      child: tab,
    );
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ChorusSpace.tileRadius),
        border: Border.all(
          color: attention ? ring : ring.withValues(alpha: 0),
          width: 4,
        ),
      ),
      child: tab,
    );
  }
}

/// The "+" tab after the last board.
class _AddTab extends StatelessWidget {
  const _AddTab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return PressableSurface(
      key: BoardTabs.addKey,
      onTap: onTap,
      semanticLabel: BoardTabs.addLabel,
      color: colors.surface,
      edgeColor: colors.line,
      foregroundColor: colors.ink,
      borderRadius: ChorusSpace.tileRadius,
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ChorusSpace.tileRadius),
            border: Border.all(color: colors.inkMuted, width: 1.5),
          ),
          child: const Center(child: Icon(Icons.add_rounded)),
        ),
      ),
    );
  }
}
