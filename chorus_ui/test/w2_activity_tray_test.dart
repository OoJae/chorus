// "What changed" with Undo, "Needs a home" in plain words, suggested words
// and the circle's members, against the in-memory fakes.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/activity/activity_screen.dart';
import 'package:chorus_ui/activity/activity_text.dart';
import 'package:chorus_ui/activity/members_screen.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_activity.dart';
import 'package:chorus_ui/editor/contested_tray_card.dart';
import 'package:chorus_ui/editor/tray_panel.dart';
import 'package:chorus_ui/editor/word_suggestions_tray.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features_harness.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  setScreen(tester, const Size(400, 900));
  await tester.pumpWidget(featureApp(home));
  await tester.pumpAndSettle();
}

EditFacts _edit(
  String id,
  String tileId,
  String prop,
  String? oldValue,
  String? newValue, {
  String reason = 'edit',
  String by = 'Ms Rivera',
  DateTime? at,
}) => EditFacts(
  id: id,
  tileId: tileId,
  prop: prop,
  oldValue: oldValue,
  newValue: newValue,
  reason: reason,
  actorId: by,
  actorName: by,
  editedAt: at ?? DateTime.now().toUtc(),
);

void main() {
  group('plain words', () {
    test('a line per kind of change', () {
      final at = DateTime.utc(2026, 10, 14, 18, 4);
      ActivityEntry entry(ActivityKind kind, {String? old, String? now}) =>
          ActivityEntry(
            id: 'x',
            kind: kind,
            tileId: 't',
            label: 'cup',
            actorId: 'd',
            actorName: 'Dad',
            at: at,
            oldValue: old,
            newValue: now,
          );
      expect(activityLine(entry(ActivityKind.added)), "Dad added 'cup'");
      expect(
        activityLine(entry(ActivityKind.renamed, old: 'cup', now: 'mug')),
        "Dad renamed 'cup' to 'mug'",
      );
      expect(activityLine(entry(ActivityKind.putAway)), "Dad put 'cup' away");
      expect(activityLine(entry(ActivityKind.sitterTap)), "Sitter: 'cup'");
      expect(sinceLastLookedText(1), 'Since you last looked: 1 change');
      expect(sinceLastLookedText(3), 'Since you last looked: 3 changes');
      expect(initialOf('ms rivera'), 'M');
      expect(initialOf(''), '?');
    });

    test('day headings', () {
      final now = DateTime(2026, 10, 14, 12);
      expect(dayHeading(DateTime(2026, 10, 14, 8), now), 'Today');
      expect(dayHeading(DateTime(2026, 10, 13, 8), now), 'Yesterday');
      expect(dayHeading(DateTime(2026, 10, 12, 8), now), 'Mon 12 Oct');
    });

    test('the clash sentence never says which word won', () {
      const holder = TileFacts(
        id: 'a',
        boardId: 'b',
        cellKey: 'b:0:0',
        label: 'cake',
        createdByName: 'Mum',
      );
      const waiting = TileFacts(
        id: 'c',
        boardId: 'b',
        cellKey: 'tray:c',
        label: 'swing',
        createdByName: 'Ms Rivera',
      );
      expect(
        bothPutAWordText(waiting, holder),
        'Mum and Ms Rivera both put a word in this spot while offline. '
        'Nothing was lost.',
      );
      for (final text in [
        bothPutAWordText(waiting, holder),
        bothPutAWordText(waiting, null),
        activityEmpty,
        undoneMessage,
        undoWaitingMessage('cake'),
      ]) {
        expect(text.toLowerCase(), isNot(contains('conflict')));
        expect(text.toLowerCase(), isNot(contains('error')));
      }
    });
  });

  group('What changed', () {
    testWidgets('shows lines newest first and undoes a rename', (tester) async {
      final store = FakeActivityStore.seeded(leaveEmpty: {(5, 5)});
      await store.addTile(
        boardId: store.homeBoardId,
        row: 5,
        col: 5,
        label: 'mug',
      );
      final mug = store.tiles.firstWhere((t) => t.label == 'mug');
      store.edits = [
        _edit('e0', mug.id, 'label', null, 'cup', reason: 'add', by: 'Mum'),
        _edit('e1', mug.id, 'label', 'cup', 'mug'),
      ];
      final seen = FakeActivitySeen();
      await _pump(tester, ActivityScreen(store: store, seen: seen));

      expect(find.text('Today'), findsOneWidget);
      expect(find.textContaining("Ms Rivera renamed 'cup' to 'mug'"), findsOne);
      expect(find.textContaining("Mum added 'mug'"), findsOne);
      expect(seen.last, isNotNull);

      await tester.tap(find.text(undoLabel).first);
      await tester.pumpAndSettle();
      expect(store.undone.single.kind, ActivityKind.renamed);
      expect(store.tiles.firstWhere((t) => t.id == mug.id).label, 'cup');
      expect(find.text(undoneMessage), findsOneWidget);
    });

    testWidgets('a read-only partner sees no Undo', (tester) async {
      final store = FakeActivityStore.seeded(
        role: CircleRole.partner,
        leaveEmpty: {(5, 5)},
      );
      final cup = store.tiles.first;
      store.edits = [_edit('e1', cup.id, 'label', 'old', cup.label)];
      await _pump(tester, ActivityScreen(store: store));
      expect(find.textContaining('renamed'), findsOneWidget);
      expect(find.text(undoLabel), findsNothing);
    });

    testWidgets('a sitter tap is a line', (tester) async {
      final store = FakeActivityStore.seeded();
      await _pump(
        tester,
        ActivityScreen(
          store: store,
          sitterTaps: () async => [
            SitterTap(label: 'tired', at: DateTime.now().toUtc()),
          ],
        ),
      );
      expect(find.textContaining("Sitter: 'tired'"), findsOneWidget);
    });

    testWidgets('the banner counts changes since the last look', (
      tester,
    ) async {
      final store = FakeActivityStore.seeded();
      final cup = store.tiles.first;
      store.edits = [
        _edit('e1', cup.id, 'label', 'a', 'b', at: DateTime.utc(2026, 10, 14)),
        _edit('e2', cup.id, 'label', 'b', 'c', at: DateTime.utc(2026, 10, 15)),
      ];
      var opened = 0;
      await _pump(
        tester,
        Scaffold(
          body: ActivityBanner(
            store: store,
            seen: FakeActivitySeen(DateTime.utc(2026, 10, 14, 12)),
            onOpen: () => opened++,
          ),
        ),
      );
      expect(find.text(sinceLastLookedText(1)), findsOneWidget);
      await tester.tap(find.text(sinceLastLookedAction));
      await tester.pumpAndSettle();
      expect(opened, 1);
    });
  });

  group('Needs a home', () {
    testWidgets('a clash shows both words, both adults and three choices', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded(leaveEmpty: {(5, 5), (5, 4)});
      store.remoteAdd(row: 5, col: 5, label: 'cake', byName: 'Mum');
      store.remoteConflict(row: 5, col: 5, label: 'swing', byName: 'Ms Rivera');
      await _pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: TrayPanel(store: store, boardId: store.homeBoardId),
          ),
        ),
      );
      expect(find.byType(ContestedTrayCard), findsOneWidget);
      expect(find.text(holdsSpotCaption), findsOneWidget);
      expect(find.text(waitingCaption), findsOneWidget);
      expect(
        find.text(
          'Mum and Ms Rivera both put a word in this spot while offline. '
          'Nothing was lost.',
        ),
        findsOneWidget,
      );
      expect(find.text(placeNextLabel), findsOneWidget);
      expect(find.text(chooseNewSpotLabel), findsOneWidget);
      expect(find.text(putAwayLabel), findsOneWidget);
      expect(find.textContaining('Swap'), findsNothing);

      await tester.tap(find.text(placeNextLabel));
      await tester.pumpAndSettle();
      final swing = store.tiles.firstWhere((t) => t.label == 'swing');
      expect(CellKey.parse(swing.cellKey), isA<PlacedCell>());
      final cake = store.tiles.firstWhere((t) => t.label == 'cake');
      expect(cake.cellKey, placedKey(store.homeBoardId, 5, 5));
    });

    testWidgets('an editor adds a suggestion, choosing its spot', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded(leaveEmpty: {(5, 5)});
      final suggestions = FakeWordSuggestions()..add('slide');
      await _pump(
        tester,
        WordSuggestionsScope(
          suggestions: suggestions,
          child: Scaffold(
            body: SingleChildScrollView(
              child: TrayPanel(store: store, boardId: store.homeBoardId),
            ),
          ),
        ),
      );
      expect(find.text(suggestionsTitle(1)), findsOneWidget);
      expect(find.text('Suggested by Grandma'), findsOneWidget);
      await tester.tap(find.text(addToBoardLabel));
      await tester.pumpAndSettle();
      expect(find.text('Where should "slide" go?'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await tester.pumpAndSettle();
      final slide = store.tiles.firstWhere((t) => t.label == 'slide');
      expect(slide.cellKey, placedKey(store.homeBoardId, 5, 5));
      expect(suggestions.answers, [('slide', true)]);
      expect(find.text(suggestionsTitle(1)), findsNothing);
    });

    testWidgets('a waiting suggestion counts in the heading', (tester) async {
      final store = FakeBoardStore.seeded();
      final waiting = trayEntriesFor(store, store.homeBoardId).length;
      final suggestions = FakeWordSuggestions()..add('slide');
      await _pump(
        tester,
        WordSuggestionsScope(
          suggestions: suggestions,
          child: Scaffold(
            body: SingleChildScrollView(
              child: TrayPanel(store: store, boardId: store.homeBoardId),
            ),
          ),
        ),
      );
      final heading = find.byKey(TrayPanel.headingKey);
      expect(
        find.descendant(
          of: heading,
          matching: find.text(trayTitle(waiting + 1)),
        ),
        findsOneWidget,
      );
      if (waiting == 0) {
        expect(find.text('No words are waiting.'), findsNothing);
      }

      await tester.tap(find.text(noThanksLabel));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: heading, matching: find.text(trayTitle(waiting))),
        findsOneWidget,
      );
      if (waiting == 0) {
        expect(find.text('No words are waiting.'), findsOneWidget);
      }
    });

    testWidgets('a partner\'s heading counts no suggestions', (tester) async {
      final store = FakeBoardStore.seeded()..role = CircleRole.partner;
      final waiting = trayEntriesFor(store, store.homeBoardId).length;
      final suggestions = FakeWordSuggestions()..add('slide');
      await _pump(
        tester,
        WordSuggestionsScope(
          suggestions: suggestions,
          child: Scaffold(
            body: SingleChildScrollView(
              child: TrayPanel(store: store, boardId: store.homeBoardId),
            ),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(TrayPanel.headingKey),
          matching: find.text(trayTitle(waiting)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('No thanks declines; a partner never sees suggestions', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      final suggestions = FakeWordSuggestions()..add('slide');
      await _pump(
        tester,
        WordSuggestionsScope(
          suggestions: suggestions,
          child: Scaffold(
            body: SingleChildScrollView(
              child: TrayPanel(store: store, boardId: store.homeBoardId),
            ),
          ),
        ),
      );
      await tester.tap(find.text(noThanksLabel));
      await tester.pumpAndSettle();
      expect(suggestions.answers, [('slide', false)]);

      store.role = CircleRole.partner;
      suggestions.add('sand');
      await tester.pumpAndSettle();
      expect(find.text('sand'), findsNothing);
    });

    testWidgets('a partner suggests a word', (tester) async {
      final suggestions = FakeWordSuggestions();
      await _pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSuggestWordDialog(context, suggestions),
              child: const Text(suggestWordLabel),
            ),
          ),
        ),
      );
      await tester.tap(find.text(suggestWordLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'swing');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(suggestions.suggested, ['swing']);
      expect(find.text(suggestionSentMessage), findsOneWidget);
    });
  });

  group('People in this circle', () {
    testWidgets('a guardian removes someone else, never themselves', (
      tester,
    ) async {
      final members = FakeCircleMembers([
        const CircleMember(
          userId: 'me',
          name: 'Mum',
          roleName: 'Guardian',
          isMe: true,
        ),
        const CircleMember(userId: 'r', name: 'Ms Rivera', roleName: 'Teacher'),
      ]);
      await _pump(tester, MembersScreen(members: members));
      expect(find.text('Mum (you)'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text(removeMemberQuestion('Ms Rivera')), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await tester.pumpAndSettle();
      expect(members.members.map((m) => m.name), ['Mum']);
      expect(find.text(memberRemovedMessage('Ms Rivera')), findsOneWidget);
    });

    testWidgets('others see the list without Remove', (tester) async {
      final members = FakeCircleMembers([
        const CircleMember(userId: 'm', name: 'Mum', roleName: 'Guardian'),
      ], canRemove: false);
      await _pump(tester, MembersScreen(members: members));
      expect(find.text('Mum'), findsOneWidget);
      expect(find.text('Remove'), findsNothing);
    });

    testWidgets('offline shows a calm note', (tester) async {
      final members = FakeCircleMembers([])..offline = true;
      await _pump(tester, MembersScreen(members: members));
      expect(find.text(membersUnavailableMessage), findsOneWidget);
    });
  });
}
