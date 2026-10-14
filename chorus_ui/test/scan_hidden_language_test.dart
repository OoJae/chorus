// Switch scanning sees the board as the child does: a hidden word is blank
// and silent to a switch too, and a word shown in the second language is
// previewed, chosen and put on the strip in it, as a tap would. Only words
// shown in the second language are said with its voice.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts_device.dart';
import 'package:chorus_ui/contracts_language.dart';
import 'package:chorus_ui/device/device_settings_scope.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_device.dart';
import 'package:chorus_ui/fakes_hidden_language.dart';
import 'package:chorus_ui/talker/talker_controller.dart';
import 'package:chorus_ui/talker/talker_access.dart' show scanStripHighlightKey;
import 'package:chorus_ui/talker/switch_scanner.dart' show scanHighlightKey;
import 'package:chorus_ui/talker/talker_extras.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/talker/word_tools/word_tools.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _yoruba = HomeLanguage(code: 'yo', name: 'Yoruba');

/// The home board's placed words, by cell.
Map<(int, int), TileFacts> _homeCells(FakeBoardStore store) {
  final home = store.boards.firstWhere((b) => b.isHome);
  return gridOf(home.id, store.tiles, store.boards);
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  DeviceSettings settings = const DeviceSettings(
    scanMode: ScanMode.twoSwitches,
  ),
}) async {
  tester.view.physicalSize = const Size(1024, 768);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    DeviceSettingsScope(
      store: InMemoryDeviceSettings(settings),
      child: MaterialApp(theme: chorusTheme(), home: screen),
    ),
  );
  await tester.pump();
}

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  late FakeBoardStore store;
  late TileFacts first;
  late TileFacts second;
  late TileFacts third;

  setUp(() {
    store = FakeBoardStore.seeded(withWordsBoard: false);
    final cells = _homeCells(store);
    first = cells[(0, 0)]!;
    second = cells[(0, 1)]!;
    third = cells[(0, 2)]!;
  });

  group('a hidden word and switch scanning', () {
    testWidgets('the highlight skips it and a switch never chooses it', (
      tester,
    ) async {
      final speech = FakeSpeech();
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          hiddenWords: FakeHiddenWords(hidden: {second.id}),
        ),
        settings: const DeviceSettings(
          scanMode: ScanMode.twoSwitches,
          scanPreview: true,
        ),
      );
      expect(find.byKey(ValueKey('hidden-${second.id}')), findsOneWidget);
      // Row 0 opens on the first word; space goes past the blank cell.
      await _press(tester, LogicalKeyboardKey.enter);
      await _press(tester, LogicalKeyboardKey.space);
      expect(speech.spoken, [first.spokenText, third.spokenText]);
      await _press(tester, LogicalKeyboardKey.enter);
      expect(speech.spoken, [
        first.spokenText,
        third.spokenText,
        third.spokenText,
      ]);
      expect(speech.spoken, isNot(contains(second.spokenText)));
      await _close(tester);
    });

    testWidgets('"Show everything" lets the switch reach it again', (
      tester,
    ) async {
      final speech = FakeSpeech();
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          hiddenWords: FakeHiddenWords(hidden: {second.id}),
        ),
      );
      await tester.tap(find.byKey(TalkerChromeToggle.showEverythingKey));
      await tester.pump();
      await _press(tester, LogicalKeyboardKey.enter);
      await _press(tester, LogicalKeyboardKey.space);
      await _press(tester, LogicalKeyboardKey.enter);
      expect(speech.spoken, [second.spokenText]);
      await _close(tester);
    });
  });

  group('the sentence strip and switch scanning', () {
    bool stripRinged(WidgetTester tester) {
      final box = tester.widget<DecoratedBox>(
        find.byKey(scanStripHighlightKey),
      );
      return (box.decoration as BoxDecoration).border != null;
    }

    testWidgets('after the last row the strip is a stop: a switch says the '
        'sentence and clears it, and nothing moves', (tester) async {
      final handle = tester.ensureSemantics();
      final speech = FakeSpeech();
      await _pump(
        tester,
        TalkerScreen(store: store, speech: speech, sync: FakeSyncStatus()),
      );
      final rects = {
        for (final finder in [
          find.byKey(scanStripHighlightKey),
          find.byKey(ValueKey(first.id)),
          find.byKey(ValueKey(third.id)),
        ])
          finder: tester.getRect(finder),
      };
      final rows = {for (final (row, _) in _homeCells(store).keys) row}.length;
      // An empty strip is never a stop: the rows go round to row 0.
      expect(stripRinged(tester), isFalse);
      for (var i = 0; i < rows; i++) {
        await _press(tester, LogicalKeyboardKey.space);
        expect(stripRinged(tester), isFalse);
      }
      // Row 0: choose its first word.
      await _press(tester, LogicalKeyboardKey.enter);
      await _press(tester, LogicalKeyboardKey.enter);
      expect(speech.spoken, [first.spokenText]);
      expect(find.bySemanticsLabel('Sentence: ${first.label}'), findsOneWidget);
      // Past the last row: the strip.
      for (var i = 0; i < rows; i++) {
        await _press(tester, LogicalKeyboardKey.space);
      }
      expect(stripRinged(tester), isTrue);
      expect(find.byKey(scanHighlightKey), findsOneWidget);
      for (final MapEntry(key: finder, value: rect) in rects.entries) {
        expect(tester.getRect(finder), rect, reason: 'nothing moves');
      }
      await _press(tester, LogicalKeyboardKey.enter);
      await tester.pump();
      expect(speech.spoken, [first.spokenText, first.spokenText]);
      expect(find.bySemanticsLabel('Sentence, empty'), findsOneWidget);
      expect(stripRinged(tester), isFalse);
      handle.dispose();
      await _close(tester);
    });
  });

  group('the second language and switch scanning', () {
    late FakeHomeLanguages languages;

    setUp(() {
      languages = FakeHomeLanguages(
        language: _yoruba,
        words: {
          first.id: WordInLanguage(
            tileId: first.id,
            label: 'omi',
            speech: 'omi o',
          ),
        },
      );
    });

    testWidgets('preview, choice and strip are in the language shown', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
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
        settings: const DeviceSettings(
          scanMode: ScanMode.twoSwitches,
          scanPreview: true,
        ),
      );
      await tester.tap(find.byKey(TalkerChromeToggle.languageKey));
      await tester.pump();
      await _press(tester, LogicalKeyboardKey.enter);
      expect(voice.said, ['yo: omi o'], reason: 'the preview');
      expect(speech.spoken, isEmpty);
      await _press(tester, LogicalKeyboardKey.enter);
      expect(voice.said, ['yo: omi o', 'yo: omi o']);
      expect(find.bySemanticsLabel('Sentence: omi'), findsOneWidget);
      handle.dispose();
      await _close(tester);
    });
  });

  group('the second language voice', () {
    late FakeHomeLanguages languages;
    late FakeSpeech speech;
    late FakeLanguageVoice voice;
    late TalkerExtras extras;
    late TalkerController controller;

    setUp(() {
      languages = FakeHomeLanguages(
        language: _yoruba,
        words: {
          first.id: WordInLanguage(
            tileId: first.id,
            label: 'omi',
            speech: 'omi o',
          ),
          second.id: WordInLanguage(
            tileId: second.id,
            label: 'fe',
            speech: 'fe',
          ),
        },
      );
      speech = FakeSpeech();
      voice = FakeLanguageVoice(codes: {'yo'});
      extras = TalkerExtras(
        isSafe: () => true,
        languages: languages,
        voice: voice,
      );
      controller = TalkerController(
        store: store,
        speech: extras.speechFor(speech, strip: () => controller.strip)!,
        speaker: extras.speakerFor(null, speech, (_) => null),
      );
      addTearDown(controller.dispose);
      addTearDown(extras.dispose);
      extras.setLanguageOn(true);
    });

    test('a sentence of words shown in it is said with its voice', () async {
      controller.tapTile(extras.shownTile(first));
      controller.tapTile(extras.shownTile(second));
      await pumpEventQueue();
      voice.said.clear();
      await controller.speakStrip();
      expect(voice.said, ['yo: omi o fe']);
    });

    test(
      'a quick phrase or typed word is said in the first language',
      () async {
        controller.tapTile(extras.shownTile(first));
        await pumpEventQueue();
        controller.addWords([stripWord('I need a break', kind: 'phrase')]);
        controller.addWords([stripWord('cake')]);
        await pumpEventQueue();
        expect(voice.said, ['yo: omi o']);
        expect(speech.spoken, ['I need a break', 'cake']);
        // A sentence that mixes them is said in the first language too.
        await controller.speakStrip();
        expect(voice.said, ['yo: omi o']);
        expect(speech.spoken.last, 'omi o I need a break cake');
      },
    );

    test(
      'a scene spot and a new ending are said in the first language',
      () async {
        controller.addOtherWord(stripWord('swing', kind: 'scene'));
        await pumpEventQueue();
        controller.tapTile(extras.shownTile(first));
        await pumpEventQueue();
        controller.replaceLastWord(stripWord('omis', kind: 'ending'));
        await pumpEventQueue();
        expect(voice.said, ['yo: omi o']);
        expect(speech.spoken, ['swing', 'omis']);
      },
    );

    test('a word put on the strip before the switch came on stays in the '
        'first language', () async {
      extras.setLanguageOn(false);
      controller.tapTile(extras.shownTile(first));
      extras.setLanguageOn(true);
      controller.tapTile(extras.shownTile(second));
      await pumpEventQueue();
      voice.said.clear();
      speech.spoken.clear();
      await controller.speakStrip();
      expect(voice.said, isEmpty);
      expect(speech.spoken, ['${first.spokenText} fe']);
    });
  });
}
