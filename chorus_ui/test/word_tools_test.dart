// The talker's word tools: the word endings key, quick phrases and the
// keyboard with word prediction, and the adults' "Quick phrases" page.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_quick_phrases.dart';
import 'package:chorus_ui/features/flags/w4.dart';
import 'package:chorus_ui/features/quick_phrases_screen.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/talker/word_tools/keyboard_page.dart';
import 'package:chorus_ui/talker/word_tools/word_tools.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _tablet = Size(1200, 1600);
const _portrait = Size(360, 800);
const _landscape = Size(800, 360);

Finder _tile(String label) =>
    find.byWidgetPredicate((w) => w is TileView && w.tile.label == label);

Finder _toolKey(String label) =>
    find.byWidgetPredicate((w) => w is WordToolKey && w.label == label);

final Finder _strip = find.bySemanticsLabel(RegExp('^Sentence'));

/// The sentence as drawn inside the strip.
Finder _sentence(String text) =>
    find.descendant(of: _strip, matching: find.text(text));

class _Talker {
  _Talker(this.speech, this.counts, this.book);

  final FakeSpeech speech;
  final MemorySpokenWordCounts counts;
  final FakeQuickPhraseBook book;
}

Future<_Talker> _pump(
  WidgetTester tester, {
  Size size = _tablet,
  MemorySpokenWordCounts? counts,
  FakeQuickPhraseBook? book,
  BoardStore? store,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final speech = FakeSpeech();
  final talker = _Talker(
    speech,
    counts ?? MemorySpokenWordCounts(),
    book ?? FakeQuickPhraseBook(),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: chorusTheme(),
      home: WordToolsScope(
        phrases: talker.book,
        counts: talker.counts,
        child: TalkerScreen(
          store: store ?? FakeBoardStore.seeded(),
          speech: speech,
          sync: FakeSyncStatus(),
        ),
      ),
    ),
  );
  return talker;
}

void main() {
  test('every word tool is on by default', () {
    expect(w4WordEndings, isTrue);
    expect(w4QuickPhrases, isTrue);
    expect(w4Keyboard, isTrue);
  });

  test('the words parents and children see are plain', () {
    for (final text in [
      wordEndingsLabel,
      quickPhrasesLabel,
      keyboardLabel,
      endingsEmptyMessage,
      backToBoardLabel,
      keyboardSpeakLabel,
      keyboardAddLabel,
      quickPhrasesTitle,
      quickPhrasesIntro,
      phrasesSavedMessage,
      phrasesNotSavedMessage,
      phrasesReadOnlyMessage,
      phrasesFullMessage,
    ]) {
      expect(text, isNotEmpty);
      for (final word in ['conflict', 'sync', 'replica', 'error']) {
        expect(text.toLowerCase(), isNot(contains(word)), reason: text);
      }
    }
    expect(endingsNoneMessage('I'), 'No endings for "I".');
  });

  group('on a tablet', () {
    testWidgets('the three keys sit between the strip and Speak, and Speak, '
        'Delete last word and Clear keep their places at the right', (
      tester,
    ) async {
      await _pump(tester);
      final strip = tester.getRect(_strip);
      final speak = tester.getRect(find.bySemanticsLabel('Speak'));
      final delete = tester.getRect(find.bySemanticsLabel('Delete last word'));
      final clear = tester.getRect(find.bySemanticsLabel('Clear'));
      // The strip's buttons are where they always were: 64 wide, against
      // the right edge with a gap between each.
      expect(clear.right, closeTo(_tablet.width - 6, 0.5));
      expect(clear.width, 64);
      expect(delete.right, closeTo(clear.left - 8, 0.5));
      expect(speak.right, closeTo(delete.left - 8, 0.5));
      for (final label in [
        wordEndingsLabel,
        quickPhrasesLabel,
        keyboardLabel,
      ]) {
        final key = tester.getRect(_toolKey(label));
        expect(key.left, greaterThanOrEqualTo(strip.right), reason: label);
        expect(key.right, lessThanOrEqualTo(speak.left), reason: label);
        expect(key.top, strip.top, reason: label);
        expect(key.height, strip.height, reason: label);
      }
      // The board starts below all of it.
      expect(
        tester.getRect(_tile('like')).top,
        greaterThan(tester.getRect(_toolKey(keyboardLabel)).bottom),
      );
    });

    testWidgets('word endings offer the forms of the last word, and a tap '
        'replaces it and speaks it', (tester) async {
      final talker = await _pump(tester);
      await tester.tap(_tile('I'));
      await tester.tap(_tile('go'));
      await tester.pump();
      await tester.tap(_toolKey(wordEndingsLabel));
      await tester.pumpAndSettle();
      expect(find.text('going'), findsOneWidget);
      expect(find.text('went'), findsOneWidget);
      expect(find.text('goes'), findsOneWidget);
      await tester.tap(find.text('went'));
      await tester.pumpAndSettle();
      expect(_sentence('I went'), findsOneWidget);
      expect(talker.speech.spoken.last, 'went');

      // Again on the new word: the plain word comes back as a choice.
      await tester.tap(_toolKey(wordEndingsLabel));
      await tester.pumpAndSettle();
      expect(find.text('go'), findsWidgets);
      expect(find.text('going'), findsOneWidget);
    });

    testWidgets('word endings say what to do with an empty sentence, and '
        'that a pronoun has none', (tester) async {
      await _pump(tester);
      await tester.tap(_toolKey(wordEndingsLabel));
      await tester.pumpAndSettle();
      expect(find.text(endingsEmptyMessage), findsOneWidget);
      await tester.tap(find.text(backToBoardLabel));
      await tester.pumpAndSettle();

      await tester.tap(_tile('I'));
      await tester.pump();
      await tester.tap(_toolKey(wordEndingsLabel));
      await tester.pumpAndSettle();
      expect(find.text(endingsNoneMessage('I')), findsOneWidget);
    });

    testWidgets('quick phrases open over the board; a tap speaks the phrase, '
        'adds it to the sentence and goes back', (tester) async {
      final talker = await _pump(tester);
      await tester.tap(_toolKey(quickPhrasesLabel));
      await tester.pumpAndSettle();
      for (final phrase in defaultQuickPhrases) {
        expect(find.text(phrase), findsOneWidget, reason: phrase);
      }
      expect(talker.book.refreshes, 1);
      await tester.tap(find.text('I need a break'));
      await tester.pumpAndSettle();
      expect(talker.speech.spoken.last, 'I need a break');
      expect(_sentence('I need a break'), findsOneWidget);
      expect(find.text('Toilet'), findsNothing, reason: 'back on the board');
      // A phrase is not a word to predict.
      expect(talker.counts.counts, isEmpty);
    });

    testWidgets("quick phrases show the circle's own", (tester) async {
      await _pump(
        tester,
        book: FakeQuickPhraseBook(phrases: ['Swing please', 'Too loud']),
      );
      await tester.tap(_toolKey(quickPhrasesLabel));
      await tester.pumpAndSettle();
      expect(find.text('Swing please'), findsOneWidget);
      expect(find.text('Too loud'), findsOneWidget);
      expect(find.text('Toilet'), findsNothing);
    });

    testWidgets('the keyboard predicts as letters are typed, speaks the '
        'line and adds it to the sentence', (tester) async {
      final talker = await _pump(tester);
      await tester.tap(_toolKey(keyboardLabel));
      await tester.pumpAndSettle();
      expect(find.text(keyboardHint), findsOneWidget);

      Finder key(String label) => find.bySemanticsLabel(label);
      await tester.tap(key('j'));
      await tester.pump();
      await tester.tap(key('u'));
      await tester.pump();
      expect(find.text('ju|'), findsOneWidget);
      expect(find.bySemanticsLabel('juice'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('juice'));
      await tester.pump();
      expect(find.text('juice |'), findsOneWidget);

      await tester.tap(key(keyboardSpeakLabel));
      await tester.pump();
      expect(talker.speech.spoken.last, 'juice');

      await tester.tap(key('p'));
      await tester.pump();
      await tester.tap(key(keyboardDeleteLabel));
      await tester.pump();
      expect(find.text('juice |'), findsOneWidget);

      await tester.tap(key(keyboardAddLabel));
      await tester.pumpAndSettle();
      expect(_sentence('juice'), findsOneWidget);
      expect(talker.counts.counts['juice'], greaterThanOrEqualTo(1));
    });

    testWidgets('the keyboard switches between ABC and QWERTY', (tester) async {
      await _pump(tester);
      await tester.tap(_toolKey(keyboardLabel));
      await tester.pumpAndSettle();
      // ABC order: b comes straight after a on the first row.
      final a = tester.getRect(find.bySemanticsLabel('a'));
      final b = tester.getRect(find.bySemanticsLabel('b'));
      expect(b.top, a.top);
      await tester.tap(find.bySemanticsLabel(keyboardQwertyLabel));
      await tester.pump();
      final q = tester.getRect(find.bySemanticsLabel('q'));
      final w = tester.getRect(find.bySemanticsLabel('w'));
      expect(w.top, q.top);
      expect(w.left, greaterThan(q.left));
      expect(
        tester.getRect(find.bySemanticsLabel('a')).top,
        greaterThan(q.top),
        reason: 'a is on the second row',
      );
      // Put back for the next test.
      await tester.tap(find.bySemanticsLabel(keyboardAbcLabel));
      await tester.pump();
    });

    testWidgets("the keyboard puts this device's own words first", (
      tester,
    ) async {
      await _pump(tester, counts: MemorySpokenWordCounts({'giraffe': 3}));
      await tester.tap(_toolKey(keyboardLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('g'));
      await tester.pump();
      final first = predictWords('g', counts: {'giraffe': 3}).first;
      expect(first, 'giraffe');
      expect(find.bySemanticsLabel('giraffe'), findsOneWidget);
    });

    testWidgets('words tapped on the board are counted on this device', (
      tester,
    ) async {
      final talker = await _pump(tester);
      await tester.tap(_tile('want'));
      await tester.tap(_tile('more'));
      await tester.pump();
      expect(talker.counts.counts, {'want': 1, 'more': 1});
    });
  });

  group('on a phone', () {
    for (final (name, size) in [
      ('upright', _portrait),
      ('on its side', _landscape),
    ]) {
      testWidgets('$name: no key takes room from the strip, and holding the '
          'strip offers the word tools', (tester) async {
        final talker = await _pump(tester, size: size);
        expect(_toolKey(quickPhrasesLabel), findsNothing);
        await tester.longPress(_strip);
        await tester.pumpAndSettle();
        expect(find.byType(WordToolsChooser), findsOneWidget);
        await tester.tap(find.bySemanticsLabel(quickPhrasesLabel));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Help'));
        await tester.pumpAndSettle();
        expect(talker.speech.spoken.last, 'Help');
        expect(_sentence('Help'), findsOneWidget);
      });
    }

    testWidgets('a tap on the strip still speaks it', (tester) async {
      final talker = await _pump(tester, size: _portrait);
      await tester.tap(_tile('want'));
      await tester.pump();
      await tester.tap(_strip);
      await tester.pump();
      expect(talker.speech.spoken, ['want', 'want']);
      expect(find.byType(WordToolsChooser), findsNothing);
    });
  });

  group('the "Quick phrases" page', () {
    Future<FakeQuickPhraseBook> open(
      WidgetTester tester, {
      FakeQuickPhraseBook? book,
    }) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final phrases = book ?? FakeQuickPhraseBook();
      await tester.pumpWidget(
        MaterialApp(
          theme: chorusTheme(),
          home: QuickPhrasesScreen(book: phrases),
        ),
      );
      await tester.pumpAndSettle();
      return phrases;
    }

    testWidgets('lists the phrases and saves an added one for everyone', (
      tester,
    ) async {
      final book = await open(tester);
      expect(find.text(quickPhrasesIntro), findsOneWidget);
      for (final phrase in defaultQuickPhrases) {
        expect(find.text(phrase), findsOneWidget);
      }
      await tester.tap(find.text(addPhraseLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Too loud');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Too loud'), findsOneWidget);
      await tester.tap(find.text(savePhrasesLabel));
      await tester.pumpAndSettle();
      expect(book.saved.single, [...defaultQuickPhrases, 'Too loud']);
      expect(find.text(phrasesSavedMessage), findsOneWidget);
    });

    testWidgets('renames, removes and moves a phrase up', (tester) async {
      final book = await open(
        tester,
        book: FakeQuickPhraseBook(phrases: ['One', 'Two', 'Three']),
      );
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Deux');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(movePhraseUpLabel).at(2));
      await tester.pump();
      await tester.tap(find.byTooltip(removePhraseLabel).first);
      await tester.pump();
      await tester.tap(find.text(savePhrasesLabel));
      await tester.pumpAndSettle();
      expect(book.saved.single, ['Three', 'Deux']);
    });

    testWidgets('says so when saving fails, and keeps the edit', (
      tester,
    ) async {
      final book = FakeQuickPhraseBook(phrases: ['One', 'Two'])
        ..failSaves = true;
      await open(tester, book: book);
      await tester.tap(find.byTooltip(removePhraseLabel).first);
      await tester.pump();
      await tester.tap(find.text(savePhrasesLabel));
      await tester.pumpAndSettle();
      expect(find.text(phrasesNotSavedMessage), findsOneWidget);
      expect(find.text('One'), findsNothing);
      expect(book.phrases, ['One', 'Two']);
    });

    testWidgets('the starting phrases can be put back', (tester) async {
      final book = await open(
        tester,
        book: FakeQuickPhraseBook(phrases: ['Mine']),
      );
      await tester.tap(find.text(resetPhrasesLabel));
      await tester.pump();
      await tester.tap(find.text(savePhrasesLabel));
      await tester.pumpAndSettle();
      expect(book.saved.single, defaultQuickPhrases);
    });

    testWidgets('a read-only partner sees them and cannot change them', (
      tester,
    ) async {
      await open(tester, book: FakeQuickPhraseBook(canEdit: false));
      expect(find.text(phrasesReadOnlyMessage), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text(savePhrasesLabel), findsNothing);
      expect(find.text(addPhraseLabel), findsNothing);
    });
  });
}
