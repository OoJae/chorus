/// Where everything on home goes, at every size.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../brand/tokens.dart';

/// Builds the hero for a lean that runs from 0 (upright) to 1 (leaned back)
/// as the page scrolls.
typedef HomeHeroBuilder =
    Widget Function(BuildContext context, ValueListenable<double> lean);

/// Home, full bleed on card: [status] at the top, then the display [title]
/// drawn over the hero's top edge, any [notes], and the quiet [list];
/// [actions] stay in the thumb's reach at the bottom.
///
/// On a phone held upright everything is one column that scrolls under the
/// actions, and the hero leans back and shrinks as it goes. Held sideways,
/// and on a tablet or desktop held the same way, the hero stands on the left
/// and the list scrolls on the right above the actions; the list's scroll
/// leans the hero there.
///
/// Only the hero's transform follows the scroll: nothing is laid out again.
class HomeLayout extends StatefulWidget {
  const HomeLayout({
    super.key,
    required this.status,
    required this.title,
    required this.hero,
    required this.actions,
    this.notes = const [],
    this.list = const [],
  });

  /// The sync chip.
  final Widget status;

  /// "Maya's board", in the display face.
  final String title;

  final HomeHeroBuilder hero;

  /// What the thumb reaches for: opening the board, editing it.
  final Widget actions;

  /// Short notes about the board, right under it: still loading, could not
  /// check in, no words yet.
  final List<Widget> notes;

  /// The quiet list below the fold: settings, sharing, the way out.
  final List<Widget> list;

  /// How far the hero's top edge reaches up under the title, as a share of
  /// the title's size: about the depth of its descenders, which are drawn
  /// in front of it.
  static const double titleOverlap = 0.2;

  /// The largest side the hero is drawn at.
  static const double maxHero = 560;

  /// The widest the one-column layout's content gets.
  static const double maxColumn = 560;

  /// The scroll view, for tests.
  @visibleForTesting
  static const Key scrollKey = ValueKey('HomeLayout.scroll');

  /// The bar that holds [actions], for tests.
  @visibleForTesting
  static const Key actionsKey = ValueKey('HomeLayout.actions');

  /// Whether a screen of [size] gets the two panes.
  static bool twoPanes(Size size) =>
      size.width > size.height && size.width >= ChorusSpace.wideFrom;

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _lean = ValueNotifier(0);

  /// How far the page scrolls before the hero has leaned all the way.
  double _leanDistance = 320;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_follow);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _lean.dispose();
    super.dispose();
  }

  void _follow() {
    if (!_scroll.hasClients) return;
    _lean.value = (_scroll.offset / _leanDistance).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final colors = ChorusColors.of(context);
    final margin = ChorusSpace.margin(size.width);
    return Scaffold(
      backgroundColor: colors.card,
      body: HomeLayout.twoPanes(size)
          ? _twoPanes(context, size, margin)
          : _column(context, margin),
    );
  }

  /// A phone held upright, or a tall tablet.
  Widget _column(BuildContext context, double margin) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final width =
                  math.min(box.maxWidth, HomeLayout.maxColumn + 2 * margin) -
                  2 * margin;
              // Big enough to be the screen's one loud thing, small enough
              // that its bottom edge shows above the actions.
              final side = math.max(
                0.0,
                math.min(
                  math.min(width, HomeLayout.maxHero),
                  math.max(200.0, box.maxHeight * 0.62),
                ),
              );
              _leanDistance = math.max(1.0, side);
              Widget centred(Widget child, {double inset = 0}) => Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: HomeLayout.maxColumn + 2 * margin,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: inset),
                    child: child,
                  ),
                ),
              );
              return CustomScrollView(
                key: HomeLayout.scrollKey,
                controller: _scroll,
                slivers: [
                  SliverSafeArea(
                    bottom: false,
                    sliver: SliverToBoxAdapter(
                      child: centred(
                        inset: margin,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: widget.status,
                            ),
                            const SizedBox(height: 20),
                            _TitleOverHero(
                              title: widget.title,
                              hero: SizedBox(
                                width: side,
                                height: side + ChorusSpace.edge,
                                child: widget.hero(context, _lean),
                              ),
                            ),
                            for (final note in widget.notes) ...[
                              const SizedBox(height: 16),
                              note,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverSafeArea(
                    top: false,
                    bottom: false,
                    sliver: SliverToBoxAdapter(
                      child: centred(
                        // List rows inset their own content to the margin.
                        inset: math.max(0, margin - 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: widget.list,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        _ActionsBar(
          padding: EdgeInsetsDirectional.fromSTEB(margin, 12, margin, 16),
          maxWidth: HomeLayout.maxColumn,
          child: widget.actions,
        ),
      ],
    );
  }

  /// A phone held sideways, a tablet or a desktop.
  Widget _twoPanes(BuildContext context, Size size, double margin) {
    _leanDistance = 360;
    final paneWidth = size.width >= 1000
        ? 440.0
        : math.min(380.0, size.width * 0.46);
    return SafeArea(
      bottom: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SafeArea(
              top: false,
              right: false,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(margin, 12, margin, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: HomeLayout.maxHero,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: widget.status,
                        ),
                        SizedBox(height: size.height < 480 ? 8 : 20),
                        Expanded(
                          child: _TitleOverHero(
                            title: widget.title,
                            hero: LayoutBuilder(
                              builder: (context, box) {
                                final side = math.max(
                                  0.0,
                                  math.min(
                                    math.min(box.maxWidth, HomeLayout.maxHero),
                                    box.maxHeight - ChorusSpace.edge,
                                  ),
                                );
                                return Align(
                                  alignment: AlignmentDirectional.topStart,
                                  child: SizedBox(
                                    width: side,
                                    height: side + ChorusSpace.edge,
                                    child: widget.hero(context, _lean),
                                  ),
                                );
                              },
                            ),
                            fill: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: paneWidth,
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    key: HomeLayout.scrollKey,
                    controller: _scroll,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          0,
                          12,
                          math.max(0, margin - 16),
                          16,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final note in widget.notes)
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: note,
                                ),
                              ...widget.list,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _ActionsBar(
                  // In line with the list rows' own inset.
                  padding: EdgeInsetsDirectional.fromSTEB(16, 12, margin, 16),
                  maxWidth: paneWidth,
                  child: widget.actions,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The thumb's reach: the actions on the card, with a hairline over them
/// when the page scrolls under.
class _ActionsBar extends StatelessWidget {
  const _ActionsBar({
    required this.padding,
    required this.maxWidth,
    required this.child,
  });

  final EdgeInsetsDirectional padding;
  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    return DecoratedBox(
      key: HomeLayout.actionsKey,
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The display title with the hero's top edge reaching up under its foot.
///
/// The hero starts inside the title's last line, but the title is drawn in
/// front, so its descenders stay whole ("Maya's", "Peggy's"): the letters
/// sit on the board's card. Taps there go through the title to the hero.
///
/// The title wraps rather than run off the screen, so a long name or a large
/// text size keeps all its words. Screen readers hear it as the heading.
class _TitleOverHero extends StatelessWidget {
  const _TitleOverHero({
    required this.title,
    required this.hero,
    this.fill = false,
  });

  final String title;
  final Widget hero;

  /// True gives the hero all the height left under the title.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final scaler = ChorusType.displayScaler(context);
    final overlap =
        scaler.scale(ChorusType.display.fontSize!) * HomeLayout.titleOverlap;
    return _HeroUnderTitle(
      overlap: overlap,
      fill: fill,
      textDirection: Directionality.of(context),
      hero: hero,
      // Drawn over the hero but never in the way of a finger on it.
      title: IgnorePointer(
        child: Semantics(
          header: true,
          child: Text(
            title,
            textScaler: scaler,
            style: ChorusType.display.copyWith(color: colors.ink),
          ),
        ),
      ),
    );
  }
}

/// Lays [title] out at the top and [hero] under it, starting [overlap]
/// above the title's foot, and paints the title last, in front.
class _HeroUnderTitle extends MultiChildRenderObjectWidget {
  _HeroUnderTitle({
    required this.overlap,
    required this.fill,
    required this.textDirection,
    required Widget hero,
    required Widget title,
  }) : super(children: [hero, title]);

  final double overlap;
  final bool fill;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHeroUnderTitle(overlap, fill, textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeroUnderTitle renderObject,
  ) {
    renderObject
      ..overlap = overlap
      ..fill = fill
      ..textDirection = textDirection;
  }
}

class _HeroUnderTitleData extends ContainerBoxParentData<RenderBox> {}

class _RenderHeroUnderTitle extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HeroUnderTitleData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _HeroUnderTitleData> {
  _RenderHeroUnderTitle(this._overlap, this._fill, this._textDirection);

  double _overlap;
  set overlap(double value) {
    if (value == _overlap) return;
    _overlap = value;
    markNeedsLayout();
  }

  /// True: the hero gets all the height left, as in an [Expanded].
  bool _fill;
  set fill(bool value) {
    if (value == _fill) return;
    _fill = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _hero => firstChild!;
  RenderBox get _title => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _HeroUnderTitleData) {
      child.parentData = _HeroUnderTitleData();
    }
  }

  /// Where the hero starts: the title's height less the overlap.
  double _heroTop(double titleHeight) => math.max(0, titleHeight - _overlap);

  BoxConstraints _heroConstraints(BoxConstraints constraints, double top) {
    final width = BoxConstraints(maxWidth: constraints.maxWidth);
    if (!_fill || !constraints.hasBoundedHeight) return width;
    return width.copyWith(
      minHeight: math.max(0, constraints.maxHeight - top),
      maxHeight: math.max(0, constraints.maxHeight - top),
    );
  }

  Size _sizeFor(BoxConstraints constraints, Size title, Size hero) {
    final top = _heroTop(title.height);
    return constraints.constrain(
      Size(math.max(title.width, hero.width), top + hero.height),
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final title = _title.getDryLayout(
      BoxConstraints(maxWidth: constraints.maxWidth),
    );
    final hero = _hero.getDryLayout(
      _heroConstraints(constraints, _heroTop(title.height)),
    );
    return _sizeFor(constraints, title, hero);
  }

  @override
  void performLayout() {
    final title = _title
      ..layout(
        BoxConstraints(maxWidth: constraints.maxWidth),
        parentUsesSize: true,
      );
    final top = _heroTop(title.size.height);
    final hero = _hero
      ..layout(_heroConstraints(constraints, top), parentUsesSize: true);
    size = _sizeFor(constraints, title.size, hero.size);
    double start(RenderBox child) =>
        _textDirection == TextDirection.rtl ? size.width - child.size.width : 0;
    (title.parentData! as _HeroUnderTitleData).offset = Offset(start(title), 0);
    (hero.parentData! as _HeroUnderTitleData).offset = Offset(start(hero), top);
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _title.getMinIntrinsicWidth(double.infinity),
    _hero.getMinIntrinsicWidth(double.infinity),
  );

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
    _title.getMaxIntrinsicWidth(double.infinity),
    _hero.getMaxIntrinsicWidth(double.infinity),
  );

  @override
  double computeMinIntrinsicHeight(double width) =>
      _heroTop(_title.getMinIntrinsicHeight(width)) +
      _hero.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _heroTop(_title.getMaxIntrinsicHeight(width)) +
      _hero.getMaxIntrinsicHeight(width);

  // Children paint in order, hero first; taps are tried title first, and
  // the title lets them through.
  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
