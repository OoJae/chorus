// The editor in a desktop window: the board takes the height under its tabs,
// with the hint, the chip, model mode and the tray in the column beside it.
// A message about the board floats over that column, not over the board.
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/editor/tray_panel.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_live.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/board_tabs.dart';
import 'package:chorus_ui/widgets/sync_chip.dart';
import 'package:chorus_ui/widgets/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget screen, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: chorusTheme(), home: screen));
}

void main() {
  group('side by side', () {
    // 1280x800 and 1466x800 are the windows the grid was seen small in.
    for (final size in const [
      Size(1440, 900),
      Size(1280, 800),
      Size(1466, 800),
    ]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}: tiles of at '
          'least 96 px, the whole board on screen, every control kept and '
          'nothing overflows', (tester) async {
        final live = FakeLiveSession();
        addTearDown(live.dispose);
        await _pump(
          tester,
          EditorScreen(
            store: FakeBoardStore.seeded(),
            // The widest chip: its words and "Sync now".
            sync: FakeSyncStatus(state: SyncState.offline),
            live: live,
          ),
          size,
        );
        expect(tester.takeException(), isNull);

        expect(find.byType(TileView), findsNWidgets(36));
        expect(
          tester.getSize(find.byType(TileView).first).width,
          greaterThanOrEqualTo(96),
        );
        final grid = tester.getRect(find.byType(EditorGrid));
        expect(grid.bottom, lessThanOrEqualTo(size.height));
        expect(grid.right, lessThanOrEqualTo(size.width));

        // The tabs sit on top of the board, as wide as it is.
        final tabs = tester.getRect(find.byType(BoardTabs));
        expect(tabs.bottom, lessThanOrEqualTo(grid.top));
        expect(tabs.width, moreOrLessEquals(grid.width, epsilon: 0.5));

        // Everything else is in the column on the right.
        for (final control in [
          find.byType(SyncChip),
          find.text('Sync now'),
          find.textContaining('Tap an empty spot to add a word'),
          find.text('Show words on the board'),
          find.text('Needs a home'),
        ]) {
          expect(control, findsOneWidget);
          expect(tester.getRect(control).left, greaterThan(grid.right));
        }
      });
    }

    testWidgets('a placed word is confirmed over the tray column, clear of '
        'the board', (tester) async {
      final store = FakeBoardStore.seeded(leaveEmpty: const {(5, 5)})
        ..remoteConflict(row: 0, col: 0, label: 'playground');
      await _pump(
        tester,
        EditorScreen(store: store, sync: FakeSyncStatus()),
        const Size(1440, 900),
      );
      await tester.tap(find.text('Place in next free spot'));
      await tester.pumpAndSettle();

      final bar = find.byType(SnackBar);
      expect(
        find.descendant(
          of: bar,
          matching: find.text('"playground" is on the board.'),
        ),
        findsOneWidget,
      );
      // The bar itself, inside the margins round it.
      final message = tester.getRect(
        find.descendant(of: bar, matching: find.byType(Material)).first,
      );
      final grid = tester.getRect(find.byType(EditorGrid));
      // The word went to the board's last cell, in the row the bar used to
      // cover.
      final placed = tester.getRect(
        find.ancestor(
          of: find.text('playground'),
          matching: find.byType(TileView),
        ),
      );
      expect(placed.bottom, moreOrLessEquals(grid.bottom, epsilon: 3));
      expect(placed.right, moreOrLessEquals(grid.right, epsilon: 3));
      expect(message.overlaps(grid), isFalse);
      expect(
        message.left,
        greaterThanOrEqualTo(tester.getRect(find.text('Needs a home')).left),
      );
      expect(message.right, lessThanOrEqualTo(1440));
      expect(message.bottom, lessThanOrEqualTo(900));
      await tester.pump(const Duration(seconds: 5));
    });
  });

  testWidgets('on a phone the board and the tray are one page as before, and '
      'a message spans the bottom', (tester) async {
    await _pump(
      tester,
      EditorScreen(store: FakeBoardStore.seeded(), sync: FakeSyncStatus()),
      const Size(360, 800),
    );
    expect(find.byType(ListView), findsOneWidget);
    final grid = tester.getRect(find.byType(EditorGrid));
    expect(grid.width, moreOrLessEquals(360 - 32));
    expect(
      tester.getTopLeft(find.byType(SyncChip)).dy,
      lessThan(grid.top),
      reason: 'the chip is above the board',
    );
    expect(
      tester.getTopLeft(find.text('Needs a home')).dy,
      greaterThan(grid.bottom),
      reason: 'the tray is under it',
    );

    ScaffoldMessenger.of(tester.element(find.byType(EditorGrid))).showSnackBar(
      const SnackBar(content: Text('"playground" is on the board.')),
    );
    await tester.pumpAndSettle();
    final message = tester.getRect(
      find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(message.width, 360);
    expect(message.bottom, 800);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
