// The pieces of this wave joined up: the talker with a clip speaker, photos
// and a live session; the editor with model mode and photos; the add-word
// sheet with a suggested word.
import 'dart:async';

import 'package:chorus_ui/contracts_suggest.dart';
import 'package:chorus_ui/editor/add_word_sheet.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_live.dart';
import 'package:chorus_ui/fakes_media.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/tile_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _empty = (4, 5);

/// Answers with [idea], or with whatever [gate] completes with when set.
class _Suggester implements WordSuggester {
  _Suggester({bool available = true}) : available = ValueNotifier(available);

  @override
  final ValueNotifier<bool> available;

  WordIdea? idea;
  Completer<WordIdea?>? gate;
  Object? failWith;
  final List<Uint8List> asked = [];

  @override
  Future<WordIdea?> fromPhoto(Uint8List photo) async {
    asked.add(photo);
    final error = failWith;
    if (error != null) throw error;
    return gate?.future ?? idea;
  }
}

Widget _sheetHost(
  FakeBoardStore store, {
  required FakeMediaStore media,
  required FakeMediaCapture capture,
  WordSuggester? suggester,
}) => MaterialApp(
  theme: chorusTheme(),
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showAddWordSheet(
          context,
          store: store,
          boardId: store.homeBoardId,
          row: _empty.$1,
          col: _empty.$2,
          media: media,
          capture: capture,
          suggester: suggester,
        ),
        child: const Text('open'),
      ),
    ),
  ),
);

Future<void> _openAndPick(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Choose a photo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Choose a photo'));
  await tester.pumpAndSettle();
}

Future<void> _tapSuggest(WidgetTester tester) async {
  await tester.ensureVisible(find.text(suggestFromPhotoLabel));
  await tester.pumpAndSettle();
  await tester.tap(find.text(suggestFromPhotoLabel));
  await tester.pumpAndSettle();
}

Future<void> _pumpTalker(WidgetTester tester, Widget talker) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: chorusTheme(), home: talker));
}

/// Presses Tab until the keyboard is on "Hold to leave".
Future<void> _tabToLeave(WidgetTester tester) async {
  bool there() =>
      Focus.of(tester.element(find.text(leaveLabel))).hasPrimaryFocus;
  for (var presses = 0; !there(); presses++) {
    expect(presses, lessThan(20), reason: 'Tab never gets there');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
}

void main() {
  group('Suggest a word from the photo', () {
    late FakeMediaBoardStore store;
    late FakeMediaStore media;
    late FakeMediaCapture capture;

    setUp(() {
      store = FakeMediaBoardStore.seeded(leaveEmpty: const {_empty});
      media = FakeMediaStore();
      capture = FakeMediaCapture(hasCamera: false);
    });

    testWidgets('is offered only once a photo is picked, and only while '
        'available', (tester) async {
      final suggester = _Suggester();
      await tester.pumpWidget(
        _sheetHost(store, media: media, capture: capture, suggester: suggester),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(suggestFromPhotoLabel), findsNothing);

      await tester.ensureVisible(find.text('Choose a photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose a photo'));
      await tester.pumpAndSettle();
      expect(find.text(suggestFromPhotoLabel), findsOneWidget);
      expect(find.text(suggestSendsPhotoMessage), findsOneWidget);
      // Offering is not asking: nothing has been sent.
      expect(suggester.asked, isEmpty);

      // The connection goes: the offer goes with it.
      suggester.available.value = false;
      await tester.pump();
      expect(find.text(suggestFromPhotoLabel), findsNothing);
    });

    testWidgets('is not offered at all without a suggester', (tester) async {
      await tester.pumpWidget(
        _sheetHost(store, media: media, capture: capture),
      );
      await _openAndPick(tester);
      expect(find.byKey(const ValueKey('word-photo-preview')), findsOneWidget);
      expect(find.text(suggestFromPhotoLabel), findsNothing);
    });

    testWidgets('a suggestion fills the form only when the adult picks it, '
        'and the adult still adds the word', (tester) async {
      final suggester = _Suggester()
        ..idea = const WordIdea(
          label: 'juice',
          speech: 'juice please',
          colorKey: 'verb',
          alternatives: ['drink', 'cup'],
        );
      await tester.pumpWidget(
        _sheetHost(store, media: media, capture: capture, suggester: suggester),
      );
      await _openAndPick(tester);
      await _tapSuggest(tester);

      expect(suggester.asked, [capture.photo]);
      for (final word in ['juice', 'drink', 'cup']) {
        expect(find.widgetWithText(ActionChip, word), findsOneWidget);
      }
      // Shown, not applied.
      final fields = find.byType(TextField);
      expect(tester.widget<TextField>(fields.at(0)).controller!.text, '');
      expect(store.tiles.where((t) => t.label == 'juice'), isEmpty);

      await tester.tap(find.widgetWithText(ActionChip, 'juice'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(fields.at(0)).controller!.text, 'juice');
      expect(
        tester.widget<TextField>(fields.at(1)).controller!.text,
        'juice please',
      );
      expect(store.tiles.where((t) => t.label == 'juice'), isEmpty);

      await tester.ensureVisible(find.text('Add to board'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to board'));
      await tester.pumpAndSettle();
      final added = store.tiles.singleWhere((t) => t.label == 'juice');
      expect(added.speech, 'juice please');
      expect(added.colorKey, 'verb');
      expect(added.imageHash, isNotNull);
    });

    testWidgets('an alternative is used as written, and a colour the tiles '
        'do not have leaves the word plain', (tester) async {
      final suggester = _Suggester()
        ..idea = const WordIdea(
          label: 'dog',
          speech: 'dog',
          colorKey: 'noun',
          alternatives: ['puppy'],
        );
      await tester.pumpWidget(
        _sheetHost(store, media: media, capture: capture, suggester: suggester),
      );
      await _openAndPick(tester);
      await _tapSuggest(tester);
      await tester.tap(find.widgetWithText(ActionChip, 'puppy'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      expect(tester.widget<TextField>(fields.at(0)).controller!.text, 'puppy');
      expect(tester.widget<TextField>(fields.at(1)).controller!.text, '');
      expect(
        tester
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .any((chip) => chip.selected),
        isFalse,
      );
    });

    testWidgets('no answer, or a failure, is one quiet line and the form '
        'still works', (tester) async {
      final suggester = _Suggester();
      await tester.pumpWidget(
        _sheetHost(store, media: media, capture: capture, suggester: suggester),
      );
      await _openAndPick(tester);
      await _tapSuggest(tester);
      expect(find.text(noSuggestionMessage), findsOneWidget);
      expect(find.byType(ActionChip), findsNothing);

      suggester.failWith = StateError('no');
      await _tapSuggest(tester);
      expect(find.text(noSuggestionMessage), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField).first, 'Grandma');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add to board'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to board'));
      await tester.pumpAndSettle();
      expect(store.tiles.where((t) => t.label == 'Grandma'), hasLength(1));
    });

    testWidgets('an answer for a photo that was removed meanwhile is '
        'dropped', (tester) async {
      final suggester = _Suggester()..gate = Completer<WordIdea?>();
      await tester.pumpWidget(
        _sheetHost(store, media: media, capture: capture, suggester: suggester),
      );
      await _openAndPick(tester);
      await tester.ensureVisible(find.text(suggestFromPhotoLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(suggestFromPhotoLabel));
      await tester.pump();
      expect(find.text('Looking at the photo'), findsOneWidget);

      await tester.tap(find.text('Remove photo'));
      await tester.pump();
      suggester.gate!.complete(const WordIdea(label: 'juice'));
      await tester.pumpAndSettle();
      expect(find.byType(ActionChip), findsNothing);
      expect(find.text(noSuggestionMessage), findsNothing);
    });
  });

  group('TalkerScreen, wired', () {
    testWidgets('a tapped word goes to the clip speaker, a sentence to the '
        'voice', (tester) async {
      final store = FakeBoardStore.seeded();
      final speech = FakeSpeech();
      final speaker = FakeTileSpeaker(speech: speech);
      await _pumpTalker(
        tester,
        TalkerScreen(
          store: store,
          speech: speech,
          sync: FakeSyncStatus(),
          speaker: speaker,
        ),
      );
      await tester.tap(find.text('want'));
      await tester.tap(find.text('more'));
      await tester.pump();
      expect([for (final tile in speaker.said) tile.label], ['want', 'more']);

      await tester.tap(find.bySemanticsLabel('Speak'));
      await tester.pump();
      expect(speech.spoken.last, 'want more');
    });

    testWidgets('a photo on this device is drawn on its tile', (tester) async {
      final store = FakeMediaBoardStore.seeded();
      final media = FakeMediaStore();
      final hash = media.arrive(tinyPng);
      final want = store.tiles.firstWhere((tile) => tile.label == 'want');
      await store.setTileMedia(want.id, imageHash: hash);
      await _pumpTalker(
        tester,
        TalkerScreen(
          store: store,
          speech: FakeSpeech(),
          sync: FakeSyncStatus(),
          media: media,
        ),
      );
      await tester.pump();
      expect(find.byKey(TileView.photoKey), findsOneWidget);
      // Its photo, not the symbol for "want".
      expect(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is TileView && w.tile.label == 'want',
          ),
          matching: find.byKey(TileView.symbolKey),
        ),
        findsNothing,
      );
      // The word keeps its cell and its label.
      expect(find.text('want'), findsOneWidget);
    });

    testWidgets('says so for as long as it is joined to the circle', (
      tester,
    ) async {
      final live = FakeLiveSession(connected: false);
      addTearDown(live.dispose);
      await _pumpTalker(
        tester,
        TalkerScreen(
          store: FakeBoardStore.seeded(),
          speech: FakeSpeech(),
          sync: FakeSyncStatus(),
          live: live,
        ),
      );
      expect(find.bySemanticsLabel(liveConnectedMessage), findsNothing);
      live.setConnected(true);
      await tester.pump();
      expect(find.bySemanticsLabel(liveConnectedMessage), findsOneWidget);
      live.setConnected(false);
      await tester.pump();
      expect(find.bySemanticsLabel(liveConnectedMessage), findsNothing);
    });

    testWidgets('leaving takes a 2-second hold on "Hold to leave"', (
      tester,
    ) async {
      var left = 0;
      await _pumpTalker(
        tester,
        TalkerScreen(
          store: FakeBoardStore.seeded(),
          speech: FakeSpeech(),
          sync: FakeSyncStatus(),
          onExit: () => left++,
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(leaveLabel)),
      );
      await tester.pump(const Duration(milliseconds: 1900));
      expect(left, 0);
      await tester.pump(const Duration(milliseconds: 200));
      expect(left, 1);
      await gesture.up();
      await tester.pump(const Duration(seconds: 3));
    });

    for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
      testWidgets('the keyboard leaves too: Tab reaches "Hold to leave", and '
          '${key.keyLabel.trim().isEmpty ? 'Space' : key.keyLabel} held for '
          '2 seconds leaves when it is let go', (tester) async {
        var left = 0;
        await _pumpTalker(
          tester,
          TalkerScreen(
            store: FakeBoardStore.seeded(),
            speech: FakeSpeech(),
            sync: FakeSyncStatus(),
            onExit: () => left++,
          ),
        );
        await _tabToLeave(tester);
        final bar = find.byType(LinearProgressIndicator);

        // Let go early: nothing happens and the bar empties.
        await tester.sendKeyDownEvent(key);
        // The bar starts filling from the next frame.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1900));
        expect(bar, findsOneWidget);
        expect(tester.widget<LinearProgressIndicator>(bar).value, 0.95);
        await tester.sendKeyUpEvent(key);
        await tester.pump(const Duration(seconds: 3));
        expect(left, 0);
        expect(bar, findsNothing);

        // Held for the 2 seconds: the bar is full, and letting go leaves.
        await tester.sendKeyDownEvent(key);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1900));
        await tester.sendKeyRepeatEvent(key);
        await tester.pump(const Duration(milliseconds: 200));
        expect(left, 0, reason: 'the key is still down');
        expect(tester.widget<LinearProgressIndicator>(bar).value, 1);
        await tester.sendKeyUpEvent(key);
        expect(left, 1);
        await tester.pump();
        expect(bar, findsNothing);
      });
    }

    testWidgets('a key still held after leaving does not open the board '
        'again', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var opened = 0;
      // A home with one button that opens the board, as the app's has.
      await tester.pumpWidget(
        MaterialApp(
          theme: chorusTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    opened++;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        fullscreenDialog: true,
                        builder: (talkerContext) => TalkerScreen(
                          store: FakeBoardStore.seeded(),
                          speech: FakeSpeech(),
                          sync: FakeSyncStatus(),
                          onExit: () => Navigator.of(talkerContext).pop(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Talker'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(TalkerScreen), findsOneWidget);

      await _tabToLeave(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 2100));
      // The key repeats for as long as it is down; "Talker" has the
      // keyboard again as soon as the board is gone.
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
        await tester.pump(const Duration(milliseconds: 40));
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(TalkerScreen), findsNothing);
      expect(opened, 1);
    });

    testWidgets('"Hold to leave" is marked while the keyboard is on it, and '
        'a screen reader is told how to hold it', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpTalker(
        tester,
        TalkerScreen(
          store: FakeBoardStore.seeded(),
          speech: FakeSpeech(),
          sync: FakeSyncStatus(),
          onExit: () {},
        ),
      );
      // What is painted over the pill itself.
      CustomPainter? mark() => tester
          .widget<CustomPaint>(
            find
                .ancestor(
                  of: find.text(leaveLabel),
                  matching: find.byType(CustomPaint),
                )
                .first,
          )
          .foregroundPainter;
      final control = find.bySemanticsLabel(
        'Hold for 2 seconds to leave the board',
      );
      expect(mark(), isNull);
      expect(
        tester.getSemantics(control),
        isSemantics(
          hint: holdWithKeyboardHint,
          isButton: true,
          isFocusable: true,
          isFocused: false,
          hasLongPressAction: true,
        ),
      );
      final before = tester.getRect(find.text(leaveLabel));

      await _tabToLeave(tester);
      expect(mark(), isNotNull);
      expect(tester.getSemantics(control), isSemantics(isFocused: true));
      // The mark is drawn over the control: nothing moves.
      expect(tester.getRect(find.text(leaveLabel)), before);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(mark(), isNull);
      semantics.dispose();
    });
  });

  group('EditorScreen, wired', () {
    Future<void> pumpEditor(WidgetTester tester, Widget editor) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(theme: chorusTheme(), home: editor));
    }

    testWidgets('in model mode a tap points at the word and opens nothing', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      final live = FakeLiveSession();
      addTearDown(live.dispose);
      await pumpEditor(
        tester,
        EditorScreen(store: store, sync: FakeSyncStatus(), live: live),
      );
      final want = store.tiles.firstWhere((tile) => tile.label == 'want');

      // Off: a tap opens the edit sheet as before.
      await tester.tap(find.text('want'));
      await tester.pumpAndSettle();
      expect(find.text('Change this word'), findsOneWidget);
      expect(live.sentPulses, isEmpty);
      Navigator.of(tester.element(find.text('Change this word'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('want').first);
      await tester.pump();
      expect(live.sentPulses, [want.id]);
      expect(find.text('Change this word'), findsNothing);
      // Let the glow fade so no timer is left behind.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('without a live session there is no model mode', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        EditorScreen(store: FakeBoardStore.seeded(), sync: FakeSyncStatus()),
      );
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('a word with a photo shows it in the grid, and its sheet '
        'offers the photo and recording rows', (tester) async {
      final store = FakeMediaBoardStore.seeded();
      final media = FakeMediaStore();
      final hash = media.arrive(tinyPng);
      final want = store.tiles.firstWhere((tile) => tile.label == 'want');
      await store.setTileMedia(want.id, imageHash: hash);
      await pumpEditor(
        tester,
        EditorScreen(
          store: store,
          sync: FakeSyncStatus(),
          media: media,
          capture: FakeMediaCapture(hasCamera: false),
        ),
      );
      await tester.pump();
      expect(find.byKey(TileView.photoKey), findsOneWidget);

      await tester.tap(find.text('want'));
      await tester.pumpAndSettle();
      expect(find.text('Photo (optional)'), findsOneWidget);
      expect(find.text('Record how we say it (optional)'), findsOneWidget);
    });
  });
}
