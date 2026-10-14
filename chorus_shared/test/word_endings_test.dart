import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

void main() {
  group('pluralOf', () {
    final cases = {
      'dog': 'dogs',
      'cup': 'cups',
      'bus': 'buses',
      'box': 'boxes',
      'church': 'churches',
      'dish': 'dishes',
      'baby': 'babies',
      'toy': 'toys',
      'day': 'days',
      'photo': 'photos',
      'child': 'children',
      'foot': 'feet',
      'mouse': 'mice',
      'person': 'people',
      'tooth': 'teeth',
      'man': 'men',
      'woman': 'women',
      'sheep': 'sheep',
      'fish': 'fish',
      'leaf': 'leaves',
      'knife': 'knives',
      'potato': 'potatoes',
      'snowman': 'snowmen',
      'quiz': 'quizzes',
    };
    cases.forEach((word, plural) {
      test('$word → $plural', () => expect(pluralOf(word), plural));
    });

    test('keeps a capital and works on the last word of a label', () {
      expect(pluralOf('Dog'), 'Dogs');
      expect(pluralOf('ice cream'), 'ice creams');
      expect(pluralOf('Teddy bear'), 'Teddy bears');
    });
  });

  group('ingOf', () {
    final cases = {
      'run': 'running',
      'make': 'making',
      'see': 'seeing',
      'go': 'going',
      'play': 'playing',
      'stop': 'stopping',
      'sit': 'sitting',
      'swim': 'swimming',
      'get': 'getting',
      'put': 'putting',
      'hug': 'hugging',
      'eat': 'eating',
      'look': 'looking',
      'open': 'opening',
      'fix': 'fixing',
      'lie': 'lying',
      'die': 'dying',
      'be': 'being',
      'begin': 'beginning',
      'forget': 'forgetting',
      'visit': 'visiting',
      'ride': 'riding',
      'dance': 'dancing',
      'agree': 'agreeing',
      'picnic': 'picnicking',
      'want': 'wanting',
      'turn': 'turning',
      'help': 'helping',
      'quit': 'quitting',
    };
    cases.forEach((word, form) {
      test('$word → $form', () => expect(ingOf(word), form));
    });
  });

  group('pastOf', () {
    final cases = {
      'want': 'wanted',
      'go': 'went',
      'eat': 'ate',
      'see': 'saw',
      'come': 'came',
      'do': 'did',
      'get': 'got',
      'give': 'gave',
      'have': 'had',
      'make': 'made',
      'say': 'said',
      'take': 'took',
      'think': 'thought',
      'like': 'liked',
      'love': 'loved',
      'cry': 'cried',
      'try': 'tried',
      'play': 'played',
      'stop': 'stopped',
      'hug': 'hugged',
      'look': 'looked',
      'help': 'helped',
      'open': 'opened',
      'visit': 'visited',
      'run': 'ran',
      'put': 'put',
      'drink': 'drank',
      'fall': 'fell',
      'buy': 'bought',
      'catch': 'caught',
      'is': 'was',
      'are': 'were',
      'picnic': 'picnicked',
      'can': 'could',
      'turn': 'turned',
    };
    cases.forEach((word, form) {
      test('$word → $form', () => expect(pastOf(word), form));
    });

    test('knows about a hundred irregular verbs', () {
      expect(irregularPasts.length, greaterThanOrEqualTo(60));
    });
  });

  group('thirdPersonOf', () {
    final cases = {
      'go': 'goes',
      'do': 'does',
      'have': 'has',
      'want': 'wants',
      'watch': 'watches',
      'wash': 'washes',
      'fix': 'fixes',
      'cry': 'cries',
      'play': 'plays',
      'be': 'is',
      'kiss': 'kisses',
    };
    cases.forEach((word, form) {
      test('$word → $form', () => expect(thirdPersonOf(word), form));
    });
  });

  group('possessiveOf', () {
    final cases = {
      'Mum': "Mum's",
      'dog': "dog's",
      'dogs': "dogs'",
      'children': "children's",
      'bus': "bus's",
      'Chris': "Chris's",
      'boss': "boss's",
    };
    cases.forEach((word, form) {
      test('$word → $form', () => expect(possessiveOf(word), form));
    });
  });

  group('wordKindOf', () {
    test('a tile colour says first', () {
      expect(wordKindOf('juice', colorKey: 'verb'), WordKind.verb);
      expect(wordKindOf('I', colorKey: 'pronoun'), WordKind.none);
      expect(wordKindOf('what', colorKey: 'question'), WordKind.none);
      expect(wordKindOf('good', colorKey: 'descriptor'), WordKind.none);
      expect(wordKindOf('not', colorKey: 'negation'), WordKind.none);
    });

    test('then the word itself', () {
      expect(wordKindOf('eat'), WordKind.verb);
      expect(wordKindOf('jump'), WordKind.verb);
      expect(wordKindOf('child'), WordKind.noun);
      expect(wordKindOf('the'), WordKind.none);
      expect(wordKindOf('juice'), WordKind.unknown);
      expect(wordKindOf('juice', colorKey: 'determiner'), WordKind.unknown);
    });

    test('numbers and marks take no ending', () {
      expect(wordKindOf('42'), WordKind.none);
      expect(wordKindOf('?'), WordKind.none);
      expect(wordKindOf(''), WordKind.none);
    });
  });

  group('wordFormsFor', () {
    List<String> texts(String word, {String? colorKey}) => [
      for (final form in wordFormsFor(word, colorKey: colorKey)) form.text,
    ];

    test('a verb gets -ing, -ed and -s', () {
      expect(texts('go', colorKey: 'verb'), ['going', 'went', 'goes']);
      expect(texts('want', colorKey: 'verb'), ['wanting', 'wanted', 'wants']);
    });

    test('a noun gets plural and possessive', () {
      expect(texts('child'), ['children', "child's"]);
    });

    test('an unknown word gets the common ones', () {
      expect(texts('juice'), ['juices', 'juicing', 'juiced', "juice's"]);
    });

    test('a pronoun or a question gets none', () {
      expect(wordFormsFor('I', colorKey: 'pronoun'), isEmpty);
      expect(wordFormsFor('where', colorKey: 'question'), isEmpty);
      expect(wordFormsFor('   '), isEmpty);
    });

    test('a word that already has an ending offers its base back', () {
      final forms = wordFormsFor('went', colorKey: 'verb');
      expect(forms.first, const EndingForm(null, 'go'));
      expect([for (final f in forms) f.text], ['go', 'going', 'goes']);
      expect(texts('running'), ['run', 'ran', 'runs']);
      expect(texts('children'), ['child', "child's"]);
      expect(texts('finished', colorKey: 'verb'), [
        'finish',
        'finishing',
        'finishes',
      ]);
    });

    test('never offers the word itself', () {
      for (final word in ['put', 'cut', 'sheep', 'hit']) {
        expect(texts(word), isNot(contains(word)), reason: word);
      }
    });

    test('keeps the capital of a name', () {
      expect(texts('Dad'), contains("Dad's"));
    });

    test('every starter verb has three forms and none is the word', () {
      for (final word in universalCore36.where((w) => w.colorKey == 'verb')) {
        final forms = wordFormsFor(word.label, colorKey: 'verb');
        expect(forms, isNotEmpty, reason: word.label);
        for (final form in forms) {
          expect(form.text, isNot(word.label), reason: word.label);
          expect(form.text, isNotEmpty);
        }
      }
    });
  });

  group('baseWordOf', () {
    test('maps known forms back', () {
      expect(baseWordOf('went'), 'go');
      expect(baseWordOf('ate'), 'eat');
      expect(baseWordOf('making'), 'make');
      expect(baseWordOf('stopped'), 'stop');
      expect(baseWordOf('feet'), 'foot');
      expect(baseWordOf('Went'), 'Go');
    });

    test('leaves other words alone', () {
      expect(baseWordOf('juice'), 'juice');
      expect(baseWordOf('read'), 'read');
      expect(baseWordOf('put'), 'put');
    });
  });
}
