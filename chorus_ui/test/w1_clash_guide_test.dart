// "Try a clash" in the editor: the guide's three steps against fakes, its
// refusals, and that it survives the add-word sheet.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/brand/haptics.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_clash.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_clash.dart';
import 'package:chorus_ui/features/clash/clash_guide.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(1280, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Reduced motion: the glow and the spinner hold still, so the test can
  // wait for everything else to settle.
  await tester.pumpWidget(
    MaterialApp(
      theme: chorusTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: screen,
    ),
  );
}

Future<void> _startClash(WidgetTester tester) async {
  await tester.tap(find.byTooltip(boardMenuLabel));
  await tester.pumpAndSettle();
  await tester.tap(find.text(tryAClashLabel));
  await tester.pumpAndSettle();
}

Finder get _card => find.byKey(ClashGuideCard.cardKey);

Finder _inCard(String text) =>
    find.descendant(of: _card, matching: find.text(text));

void main() {
  setUp(() => ChorusHaptics.sink = (_) {});
  tearDown(() => ChorusHaptics.sink = null);

  for (final size in const [Size(1280, 800), Size(360, 740)]) {
    testWidgets('at ${size.width.toInt()} wide, the guide goes offline, has '
        'the partner fill an empty spot that glows, follows the adult\'s own '
        'word there, and explains the outcome once both words are here', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded(leaveEmpty: {(2, 3)});
      final sync = FakeSyncStatus();
      final partner = FakeClashPartner();
      await _pump(
        tester,
        EditorScreen(store: store, sync: sync, clash: partner),
        size: size,
      );
      await _startClash(tester);

      // Step 1 and 2: offline, the partner asked for the empty spot.
      expect(sync.workingOffline, isTrue);
      expect(partner.asked.single, (
        boardId: store.homeBoardId,
        row: 2,
        col: 3,
      ));
      expect(_inCard(clashPlaceYoursMessage('bubbles')), findsOneWidget);
      // The glowing spot is brought into view by itself.
      expect(find.byType(ClashGlow), findsOneWidget);
      final glow = tester.getRect(find.byType(ClashGlow));
      expect(glow.center.dy, lessThan(size.height * 0.75));

      // The add-word sheet opens over the guide and closes again.
      await tester.tap(find.byType(ClashGlow), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      expect(_inCard(clashPlaceYoursMessage('bubbles')), findsOneWidget);

      // The adult's word goes in the glowing spot (as the sheet would).
      await store.addTile(
        boardId: store.homeBoardId,
        row: 2,
        col: 3,
        label: 'juice',
      );
      await tester.pumpAndSettle();
      expect(_inCard(clashGoOnlineMessage), findsOneWidget);
      expect(find.byType(ClashGlow), findsNothing);

      await tester.ensureVisible(find.text(clashGoOnlineAction));
      await tester.tap(find.text(clashGoOnlineAction));
      await tester.pumpAndSettle();
      expect(sync.workingOffline, isFalse);
      expect(_inCard(clashWaitingMessage), findsOneWidget);

      // The partner's word arrives; the engine parked one of the two.
      store.remoteConflict(
        row: 2,
        col: 3,
        label: 'bubbles',
        byName: 'Practice partner',
      );
      await tester.pumpAndSettle();
      expect(
        _inCard(clashDoneMessage(kept: 'juice', waiting: 'bubbles')),
        findsOneWidget,
      );
      // Nothing was lost.
      expect(
        store.tiles.where((t) => t.label == 'juice' || t.label == 'bubbles'),
        hasLength(2),
      );

      await tester.ensureVisible(_inCard(clashDoneAction));
      await tester.pumpAndSettle();
      await tester.tap(_inCard(clashDoneAction));
      await tester.pumpAndSettle();
      expect(_card, findsNothing);
    });
  }

  testWidgets('when the board on show is full, the guide uses another board '
      'with an empty spot and shows it', (tester) async {
    final store = FakeBoardStore.seeded();
    final sync = FakeSyncStatus();
    final partner = FakeClashPartner();
    await _pump(tester, EditorScreen(store: store, sync: sync, clash: partner));
    await _startClash(tester);
    expect(partner.asked.single.boardId, store.wordsBoardId);
    expect(find.byType(ClashGlow), findsOneWidget);
  });

  testWidgets('when the server already has a word in the spot, the guide '
      'asks for the next empty one', (tester) async {
    final store = FakeBoardStore.seeded(leaveEmpty: {(0, 0), (0, 1)});
    final partner = FakeClashPartner(refusals: [PracticeRefusal.cellTaken]);
    await _pump(
      tester,
      EditorScreen(store: store, sync: FakeSyncStatus(), clash: partner),
    );
    await _startClash(tester);
    expect(partner.asked.map((a) => (a.row, a.col)), [(0, 0), (0, 1)]);
    expect(_inCard(clashPlaceYoursMessage('bubbles')), findsOneWidget);
  });

  for (final (refusal, message) in [
    (PracticeRefusal.tooMany, clashTooManyMessage),
    (PracticeRefusal.noSuchCell, clashNoSuchCellMessage),
    (PracticeRefusal.unreachable, clashUnreachableMessage),
  ]) {
    testWidgets('when the partner refuses with ${refusal.name}, the guide '
        'says so plainly, goes back online and offers Try again', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded(leaveEmpty: {(1, 1)});
      final sync = FakeSyncStatus();
      final partner = FakeClashPartner(refusals: [refusal]);
      await _pump(
        tester,
        EditorScreen(store: store, sync: sync, clash: partner),
      );
      await _startClash(tester);
      expect(_inCard(message), findsOneWidget);
      expect(sync.workingOffline, isFalse);
      expect(find.byType(ClashGlow), findsNothing);

      await tester.tap(_inCard(clashTryAgainAction));
      await tester.pumpAndSettle();
      expect(_inCard(clashPlaceYoursMessage('bubbles')), findsOneWidget);
    });
  }

  testWidgets('when every spot on every board is taken, the guide says so '
      'and never goes offline', (tester) async {
    final store = FakeBoardStore.seeded(withWordsBoard: false);
    final sync = FakeSyncStatus();
    final partner = FakeClashPartner();
    await _pump(tester, EditorScreen(store: store, sync: sync, clash: partner));
    await _startClash(tester);
    expect(_inCard(clashNoSpotMessage), findsOneWidget);
    expect(partner.asked, isEmpty);
    expect(sync.workingOffline, isFalse);
  });

  testWidgets('when Work offline goes off before the adult\'s word, the '
      'partner\'s word fills the spot and the guide offers another go', (
    tester,
  ) async {
    final store = FakeBoardStore.seeded(leaveEmpty: {(2, 3)});
    final sync = FakeSyncStatus();
    await _pump(
      tester,
      EditorScreen(store: store, sync: sync, clash: FakeClashPartner()),
    );
    await _startClash(tester);
    await sync.setWorkingOffline(false);
    store.remoteAdd(
      row: 2,
      col: 3,
      label: 'bubbles',
      byName: 'Practice partner',
    );
    await tester.pumpAndSettle();
    expect(_inCard(clashMissedMessage), findsOneWidget);
  });

  testWidgets('closing the guide part way puts the device back online', (
    tester,
  ) async {
    final store = FakeBoardStore.seeded(leaveEmpty: {(2, 3)});
    final sync = FakeSyncStatus();
    await _pump(
      tester,
      EditorScreen(store: store, sync: sync, clash: FakeClashPartner()),
    );
    await _startClash(tester);
    expect(sync.workingOffline, isTrue);
    await tester.tap(_inCard(clashCloseAction));
    await tester.pumpAndSettle();
    expect(_card, findsNothing);
    expect(sync.workingOffline, isFalse);
  });

  testWidgets('a read-only partner, or an editor with no practice partner, '
      'gets no "Try a clash"', (tester) async {
    final viewer = FakeBoardStore.seeded(role: CircleRole.partner);
    expect(offersClash(FakeClashPartner(), viewer), isFalse);
    final editor = FakeBoardStore.seeded();
    expect(offersClash(null, editor), isFalse);
    expect(offersClash(FakeClashPartner(), editor), isTrue);

    await _pump(tester, EditorScreen(store: editor, sync: FakeSyncStatus()));
    await tester.tap(find.byTooltip(boardMenuLabel));
    await tester.pumpAndSettle();
    expect(find.text(tryAClashLabel), findsNothing);
  });

  test('the guide never names a winner before both words are here', () {
    for (final text in [
      clashPreparingMessage,
      clashPlaceYoursMessage('bubbles'),
      clashGoOnlineMessage,
      clashWaitingMessage,
    ]) {
      expect(text.toLowerCase(), isNot(matches(RegExp(r'\bwins?\b'))));
      expect(text.toLowerCase(), isNot(matches(RegExp(r'\bkeeps?\b'))));
      expect(text.toLowerCase(), isNot(contains('conflict')));
      expect(text.toLowerCase(), isNot(contains('error')));
    }
    expect(
      clashDoneMessage(kept: 'bubbles', waiting: 'juice'),
      contains('Nothing was lost'),
    );
    // The spot the guide glows is always a plain placed key.
    expect(placedKey('b', 2, 3), 'b:2:3');
  });
}
