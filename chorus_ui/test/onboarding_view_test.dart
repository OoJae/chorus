// The onboarding screen: one screen, a live board of six real words that
// speaks with no account, a strip that fills, and the two ways on in the
// thumb zone, at every size, in the dark, at the largest text and under
// reduced motion.
import 'dart:math' as math;

import 'package:chorus_ui/brand/board_object.dart';
import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/brand/mark.dart';
import 'package:chorus_ui/brand/pressable_surface.dart';
import 'package:chorus_ui/brand/test_fonts.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/onboarding/launch_reveal.dart';
import 'package:chorus_ui/onboarding/onboarding_view.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _sizes = [
  Size(360, 640),
  Size(360, 820),
  Size(820, 360),
  Size(1280, 800),
  Size(1440, 900),
];

/// WCAG 2 contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// A voice that is not there: every call fails.
class _NoVoice implements SpeechService {
  @override
  Future<void> warmUp() async => throw StateError('no engine');

  @override
  Future<void> speak(String text) async => throw StateError('no engine');

  @override
  Future<void> stop() async {}

  @override
  final ValueListenable<bool> speaking = ValueNotifier(false);

  @override
  final ValueListenable<bool> offlineVoiceReady = ValueNotifier(false);
}

class _Taps {
  int makeBoard = 0;
  int haveOne = 0;
}

Widget _app(
  Widget home, {
  bool dark = false,
  bool reduced = false,
  double textScale = 1,
}) => MaterialApp(
  theme: chorusTheme(),
  darkTheme: chorusDarkTheme(),
  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reduced,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  home: home,
);

Future<_Taps> _pump(
  WidgetTester tester, {
  SpeechService? speech,
  Size size = const Size(360, 640),
  bool dark = false,
  bool reduced = false,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final taps = _Taps();
  await tester.pumpWidget(
    _app(
      OnboardingView(
        speech: speech ?? FakeSpeech(),
        onMakeBoard: () => taps.makeBoard++,
        onHaveOne: () => taps.haveOne++,
      ),
      dark: dark,
      reduced: reduced,
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
  return taps;
}

Finder _tile(String label) => find.ancestor(
  of: find.descendant(
    of: find.byKey(OnboardingView.boardKey),
    matching: find.text(label),
  ),
  matching: find.byType(PressableSurface),
);

Finder get _speak => find.descendant(
  of: find.byKey(OnboardingView.stripKey),
  matching: find.byType(PressableSurface),
);

String _stripText(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(OnboardingView.stripKey),
        matching: find.byType(Text),
      ),
    )
    .data!;

void main() {
  late List<ChorusHaptic> felt;

  setUpAll(loadChorusFonts);
  setUp(() {
    felt = [];
    ChorusHaptics.sink = felt.add;
  });
  tearDown(() => ChorusHaptics.sink = null);

  testWidgets('one screen: the mark and wordmark, the display line, six '
      'real words, the strip, the line about no signal and the two ways '
      'on; no slides and no dots', (tester) async {
    await _pump(tester);

    expect(find.byType(ChorusLockup), findsOneWidget);
    expect(find.text('chorus'), findsOneWidget);
    expect(find.text(OnboardingCopy.lineOne), findsOneWidget);
    expect(find.text(OnboardingCopy.lineTwo), findsOneWidget);
    for (final word in onboardingWords) {
      expect(_tile(word), findsOneWidget, reason: word);
    }
    expect(find.text(OnboardingCopy.emptyStrip), findsOneWidget);
    expect(find.text(OnboardingCopy.body), findsOneWidget);
    expect(find.text(OnboardingCopy.makeBoard), findsOneWidget);
    expect(find.text(OnboardingCopy.haveOne), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(find.byType(TabPageSelector), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('the six words keep their starter-board colours and their Mulberry '
      'symbols where they have one', () {
    final cells = {for (final cell in onboardingCells()) cell.label: cell};
    expect(cells.keys, onboardingWords);
    expect(
      {for (final cell in cells.values) cell.label: cell.family},
      {
        'I': TileFamily.person,
        'want': TileFamily.action,
        'more': TileFamily.describe,
        'help': TileFamily.action,
        'go': TileFamily.action,
        'stop': TileFamily.action,
      },
    );
    expect(
      {for (final cell in cells.values) cell.label: (cell.row, cell.col)},
      {
        'I': (0, 0),
        'want': (0, 1),
        'more': (0, 2),
        'help': (1, 0),
        'go': (1, 1),
        'stop': (1, 2),
      },
    );
    for (final word in ['I', 'want', 'more', 'help', 'go']) {
      expect(cells[word]!.image, isNotNull, reason: word);
    }
    // Mulberry has no "stop" among the starter symbols.
    expect(cells['stop']!.image, isNull);
  });

  testWidgets('each tile is drawn in its family colour', (tester) async {
    await _pump(tester);
    for (final cell in onboardingCells()) {
      expect(
        tester.widget<PressableSurface>(_tile(cell.label)).color,
        cell.family.light.fill,
        reason: cell.label,
      );
    }
  });

  testWidgets('a tapped word is spoken at once, felt as a light tap, and '
      'fills the strip; Speak says the sentence with a firmer one', (
    tester,
  ) async {
    final speech = FakeSpeech();
    await _pump(tester, speech: speech);

    for (final word in ['I', 'want', 'more']) {
      await tester.tap(_tile(word));
      await tester.pumpAndSettle();
    }
    expect(speech.spoken, ['I', 'want', 'more']);
    expect(felt, List.filled(3, ChorusHaptic.wordTapped));
    expect(_stripText(tester), 'I want more');

    await tester.tap(_speak);
    await tester.pumpAndSettle();
    expect(speech.spoken.last, 'I want more');
    expect(felt.last, ChorusHaptic.sentenceSpoken);
    expect(felt.length, 4);
  });

  testWidgets('the voice is woken as the screen opens, so the first word '
      'is quick', (tester) async {
    final speech = FakeSpeech();
    await _pump(tester, speech: speech);
    expect(speech.warmUps, 1);
  });

  testWidgets('Speak does nothing while the strip is empty', (tester) async {
    final semantics = tester.ensureSemantics();
    final speech = FakeSpeech();
    await _pump(tester, speech: speech);

    await tester.tap(_speak);
    await tester.pumpAndSettle();
    expect(speech.spoken, isEmpty);
    expect(felt, isEmpty);
    expect(
      tester.getSemantics(find.bySemanticsLabel(OnboardingCopy.speak)),
      isSemantics(
        label: OnboardingCopy.speak,
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    semantics.dispose();
  });

  testWidgets('after Speak the next word starts a new sentence, and a long '
      'one keeps only its newest words', (tester) async {
    await _pump(tester);
    for (final word in ['I', 'want', 'more']) {
      await tester.tap(_tile(word));
      await tester.pump();
    }
    await tester.tap(_speak);
    await tester.pump();
    expect(_stripText(tester), 'I want more');

    await tester.tap(_tile('help'));
    await tester.pump();
    expect(_stripText(tester), 'help');

    for (final word in ['go', 'stop', 'I', 'want']) {
      await tester.tap(_tile(word));
      await tester.pump();
    }
    expect(_stripText(tester), 'go stop I want');
    expect(_stripText(tester).split(' ').length, OnboardingView.stripLength);
    await tester.pumpAndSettle();
  });

  testWidgets('with no voice on the device the board still fills the '
      'strip and nothing fails', (tester) async {
    await _pump(tester, speech: _NoVoice());
    await tester.tap(_tile('help'));
    await tester.pumpAndSettle();
    await tester.tap(_speak);
    await tester.pumpAndSettle();
    expect(_stripText(tester), 'help');
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Make a board for my child" and "I already have one" lead '
      'on', (tester) async {
    final taps = await _pump(tester);
    await tester.tap(find.text(OnboardingCopy.makeBoard));
    await tester.pumpAndSettle();
    expect(taps.makeBoard, 1);
    expect(taps.haveOne, 0);
    await tester.tap(find.text(OnboardingCopy.haveOne));
    await tester.pumpAndSettle();
    expect(taps.haveOne, 1);
  });

  testWidgets('a screen reader hears the heading whole, the board as six '
      'buttons, the strip and Speak', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    expect(
      tester.getSemantics(find.bySemanticsLabel('One board. Many voices.')),
      isSemantics(label: 'One board. Many voices.', isHeader: true),
    );
    for (final word in onboardingWords) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(word)),
        isSemantics(label: word, isButton: true, hasTapAction: true),
      );
    }
    expect(find.bySemanticsLabel('Sentence, empty'), findsOneWidget);
    expect(find.bySemanticsLabel('Chorus'), findsOneWidget);
    semantics.dispose();
  });

  for (final size in _sizes) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('$label: everything fits without an error, the second line '
        'runs off the right edge on purpose, and the tiles are big enough '
        'to hit', (tester) async {
      for (final dark in [false, true]) {
        await _pump(tester, size: size, dark: dark);
        expect(tester.takeException(), isNull, reason: 'dark: $dark');

        // "Many voices." starts on screen and its full stop falls off it,
        // but no more than its last letter goes.
        final line = find.text(OnboardingCopy.lineTwo);
        final paragraph = tester.renderObject<RenderParagraph>(line);
        final full = paragraph.getMaxIntrinsicWidth(double.infinity);
        final start = tester.getTopLeft(line).dx;
        final past = start + full - size.width;
        expect(start, lessThan(size.width / 2 + size.width / 4));
        expect(past, greaterThan(0), reason: 'it runs off the edge');
        expect(past, lessThan(full * 0.12), reason: 'it can still be read');

        final tile = tester.getSize(_tile('want'));
        expect(tile.shortestSide, greaterThanOrEqualTo(48));
        expect(tester.getSize(_speak).shortestSide, greaterThanOrEqualTo(48));
      }
    });
  }

  for (final size in [const Size(360, 640), const Size(360, 820)]) {
    testWidgets('on an upright ${size.height.toInt()} phone both ways on '
        'are in the bottom third, 8 apart', (tester) async {
      await _pump(tester, size: size);
      final make = tester.getRect(
        find.ancestor(
          of: find.text(OnboardingCopy.makeBoard),
          matching: find.byType(PressableSurface),
        ),
      );
      final have = tester.getRect(
        find.widgetWithText(TextButton, 'I already have one'),
      );
      expect(make.top, greaterThan(size.height * 2 / 3));
      expect(have.bottom, lessThanOrEqualTo(size.height));
      expect(have.top - make.bottom, greaterThanOrEqualTo(8));
      expect(have.height, greaterThanOrEqualTo(48));
    });
  }

  testWidgets('at twice the text size nothing breaks, and the screen '
      'scrolls to both ways on', (tester) async {
    for (final size in _sizes) {
      final taps = await _pump(tester, size: size, textScale: 2);
      expect(tester.takeException(), isNull, reason: '$size');
      await tester.ensureVisible(find.text(OnboardingCopy.haveOne));
      await tester.pumpAndSettle();
      await tester.tap(find.text(OnboardingCopy.haveOne));
      await tester.pumpAndSettle();
      expect(taps.haveOne, 1, reason: '$size');
    }
  });

  testWidgets('in the dark the page is slate, the strip a raised panel, and '
      'the words read on both', (tester) async {
    await _pump(tester, dark: true);
    const dark = ChorusColors.dark;
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor ??
          Theme.of(
            tester.element(find.byType(Scaffold)),
          ).scaffoldBackgroundColor,
      dark.card,
    );
    final strip = tester.widget<Container>(
      find.descendant(
        of: find.byKey(OnboardingView.stripKey),
        matching: find.byType(Container),
      ),
    );
    expect((strip.decoration! as BoxDecoration).color, dark.surface);
    Color ink(Finder text) =>
        tester.renderObject<RenderParagraph>(text).text.style!.color!;
    expect(
      _contrast(ink(find.text(OnboardingCopy.body)), dark.card),
      greaterThanOrEqualTo(7),
    );
    expect(
      _contrast(ink(find.text(OnboardingCopy.lineOne)), dark.card),
      greaterThanOrEqualTo(7),
    );
    expect(
      _contrast(ink(find.text(OnboardingCopy.emptyStrip)), dark.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      tester.widget<PressableSurface>(_tile('I')).color,
      TileFamily.person.dark.fill,
    );
  });

  testWidgets('under reduced motion the board lies flat, and the screen '
      'fades in all at once in 150 ms', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        OnboardingView(
          speech: FakeSpeech(),
          onMakeBoard: () {},
          onHaveOne: () {},
        ),
        reduced: true,
      ),
    );
    expect(find.byKey(BoardObject.tiltKey), findsNothing);
    double opacityOf(String text) => tester
        .widget<Opacity>(
          find
              .ancestor(of: find.text(text), matching: find.byType(Opacity))
              .first,
        )
        .opacity;
    await tester.pump(const Duration(milliseconds: 75));
    // Every part at the same point of the same fade, none moved.
    expect(opacityOf(OnboardingCopy.body), closeTo(0.5, 0.05));
    expect(opacityOf(OnboardingCopy.makeBoard), closeTo(0.5, 0.05));
    for (final transform in tester.widgetList<Transform>(
      find.ancestor(
        of: find.text(OnboardingCopy.body),
        matching: find.byType(Transform),
      ),
    )) {
      expect(transform.transform.getTranslation().y, 0);
    }
    await tester.pump(const Duration(milliseconds: 80));
    expect(opacityOf(OnboardingCopy.makeBoard), 1);
    expect(tester.hasRunningAnimations, isFalse);

    // A tap still speaks and fills the strip.
    await tester.tap(_tile('go'));
    await tester.pump();
    expect(_stripText(tester), 'go');
  });

  testWidgets('with motion, the parts arrive in turn, and the board tilts '
      'under the thumb', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        OnboardingView(
          speech: FakeSpeech(),
          onMakeBoard: () {},
          onHaveOne: () {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    double opacityOf(String text) => tester
        .widget<Opacity>(
          find
              .ancestor(of: find.text(text), matching: find.byType(Opacity))
              .first,
        )
        .opacity;
    // The mark is on its way while the actions have not started.
    expect(opacityOf('chorus'), greaterThan(0));
    expect(opacityOf(OnboardingCopy.makeBoard), 0);
    await tester.pumpAndSettle();
    expect(opacityOf(OnboardingCopy.makeBoard), 1);

    expect(find.byKey(BoardObject.tiltKey), findsOneWidget);
  });

  testWidgets('it waits for the launch reveal before it comes in', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: chorusTheme(),
        builder: (context, child) => LaunchReveal(child: child!),
        home: OnboardingView(
          speech: FakeSpeech(),
          onMakeBoard: () {},
          onHaveOne: () {},
        ),
      ),
    );
    double lockupOpacity() => tester
        .widget<Opacity>(
          find
              .ancestor(of: find.text('chorus'), matching: find.byType(Opacity))
              .first,
        )
        .opacity;
    await tester.pump(const Duration(milliseconds: 600));
    expect(lockupOpacity(), 0);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
    expect(lockupOpacity(), greaterThan(0));
    await tester.pumpAndSettle();
    expect(lockupOpacity(), 1);
  });

  testWidgets('animateIn: false shows everything at once', (tester) async {
    await tester.pumpWidget(
      _app(
        OnboardingView(
          speech: FakeSpeech(),
          animateIn: false,
          onMakeBoard: () {},
          onHaveOne: () {},
        ),
      ),
    );
    final opacity = tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.text(OnboardingCopy.makeBoard),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;
    expect(opacity, 1);
  });
}
