// The brand mark, the wordmark and the launch reveal, including its
// reduced-motion path.
import 'dart:io';

import 'package:chorus_ui/brand/mark.dart';
import 'package:chorus_ui/brand/reveal.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {bool reduced = false, double textScale = 1}) =>
    MaterialApp(
      theme: chorusTheme(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduced,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );

double _progress(WidgetTester tester) =>
    (tester.widget<CustomPaint>(find.byKey(ChorusReveal.paintKey)).painter!
            as RevealPainter)
        .progress
        .value;

void main() {
  group('mark', () {
    test('four tiles in the key colours, the top-left one raised', () {
      const box = Rect.fromLTWH(0, 0, 100, 100);
      final tiles = MarkGeometry.tilesIn(box);
      expect(tiles.map((t) => t.family), [
        TileFamily.action,
        TileFamily.person,
        TileFamily.describe,
        TileFamily.question,
      ]);
      for (final tile in tiles) {
        expect(box.contains(tile.outer.topLeft), isTrue);
        expect(tile.outer.bottom, lessThanOrEqualTo(box.bottom + 0.001));
        expect(tile.face.bottom, lessThan(tile.outer.bottom));
      }
      final [raised, beside, ...] = tiles;
      expect(raised.face.top, lessThan(beside.face.top));
      expect(raised.outer.bottom, lessThan(beside.outer.bottom));
      expect(raised.edge, closeTo(beside.edge, 0.001));
      // The gaps are wide, so it reads small: a fifth of a tile or more.
      expect(
        beside.outer.left - raised.outer.right,
        greaterThan(0.2 * raised.outer.width),
      );
    });

    test('it is the drawing the app icons and splash are rendered from', () {
      // Every icon, the Android splash and the web loader come from this
      // SVG, so the mark keeps its shape from the system splash into the
      // app's first frame.
      final svg = File('../docs/brand/mark.svg').readAsStringSync();
      double attr(String rect, String name) =>
          double.parse(RegExp(' $name="([0-9.]+)"').firstMatch(rect)![1]!);
      final rects = RegExp(
        r'<rect [^>]*>',
      ).allMatches(svg).map((m) => m[0]!).toList();
      // Each tile is its edge colour drawn whole, then the face over it.
      expect(rects, hasLength(8));
      final tiles = MarkGeometry.tilesIn(const Rect.fromLTWH(0, 0, 64, 64));
      for (final (i, tile) in tiles.indexed) {
        final [whole, face] = rects.sublist(i * 2, i * 2 + 2);
        final light = tile.family.colorsFor(Brightness.light);
        String hex(Color c) =>
            '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'
                .toUpperCase();
        expect(whole, contains('fill="${hex(light.edge)}"'));
        expect(face, contains('fill="${hex(light.fill)}"'));
        expect(
          tile.outer,
          rectMoreOrLessEquals(
            Rect.fromLTWH(
              attr(whole, 'x'),
              attr(whole, 'y'),
              attr(whole, 'width'),
              attr(whole, 'height'),
            ),
          ),
        );
        expect(tile.face.height, closeTo(attr(face, 'height'), 0.001));
        expect(
          MarkGeometry.radiusFor(tile.outer.width),
          closeTo(attr(whole, 'rx'), 0.001),
        );
      }
    });

    testWidgets('it draws at any size, and is decorative unless labelled', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChorusMark(size: 29),
              ChorusMark(size: 192, semanticLabel: 'Chorus'),
            ],
          ),
        ),
      );
      expect(tester.getSize(find.byType(ChorusMark).first), const Size(29, 29));
      expect(
        tester.getSize(find.byType(ChorusMark).last),
        const Size(192, 192),
      );
      expect(find.bySemanticsLabel('Chorus'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('wordmark', () {
    testWidgets('"chorus" in lowercase Fraunces 600, soft, tracked in', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const ChorusWordmark(size: 40)));
      final text = tester.widget<Text>(find.text('chorus'));
      final style = text.style!;
      expect(style.fontFamily, 'packages/chorus_ui/Fraunces');
      expect(style.fontSize, 40);
      expect(style.letterSpacing, closeTo(-0.8, 0.001));
      expect(style.color, ChorusColors.light.ink);
      final axes = {for (final v in style.fontVariations!) v.axis: v.value};
      expect(axes, {'wght': 600, 'SOFT': 100, 'WONK': 0, 'opsz': 40});
    });

    testWidgets('it grows with the reader\'s text scale only to 1.3', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const ChorusWordmark(), textScale: 2));
      final text = tester.widget<Text>(find.text('chorus'));
      expect(text.textScaler!.scale(10), closeTo(13, 0.001));
    });

    testWidgets('the lockup is the mark left of the word, read as "Chorus"', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(const ChorusLockup()));
      expect(
        tester.getCenter(find.byType(ChorusMark)).dx,
        lessThan(tester.getCenter(find.text('chorus')).dx),
      );
      expect(find.bySemanticsLabel('Chorus'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('reveal', () {
    test('columns leave the mark one after another, bounce, and end exactly '
        'in place', () {
      expect(RevealPainter.travel(0, 0), 0);
      expect(RevealPainter.travel(5, 0.2), 0, reason: 'not started yet');
      expect(
        RevealPainter.travel(0, 0.2),
        greaterThan(RevealPainter.travel(3, 0.2)),
      );
      var most = 0.0;
      for (var t = 0.0; t < 1; t += 0.01) {
        final p = RevealPainter.travel(0, t);
        if (p > most) most = p;
      }
      expect(most, greaterThan(1), reason: 'the chorus spring bounces');
      for (var col = 0; col < 6; col++) {
        expect(RevealPainter.travel(col, 1), 1);
        expect(RevealPainter.travel(col, 0.99), closeTo(1, 0.02));
      }
    });

    testWidgets('it plays for 0.9 s, calls onDone once, and does not play '
        'again', (tester) async {
      var done = 0;
      Widget reveal() => _app(ChorusReveal(onDone: () => done++));
      await tester.pumpWidget(reveal());
      expect(_progress(tester), 0);

      await tester.pump(const Duration(milliseconds: 450));
      expect(_progress(tester), inExclusiveRange(0, 1));
      expect(done, 0);

      await tester.pump(const Duration(milliseconds: 500));
      expect(_progress(tester), 1);
      expect(done, 1);

      await tester.pumpWidget(reveal());
      await tester.pumpAndSettle();
      expect(_progress(tester), 1);
      expect(done, 1);
    });

    testWidgets('under reduced motion it shows the final frame at once, then '
        'calls onDone', (tester) async {
      var done = 0;
      await tester.pumpWidget(
        _app(ChorusReveal(onDone: () => done++), reduced: true),
      );
      expect(_progress(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
      expect(done, 1);
    });
  });
}
