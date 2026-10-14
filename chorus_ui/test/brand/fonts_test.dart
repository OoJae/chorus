// The three bundled families: declared, shipped with their licences,
// variable fonts that the engine draws at the weight asked for, and loadable
// by tests that measure real text.
import 'dart:convert';
import 'dart:io';

import 'package:chorus_ui/brand/test_fonts.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads a bundled font file under [family], for measuring real glyphs.
Future<void> _load(String family, String asset) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(asset));
  await loader.load();
}

double _width(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the font manifest lists the three families and their files', () async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json'))
            as List<Object?>;
    final assets = {
      for (final entry in manifest.cast<Map<String, Object?>>())
        entry['family']: [
          for (final font
              in (entry['fonts']! as List<Object?>)
                  .cast<Map<String, Object?>>())
            font['asset'],
        ],
    };
    // Run as its own app, the package's families have bare names; the app
    // that depends on it sees them as packages/chorus_ui/<family>.
    expect(assets['Fraunces'], ['assets/fonts/Fraunces-Variable.ttf']);
    expect(assets['AtkinsonHyperlegibleNext'], [
      'assets/fonts/AtkinsonHyperlegibleNext-Variable.ttf',
    ]);
    expect(assets['IBMPlexMono'], ['assets/fonts/IBMPlexMono-Medium.ttf']);
  });

  test('each font has its Open Font License next to it', () {
    for (final family in [
      'Fraunces',
      'AtkinsonHyperlegibleNext',
      'IBMPlexMono',
    ]) {
      final licence = File('assets/fonts/$family-OFL.txt');
      expect(licence.existsSync(), isTrue, reason: family);
      expect(licence.readAsStringSync(), contains('SIL Open Font License'));
    }
  });

  test('the variable Atkinson draws heavier, and wider, at w700 with no '
      'wght axis given', () async {
    await _load(
      'AtkinsonUnderTest',
      'assets/fonts/AtkinsonHyperlegibleNext-Variable.ttf',
    );
    const text = 'Many voices';
    const style = TextStyle(fontFamily: 'AtkinsonUnderTest', fontSize: 40);
    final regular = _width(text, style);
    final bold = _width(text, style.copyWith(fontWeight: FontWeight.w700));
    expect(bold, greaterThan(regular));
  });

  test('Fraunces answers its optical size axis', () async {
    await _load('FrauncesUnderTest', 'assets/fonts/Fraunces-Variable.ttf');
    const text = 'One board';
    const base = TextStyle(
      fontFamily: 'FrauncesUnderTest',
      fontSize: 40,
      fontWeight: FontWeight.w600,
    );
    final small = _width(
      text,
      base.copyWith(
        fontVariations: const [
          FontVariation.weight(600),
          FontVariation.opticalSize(9),
        ],
      ),
    );
    final large = _width(
      text,
      base.copyWith(
        fontVariations: const [
          FontVariation.weight(600),
          FontVariation.opticalSize(144),
        ],
      ),
    );
    // Small optical sizes are drawn wider, for legibility.
    expect(small, isNot(closeTo(large, 0.5)));
  });

  // Last: the fonts it loads stay loaded for the rest of this file.
  test('loadChorusFonts gives tests the real fonts under the names the type '
      'roles use', () async {
    // The test font draws every letter a full square.
    expect(
      _width('il', ChorusType.body),
      closeTo(_width('WW', ChorusType.body), 0.01),
    );

    await loadChorusFonts();

    for (final style in [ChorusType.body, ChorusType.display]) {
      expect(_width('il', style), lessThan(_width('WW', style) * 0.6));
    }
    // Plex Mono is narrower than a square, and every letter the same.
    final mono = _width('MMMM', ChorusType.status);
    expect(mono, lessThan(4 * ChorusType.status.fontSize! * 0.8));
    expect(_width('iiii', ChorusType.status), closeTo(mono, 0.01));
  });
}
