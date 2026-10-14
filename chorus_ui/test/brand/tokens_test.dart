// The design tokens: contrast that holds in both modes, the colour key
// mapped from the stored keys, type that names the bundled fonts, and the
// space rules.
import 'dart:math' as math;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2 contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

const _modes = {'light': ChorusColors.light, 'dark': ChorusColors.dark};

void main() {
  group('contrast', () {
    for (final brightness in Brightness.values) {
      test('the tile label is at least 9:1 on every fill '
          '(${brightness.name})', () {
        for (final family in TileFamily.values) {
          final fill = family.colorsFor(brightness).fill;
          expect(
            contrast(tileLabelInk, fill),
            greaterThanOrEqualTo(9),
            reason: '${family.name} in ${brightness.name}',
          );
        }
      });

      test('every edge is darker than its fill (${brightness.name})', () {
        for (final family in TileFamily.values) {
          final colors = family.colorsFor(brightness);
          expect(
            colors.edge.computeLuminance(),
            lessThan(colors.fill.computeLuminance()),
            reason: family.name,
          );
        }
      });
    }

    _modes.forEach((mode, c) {
      test('ink and muted ink read on card and surface ($mode)', () {
        for (final background in [c.card, c.surface]) {
          // AAA for ink, AA for the secondary text.
          expect(contrast(c.ink, background), greaterThanOrEqualTo(7));
          expect(contrast(c.inkMuted, background), greaterThanOrEqualTo(4.5));
          expect(contrast(c.alert, background), greaterThanOrEqualTo(4.5));
        }
        // Card text on an ink button.
        expect(contrast(c.card, c.ink), greaterThanOrEqualTo(7));
      });
    });

    test('dark fills are less bright than light ones, so they do not glare '
        'on slate', () {
      for (final family in TileFamily.values) {
        expect(
          family.dark.fill.computeLuminance(),
          lessThan(family.light.fill.computeLuminance()),
          reason: family.name,
        );
      }
    });
  });

  group('tile families', () {
    test('every stored key of the starter board has its family', () {
      expect(TileFamily.forKey('verb'), TileFamily.action);
      expect(TileFamily.forKey('pronoun'), TileFamily.person);
      expect(TileFamily.forKey('descriptor'), TileFamily.describe);
      expect(TileFamily.forKey('question'), TileFamily.question);
      expect(TileFamily.forKey('negation'), TileFamily.not);
      expect(TileFamily.forKey('determiner'), TileFamily.other);
      for (final key in colorForKey.keys) {
        expect(TileFamily.forKey(key), isA<TileFamily>(), reason: key);
      }
    });

    test('each family\'s light fill is the shared colour key, so screen, '
        'paper copy and view-only page agree', () {
      // The server prints and shares from colorForKey; the screen draws from
      // the families.
      for (final MapEntry(:key, :value) in colorForKey.entries) {
        expect(
          TileFamily.forKey(key).light.fill.toARGB32(),
          value,
          reason: key,
        );
      }
    });

    test('the picker fallback names map too, in any case', () {
      expect(TileFamily.forKey('action'), TileFamily.action);
      expect(TileFamily.forKey('person'), TileFamily.person);
      expect(TileFamily.forKey('adjective'), TileFamily.describe);
      expect(TileFamily.forKey(' Verb '), TileFamily.action);
      expect(TileFamily.forKey('other'), TileFamily.other);
    });

    test('no key, or one the key does not know, is other', () {
      expect(TileFamily.forKey(null), TileFamily.other);
      expect(TileFamily.forKey(''), TileFamily.other);
      expect(TileFamily.forKey('noun'), TileFamily.other);
    });

    test('the plan\'s fills and edges', () {
      expect(TileFamily.action.light.fill, const Color(0xFFC7EFB2));
      expect(TileFamily.action.light.edge, const Color(0xFF7DB863));
      expect(TileFamily.person.dark.fill, const Color(0xFFE7D57D));
      expect(TileFamily.not.light.edge, const Color(0xFFD88858));
      expect(TileFamily.other.dark.edge, const Color(0xFF8D8C87));
    });
  });

  group('colours', () {
    test('the plan\'s light and dark values', () {
      expect(ChorusColors.light.card, const Color(0xFFF6F2EA));
      expect(ChorusColors.light.ink, const Color(0xFF15171A));
      expect(ChorusColors.dark.card, const Color(0xFF101214));
      expect(ChorusColors.dark.surface, const Color(0xFF1B1E22));
      expect(ChorusColors.dark.alert, const Color(0xFFFF8A7A));
    });

    testWidgets('screens read them from the theme, and get the light set '
        'under a theme without them', (tester) async {
      late ChorusColors fromChorus;
      late ChorusColors fromDark;
      late ChorusColors fromBare;
      await tester.pumpWidget(
        Column(
          children: [
            Theme(
              data: chorusTheme(),
              child: Builder(
                builder: (context) {
                  fromChorus = Theme.of(context).extension<ChorusColors>()!;
                  return const SizedBox();
                },
              ),
            ),
            Theme(
              data: chorusDarkTheme(),
              child: Builder(
                builder: (context) {
                  fromDark = ChorusColors.of(context);
                  return const SizedBox();
                },
              ),
            ),
            Theme(
              data: ThemeData(),
              child: Builder(
                builder: (context) {
                  fromBare = ChorusColors.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      );
      expect(fromChorus, same(ChorusColors.light));
      expect(fromDark, same(ChorusColors.dark));
      expect(fromBare, same(ChorusColors.light));
    });

    test('they blend for a theme change', () {
      final half = ChorusColors.light.lerp(ChorusColors.dark, 0.5);
      expect(
        half.card,
        Color.lerp(ChorusColors.light.card, ChorusColors.dark.card, 0.5),
      );
      expect(ChorusColors.light.lerp(null, 0.5), same(ChorusColors.light));
    });
  });

  group('type', () {
    final roles = {
      'display': ChorusType.display,
      'title': ChorusType.title,
      'headline': ChorusType.headline,
      'body': ChorusType.body,
      'label': ChorusType.label,
      'status': ChorusType.status,
      'tileLabel': ChorusType.tileLabel(20),
      'wordmark': ChorusType.wordmark(32),
    };

    test('every role names its font from the chorus_ui package, so the app '
        'finds it', () {
      roles.forEach((name, style) {
        expect(
          style.fontFamily,
          startsWith('packages/chorus_ui/'),
          reason: name,
        );
      });
      expect(ChorusType.display.fontFamily, 'packages/chorus_ui/Fraunces');
      expect(
        ChorusType.body.fontFamily,
        'packages/chorus_ui/AtkinsonHyperlegibleNext',
      );
      expect(ChorusType.status.fontFamily, 'packages/chorus_ui/IBMPlexMono');
    });

    test('sizes, line heights and tracking from the plan', () {
      void check(TextStyle style, double size, double line, double tracking) {
        expect(style.fontSize, size);
        expect(style.fontSize! * style.height!, closeTo(line, 0.001));
        expect(style.letterSpacing ?? 0, closeTo(tracking * size, 0.001));
      }

      check(ChorusType.display, 48, 50, -0.02);
      check(ChorusType.title, 30, 34, 0);
      check(ChorusType.headline, 19, 24, 0);
      check(ChorusType.body, 17, 25, 0);
      check(ChorusType.label, 15, 20, 0.02);
      check(ChorusType.status, 13, 16, 0.04);
      expect(ChorusType.headline.fontWeight, FontWeight.w700);
      expect(ChorusType.body.fontWeight, FontWeight.w400);
      expect(ChorusType.label.fontWeight, FontWeight.w600);
      expect(ChorusType.status.fontWeight, FontWeight.w500);
    });

    test('Fraunces is set soft, not wonky, at weight 600 and its own optical '
        'size', () {
      for (final style in [ChorusType.display, ChorusType.title]) {
        final axes = {for (final v in style.fontVariations!) v.axis: v.value};
        expect(axes['wght'], 600);
        expect(axes['SOFT'], 100);
        expect(axes['WONK'], 0);
        expect(axes['opsz'], style.fontSize);
      }
      final small = ChorusType.frauncesAt(ChorusType.title, 22, 28);
      expect(
        small.fontVariations!.singleWhere((v) => v.axis == 'opsz').value,
        22,
      );
    });

    test('Atkinson takes its weight from fontWeight, so a copy at another '
        'weight still draws at it', () {
      // An explicit wght would pin the weight: TileLabelSizer and TileView
      // set w700 on the inherited body style.
      for (final style in [
        ChorusType.headline,
        ChorusType.body,
        ChorusType.label,
      ]) {
        expect(
          style.fontVariations?.where((v) => v.axis == 'wght') ?? const [],
          isEmpty,
        );
      }
    });

    test('a tile label is Atkinson 700 at the board\'s one size', () {
      final style = ChorusType.tileLabel(23.5);
      expect(style.fontSize, 23.5);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.fontFamily, ChorusType.body.fontFamily);
      expect(style.letterSpacing, ChorusType.body.letterSpacing);
    });

    testWidgets('display type follows the reader\'s text scale only up to '
        '1.3; body text is not capped', (tester) async {
      late TextScaler display;
      late TextScaler body;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Builder(
            builder: (context) {
              display = ChorusType.displayScaler(context);
              body = MediaQuery.textScalerOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(display.scale(48), closeTo(48 * 1.3, 0.001));
      expect(body.scale(17), 34);
    });
  });

  group('space and shape', () {
    test('margins are 20 on phones and 32 from 600 wide', () {
      expect(ChorusSpace.margin(360), 20);
      expect(ChorusSpace.margin(599), 20);
      expect(ChorusSpace.margin(600), 32);
      expect(ChorusSpace.margin(1280), 32);
    });

    test('the grid, radii and the laminated edge', () {
      expect(ChorusSpace.steps(3), 12);
      expect(ChorusSpace.tileRadius, 14);
      expect(ChorusSpace.buttonRadius, 16);
      expect(ChorusSpace.panelRadius, 24);
      expect(ChorusSpace.sheetRadius, 28);
      expect(ChorusSpace.edge, 3);
      expect(ChorusSpace.edgePressed, 1);
      expect(ChorusSpace.pressSink, 2);
      expect(ChorusSpace.minTarget, 48);
      expect(ChorusSpace.tileRadiusFor(100), 14);
      expect(ChorusSpace.tileRadiusFor(30), lessThan(14));
    });

    test('an edge is its face, darker', () {
      const face = Color(0xFFEEE9E0);
      expect(
        edgeFor(face).computeLuminance(),
        lessThan(face.computeLuminance()),
      );
    });
  });
}
