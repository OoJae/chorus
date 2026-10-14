// The screen a second tab shows: ink on card, the words kept, the one
// action in reach of the thumb, in light and dark, at the largest text and
// the five window sizes. The gate's behaviour is in one_tab_gate_test.dart.
import 'package:chorus_flutter/screens/other_tab_screen.dart';
import 'package:chorus_ui/brand/mark.dart';
import 'package:chorus_ui/brand/test_fonts.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/theme.dart';
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

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(360, 800),
  bool dark = false,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: chorusTheme(),
      darkTheme: chorusDarkTheme(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: screen,
    ),
  );
}

void main() {
  setUpAll(loadChorusFonts);

  testWidgets('says where Chorus is, in the title face, with the brand '
      'above and the action at the bottom', (tester) async {
    var used = 0;
    await _pump(tester, OtherTabScreen(onUseHere: () => used++));
    final title = find.text('Chorus is open in another tab');
    expect(title, findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(title).text.style!.fontFamily,
      ChorusType.title.fontFamily,
    );
    expect(find.byType(ChorusLockup), findsOneWidget);
    final action = find.text('Use Chorus in this tab');
    expect(tester.getCenter(action).dy, greaterThan(800 * 2 / 3));
    await tester.tap(action);
    expect(used, 1);
  });

  testWidgets('after a move it says so', (tester) async {
    await _pump(tester, OtherTabScreen(onUseHere: () {}, moved: true));
    expect(find.text('Chorus moved to another tab'), findsOneWidget);
    expect(find.text('Chorus is open in another tab'), findsNothing);
  });

  for (final size in _sizes) {
    for (final dark in [false, true]) {
      testWidgets('fits ${size.width.toInt()}x${size.height.toInt()}, '
          '${dark ? 'dark' : 'light'}, at twice the text', (tester) async {
        var used = 0;
        await _pump(
          tester,
          OtherTabScreen(onUseHere: () => used++),
          size: size,
          dark: dark,
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        final ink = tester
            .renderObject<RenderParagraph>(
              find.text('Chorus is open in another tab'),
            )
            .text
            .style!
            .color;
        expect(ink, dark ? ChorusColors.dark.ink : ChorusColors.light.ink);
        await tester.scrollUntilVisible(
          find.text('Use Chorus in this tab'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Use Chorus in this tab'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Use Chorus in this tab'));
        expect(used, 1);
      });
    }
  }
}
