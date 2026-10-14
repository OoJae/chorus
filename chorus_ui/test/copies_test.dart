// Named board copies from the editor's board menu: saving one, the list,
// the read-only view, and "Put back" through "Needs a home".
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/contracts_copies.dart';
import 'package:chorus_ui/copies/copies_screens.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_copies.dart';
import 'package:chorus_ui/features/flags/w8.dart';
import 'package:chorus_ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpApp(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(1280, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: chorusTheme(), home: screen));
  await tester.pump();
}

Future<void> openMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip(boardMenuLabel));
  await tester.pumpAndSettle();
}

void main() {
  late FakeBoardStore store;
  late FakeBoardCopies copies;

  setUp(() {
    store = FakeBoardStore.seeded();
    copies = FakeBoardCopies(store, now: () => DateTime.utc(2026, 10, 14, 9));
  });

  TileFacts byLabel(String label) =>
      store.tiles.firstWhere((tile) => tile.label == label && !tile.archived);

  test('the flag is on, and copies are offered only with a source', () {
    expect(boardCopiesEnabled, isTrue);
    expect(offersCopies(copies), isTrue);
    expect(offersCopies(null), isFalse);
  });

  testWidgets('without copies the board menu has neither item', (tester) async {
    await pumpApp(tester, EditorScreen(store: store, sync: FakeSyncStatus()));
    await openMenu(tester);
    expect(find.text(saveCopyLabel), findsNothing);
    expect(find.text(copiesLabel), findsNothing);
  });

  testWidgets('"Save a copy" asks for a name and keeps the board\'s words; '
      'the board does not change', (tester) async {
    final before = store.tiles;
    await pumpApp(
      tester,
      EditorScreen(store: store, sync: FakeSyncStatus(), copies: copies),
    );
    await openMenu(tester);
    await tester.tap(find.text(saveCopyLabel));
    await tester.pumpAndSettle();
    // A name is needed.
    await tester.tap(find.text('Save copy'));
    await tester.pump();
    expect(find.text('Give the copy a name.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Before the school trip');
    await tester.tap(find.text('Save copy'));
    await tester.pumpAndSettle();

    expect(
      find.text(savedCopyMessage('Before the school trip')),
      findsOneWidget,
    );
    final kept = await copies.list();
    expect(kept.single.name, 'Before the school trip');
    expect(kept.single.wordCount, 36);
    expect(store.tiles, before);
  });

  testWidgets('a copy shows its grid read-only, lists the words the board '
      'no longer has, and "Put back" sends one to "Needs a home" without '
      'touching a cell', (tester) async {
    final board = store.boards.firstWhere((b) => b.isHome);
    await copies.take(board, 'Before');
    final help = byLabel('help');
    await store.archiveTile(help.id);
    final placed = gridOf(board.id, store.tiles, store.boards);

    await pumpApp(
      tester,
      EditorScreen(store: store, sync: FakeSyncStatus(), copies: copies),
    );
    await openMenu(tester);
    await tester.tap(find.text(copiesLabel));
    await tester.pumpAndSettle();
    expect(find.textContaining('36 words'), findsOneWidget);
    await tester.tap(find.text('Before'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text(putBackLabel), 200);
    expect(find.text(notOnBoardHeading), findsOneWidget);
    expect(find.text(putBackLabel), findsOneWidget);
    await tester.tap(find.text(putBackLabel));
    await tester.pumpAndSettle();

    expect(find.text(putBackMessage('help')), findsOneWidget);
    final waiting = trayOf(store.tiles, store.boards);
    expect(waiting.single.tile.label, 'help');
    expect(waiting.single.tile.boardId, board.id);
    expect(waiting.single.reason, TrayReason.unplaced);
    // Every placed word is where it was.
    expect(gridOf(board.id, store.tiles, store.boards), placed);
    // Waiting now, so it is no longer offered.
    expect(find.text(putBackLabel), findsNothing);
    expect(find.text(allWordsHereMessage), findsOneWidget);
  });

  testWidgets('a read-only partner can look at copies but not save, delete '
      'or put back', (tester) async {
    final board = store.boards.firstWhere((b) => b.isHome);
    await copies.take(board, 'Before');
    await store.archiveTile(byLabel('help').id);
    store.role = CircleRole.partner;

    await pumpApp(
      tester,
      EditorScreen(store: store, sync: FakeSyncStatus(), copies: copies),
    );
    await openMenu(tester);
    expect(find.text(saveCopyLabel), findsNothing);
    await tester.tap(find.text(copiesLabel));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    await tester.tap(find.text('Before'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('help').last, 200);
    expect(find.text(putBackLabel), findsNothing);
  });

  testWidgets('a copy can be deleted after asking', (tester) async {
    final board = store.boards.firstWhere((b) => b.isHome);
    await copies.take(board, 'Old');
    await pumpApp(tester, CopiesScreen(copies: copies, store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete "Old"'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await copies.list(), isEmpty);
    expect(find.text(noCopiesYetMessage), findsOneWidget);
  });

  testWidgets('with no connection the list says so in plain words', (
    tester,
  ) async {
    copies.online = false;
    await pumpApp(tester, CopiesScreen(copies: copies, store: store));
    await tester.pumpAndSettle();
    expect(find.text(copiesOfflineMessage), findsOneWidget);
    expect(copiesOfflineMessage.toLowerCase(), isNot(contains('error')));
    copies.online = true;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text(noCopiesYetMessage), findsOneWidget);
  });

  test('a fake store adds a word to the tray only', () async {
    final id = await store.addToTray(
      boardId: store.homeBoardId,
      label: 'swing',
      imageHash: 'h',
    );
    final tile = store.tiles.firstWhere((t) => t.id == id);
    expect(CellKey.parse(tile.cellKey), TrayCell(id));
    expect(tile.imageHash, 'h');
    store.role = CircleRole.partner;
    expect(
      () => store.addToTray(boardId: store.homeBoardId, label: 'x'),
      throwsStateError,
    );
  });
}
