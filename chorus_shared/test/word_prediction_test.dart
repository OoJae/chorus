import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

void main() {
  group('predictionWords', () {
    test('holds every starter word once, and a few hundred words', () {
      final lower = [for (final w in predictionWords) w.toLowerCase()];
      expect(lower.toSet().length, lower.length);
      for (final word in universalCore36) {
        expect(lower, contains(word.label.toLowerCase()));
      }
      expect(predictionWords.length, greaterThan(300));
    });

    test('puts the core words first', () {
      expect(predictionWords.take(36), containsAll(['I', 'want', 'more']));
    });
  });

  group('predictWords', () {
    test('offers three words that start with the letters, best first', () {
      final words = predictWords('w');
      expect(words, hasLength(3));
      expect(words.first, 'want');
      for (final word in words) {
        expect(word.toLowerCase(), startsWith('w'));
      }
    });

    test('narrows with each letter', () {
      expect(predictWords('he').first, 'help');
      expect(predictWords('hel'), ['help', 'hello']);
      expect(predictWords('juic'), ['juice']);
      expect(predictWords('zzz'), isEmpty);
    });

    test('ignores case', () {
      expect(predictWords('WA').first, 'want');
      expect(predictWords('i').first, 'I');
    });

    test('a word this device has spoken comes first', () {
      expect(predictWords('w').first, 'want');
      final counts = {'water': 2};
      expect(predictWords('w', counts: counts).first, 'water');
      expect(predictWords('w', counts: {'water': 2, 'walk': 9}).take(2), [
        'walk',
        'water',
      ]);
    });

    test('offers spoken words the list does not have', () {
      expect(predictWords('mab', counts: {'mabel': 3}), ['mabel']);
    });

    test('an empty prefix offers the most likely words', () {
      expect(predictWords(''), hasLength(3));
      expect(predictWords('', counts: {'dinosaur': 5}).first, 'dinosaur');
    });

    test('respects the limit', () {
      expect(predictWords('s', limit: 5), hasLength(5));
      expect(predictWords('s', limit: 0), isEmpty);
    });

    test('a ranked list of its own can be used', () {
      expect(predictWords('b', words: ['bus', 'ball', 'bed']), [
        'bus',
        'ball',
        'bed',
      ]);
    });
  });

  group('typing helpers', () {
    test('wordBeingTyped is the letters after the last space', () {
      expect(wordBeingTyped(''), '');
      expect(wordBeingTyped('he'), 'he');
      expect(wordBeingTyped('I want ju'), 'ju');
      expect(wordBeingTyped('I want '), '');
    });

    test('completeWord replaces the word being typed', () {
      expect(completeWord('I want ju', 'juice'), 'I want juice ');
      expect(completeWord('he', 'help'), 'help ');
      expect(completeWord('I ', 'want'), 'I want ');
    });
  });

  group('countSpokenWords', () {
    test('counts each word by its lowercase form', () {
      var counts = countSpokenWords(const {}, 'I want Juice');
      counts = countSpokenWords(counts, 'juice please!');
      expect(counts, {'i': 1, 'want': 1, 'juice': 2, 'please': 1});
    });

    test('skips numbers and marks', () {
      expect(countSpokenWords(const {}, '42 ? -- ok'), {'ok': 1});
    });

    test('keeps at most maxWords, dropping the least used', () {
      var counts = <String, int>{'go': 5, 'up': 1};
      counts = countSpokenWords(counts, 'cat', maxWords: 2);
      expect(counts.length, 2);
      expect(counts, containsPair('go', 5));
    });
  });

  group('quick phrases', () {
    test('the defaults are the six the brief names', () {
      expect(defaultQuickPhrases, [
        'Stop',
        'Help',
        "I'm hurt",
        'Toilet',
        'All done',
        'I need a break',
      ]);
    });

    test('cleanQuickPhrases trims, drops empties and repeats, and caps', () {
      expect(cleanQuickPhrases(['  Stop ', '', 'stop', 'Help   me']), [
        'Stop',
        'Help me',
      ]);
      final many = [for (var i = 0; i < 40; i++) 'Phrase $i'];
      expect(cleanQuickPhrases(many), hasLength(maxQuickPhrases));
      final long = 'a' * 200;
      expect(cleanQuickPhrases([long]).single.length, maxQuickPhraseLength);
    });
  });
}
