/// The first screen of a new device: the idea of Chorus, as a board that
/// works.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:chorus_shared/chorus_shared.dart' show universalCore36;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../brand/board_object.dart';
import '../brand/haptics.dart';
import '../brand/mark.dart';
import '../brand/motion.dart';
import '../brand/pressable_surface.dart';
import '../brand/symbols.dart';
import '../brand/tokens.dart';
import '../contracts.dart' show SpeechService;
import 'fill_or_scroll.dart';
import 'launch_reveal.dart';

/// The words on the onboarding screen.
abstract final class OnboardingCopy {
  static const String lineOne = 'One board.';
  static const String lineTwo = 'Many voices.';
  static const String body = 'Tap a word. It speaks, even with no signal.';
  static const String makeBoard = 'Make a board for my child';
  static const String haveOne = 'I already have one';
  static const String emptyStrip = 'Words you tap go here';
  static const String board = 'A board to try';
  static const String speak = 'Speak';
}

/// The six words of the onboarding board, "I want more" over "help go
/// stop", from the starter board's own vocabulary.
const List<String> onboardingWords = [
  'I',
  'want',
  'more',
  'help',
  'go',
  'stop',
];

/// The onboarding board's tiles: each word in its starter-board colour
/// family, with its Mulberry symbol where it has one.
List<BoardCell> onboardingCells() => [
  for (final (i, label) in onboardingWords.indexed)
    BoardCell(
      row: i ~/ 3,
      col: i % 3,
      label: label,
      family: TileFamily.forKey(_starterKeyOf(label)),
      image: symbolImageFor(label),
    ),
];

String? _starterKeyOf(String label) {
  for (final word in universalCore36) {
    if (word.label == label) return word.colorKey;
  }
  return null;
}

/// One screen, the thesis: the mark, "One board. Many voices.", a live
/// board of six real words that tilts under the thumb and speaks each tapped
/// word on this device, with no account and no network, and a sentence
/// strip that fills as they are tapped. The two ways on sit in the thumb
/// zone. No slides, no dots.
///
/// On a phone held upright it is one column. Held sideways, or on a wide
/// screen, the board and its strip take the left half and the words and
/// actions the right; a screen reader still reads the words first.
///
/// Its parts arrive in turn once the launch reveal ([LaunchReveal]) is
/// over; under reduced motion they fade in together in
/// [ChorusMotion.reducedFade].
class OnboardingView extends StatefulWidget {
  const OnboardingView({
    super.key,
    required this.speech,
    required this.onMakeBoard,
    required this.onHaveOne,
    this.animateIn = true,
  });

  /// The app's own voice, which needs no account.
  final SpeechService speech;

  /// "Make a board for my child": on to sign-up.
  final VoidCallback onMakeBoard;

  /// "I already have one": on to sign-in.
  final VoidCallback onHaveOne;

  /// False shows everything at once, as when coming back to this screen.
  final bool animateIn;

  /// How many words the strip keeps: the newest ones.
  static const int stripLength = 4;

  /// The board, for tests.
  @visibleForTesting
  static const Key boardKey = ValueKey('OnboardingView.board');

  /// The sentence strip, for tests.
  @visibleForTesting
  static const Key stripKey = ValueKey('OnboardingView.strip');

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with SingleTickerProviderStateMixin {
  // Content no wider than this on a tablet held upright.
  static const double _maxContent = 560;

  // The board on a wide screen: large enough to be the object, no larger.
  static const double _maxBoardWidth = 520;

  // The smallest tile that is still a 48 dp target 8 dp from the next.
  static const double _minTile = 52;

  final List<BoardCell> _cells = onboardingCells();

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    value: widget.animateIn ? 0 : 1,
  );
  bool _entering = false;

  List<String> _strip = const [];

  // Spoken: the next word starts a new sentence.
  bool _spoken = false;

  @override
  void initState() {
    super.initState();
    // The first word should not wait for the voice to wake.
    unawaited(_quietly(widget.speech.warmUp));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entering || _entrance.isCompleted) return;
    if (!LaunchReveal.isOver(context)) return;
    _entering = true;
    _entrance.duration = ChorusMotion.reduced(context)
        ? ChorusMotion.reducedFade
        : _Arrive.length;
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  static Future<void> _quietly(Future<void> Function() call) async {
    try {
      await call();
    } catch (_) {
      // No voice on this device: the screen still works, silently.
    }
  }

  void _tapWord(BoardCell cell) {
    unawaited(_quietly(() => widget.speech.speak(cell.label)));
    setState(() {
      final words = [if (!_spoken) ..._strip, cell.label];
      _strip = words.length > OnboardingView.stripLength
          ? words.sublist(words.length - OnboardingView.stripLength)
          : words;
      _spoken = false;
    });
  }

  void _speakStrip() {
    if (_strip.isEmpty) return;
    final sentence = _strip.join(' ');
    unawaited(_quietly(() => widget.speech.speak(sentence)));
    setState(() => _spoken = true);
  }

  Widget _arrive(
    int order,
    Widget child, {
    Offset from = const Offset(0, 16),
    double scaleFrom = 1,
  }) => _Arrive(
    entrance: _entrance,
    order: order,
    from: from,
    scaleFrom: scaleFrom,
    child: child,
  );

  Widget get _lockup => const ChorusLockup(size: 26);

  Widget _display(double width, {required bool compact}) => _DisplayLine(
    width: width,
    compact: compact,
    wrapLine: (line, text) =>
        _arrive(1, text, from: Offset(line == 0 ? 0 : 48, line == 0 ? 16 : 0)),
  );

  Widget get _board => BoardObject(
    key: OnboardingView.boardKey,
    rows: 2,
    cols: 3,
    cells: _cells,
    semanticLabel: OnboardingCopy.board,
    onTileTap: _tapWord,
  );

  Widget get _sentence =>
      _Strip(key: OnboardingView.stripKey, words: _strip, onSpeak: _speakStrip);

  Widget get _body => const Text(OnboardingCopy.body, style: ChorusType.body);

  Widget get _actions => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PressableSurface(
        onTap: widget.onMakeBoard,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: const Text(
          OnboardingCopy.makeBoard,
          textAlign: TextAlign.center,
          style: ChorusType.label,
        ),
      ),
      const SizedBox(height: ChorusSpace.targetGap),
      TextButton(
        onPressed: widget.onHaveOne,
        child: const Text(OnboardingCopy.haveOne, textAlign: TextAlign.center),
      ),
    ],
  );

  /// The board's height when it is [width] wide: its tiles are square, two
  /// rows of three, with the gaps and padding `BoardObject` gives them.
  static double _boardHeightFor(double width) =>
      BoardObject.heightFor(rows: 2, cols: 3, width: width);

  static double get _minBoardHeight =>
      _boardHeightFor(BoardObject.widthForTile(cols: 3, tile: _minTile));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No bar, only what keeps the status bar icons readable on card.
      appBar: AppBar(toolbarHeight: 0),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, box) {
            final room = box.biggest;
            return room.width > room.height ? _wide(room) : _upright(room);
          },
        ),
      ),
    );
  }

  /// A phone held upright: the wireframe, top to bottom.
  Widget _upright(Size room) {
    final margin = ChorusSpace.margin(room.width);
    final content = math.max(
      0.0,
      math.min(room.width - 2 * margin, _maxContent),
    );
    final side = (room.width - content) / 2;
    Widget inset(Widget child) => Padding(
      padding: EdgeInsets.only(right: side),
      child: child,
    );
    return FillOrScroll(
      padding: EdgeInsets.only(left: side, top: 4, bottom: 4),
      children: [
        inset(_arrive(0, _lockup)),
        const SizedBox(height: 12),
        // To the right edge of the screen, not the content: the second line
        // runs off it on purpose.
        _display(room.width - side, compact: room.height < 480),
        const SizedBox(height: 12),
        // The board, its strip and its caption stay together between the
        // heading and the actions: the board gives up height first on a
        // short phone, and on a tall one the group sits in the middle.
        Expanded(
          child: inset(
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: IntrinsicFloor(
                    minHeight: _minBoardHeight,
                    child: SizedBox(
                      height: _boardHeightFor(content),
                      child: _arrive(2, _board, scaleFrom: 0.94),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _arrive(3, _sentence),
                const SizedBox(height: 8),
                _arrive(3, _body),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        inset(_arrive(4, _actions)),
      ],
    );
  }

  /// Held sideways or on a wide screen: the board on the left, the words
  /// and the actions on the right.
  Widget _wide(Size room) {
    final margin = ChorusSpace.margin(room.width);
    final half = room.width / 2;
    final boardWidth = math.max(
      0.0,
      math.min(half - 2 * margin, _maxBoardWidth),
    );
    // A phone on its side keeps the actions in the thumb zone; a tall
    // screen has room to set everything in the middle.
    final short = room.height < 600;
    Widget inset(Widget child) => Padding(
      padding: EdgeInsets.only(right: margin),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: child,
        ),
      ),
    );
    final boardSide = Semantics(
      sortKey: const OrdinalSortKey(1),
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: EdgeInsets.all(margin),
        child: Center(
          child: SizedBox(
            width: boardWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SizedBox(
                    height: _boardHeightFor(boardWidth),
                    child: _arrive(2, _board, scaleFrom: 0.94),
                  ),
                ),
                const SizedBox(height: 12),
                _arrive(3, _sentence),
              ],
            ),
          ),
        ),
      ),
    );
    final wordSide = Semantics(
      sortKey: const OrdinalSortKey(0),
      container: true,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, box) => FillOrScroll(
          padding: EdgeInsets.symmetric(vertical: short ? 16 : margin),
          children: [
            if (!short) const Spacer(flex: 2),
            inset(_arrive(0, _lockup)),
            SizedBox(height: short ? 12 : 24),
            _display(box.maxWidth, compact: short),
            SizedBox(height: short ? 8 : 16),
            inset(_arrive(3, _body)),
            if (short) const Spacer() else const SizedBox(height: 32),
            inset(_arrive(4, _actions)),
            if (!short) const Spacer(flex: 3),
          ],
        ),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: half, child: boardSide),
        Expanded(child: wordSide),
      ],
    );
  }
}

/// Brings [child] in at its turn ([order]) in the entrance: a fade with a
/// short rise, or a slide from [from], on the entrance curve. Under reduced
/// motion every part only fades, all together.
class _Arrive extends StatelessWidget {
  const _Arrive({
    required this.entrance,
    required this.order,
    required this.from,
    required this.scaleFrom,
    required this.child,
  });

  final Animation<double> entrance;
  final int order;
  final Offset from;
  final double scaleFrom;
  final Widget child;

  static const int _step = 60;
  static const int _each = 450;
  static const int _last = 4;
  static const int _total = _last * _step + _each;

  /// The whole entrance, last part included.
  static const Duration length = Duration(milliseconds: _total);

  @override
  Widget build(BuildContext context) {
    final reduced = ChorusMotion.reduced(context);
    final curve = Interval(
      order * _step / _total,
      (order * _step + _each) / _total,
      curve: ChorusMotion.entrance,
    );
    return AnimatedBuilder(
      animation: entrance,
      child: child,
      builder: (context, child) {
        final t = reduced ? entrance.value : curve.transform(entrance.value);
        final away = reduced ? 0.0 : 1 - t;
        final scale = 1 - (1 - scaleFrom) * away;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(
              from.dx * away,
              from.dy * away,
              0,
            )..scaleByDouble(scale, scale, 1, 1),
            child: child,
          ),
        );
      },
    );
  }
}

/// "One board." over "Many voices.", the second line running off the
/// right edge on purpose: it is set so that its full stop and part of its
/// last letter fall past [width], the room from the line's start to the
/// edge of the screen. A screen reader hears both lines whole.
///
/// The type is Display, at the reader's text size up to the display cap;
/// it grows on a wide screen so the second line still reaches the edge, and
/// shrinks only when it would otherwise lose more than the full stop.
class _DisplayLine extends StatelessWidget {
  const _DisplayLine({
    required this.width,
    required this.compact,
    required this.wrapLine,
  });

  final double width;

  /// A short screen: a smaller display size, so the board keeps its room.
  final bool compact;

  /// Wraps each line (0 or 1) for its entrance.
  final Widget Function(int line, Widget text) wrapLine;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final direction = Directionality.of(context);
    TextStyle at(double size) => ChorusType.frauncesAt(
      ChorusType.display,
      size,
      size * 50 / 48,
    ).copyWith(color: colors.ink);
    double measure(String text, double size) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: at(size)),
        textDirection: direction,
        maxLines: 1,
      )..layout();
      final measured = painter.width;
      painter.dispose();
      return measured;
    }

    // What of the second line stays on screen: all but the full stop and
    // a little over half its last letter.
    double shownAt(double size) =>
        measure(OnboardingCopy.lineTwo, size) -
        measure('.', size) -
        0.6 * measure('s', size);

    final room = math.max(1.0, width);
    final floor = ChorusType.displayScaler(context).scale(compact ? 40 : 48);
    final ceiling = math.max(floor, compact ? 44.0 : 96.0);
    // The size at which the shown part would fill the room exactly.
    final fill = 48 * room / math.max(1.0, shownAt(48));
    final size = math.min(fill, (fill * 0.72).clamp(floor, ceiling));
    final indent = math.max(0.0, room - shownAt(size));

    final style = at(size);
    Widget line(String text) => Text(
      text,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      textScaler: TextScaler.noScaling,
      style: style,
    );
    return Semantics(
      header: true,
      label: '${OnboardingCopy.lineOne} ${OnboardingCopy.lineTwo}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          wrapLine(0, line(OnboardingCopy.lineOne)),
          wrapLine(
            1,
            Padding(
              padding: EdgeInsetsDirectional.only(start: indent),
              child: line(OnboardingCopy.lineTwo),
            ),
          ),
        ],
      ),
    );
  }
}

/// The sentence so far, with Speak at its end. Speak is dimmed and does
/// nothing while the strip is empty.
class _Strip extends StatelessWidget {
  const _Strip({super.key, required this.words, required this.onSpeak});

  final List<String> words;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final empty = words.isEmpty;
    final sentence = words.join(' ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Semantics(
              label: empty ? 'Sentence, empty' : 'Sentence: $sentence',
              excludeSemantics: true,
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                alignment: AlignmentDirectional.centerStart,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
                  border: Border.all(color: colors.ink, width: 2),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    empty ? OnboardingCopy.emptyStrip : sentence,
                    maxLines: 1,
                    softWrap: false,
                    textScaler: MediaQuery.textScalerOf(
                      context,
                    ).clamp(maxScaleFactor: 1.5),
                    style: empty
                        ? ChorusType.body.copyWith(color: colors.inkMuted)
                        : ChorusType.headline.copyWith(
                            fontSize: 22,
                            height: 28 / 22,
                            color: colors.ink,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: ChorusSpace.targetGap),
          SizedBox(
            width: 64,
            child: AnimatedOpacity(
              opacity: empty ? 0.38 : 1,
              duration: ChorusMotion.duration(
                context,
                ChorusMotion.toggleDuration,
              ),
              child: PressableSurface(
                onTap: empty ? null : onSpeak,
                semanticLabel: OnboardingCopy.speak,
                haptic: ChorusHaptic.sentenceSpoken,
                child: const Icon(Icons.volume_up_rounded, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
