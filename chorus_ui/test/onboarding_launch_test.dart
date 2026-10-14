// The launch: the chorus reveal plays once over the first screen, which is
// built underneath from the first frame, then fades away; under reduced
// motion it shows its last frame and goes.
import 'package:chorus_ui/brand/reveal.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/onboarding/launch_reveal.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the app's first screen: counts how often it was made and
/// tapped, and shows whether the reveal is over.
class _Screen extends StatefulWidget {
  const _Screen();

  static int made = 0;

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  int taps = 0;

  @override
  void initState() {
    super.initState();
    _Screen.made++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => setState(() => taps++),
          child: Text(
            '${LaunchReveal.isOver(context) ? 'over' : 'playing'} $taps',
          ),
        ),
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  bool reduced = false,
  bool play = true,
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _Screen.made = 0;
  await tester.pumpWidget(
    MaterialApp(
      theme: chorusTheme(),
      darkTheme: chorusDarkTheme(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: LaunchReveal(play: play, child: child!),
      ),
      home: const _Screen(),
    ),
  );
}

void main() {
  testWidgets('the reveal covers the first screen, which is made at once '
      'underneath, then fades away after 0.9 s, the screen kept as it was', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    expect(find.byKey(LaunchReveal.overlayKey), findsOneWidget);
    expect(find.byType(ChorusReveal), findsOneWidget);
    expect(_Screen.made, 1, reason: 'built under the reveal');
    expect(find.text('playing 0'), findsOneWidget);
    // Touches stop at the reveal, and a screen reader hears only "Chorus".
    await tester.tap(find.text('playing 0'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('playing 0'), findsOneWidget);
    expect(find.bySemanticsLabel('Chorus'), findsOneWidget);
    expect(find.bySemanticsLabel('playing 0'), findsNothing);

    await tester.pump(const Duration(milliseconds: 850));
    expect(find.text('playing 0'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    // Over: the screen may start its own entrance while the reveal fades.
    expect(find.text('over 0'), findsOneWidget);
    expect(find.byKey(LaunchReveal.overlayKey), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(LaunchReveal.overlayKey), findsNothing);
    expect(_Screen.made, 1, reason: 'the same screen, not a new one');

    await tester.tap(find.text('over 0'));
    await tester.pump();
    expect(find.text('over 1'), findsOneWidget);
    expect(find.bySemanticsLabel('over 1'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('it plays once: rebuilding the app does not bring it back', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();
    await _pump(tester);
    await tester.pump();
    expect(find.byKey(LaunchReveal.overlayKey), findsNothing);
  });

  testWidgets('under reduced motion it shows the settled board and goes in '
      'a 150 ms crossfade', (tester) async {
    await _pump(tester, reduced: true);
    final painter =
        tester.widget<CustomPaint>(find.byKey(ChorusReveal.paintKey)).painter!
            as RevealPainter;
    expect(painter.progress.value, 1, reason: 'the final frame');

    await tester.pump();
    expect(find.text('over 0'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(LaunchReveal.overlayKey), findsOneWidget);
    // Just past the 150 ms of the fade.
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    expect(find.byKey(LaunchReveal.overlayKey), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('play: false shows the screen at once', (tester) async {
    await _pump(tester, play: false);
    expect(find.byKey(LaunchReveal.overlayKey), findsNothing);
    expect(find.text('over 0'), findsOneWidget);
  });

  testWidgets('the reveal is drawn on card, and on slate in the dark', (
    tester,
  ) async {
    for (final dark in [false, true]) {
      await _pump(tester, dark: dark);
      final page = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byKey(LaunchReveal.overlayKey),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(
        page.color,
        dark ? ChorusColors.dark.card : ChorusColors.light.card,
      );
      await tester.pumpAndSettle();
      // A fresh app for the next mode.
      await tester.pumpWidget(const SizedBox());
    }
  });

  test('it starts from the mark at the size the Android splash draws it', () {
    // The reveal's first frame draws the mark 0.42 of its side.
    expect(
      LaunchReveal.revealSizeFor(const Size(412, 915)) * 0.42,
      closeTo(LaunchReveal.splashMark, 0.01),
    );
    // A small screen keeps a margin.
    expect(LaunchReveal.revealSizeFor(const Size(300, 500)), 268);
  });
}
