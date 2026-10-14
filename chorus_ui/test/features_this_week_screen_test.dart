import 'dart:async';

import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_wordlog.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_features.dart';
import 'package:chorus_ui/features/feature_page.dart';
import 'package:chorus_ui/features/this_week_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features_harness.dart';

/// A source that answers only when told to.
class _HeldSource implements WeekSummarySource {
  final List<Completer<WeekSummary?>> asked = [];

  @override
  Future<WeekSummary?> thisWeek() {
    final answer = Completer<WeekSummary?>();
    asked.add(answer);
    return answer.future;
  }
}

void main() {
  // Wednesday 14 October 2026, 09:00 UTC.
  final clock = DateTime.utc(2026, 10, 14, 9);
  DateTime now() => clock;

  late FakeBoardStore store;
  late FakeWordLog log;
  late FakeWeekSummarySource source;

  TileFacts word(String label) =>
      store.tiles.firstWhere((tile) => tile.label == label);

  setUp(() {
    store = FakeBoardStore.seeded();
    log = FakeWordLog(enabled: true, now: now);
    source = FakeWeekSummarySource(store: store, log: log, now: now);
  });

  Future<void> pump(
    WidgetTester tester,
    WeekSummarySource from, {
    CircleRole? role = CircleRole.guardian,
    VoidCallback? onOpenWordLog,
    Size size = const Size(360, 820),
    bool settle = true,
  }) async {
    setScreen(tester, size);
    await tester.pumpWidget(
      featureApp(
        ThisWeekScreen(
          source: from,
          childName: 'Maya',
          log: log,
          tiles: store.tiles,
          role: role,
          onOpenWordLog: onOpenWordLog,
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('shows the most used words as tiles with their counts, in '
      'their colours', (tester) async {
    for (var i = 0; i < 3; i++) {
      log.noteSpoken(word('want'));
    }
    log.noteSpoken(word('more'));
    await pump(tester, source);

    expect(find.text('Most used'), findsOneWidget);
    expect(find.bySemanticsLabel('want, 3 times'), findsOneWidget);
    expect(find.bySemanticsLabel('more, once'), findsOneWidget);
    expect(find.text('×3'), findsOneWidget);
    expect(find.text('4 taps · 2 words'), findsOneWidget);

    // "want" is a verb: the action family's fill.
    final fills = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.bySemanticsLabel('want, 3 times'),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => (box.decoration as BoxDecoration).color);
    expect(fills, contains(TileFamily.action.light.fill));
  });

  testWidgets('lists first-time words, added words and words not used yet', (
    tester,
  ) async {
    log.noteSpoken(word('want'));
    await pump(tester, source);
    expect(find.text('Used for the first time'), findsOneWidget);
    expect(find.text('Not used yet'), findsOneWidget);
    // Seeded long ago, so nothing was added this week.
    expect(find.text('Added this week'), findsNothing);

    // 35 starter words are unused: twelve show, then "Show all".
    final unused = find.descendant(
      of: find.byType(Wrap).last,
      matching: find.byType(WordTile),
    );
    expect(unused, findsNWidgets(ThisWeekScreen.notUsedShown));
    await tester.scrollUntilVisible(find.text('Show all 35'), 200);
    await tester.tap(find.text('Show all 35'));
    await tester.pumpAndSettle();
    expect(unused, findsNWidgets(35));
  });

  testWidgets('holds the space with grey tiles while it loads', (tester) async {
    final held = _HeldSource();
    await pump(tester, held, settle: false);
    await tester.pump();
    expect(find.bySemanticsLabel('Loading this week'), findsOneWidget);
    expect(find.byType(SkeletonTile), findsWidgets);

    held.asked.single.complete(
      summarizeWeek(const [], store.tiles, weekStartOf(clock)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonTile), findsNothing);
    expect(find.text('Nothing tapped yet this week.'), findsOneWidget);
  });

  testWidgets('a week that could not be had says why, and Try again asks '
      'again', (tester) async {
    final held = _HeldSource();
    await pump(tester, held, settle: false);
    held.asked.single.complete(null);
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be loaded'), findsOneWidget);
    expect(find.textContaining('needs a connection'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(held.asked, hasLength(2));
    held.asked.last.complete(
      summarizeWeek(const [], store.tiles, weekStartOf(clock)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be loaded'), findsNothing);
  });

  testWidgets('a log that is off says so, offers Word log, and asks the '
      'server nothing', (tester) async {
    await log.setEnabled(false);
    var opened = 0;
    await pump(tester, source, onOpenWordLog: () => opened++);
    expect(find.text('The word log is off.'), findsOneWidget);
    expect(source.asked, 0);
    await tester.tap(find.text('Open Word log'));
    expect(opened, 1);

    // Turned on elsewhere: the week loads.
    await log.setEnabled(true);
    await tester.pumpAndSettle();
    expect(source.asked, 1);
    expect(find.text('The word log is off.'), findsNothing);
  });

  testWidgets('a teacher is told who may see it, and nothing is asked', (
    tester,
  ) async {
    await pump(tester, source, role: CircleRole.teacher);
    expect(
      find.text('This week is for guardians and therapists.'),
      findsOneWidget,
    );
    expect(source.asked, 0);
  });

  testWidgets('words noted while it loads do not ask again', (tester) async {
    final held = _HeldSource();
    await pump(tester, held, settle: false);
    log.noteSpoken(word('want'));
    log.noteSpoken(word('go'));
    await tester.pump();
    expect(held.asked, hasLength(1));
    held.asked.single.complete(
      summarizeWeek(const [], store.tiles, weekStartOf(clock)),
    );
    await tester.pumpAndSettle();
    expect(held.asked, hasLength(1));
  });

  testWidgets('Refresh asks again', (tester) async {
    await pump(tester, source);
    expect(source.asked, 1);
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(source.asked, 2);
  });
}
