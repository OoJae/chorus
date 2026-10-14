import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts_modelling.dart';
import 'package:chorus_ui/contracts_wordlog.dart' show WeekSummarySource;
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/editor/model_mode_bar.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_live.dart';
import 'package:chorus_ui/fakes_modelling.dart';
import 'package:chorus_ui/features/this_week_screen.dart';
import 'package:chorus_ui/home/home_actions.dart';
import 'package:chorus_ui/modelling/focus_nudge_note.dart';
import 'package:chorus_ui/modelling/focus_words_screen.dart';
import 'package:chorus_ui/modelling/modelling_tools.dart';
import 'package:chorus_ui/modelling/week_modelling.dart';
import 'package:chorus_ui/modelling/word_finder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features_harness.dart';

class _Week implements WeekSummarySource {
  _Week(this.week);
  final WeekSummary week;

  @override
  Future<WeekSummary?> thisWeek() async => week;
}

void main() {
  late FakeBoardStore store;
  late FakeLiveSession live;
  late FakeModelling modelling;

  setUp(() {
    store = FakeBoardStore.seeded();
    live = FakeLiveSession(present: ["Maya's board"]);
    modelling = FakeModelling();
  });

  TileFacts tileNamed(String label) => store.tiles.firstWhere(
    (tile) => tile.label == label && tile.boardId == store.homeBoardId,
  );

  group('word finder', () {
    testWidgets('finds a word, draws its board and cell, and glows it on the '
        "child's board", (tester) async {
      setScreen(tester, const Size(400, 800));
      await tester.pumpWidget(
        featureApp(WordFinderScreen(store: store, live: live)),
      );
      await tester.enterText(find.byType(TextField), 'help');
      await tester.pump();

      expect(find.text('help'), findsWidgets);
      expect(find.textContaining('row 2, column 5'), findsOneWidget);
      expect(find.byType(GridMap), findsWidgets);

      await tester.tap(find.text(showOnBoardLabel('Maya')).first);
      await tester.pump();
      expect(live.sentPulses, [tileNamed('help').id]);
      expect(
        find.text(shownOnTabMessage('help', 'Maya', 'Home')),
        findsOneWidget,
      );
      // Lets the glow and the message run out.
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('with one board the message names no tab', (tester) async {
      store = FakeBoardStore.seeded(withWordsBoard: false);
      setScreen(tester, const Size(400, 800));
      await tester.pumpWidget(
        featureApp(WordFinderScreen(store: store, live: live)),
      );
      await tester.enterText(find.byType(TextField), 'help');
      await tester.pump();
      await tester.tap(find.text(showOnBoardLabel('Maya')).first);
      await tester.pump();
      expect(find.text(shownMessage('help', 'Maya')), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('says when nothing matches, and offers no glow offline', (
      tester,
    ) async {
      final offline = FakeLiveSession(connected: false);
      await tester.pumpWidget(
        featureApp(WordFinderScreen(store: store, live: offline)),
      );
      await tester.enterText(find.byType(TextField), 'zebra');
      await tester.pump();
      expect(find.text(findNothingMessage), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'more');
      await tester.pump();
      expect(find.text(findNeedsConnectionMessage), findsOneWidget);
      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text(showOnBoardLabel('Maya')).first,
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('opens from the editor bar', (tester) async {
      setScreen(tester, const Size(1280, 800));
      await tester.pumpWidget(
        featureApp(EditorScreen(store: store, sync: FakeSyncStatus())),
      );
      await tester.tap(find.byTooltip(findWordLabel));
      await tester.pumpAndSettle();
      expect(find.byType(WordFinderScreen), findsOneWidget);
    });
  });

  group('model mode', () {
    Future<void> openEditor(
      WidgetTester tester, {
      SpeechListener? speech,
    }) async {
      setScreen(tester, const Size(1280, 900));
      await tester.pumpWidget(
        featureApp(
          EditorScreen(
            store: store,
            sync: FakeSyncStatus(),
            live: live,
            modelling: modelling,
            speech: speech,
          ),
        ),
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
    }

    testWidgets("an adult's tap glows and is noted as modelled", (
      tester,
    ) async {
      await openEditor(tester);
      await tester.tap(find.text('more').first);
      await tester.pump();
      expect(live.sentPulses, [tileNamed('more').id]);
      expect([for (final t in modelling.modelled) t.label], ['more']);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('shows the focus tips and rings the focus words', (
      tester,
    ) async {
      modelling = FakeModelling(
        focusWords: [
          FocusPin(tileId: tileNamed('help').id, tip: 'At snack time.'),
        ],
      );
      await openEditor(tester);
      expect(find.text(focusTipsHeading), findsOneWidget);
      expect(find.text('help: At snack time.'), findsOneWidget);
      expect(find.byType(FocusRing), findsOneWidget);
    });

    testWidgets('Listen glows the words it hears, in order', (tester) async {
      final speech = FakeSpeechListener();
      await openEditor(tester, speech: speech);
      await tester.tap(find.text(listenLabel));
      await tester.pump();
      expect(speech.listening, isTrue);
      expect(find.text(listeningMessage), findsOneWidget);

      speech.hear('want MORE!');
      await tester.pump();
      await tester.pump(spokenGlowGap);
      expect(live.sentPulses, [tileNamed('want').id, tileNamed('more').id]);
      expect(find.text('Glowing: want · more'), findsOneWidget);

      await tester.tap(find.text(stopListeningLabel));
      await tester.pump();
      expect(speech.listening, isFalse);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('Listen is not shown where speech is not available', (
      tester,
    ) async {
      await openEditor(tester, speech: FakeSpeechListener(available: false));
      expect(find.text(listenLabel), findsNothing);
      expect(find.byKey(ModellingTools.findFieldKey), findsOneWidget);
    });

    testWidgets("the bar's search field opens the finder with the word", (
      tester,
    ) async {
      await openEditor(tester);
      await tester.enterText(find.byKey(ModellingTools.findFieldKey), 'help');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.byType(WordFinderScreen), findsOneWidget);
      expect(find.textContaining('row 2, column 5'), findsOneWidget);
    });

    testWidgets('the bar works as before without modelling', (tester) async {
      await tester.pumpWidget(
        featureApp(
          Scaffold(
            body: ModelModeBar(live: live, enabled: true, onChanged: (_) {}),
          ),
        ),
      );
      expect(find.byType(ModellingTools), findsNothing);
    });
  });

  group('focus words', () {
    testWidgets('a therapist picks words with tips and saves them', (
      tester,
    ) async {
      setScreen(tester, const Size(400, 900));
      await tester.pumpWidget(
        featureApp(FocusWordsScreen(store: store, modelling: modelling)),
      );
      await tester.tap(find.widgetWithText(FilterChip, 'help'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'At snack time.');
      await tester.tap(find.text(saveFocusLabel));
      await tester.pumpAndSettle();
      expect(modelling.focusWords, [
        FocusPin(tileId: tileNamed('help').id, tip: 'At snack time.'),
      ]);
    });

    testWidgets('no more than three', (tester) async {
      setScreen(tester, const Size(400, 900));
      modelling = FakeModelling(
        focusWords: [
          for (final word in ['help', 'more', 'go'])
            FocusPin(tileId: tileNamed(word).id),
        ],
      );
      await tester.pumpWidget(
        featureApp(FocusWordsScreen(store: store, modelling: modelling)),
      );
      expect(find.byType(TextField), findsNWidgets(3));
      final chip = find.widgetWithText(FilterChip, 'want').first;
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pump();
      expect(find.text(focusFullMessage), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      await tester.ensureVisible(find.text(saveFocusLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(saveFocusLabel));
      await tester.pumpAndSettle();
      expect(
        [for (final pin in modelling.focusWords) pin.tileId],
        [
          for (final word in ['help', 'more', 'go']) tileNamed(word).id,
        ],
      );
    });
  });

  group('nudge', () {
    testWidgets('home shows it kindly and it can be hidden', (tester) async {
      final week = DateTime.utc(2026, 10, 12);
      modelling.nudgeNote = FocusNudgeNote(
        tileId: 'x',
        label: 'help',
        weekStart: week,
      );
      await tester.pumpWidget(
        featureApp(
          Scaffold(
            body: ListenableBuilder(
              listenable: modelling,
              builder: (context, _) =>
                  Column(children: [?focusNudgeNoteFor(modelling)]),
            ),
          ),
        ),
      );
      expect(
        find.text(
          "Nobody has modelled 'help' yet this week. Try it at snack time.",
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip(dismissNudgeLabel));
      await tester.pump();
      expect(find.byType(HomeNote), findsNothing);
      expect(modelling.nudgeNote, isNull);
      expect(focusNudgeNoteFor(modelling), isNull);
      expect(focusNudgeNoteFor(null), isNull);
    });

    test('uses the tip when there is one', () {
      expect(
        focusNudgeMessage(
          FocusNudgeNote(
            tileId: 'x',
            label: 'more',
            tip: "At bath time: 'more bubbles?'",
            weekStart: DateTime.utc(2026, 10, 12),
          ),
        ),
        "Nobody has modelled 'more' yet this week. At bath time: 'more "
        "bubbles?'",
      );
    });
  });

  group('this week', () {
    final week = WeekSummary(
      weekStart: DateTime.utc(2026, 10, 12),
      topWords: const [WordCount('go', 3)],
      firstTimeWords: const [],
      addedWords: const [],
      notUsedYet: const [],
      totalUses: 3,
      wordsUsed: 1,
      modelled: const [ModelledCount('go', modelled: 14, said: 3)],
    );

    testWidgets('shows modelled against said, and makes the progress report', (
      tester,
    ) async {
      setScreen(tester, const Size(400, 900));
      modelling.opensLinks = true;
      await tester.pumpWidget(
        featureApp(
          ThisWeekScreen(
            source: _Week(week),
            childName: 'Maya',
            modelling: modelling,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(modelledHeading), findsOneWidget);
      expect(find.text('modelled 14 · said 3'), findsOneWidget);

      await tester.tap(find.byTooltip(progressReportLabel));
      await tester.pumpAndSettle();
      expect(modelling.reportsMade, 1);
      expect(modelling.opened, [modelling.reportUrl]);
      expect(find.text(progressReportExplain), findsOneWidget);
    });

    testWidgets('says when the report could not be made', (tester) async {
      setScreen(tester, const Size(400, 900));
      modelling = FakeModelling(failReport: true);
      await tester.pumpWidget(
        featureApp(
          ThisWeekScreen(
            source: _Week(week),
            childName: 'Maya',
            modelling: modelling,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(progressReportLabel));
      await tester.pumpAndSettle();
      expect(find.text(progressReportFailed), findsOneWidget);
    });

    testWidgets('no report action for a role that may not make one', (
      tester,
    ) async {
      modelling = FakeModelling(canPinFocus: false);
      await tester.pumpWidget(
        featureApp(
          ThisWeekScreen(
            source: _Week(week),
            childName: 'Maya',
            modelling: modelling,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip(progressReportLabel), findsNothing);
    });
  });
}
