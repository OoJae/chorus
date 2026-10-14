// Home language on the same cells (W5, item 16): a switch in the child's
// chrome shows each word that has one in the circle's second language and
// speaks it with the device's voice for it, else the word's recording, else
// the first-language word. The editor's word sheet offers "Second language".
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts_language.dart';
import 'package:chorus_ui/contracts_media.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/editor/word_extras.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_hidden_language.dart';
import 'package:chorus_ui/features/flags/w5.dart';
import 'package:chorus_ui/talker/talker_extras.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1024, 768);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: chorusTheme(), home: screen));
  await tester.pump();
}

Finder _tile(String label) =>
    find.byWidgetPredicate((w) => w is TileView && w.tile.label == label);

List<TileFacts> _homeWords(FakeBoardStore store) {
  final home = store.boards.firstWhere((b) => b.isHome);
  return gridOf(home.id, store.tiles, store.boards).values.toList();
}

/// Records the tiles it was asked to say.
class _SpySpeaker implements TileSpeaker {
  final List<String> said = [];

  @override
  Future<void> speakTile(TileFacts tile) async => said.add(tile.label);
}

const _yoruba = HomeLanguage(code: 'yo', name: 'Yoruba');

void main() {
  test('the flag is on', () => expect(homeLanguageEnabled, isTrue));

  group('the child board', () {
    late FakeBoardStore store;
    late TileFacts word;
    late TileFacts other;
    late FakeHomeLanguages languages;

    setUp(() {
      store = FakeBoardStore.seeded();
      final words = _homeWords(store);
      word = words[0];
      other = words[1];
      languages = FakeHomeLanguages(
        language: _yoruba,
        words: {
          word.id: WordInLanguage(
            tileId: word.id,
            label: 'omi',
            speech: 'omi o',
          ),
        },
      );
    });

    testWidgets('without a second language there is no switch', (tester) async {
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: FakeSpeech(),
          sync: FakeSyncStatus(),
          languages: FakeHomeLanguages(),
        ),
      );
      expect(find.byKey(TalkerChromeToggle.languageKey), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the switch flips labels in place and the voice says them', (
      tester,
    ) async {
      final speech = FakeSpeech();
      final voice = FakeLanguageVoice(codes: {'yo'});
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          languages: languages,
          languageVoice: voice,
        ),
      );
      final cell = tester.getRect(_tile(word.label));
      final next = tester.getRect(_tile(other.label));
      expect(find.text('Yoruba'), findsOneWidget);

      await tester.tap(find.byKey(TalkerChromeToggle.languageKey));
      await tester.pump();
      expect(_tile('omi'), findsOneWidget);
      expect(_tile(word.label), findsNothing);
      expect(tester.getRect(_tile('omi')), cell, reason: 'same cell');
      expect(_tile(other.label), findsOneWidget, reason: 'no translation');
      expect(tester.getRect(_tile(other.label)), next);

      await tester.tap(_tile('omi'));
      await tester.pump();
      expect(voice.said, ['yo: omi o']);
      expect(speech.spoken, isEmpty);

      // A word with none is said as before.
      await tester.tap(_tile(other.label));
      await tester.pump();
      expect(speech.spoken, [other.spokenText]);

      // And back.
      await tester.tap(find.byKey(TalkerChromeToggle.languageKey));
      await tester.pump();
      expect(_tile(word.label), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with no voice for it, the recording plays, else the first '
        'language', (tester) async {
      final speech = FakeSpeech();
      final speaker = _SpySpeaker();
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          speaker: speaker,
          sync: FakeSyncStatus(),
          languages: languages,
          languageVoice: FakeLanguageVoice(),
        ),
      );
      await tester.tap(find.byKey(TalkerChromeToggle.languageKey));
      await tester.pump();
      await tester.tap(_tile('omi'));
      await tester.pump();
      // The speaker gets the word as the board has it: its recording if it
      // has one, else its first-language text.
      expect(speaker.said, [word.label]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with no voice and no speaker, the first-language word is '
        'said', (tester) async {
      final speech = FakeSpeech();
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          languages: languages,
        ),
      );
      await tester.tap(find.byKey(TalkerChromeToggle.languageKey));
      await tester.pump();
      await tester.tap(_tile('omi'));
      await tester.pump();
      expect(speech.spoken, [word.spokenText]);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the editor', () {
    testWidgets('"Second language" sets the language and the word', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      final word = _homeWords(store).first;
      final languages = FakeHomeLanguages();
      await _pump(
        tester,
        EditorScreen(
          store: store,
          sync: FakeSyncStatus(),
          languages: languages,
        ),
      );
      await tester.tap(_tile(word.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(secondLanguageLabel));
      await tester.pumpAndSettle();

      expect(find.text(secondLanguageTitle(word.label)), findsOneWidget);
      // Yoruba is first when the circle has none yet.
      expect(find.text('Yoruba'), findsOneWidget);
      await tester.enterText(find.byKey(SecondLanguageForm.wordKey), 'omi');
      await tester.tap(find.text(languageSaveLabel));
      await tester.pumpAndSettle();

      expect(languages.language, _yoruba);
      expect(languages.wordFor(word.id)?.label, 'omi');
      expect(find.byType(SecondLanguageForm), findsNothing);
    });

    testWidgets('an empty word removes it', (tester) async {
      final store = FakeBoardStore.seeded();
      final word = _homeWords(store).first;
      final languages = FakeHomeLanguages(
        language: _yoruba,
        words: {word.id: WordInLanguage(tileId: word.id, label: 'omi')},
      );
      await _pump(
        tester,
        EditorScreen(
          store: store,
          sync: FakeSyncStatus(),
          languages: languages,
        ),
      );
      await tester.tap(_tile(word.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(secondLanguageLabel));
      await tester.pumpAndSettle();
      expect(find.text('omi'), findsOneWidget);
      await tester.enterText(find.byKey(SecondLanguageForm.wordKey), '');
      await tester.tap(find.text(languageSaveLabel));
      await tester.pumpAndSettle();
      expect(languages.wordFor(word.id), isNull);
    });

    testWidgets('a partner is not offered it', (tester) async {
      final store = FakeBoardStore.seeded();
      final word = _homeWords(store).first;
      await _pump(
        tester,
        EditorScreen(
          store: store,
          sync: FakeSyncStatus(),
          languages: FakeHomeLanguages(canChange: false),
        ),
      );
      await tester.tap(_tile(word.label));
      await tester.pumpAndSettle();
      expect(find.text(secondLanguageLabel), findsNothing);
    });
  });

  test('the fake keeps words per language', () async {
    final languages = FakeHomeLanguages(language: _yoruba);
    await languages.setWord('a', label: ' omi ', speech: ' ');
    expect(languages.wordFor('a')?.label, 'omi');
    expect(languages.wordFor('a')?.speech, isNull);
    await languages.setLanguage(
      const HomeLanguage(code: 'es', name: 'Spanish'),
    );
    expect(languages.wordFor('a'), isNull);
    await languages.setLanguage(_yoruba);
    expect(languages.wordFor('a')?.label, 'omi');
  });

  test('the words for a parent are plain', () {
    for (final text in [
      secondLanguageLabel,
      secondLanguageTitle('water'),
      languagePickerLabel,
      languageWordLabel,
      languageSpeechLabel,
      languageWordHelper,
      languageOnMessage('Yoruba'),
      languageOffMessage('Yoruba'),
    ]) {
      final lower = text.toLowerCase();
      expect(lower, isNot(contains('conflict')));
      expect(lower, isNot(contains('error')));
      expect(lower, isNot(contains('translation')));
    }
    expect(languageOffMessage('Yoruba'), 'Show the words in Yoruba');
  });
}
