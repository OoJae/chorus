import 'dart:io';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/brand/symbols.dart';
import 'package:chorus_ui/credits/credits_screen.dart';
import 'package:chorus_ui/features/flags/w7.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // These tests describe every picture on show; with a feature flag off,
  // some are hidden on purpose.
  const allOn = coreSymbolsEnabled && readyMadeBoardsEnabled;
  const skipReason = 'a symbol feature flag is off';

  test('every listed word resolves to its picture in this package', () {
    if (!allOn) return markTestSkipped(skipReason);
    expect(starterSymbolWords, hasLength(36));
    expect(readyBoardSymbolWords, hasLength(92));
    expect(symbolWords, hasLength(128));
    expect(symbolWords.toSet(), hasLength(128), reason: 'no word twice');
    for (final word in symbolWords) {
      expect(symbolAssetFor(word), 'assets/symbols/$word.png');
      final image = symbolImageFor(word)!;
      expect(image.assetName, 'assets/symbols/$word.png');
      expect(image.package, 'chorus_ui');
      expect(image.keyName, 'packages/chorus_ui/assets/symbols/$word.png');
    }
  });

  test(
    'every picture loads through the asset bundle, at each density',
    () async {
      if (!allOn) return markTestSkipped(skipReason);
      // This package's own tests run it as the app, so the bundle lists the
      // files under their own paths: the picture must be found that way too,
      // or every board in these tests and in main_fake loses its pictures.
      for (final word in symbolWords) {
        for (final (ratio, size) in [(1.0, 128), (2.0, 256), (3.0, 384)]) {
          final key = await symbolImageFor(word)!.obtainKey(
            ImageConfiguration(bundle: rootBundle, devicePixelRatio: ratio),
          );
          expect(key.scale, ratio, reason: '$word at ${ratio}x');
          final bytes = await key.bundle.load(key.name);
          expect(_pngSize(bytes.buffer.asUint8List(bytes.offsetInBytes)), (
            size,
            size,
          ), reason: key.name);
        }
      }
    },
  );

  test('a word without a picture resolves to nothing', () {
    for (final label in [
      'crackers',
      'likes',
      'stops',
      'wants',
      'want more',
      '',
    ]) {
      expect(symbolAssetFor(label), isNull, reason: label);
      expect(symbolImageFor(label), isNull, reason: label);
    }
  });

  test('case and surrounding spaces are ignored', () {
    expect(symbolAssetFor('I'), 'assets/symbols/i.png');
    expect(symbolAssetFor(' Want '), 'assets/symbols/want.png');
    expect(symbolAssetFor('FINISHED'), 'assets/symbols/finished.png');
    expect(symbolAssetFor('\twhere\n'), 'assets/symbols/where.png');
    expect(symbolImageFor(' I ')!.assetName, 'assets/symbols/i.png');
  });

  test('the pictured words are the starter words, the same ones the paper '
      'copy pictures', () {
    final starter = {for (final w in universalCore36) w.label.toLowerCase()};
    expect(starterSymbolWords.toSet(), starter);
    expect(symbolWords.toSet(), symbolSvgs.keys.toSet());
  });

  test('every starter word shows a picture, the 13 added ones included', () {
    if (!coreSymbolsEnabled) return markTestSkipped(skipReason);
    expect(addedCoreSymbols, hasLength(13));
    expect(chorusDrawnSymbols, hasLength(8));
    expect(symbolWords, containsAll(addedCoreSymbols));
    for (final word in universalCore36) {
      expect(symbolImageFor(word.label), isNotNull, reason: word.label);
    }
    for (final word in ['like', 'not', 'He', 'She', 'all', 'stop', 'it']) {
      expect(
        symbolAssetFor(word),
        'assets/symbols/${word.toLowerCase()}.png',
        reason: word,
      );
    }
  });

  test('every picture is on disk at all three densities, at its size', () {
    for (final word in symbolWords) {
      for (final (dir, size) in [('', 128), ('2.0x/', 256), ('3.0x/', 384)]) {
        final file = File('assets/symbols/$dir$word.png');
        expect(file.existsSync(), isTrue, reason: file.path);
        final (width, height) = _pngSize(file.readAsBytesSync());
        expect(width, size, reason: file.path);
        expect(height, size, reason: file.path);
      }
    }
  });

  test('the licence travels with the pictures', () {
    final licence = File('assets/symbols/LICENSE.md').readAsStringSync();
    expect(licence, contains('Mulberry Symbols'));
    expect(licence, contains('Steve Lee'));
    expect(licence, contains('creativecommons.org/licenses/by-sa/4.0'));
    expect(licence, contains('the Chorus authors'));
    for (final word in chorusDrawnSymbols) {
      expect(licence, contains(word), reason: word);
    }
  });

  test('the symbol sources travel with the pictures', () {
    final sources = File(
      'symbols_src/mulberry/SOURCES.txt',
    ).readAsLinesSync().where((line) => line.isNotEmpty);
    expect({
      for (final line in sources) line.split('|').first,
    }, readyBoardSymbolWords.toSet());
    for (final word in [...addedCoreSymbols, ...readyBoardSymbolWords]) {
      final folder = chorusDrawnSymbols.contains(word) ? 'chorus' : 'mulberry';
      final file = File('symbols_src/$folder/$word.svg');
      expect(file.existsSync(), isTrue, reason: file.path);
      expect(file.readAsStringSync(), contains('<svg'), reason: file.path);
    }
  });

  testWidgets('the credits screen gives the pictures and typefaces their '
      'attribution', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreditsScreen()));
    expect(
      find.textContaining('Mulberry Symbols by Steve Lee'),
      findsOneWidget,
    );
    expect(find.textContaining('licensed CC BY-SA 4.0'), findsOneWidget);
    expect(find.text(mulberrySymbolsCredit), findsOneWidget);
    expect(
      find.text(chorusSymbolsCredit),
      coreSymbolsEnabled ? findsOneWidget : findsNothing,
    );
    expect(chorusSymbolsCredit, contains('the Chorus authors'));
    for (final word in chorusDrawnSymbols) {
      expect(chorusSymbolsCredit, contains(word), reason: word);
    }
    expect(find.textContaining('without the original symbols'), findsNothing);
    // Each paragraph is selectable text with a scrollable of its own, so name
    // the list's.
    await tester.scrollUntilVisible(
      find.textContaining('SIL Open Font License 1.1'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('SIL Open Font License 1.1'), findsOneWidget);
  });
}

/// Width and height from a PNG's header, after checking it is a PNG.
(int, int) _pngSize(Uint8List bytes) {
  expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
  final header = ByteData.sublistView(bytes);
  return (header.getUint32(16), header.getUint32(20));
}
