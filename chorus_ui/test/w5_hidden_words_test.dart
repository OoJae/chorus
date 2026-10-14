// Hide and reveal words in place (W5, item 10): a hidden word is a blank,
// silent cell that keeps its place, changes reach the child's board only at
// a safe moment, "Show everything" shows them all until the board is left,
// and the editor marks and offers it.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/editor/word_extras.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_hidden_language.dart';
import 'package:chorus_ui/features/flags/w5.dart';
import 'package:chorus_ui/talker/talker_controller.dart';
import 'package:chorus_ui/talker/talker_extras.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(1024, 768),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: chorusTheme(), home: screen));
  await tester.pump();
}

/// Lets the board's quiet time pass. Its clock is a real stopwatch, so the
/// two seconds are real; then the next check of the safe moment runs.
Future<void> _quietTime(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 2100)),
  );
  await tester.pump(const Duration(seconds: 1));
}

Finder _tile(String label) =>
    find.byWidgetPredicate((w) => w is TileView && w.tile.label == label);

/// The home board's placed words, in reading order.
List<TileFacts> _homeWords(FakeBoardStore store) {
  final home = store.boards.firstWhere((b) => b.isHome);
  return gridOf(home.id, store.tiles, store.boards).values.toList();
}

void main() {
  test('the flags are on', () {
    expect(hideWordsEnabled, isTrue);
  });

  group('TalkerExtras', () {
    test('a word hidden elsewhere waits for a safe moment', () async {
      var safe = false;
      final hidden = FakeHiddenWords();
      final extras = TalkerExtras(isSafe: () => safe, hidden: hidden);
      addTearDown(extras.dispose);

      await hidden.setHidden('a', true);
      expect(extras.hides('a'), isFalse, reason: 'not a safe moment yet');
      expect(extras.checkSafePoint(), isFalse);

      safe = true;
      expect(extras.checkSafePoint(), isTrue);
      expect(extras.hides('a'), isTrue);

      // Shown again: it waits the same way.
      safe = false;
      await hidden.setHidden('a', false);
      expect(extras.hides('a'), isTrue);
      safe = true;
      expect(extras.checkSafePoint(), isTrue);
      expect(extras.hides('a'), isFalse);
    });

    test('at a safe moment a change applies at once', () async {
      final hidden = FakeHiddenWords();
      final extras = TalkerExtras(isSafe: () => true, hidden: hidden);
      addTearDown(extras.dispose);
      await hidden.setHidden('a', true);
      expect(extras.hides('a'), isTrue);
    });

    test('"Show everything" shows every hidden word until it is off', () {
      final extras = TalkerExtras(
        isSafe: () => false,
        hidden: FakeHiddenWords(hidden: {'a', 'b'}),
      );
      addTearDown(extras.dispose);
      expect(extras.hides('a'), isTrue);
      expect(extras.offersShowEverything, isTrue);
      extras.setShowEverything(true);
      expect(extras.hides('a'), isFalse);
      expect(extras.hides('b'), isFalse);
      extras.setShowEverything(false);
      expect(extras.hides('a'), isTrue);
    });

    test('with nothing hidden "Show everything" is not offered', () {
      final extras = TalkerExtras(
        isSafe: () => true,
        hidden: FakeHiddenWords(),
      );
      addTearDown(extras.dispose);
      expect(extras.offersShowEverything, isFalse);
      expect(TalkerExtras.maybe(isSafe: () => true), isNull);
    });
  });

  group('TalkerController.atSafePoint', () {
    test('is false with a word in the strip or right after a touch', () {
      final store = FakeBoardStore.seeded();
      final controller = TalkerController(
        store: store,
        speech: FakeSpeech(),
        quiet: Duration.zero,
      );
      addTearDown(controller.dispose);
      expect(controller.atSafePoint, isTrue);

      controller.touchDown();
      expect(controller.atSafePoint, isFalse, reason: 'a finger is down');
      controller.touchUp();
      expect(controller.atSafePoint, isTrue);

      controller.tapTile(_homeWords(store).first);
      expect(controller.atSafePoint, isFalse, reason: 'the strip has a word');
      controller.clearStrip();
      expect(controller.atSafePoint, isTrue);
    });
  });

  group('the child board', () {
    testWidgets('a hidden word is a blank, silent cell and nothing moves', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      final speech = FakeSpeech();
      final words = _homeWords(store);
      final gone = words[0];
      final next = words[1];
      final hidden = FakeHiddenWords();

      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          hiddenWords: hidden,
        ),
      );
      final before = tester.getRect(_tile(next.label));
      final cell = tester.getRect(_tile(gone.label));
      expect(find.byKey(TalkerChromeToggle.showEverythingKey), findsNothing);

      await hidden.setHidden(gone.id, true);
      // Two quiet seconds and the next check of the safe moment.
      await _quietTime(tester);

      expect(_tile(gone.label), findsNothing);
      expect(find.byType(HiddenWordCell), findsOneWidget);
      expect(tester.getRect(find.byType(HiddenWordCell)).center, cell.center);
      expect(tester.getRect(_tile(next.label)), before, reason: 'no move');

      await tester.tap(find.byType(HiddenWordCell), warnIfMissed: false);
      await tester.pump();
      expect(speech.spoken, isEmpty, reason: 'a hidden word is silent');

      // "Show everything" is in the chrome now, and shows the word in place.
      expect(find.byKey(TalkerChromeToggle.showEverythingKey), findsOneWidget);
      expect(find.text(showEverythingLabel), findsOneWidget);
      await tester.tap(find.byKey(TalkerChromeToggle.showEverythingKey));
      await tester.pump();
      expect(_tile(gone.label), findsOneWidget);
      expect(tester.getRect(_tile(gone.label)), cell);
      expect(tester.getRect(_tile(next.label)), before);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a word hidden while the strip holds a sentence waits', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      final words = _homeWords(store);
      final hidden = FakeHiddenWords();
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: FakeSpeech(),
          sync: FakeSyncStatus(),
          hiddenWords: hidden,
        ),
      );
      await tester.tap(_tile(words[1].label));
      await tester.pump();

      await hidden.setHidden(words[0].id, true);
      await _quietTime(tester);
      expect(_tile(words[0].label), findsOneWidget, reason: 'strip not empty');

      await tester.tap(find.bySemanticsLabel('Clear'));
      await tester.pump(const Duration(seconds: 1));
      expect(_tile(words[0].label), findsOneWidget, reason: 'just touched');
      await _quietTime(tester);
      expect(_tile(words[0].label), findsNothing);
      expect(find.byType(HiddenWordCell), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Show everything" is forgotten when the board is left', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      final gone = _homeWords(store).first;
      final hidden = FakeHiddenWords(hidden: {gone.id});
      Widget board() => TalkerScreen(
        store: store,
        speech: FakeSpeech(),
        sync: FakeSyncStatus(),
        hiddenWords: hidden,
      );
      await _pump(tester, board());
      expect(_tile(gone.label), findsNothing);
      await tester.tap(find.byKey(TalkerChromeToggle.showEverythingKey));
      await tester.pump();
      expect(_tile(gone.label), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await _pump(tester, board());
      expect(_tile(gone.label), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the editor', () {
    testWidgets('a hidden word is dimmed with a mark, and the sheet shows it '
        'again', (tester) async {
      final store = FakeBoardStore.seeded();
      final gone = _homeWords(store).first;
      final hidden = FakeHiddenWords(hidden: {gone.id});
      await _pump(
        tester,
        EditorScreen(store: store, sync: FakeSyncStatus(), hiddenWords: hidden),
      );
      expect(find.byType(HiddenWordMark), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HiddenWordMark),
          matching: _tile(gone.label),
        ),
        findsOneWidget,
      );

      await tester.tap(_tile(gone.label));
      await tester.pumpAndSettle();
      expect(find.text(showAgainLabel), findsOneWidget);
      expect(find.text(hideForNowLabel), findsNothing);
      await tester.tap(find.text(showAgainLabel));
      await tester.pumpAndSettle();
      expect(hidden.hiddenIds, isEmpty);
      expect(find.byType(HiddenWordMark), findsNothing);
      expect(find.text(shownAgainMessage(gone.label)), findsOneWidget);
    });

    testWidgets('"Hide for now" hides the word and keeps its cell taken', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      final word = _homeWords(store).first;
      final hidden = FakeHiddenWords();
      await _pump(
        tester,
        EditorScreen(store: store, sync: FakeSyncStatus(), hiddenWords: hidden),
      );
      final cell = tester.getRect(_tile(word.label));
      await tester.tap(_tile(word.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(hideForNowLabel));
      await tester.pumpAndSettle();

      expect(hidden.hiddenIds, {word.id});
      expect(find.text(hiddenMessage(word.label)), findsOneWidget);
      expect(find.byType(HiddenWordMark), findsOneWidget);
      expect(tester.getRect(_tile(word.label)), cell);
      // The cell is still the word's: no "Add a word here" in its place.
      expect(store.tiles.where((t) => t.id == word.id).single.archived, false);
    });

    testWidgets('a partner gets no hide action', (tester) async {
      final store = FakeBoardStore.seeded();
      final word = _homeWords(store).first;
      final hidden = FakeHiddenWords(canChange: false);
      await _pump(
        tester,
        EditorScreen(store: store, sync: FakeSyncStatus(), hiddenWords: hidden),
      );
      await tester.tap(_tile(word.label));
      await tester.pumpAndSettle();
      expect(find.text(hideForNowLabel), findsNothing);
    });
  });

  test('the words for a parent are plain', () {
    for (final text in [
      showEverythingLabel,
      showEverythingOnMessage,
      showEverythingOffMessage,
      hideForNowLabel,
      showAgainLabel,
      hiddenForNowMark,
      hiddenMessage('more'),
      shownAgainMessage('more'),
      notKeptMessage,
    ]) {
      final lower = text.toLowerCase();
      expect(lower, isNot(contains('conflict')));
      expect(lower, isNot(contains('error')));
      expect(lower, isNot(contains('sync')));
      expect(lower, isNot(contains('replica')));
    }
    expect(
      hiddenMessage('more'),
      '"more" is hidden for now. Its spot stays '
      'the same.',
    );
  });
}
