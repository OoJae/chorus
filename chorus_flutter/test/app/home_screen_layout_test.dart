// Home as the signature screen: every size, both modes and the largest text
// lay out; the hero opens the child's board in one shared-element move (a
// crossfade under reduced motion); the new entries open the feature screens
// only where the circle offers them; and the states say what is happening.
import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/screens/home_screen.dart';
import 'package:chorus_flutter/screens/services.dart';
import 'package:chorus_flutter/src/live/chorus_live_session.dart';
import 'package:chorus_ui/brand/test_fonts.dart';
import 'package:chorus_ui/brand/tokens.dart';
import 'package:chorus_ui/contracts.dart' as ui;
import 'package:chorus_ui/editor/editor_screen.dart'
    show boardMenuLabel, exportBoardLabel;
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_features.dart';
import 'package:chorus_ui/fakes_media.dart';
import 'package:chorus_ui/features/features.dart';
import 'package:chorus_ui/home/home.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const _sizes = [
  Size(360, 640),
  Size(360, 820),
  Size(820, 360),
  Size(1280, 800),
  Size(1440, 900),
];

ChorusLiveSession _live({required bool forTalker}) => ChorusLiveSession(
  join: (_, _) => const Stream.empty(),
  circleSpace: mayaSpace,
);

/// Every service a guardian's circle can have.
CircleServices _everything(FakeBoardStore store) {
  final log = FakeWordLog();
  return CircleServices(
    userId: 'me',
    media: FakeMediaStore(),
    live: _live,
    publishBoard: (_) async => 'https://chorus.example/print/abc',
    wordLog: log,
    summary: FakeWeekSummarySource(store: store, log: log),
    sharing: FakeBoardSharing(store: store),
    boards: store,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  CircleInfo? selected,
  FakeBoardStore? store,
  CircleServices? services,
  Size size = const Size(360, 820),
  double textScale = 1,
  bool dark = false,
  bool reduced = false,
  VoidCallback? onAddBoard,
  List<CircleInfo>? circles,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final circle = selected ?? circle_();
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? chorusDarkTheme() : chorusTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: HomeScreen(
        circles: circles ?? [circle],
        selected: circle,
        onSelect: (_) {},
        store: store ?? FakeBoardStore.seeded(),
        sync: FakeSyncStatus(),
        speech: FakeSpeech(),
        gateway: FakeGateway(),
        readiness: CircleReadiness.ready,
        onRetryReady: () {},
        onSignOut: () {},
        onAddBoard: onAddBoard,
        services: services,
      ),
    ),
  );
  await tester.pump();
}

// `circle` is the shared fake's name; this keeps it apart from parameters.
CircleInfo circle_({CircleRole role = CircleRole.guardian}) =>
    circle(role: role, myName: role == CircleRole.partner ? 'Gran' : 'Mum');

void main() {
  setUpAll(loadChorusFonts);

  group('at every size, in both modes and at the largest text', () {
    for (final size in _sizes) {
      for (final (textScale, dark) in [
        (1.0, false),
        (1.0, true),
        (2.0, true),
      ]) {
        testWidgets('${size.width.toInt()}x${size.height.toInt()}, text '
            '${textScale}x, ${dark ? 'dark' : 'light'}: nothing overflows and '
            'every entry can be reached', (tester) async {
          final store = FakeBoardStore.seeded();
          await _pump(
            tester,
            store: store,
            services: _everything(store),
            size: size,
            textScale: textScale,
            dark: dark,
            onAddBoard: () {},
            circles: [
              circle_(),
              circle(space: samSpace, childName: 'Sam'),
            ],
          );
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.text(addAnotherChildLabel),
            120,
            scrollable: find.descendant(
              of: find.byKey(HomeLayout.scrollKey),
              matching: find.byType(Scrollable),
            ),
          );
          expect(tester.takeException(), isNull);
          final page = tester.widget<Scaffold>(find.byType(Scaffold).first);
          expect(
            page.backgroundColor,
            dark ? ChorusColors.dark.card : ChorusColors.light.card,
          );
        });
      }
    }
  });

  testWidgets('the hero opens the child\'s board in one move: it flies and '
      'lands on the board carrying the same tag', (tester) async {
    final store = FakeBoardStore.seeded();
    await _pump(tester, store: store);
    final tag = boardHeroTag(store.homeBoardId);
    expect(tester.widget<Hero>(find.byType(Hero)).tag, tag);

    await tester.tap(find.byKey(HomeHero.boardKey));
    await tester.pump();
    await tester.pump();
    // Home's own shuttle flies, flattening as it goes.
    expect(find.byKey(BoardHero.shuttleKey), findsOneWidget);
    await tester.pumpAndSettle();

    final talker = tester.widget<TalkerScreen>(find.byType(TalkerScreen));
    expect(talker.heroTag, tag);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the primary action opens the same board the same way', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text(openBoardLabel('Maya')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(BoardHero.shuttleKey), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(TalkerScreen), findsOneWidget);
  });

  testWidgets('under reduced motion nothing flies: the child\'s board '
      'crossfades in over 150 ms', (tester) async {
    await _pump(tester, reduced: true);
    expect(find.byType(Hero), findsNothing);

    await tester.tap(find.text(openBoardLabel('Maya')));
    await tester.pump();
    expect(find.byKey(BoardHero.shuttleKey), findsNothing);
    await tester.pump(const Duration(milliseconds: 160));
    final talker = tester.widget<TalkerScreen>(find.byType(TalkerScreen));
    expect(talker.heroTag, isNull);
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(TalkerScreen),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
  });

  testWidgets('the child\'s board gets the circle\'s word log', (tester) async {
    final store = FakeBoardStore.seeded();
    final services = _everything(store);
    await _pump(tester, store: store, services: services);
    await tester.tap(find.text(openBoardLabel('Maya')));
    await tester.pumpAndSettle();
    final talker = tester.widget<TalkerScreen>(find.byType(TalkerScreen));
    expect(talker.wordLog, same(services.wordLog));
  });

  group('the new entries', () {
    testWidgets('are left out where the circle does not offer them', (
      tester,
    ) async {
      await _pump(tester, services: const CircleServices(userId: 'me'));
      expect(find.text(shareViewOnlyLabel), findsNothing);
      expect(find.text(wordLogLabel), findsNothing);
    });

    testWidgets('"Share a view-only board" opens the sharing screen for '
        'the home board', (tester) async {
      final store = FakeBoardStore.seeded();
      final sharing = FakeBoardSharing(store: store);
      await _pump(
        tester,
        store: store,
        services: CircleServices(userId: 'me', sharing: sharing),
        size: const Size(800, 1600),
      );
      await tester.tap(find.text(shareViewOnlyLabel));
      await tester.pumpAndSettle();
      final screen = tester.widget<ShareViewOnlyScreen>(
        find.byType(ShareViewOnlyScreen),
      );
      expect(screen.sharing, same(sharing));
      expect(screen.board.id, store.homeBoardId);
      expect(screen.childName, 'Maya');
      // Opening it shares nothing.
      expect(sharing.shared, isEmpty);
    });

    testWidgets('"Word log and this week" opens the word log, which leads '
        'on to the week', (tester) async {
      final store = FakeBoardStore.seeded();
      final log = FakeWordLog();
      final summary = FakeWeekSummarySource(store: store, log: log);
      await _pump(
        tester,
        store: store,
        services: CircleServices(userId: 'me', wordLog: log, summary: summary),
        size: const Size(800, 1600),
      );
      await tester.tap(find.text(wordLogLabel));
      await tester.pumpAndSettle();
      final screen = tester.widget<WordLogScreen>(find.byType(WordLogScreen));
      expect(screen.log, same(log));
      expect(screen.summary, same(summary));
      expect(screen.store, same(store));
    });

    testWidgets('the editor exports the board on show as .obf, through the '
        'circle\'s sharing', (tester) async {
      final store = FakeBoardStore.seeded();
      final sharing = FakeBoardSharing(store: store);
      await _pump(
        tester,
        store: store,
        services: CircleServices(userId: 'me', sharing: sharing),
        size: const Size(1280, 800),
      );
      await tester.tap(find.text(editWordsLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(boardMenuLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(exportBoardLabel));
      await tester.pumpAndSettle();
      final screen = tester.widget<ExportObfScreen>(
        find.byType(ExportObfScreen),
      );
      expect(screen.sharing, same(sharing));
      expect(screen.board.id, store.homeBoardId);
      expect(screen.childName, 'Maya');
      // Opening it exports nothing.
      expect(sharing.exported, isEmpty);
    });

    testWidgets('without sharing the editor offers no export', (tester) async {
      await _pump(
        tester,
        services: const CircleServices(userId: 'me'),
        size: const Size(1280, 800),
      );
      await tester.tap(find.text(editWordsLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(boardMenuLabel));
      await tester.pumpAndSettle();
      expect(find.text(exportBoardLabel), findsNothing);
    });

    testWidgets('with "This week" and no log here it opens the week', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      final summary = FakeWeekSummarySource(store: store, log: FakeWordLog());
      await _pump(
        tester,
        store: store,
        services: CircleServices(userId: 'me', summary: summary),
        size: const Size(800, 1600),
      );
      await tester.tap(find.text(wordLogLabel));
      await tester.pumpAndSettle();
      expect(find.byType(ThisWeekScreen), findsOneWidget);
    });

    testWidgets('another child\'s circle is added from the switcher, named '
        'for what it is', (tester) async {
      var added = 0;
      await _pump(
        tester,
        size: const Size(800, 1600),
        onAddBoard: () => added++,
      );
      expect(find.text('Add or join another board'), findsNothing);
      await tester.tap(find.text(addAnotherChildLabel));
      expect(added, 1);
    });
  });

  group('states', () {
    testWidgets('a board with no words yet says so, from the adult\'s side', (
      tester,
    ) async {
      final everyCell = {
        for (var row = 0; row < 6; row++)
          for (var col = 0; col < 6; col++) (row, col),
      };
      await _pump(tester, store: FakeBoardStore.seeded(leaveEmpty: everyCell));
      expect(
        find.text(
          "There are no words on Maya's board yet. Add the first ones with "
          'Edit words.',
        ),
        findsOneWidget,
      );
      // The board still opens: words added later show up on it.
      await tester.tap(find.text(openBoardLabel('Maya')));
      await tester.pumpAndSettle();
      expect(find.byType(TalkerScreen), findsOneWidget);
    });

    testWidgets('a partner is told who adds the words', (tester) async {
      final everyCell = {
        for (var row = 0; row < 6; row++)
          for (var col = 0; col < 6; col++) (row, col),
      };
      await _pump(
        tester,
        selected: circle_(role: CircleRole.partner),
        store: FakeBoardStore.seeded(
          role: ui.CircleRole.partner,
          leaveEmpty: everyCell,
        ),
      );
      expect(
        find.textContaining('appear here when someone in the circle adds'),
        findsOneWidget,
      );
      expect(find.text(editWordsLabel), findsNothing);
    });

    testWidgets('offline, the chip at the top says the board is saved here', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final selected = circle_();
      await tester.pumpWidget(
        MaterialApp(
          theme: chorusTheme(),
          home: HomeScreen(
            circles: [selected],
            selected: selected,
            onSelect: (_) {},
            store: FakeBoardStore.seeded(),
            sync: FakeSyncStatus(state: ui.SyncState.offline),
            speech: FakeSpeech(),
            gateway: FakeGateway(),
            readiness: CircleReadiness.ready,
            onRetryReady: () {},
            onSignOut: () {},
          ),
        ),
      );
      final chip = tester.getRect(find.text('Offline, saved on this device'));
      expect(chip.top, lessThan(80));
      // The board on this device still opens.
      expect(find.text(openBoardLabel('Maya')), findsOneWidget);
    });
  });
}
