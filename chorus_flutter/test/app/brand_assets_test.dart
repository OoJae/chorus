// The brand as the app bundles it from chorus_ui: the three typefaces under
// the names the type styles ask for, and a picture for every pictured word.
// chorus_ui's own tests run that package as the app, where its files have
// other names, so only these tests see what a phone or a browser loads.
import 'dart:convert';

import 'package:chorus_ui/brand/symbols.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Families by name, with their files, as the engine reads them at start.
Future<Map<String, List<String>>> _fontManifest() async {
  final entries =
      jsonDecode(await rootBundle.loadString('FontManifest.json'))
          as List<Object?>;
  return {
    for (final entry in entries.cast<Map<String, Object?>>())
      entry['family']! as String: [
        for (final font
            in (entry['fonts']! as List<Object?>).cast<Map<String, Object?>>())
          font['asset']! as String,
      ],
  };
}

double _width(WidgetTester tester, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// Width and height from a PNG's header, after checking it is a PNG.
(int, int) _pngSize(ByteData bytes) {
  expect(bytes.buffer.asUint8List(bytes.offsetInBytes, 8), [
    137, 80, 78, 71, 13, 10, 26, 10, //
  ]);
  return (bytes.getUint32(16), bytes.getUint32(20));
}

void main() {
  late Map<String, List<String>> fonts;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    fonts = await _fontManifest();
    // `flutter test` does not load the app's fonts by itself; load them as
    // the engine does on a device: by the manifest's names, from the bundle.
    for (final MapEntry(key: family, value: files) in fonts.entries) {
      if (!family.startsWith('packages/chorus_ui/')) continue;
      final loader = FontLoader(family);
      for (final file in files) {
        loader.addFont(rootBundle.load(file));
      }
      await loader.load();
    }
  });

  test('the app bundles the three typefaces under the names the type '
      'styles use', () {
    expect(fonts['packages/chorus_ui/Fraunces'], [
      'packages/chorus_ui/assets/fonts/Fraunces-Variable.ttf',
    ]);
    expect(fonts['packages/chorus_ui/AtkinsonHyperlegibleNext'], [
      'packages/chorus_ui/assets/fonts/AtkinsonHyperlegibleNext-Variable.ttf',
    ]);
    expect(fonts['packages/chorus_ui/IBMPlexMono'], [
      'packages/chorus_ui/assets/fonts/IBMPlexMono-Medium.ttf',
    ]);
    for (final style in [
      ChorusType.display,
      ChorusType.title,
      ChorusType.headline,
      ChorusType.body,
      ChorusType.label,
      ChorusType.status,
      ChorusType.tileLabel(24),
      ChorusType.wordmark(32),
    ]) {
      expect(fonts.keys, contains(style.fontFamily));
    }
  });

  testWidgets('every type style draws its own typeface, not the test '
      'squares', (tester) async {
    final roles = {
      'display': ChorusType.display,
      'title': ChorusType.title,
      'headline': ChorusType.headline,
      'body': ChorusType.body,
      'label': ChorusType.label,
      'status': ChorusType.status,
      'tile label': ChorusType.tileLabel(24),
      'wordmark': ChorusType.wordmark(32),
    };
    for (final MapEntry(key: role, value: style) in roles.entries) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Text('iiii', style: style)),
        ),
      );
      // A family that does not resolve falls back to the test font, which
      // draws every letter as a square a whole size wide.
      final drawn = tester.getSize(find.text('iiii')).width;
      expect(drawn, lessThan(4 * style.fontSize! * 0.8), reason: role);
    }

    // And each family is its own file: the same words differ in width.
    const words = 'Hamburgefonstiv 1Il';
    final widths = {
      for (final family in [
        ChorusType.display.fontFamily,
        ChorusType.body.fontFamily,
        ChorusType.status.fontFamily,
      ])
        _width(tester, words, TextStyle(fontFamily: family, fontSize: 20)),
    };
    expect(widths, hasLength(3));
  });

  test('every pictured word finds its picture in the app, at each '
      'density', () async {
    expect(symbolWords, hasLength(23));
    for (final word in symbolWords) {
      for (final (ratio, dir, size) in [
        (1.0, '', 128),
        (2.0, '2.0x/', 256),
        (3.0, '3.0x/', 384),
      ]) {
        final key = await symbolImageFor(word)!.obtainKey(
          ImageConfiguration(bundle: rootBundle, devicePixelRatio: ratio),
        );
        expect(key.name, 'packages/chorus_ui/assets/symbols/$dir$word.png');
        expect(key.scale, ratio);
        expect(_pngSize(await key.bundle.load(key.name)), (size, size));
      }
    }
  });

  testWidgets('a picture decodes and draws on a tile-sized box', (
    tester,
  ) async {
    final want = symbolImageFor('Want')!;
    await tester.pumpWidget(Image(image: want, width: 64, height: 64));
    await tester.runAsync(
      () => precacheImage(want, tester.element(find.byType(Image))),
    );
    await tester.pump();

    // The version for the screen's density: 3x on the test's screen.
    final drawn = tester.widget<RawImage>(find.byType(RawImage)).image;
    expect(drawn, isNotNull);
    expect(drawn!.width, 128 * tester.view.devicePixelRatio);
    expect(tester.takeException(), isNull);
  });
}
