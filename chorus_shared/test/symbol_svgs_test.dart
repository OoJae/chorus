import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

void main() {
  const words = [
    'finished', 'get', 'go', 'good', 'help', 'i', 'in', 'look', 'make', //
    'more', 'on', 'open', 'put', 'same', 'some', 'turn', 'up', 'want', //
    'what', 'when', 'where', 'who', 'why',
  ];

  test('all 23 symbols resolve to inline SVG markup', () {
    expect(symbolSvgs.keys, unorderedEquals(words));
    for (final word in words) {
      final svg = symbolSvgFor(word);
      expect(svg, isNotNull, reason: word);
      expect(svg, startsWith('<svg'), reason: word);
      expect(svg, contains('</svg>'), reason: word);
      expect(svg, isNot(contains('<?xml')), reason: word);
      expect(svg, isNot(contains('<!')), reason: word);
    }
  });

  test('lookup ignores case and surrounding spaces', () {
    expect(symbolSvgFor('I'), symbolSvgs['i']);
    expect(symbolSvgFor('  Want '), symbolSvgs['want']);
    expect(symbolSvgFor('banana'), isNull);
    expect(symbolSvgFor(''), isNull);
  });

  test('every symbol sits on one page without clashing with another', () {
    final ids = <String>{};
    final classes = <String>{};
    for (final MapEntry(key: word, value: svg) in symbolSvgs.entries) {
      for (final m in RegExp(r'\bid="([^"]+)"').allMatches(svg)) {
        expect(m[1], startsWith('$word-'), reason: word);
        expect(ids.add(m[1]!), isTrue, reason: 'duplicate id ${m[1]}');
      }
      // Classes styled by the symbol's own <style> must be its own.
      for (final css in RegExp(r'<style>(.*?)</style>').allMatches(svg)) {
        for (final c in RegExp(r'\.([A-Za-z_][\w-]*)').allMatches(css[1]!)) {
          expect(c[1], startsWith('$word-'), reason: word);
          classes.add(c[1]!);
        }
      }
    }
    expect(ids, isNotEmpty);
    expect(classes, contains('get-st0'));
    expect(classes, contains('go-st0'));
  });
}
