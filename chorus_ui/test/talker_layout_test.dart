// The child's screen on a phone, upright (360x800) and on its side
// (800x360): the strip gets the width, every label on a board is one size,
// and the grid keeps the height.
import 'package:chorus_shared/chorus_shared.dart';
import 'package:chorus_ui/contracts.dart';
import 'package:chorus_ui/editor/editor_screen.dart';
import 'package:chorus_ui/fakes.dart';
import 'package:chorus_ui/fakes_live.dart';
import 'package:chorus_ui/talker/talker_screen.dart';
import 'package:chorus_ui/theme.dart';
import 'package:chorus_ui/widgets/board_tabs.dart';
import 'package:chorus_ui/widgets/label_fit.dart';
import 'package:chorus_ui/widgets/sync_chip.dart';
import 'package:chorus_ui/widgets/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _portrait = Size(360, 800);
const _landscape = Size(800, 360);
const _tablet = Size(1200, 1600);

Future<void> _pump(WidgetTester tester, Widget screen, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: chorusTheme(), home: screen));
}

final Finder _strip = find.bySemanticsLabel(RegExp('^Sentence'));
final Finder _speak = find.bySemanticsLabel('Speak');
final Finder _delete = find.bySemanticsLabel('Delete last word');
final Finder _clear = find.bySemanticsLabel('Clear');

Finder _tile(String label) =>
    find.byWidgetPredicate((w) => w is TileView && w.tile.label == label);

/// The sentence as drawn inside the strip.
Finder _sentence(String text) =>
    find.descendant(of: _strip, matching: find.text(text));

/// Font size of every tile label on show.
Set<double> _labelSizes(WidgetTester tester) => {
  for (final text in tester.widgetList<Text>(
    find.descendant(of: find.byType(TileView), matching: find.byType(Text)),
  ))
    text.style!.fontSize!,
};

void main() {
  test('the layout follows the room there is', () {
    expect(talkerLayoutFor(_portrait), TalkerLayout.narrow);
    expect(talkerLayoutFor(_landscape), TalkerLayout.short);
    expect(talkerLayoutFor(const Size(640, 336)), TalkerLayout.short);
    expect(talkerLayoutFor(_tablet), TalkerLayout.roomy);
    expect(talkerLayoutFor(const Size(1200, 900)), TalkerLayout.roomy);
    // Too narrow for one row and too short: the upright arrangement.
    expect(talkerLayoutFor(const Size(400, 300)), TalkerLayout.narrow);
  });

  group('upright phone, 360x800', () {
    testWidgets('the strip has the whole width and the three buttons sit in '
        'a row beneath it', (tester) async {
      final speech = FakeSpeech();
      await _pump(
        tester,
        TalkerScreen(
          store: FakeBoardStore.seeded(),
          speech: speech,
          sync: FakeSyncStatus(),
        ),
        _portrait,
      );
      final strip = tester.getRect(_strip);
      expect(strip.width, greaterThanOrEqualTo(340));
      expect(strip.height, greaterThanOrEqualTo(56));

      final buttons = [_speak, _delete, _clear].map(tester.getRect).toList();
      for (final button in buttons) {
        expect(button.top, greaterThanOrEqualTo(strip.bottom));
        expect(button.width, greaterThanOrEqualTo(48));
        expect(button.height, greaterThanOrEqualTo(48));
        expect(button.top, buttons.first.top, reason: 'one row');
      }
      expect(buttons[0].right, lessThanOrEqualTo(buttons[1].left));
      expect(buttons[1].right, lessThanOrEqualTo(buttons[2].left));
      // The board is below all of it.
      expect(
        tester.getRect(_tile('like')).top,
        greaterThanOrEqualTo(buttons.first.bottom),
      );

      await tester.tap(_tile('want'));
      await tester.tap(_speak);
      await tester.pump();
      expect(speech.spoken, ['want', 'want']);
    });

    testWidgets('a short sentence is large and starts at the left of the '
        'strip; a long one keeps its newest word in view', (tester) async {
      await _pump(
        tester,
        TalkerScreen(
          store: FakeBoardStore.seeded(),
          speech: FakeSpeech(),
          sync: FakeSyncStatus(),
        ),
        _portrait,
      );
      await tester.tap(_tile('I'));
      await tester.tap(_tile('want'));
      await tester.pump();

      final strip = tester.getRect(_strip);
      final short = _sentence('I want');
      expect(tester.widget<Text>(short).style!.fontSize, 32);
      final shortRect = tester.getRect(short);
      expect(shortRect.left, closeTo(strip.left + 12, 3));
      expect(shortRect.right, lessThanOrEqualTo(strip.right));

      for (final word in ['different', 'finished', 'where', 'more']) {
        await tester.tap(_tile(word));
      }
      await tester.pump();
      final long = _sentence('I want different finished where more');
      expect(tester.widget<Text>(long).style!.fontSize, 32);
      final longRect = tester.getRect(long);
      expect(longRect.width, greaterThan(strip.width), reason: 'it scrolls');
      expect(longRect.right, closeTo(strip.right - 12, 3), reason: 'the tail');
    });

    testWidgets('the fullest status row still fits, with every way out and '
        'every warning on it', (tester) async {
      final store = FakeBoardStore.seeded();
      final live = FakeLiveSession();
      addTearDown(live.dispose);
      final sync = FakeSyncStatus(state: SyncState.offline);
      var left = 0;
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: FakeSpeech(offlineVoice: false),
          sync: sync,
          live: live,
          onExit: () => left++,
        ),
        _portrait,
      );
      // A word in the strip holds the merges back, so they wait.
      await tester.tap(_tile('want'));
      final want = store.tiles.singleWhere((t) => t.label == 'want');
      await store.updateTile(want.id, label: 'wish');
      await store.archiveTile(
        store.tiles.singleWhere((t) => t.label == 'more').id,
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      expect(find.textContaining('waiting'), findsOneWidget);
      expect(find.bySemanticsLabel(liveConnectedMessage), findsOneWidget);
      expect(find.bySemanticsLabel(noOfflineVoiceMessage), findsOneWidget);
      expect(find.text(leaveLabel), findsOneWidget);

      // The chip is an icon here; its words are still said, and a tap
      // retries as "Sync now" would.
      final chip = find.byType(SyncChip);
      expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
      expect(
        find.bySemanticsLabel(RegExp('Offline, saved on this device')),
        findsOneWidget,
      );
      await tester.tap(chip);
      expect(sync.syncNowCalls, 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text(leaveLabel)),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      expect(left, 1);
      await gesture.up();
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('phone on its side, 800x360', () {
    testWidgets('strip, buttons, status and "Hold to leave" share one row, '
        'the tabs stand beside the grid, and the grid has at least 70% of '
        'the height', (tester) async {
      final speech = FakeSpeech();
      var left = 0;
      await _pump(
        tester,
        TalkerScreen(
          store: FakeBoardStore.seeded(),
          speech: speech,
          sync: FakeSyncStatus(),
          onExit: () => left++,
        ),
        _landscape,
      );
      final strip = tester.getRect(_strip);
      final row = [
        _speak,
        _delete,
        _clear,
        find.byType(SyncChip),
        find.text(leaveLabel),
      ].map(tester.getRect).toList();
      for (final item in row) {
        expect(item.left, greaterThanOrEqualTo(strip.right));
        expect(item.center.dy, closeTo(strip.center.dy, 4), reason: 'one row');
      }
      for (final button in row.take(3)) {
        expect(button.width, greaterThanOrEqualTo(48));
        expect(button.height, greaterThanOrEqualTo(48));
      }
      expect(strip.width, greaterThanOrEqualTo(300));

      // The grid: from the top of the first row to the bottom of the last.
      final first = tester.getRect(_tile('like'));
      final last = tester.getRect(_tile('stop'));
      expect(first.top, greaterThanOrEqualTo(strip.bottom));
      // Each cell is its tile plus the 3 px gap round it.
      final gridHeight = last.bottom - first.top + 6;
      expect(gridHeight, greaterThanOrEqualTo(0.7 * _landscape.height));
      expect(first.height, greaterThanOrEqualTo(40));

      final tabs = tester.getRect(find.byType(BoardTabs));
      expect(tabs.right, lessThanOrEqualTo(first.left));
      expect(tabs.top, greaterThanOrEqualTo(strip.bottom));
      expect(tabs.height, greaterThanOrEqualTo(0.7 * _landscape.height));
      expect(tabs.width, greaterThanOrEqualTo(48));

      // Everything still works from here.
      await tester.tap(_tile('want'));
      await tester.tap(_speak);
      await tester.pump();
      expect(speech.spoken, ['want', 'want']);
      expect(tester.widget<Text>(_sentence('want')).style!.fontSize, 26);

      await tester.tap(
        find.descendant(
          of: find.byType(BoardTabs),
          matching: find.text('My words'),
        ),
      );
      await tester.pump();
      expect(_tile('like'), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(BoardTabs),
          matching: find.text('Home'),
        ),
      );
      await tester.pump();
      expect(_tile('like'), findsOneWidget);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text(leaveLabel)),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      expect(left, 1);
      await gesture.up();
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('with a waiting pill, the live mark and the voice warning '
        'the row still fits and the strip keeps room', (tester) async {
      final store = FakeBoardStore.seeded();
      final live = FakeLiveSession();
      addTearDown(live.dispose);
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: FakeSpeech(offlineVoice: false),
          sync: FakeSyncStatus(state: SyncState.offline),
          live: live,
        ),
        _landscape,
      );
      await tester.tap(_tile('want'));
      await store.archiveTile(
        store.tiles.singleWhere((t) => t.label == 'more').id,
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('waiting'), findsOneWidget);
      // The test font draws every letter a full em wide, about twice the
      // app's font, so the pills here are at their widest.
      expect(tester.getRect(_strip).width, greaterThanOrEqualTo(120));
    });

    testWidgets('a cell is in the same row and column as on a tablet', (
      tester,
    ) async {
      // Positions as fractions of the grid, which must not depend on the
      // arrangement round it.
      Future<Map<String, (int, int)>> cells(Size size) async {
        await _pump(
          tester,
          TalkerScreen(
            key: ValueKey(size),
            store: FakeBoardStore.seeded(),
            speech: FakeSpeech(),
            sync: FakeSyncStatus(),
          ),
          size,
        );
        final origin = tester.getRect(_tile('like'));
        return {
          for (final label in ['like', 'different', 'I', 'stop', 'where'])
            label: (
              ((tester.getRect(_tile(label)).top - origin.top) /
                      (origin.height + 6))
                  .round(),
              ((tester.getRect(_tile(label)).left - origin.left) /
                      (origin.width + 6))
                  .round(),
            ),
        };
      }

      final tablet = await cells(_tablet);
      expect(await cells(_landscape), tablet);
      expect(await cells(_portrait), tablet);
      expect(tablet['stop'], (5, 5));
    });
  });

  group('one label size for a board', () {
    for (final size in const [_portrait, _landscape, _tablet]) {
      testWidgets('every tile on the child\'s board uses it '
          '(${size.width.toInt()}x${size.height.toInt()})', (tester) async {
        await _pump(
          tester,
          TalkerScreen(
            store: FakeBoardStore.seeded(),
            speech: FakeSpeech(),
            sync: FakeSyncStatus(),
          ),
          size,
        );
        final sizes = _labelSizes(tester);
        expect(sizes, hasLength(1), reason: '"I" and "different" alike');
        expect(sizes.single, greaterThanOrEqualTo(minTileLabelSize));
        expect(sizes.single, lessThanOrEqualTo(maxTileLabelSize));
        expect(
          tester
              .widget<Text>(
                find.descendant(of: _tile('I'), matching: find.byType(Text)),
              )
              .style!
              .fontSize,
          tester
              .widget<Text>(
                find.descendant(
                  of: _tile('different'),
                  matching: find.byType(Text),
                ),
              )
              .style!
              .fontSize,
        );
        // Where there is room above the minimum, the longest label fits its
        // tile on one line at that size, unscaled.
        if (sizes.single > minTileLabelSize) {
          final label = tester.getRect(
            find.descendant(
              of: _tile('different'),
              matching: find.byType(Text),
            ),
          );
          final tile = tester.getRect(_tile('different'));
          expect(label.width, lessThanOrEqualTo(tile.width - 12));
          expect(label.height, closeTo(sizes.single, sizes.single * 0.5));
        }
      });
    }

    testWidgets('the size is worked out again only when the layout or the '
        'labels change, and a longer word makes every label smaller', (
      tester,
    ) async {
      final store = FakeBoardStore.seeded();
      await _pump(
        tester,
        TalkerScreen(
          store: store,
          speech: FakeSpeech(),
          sync: FakeSyncStatus(),
        ),
        _tablet,
      );
      final before = _labelSizes(tester).single;

      // A tap rebuilds the screen; the labels and the layout are the same.
      await tester.tap(_tile('want'));
      await tester.pump();
      expect(_labelSizes(tester), {before});

      // "My words" has one short word: its own, larger, size.
      await store.addTile(
        boardId: store.wordsBoardId,
        row: 0,
        col: 0,
        label: 'Gran',
      );
      await tester.tap(find.text('My words'));
      await tester.pump();
      expect(_labelSizes(tester), {maxTileLabelSize});
      expect(maxTileLabelSize, greaterThan(before));

      await tester.tap(find.text('Home'));
      await tester.pump();
      expect(_labelSizes(tester), {before});
    });

    test('TileLabelSizer: the longest label sets the size, between the '
        'minimum and the maximum, and nothing is measured twice', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      final sizer = TileLabelSizer();
      double fit(List<String> labels, Size tile) => sizer.sizeFor(
        labels: labels,
        tile: tile,
        style: const TextStyle(),
        scaler: TextScaler.noScaling,
        direction: TextDirection.ltr,
      );

      const tile = Size(180, 180);
      final short = fit(['I', 'go'], tile);
      expect(short, maxTileLabelSize);
      final measured = sizer.measurements;
      expect(fit(['go', 'I'], tile), short, reason: 'order does not matter');
      expect(sizer.measurements, measured, reason: 'remembered');

      final long = fit(['I', 'go', 'different'], tile);
      expect(long, lessThan(short));
      expect(long, greaterThan(minTileLabelSize));
      expect(sizer.measurements, greaterThan(measured));

      // The same labels in a smaller tile: a new fit, not below the minimum.
      expect(fit(['I', 'go', 'different'], const Size(60, 60)), 14);
      // A tile too low for the line limits the size as well as the width.
      expect(fit(['I', 'go'], const Size(180, 40)), lessThan(maxTileLabelSize));
      // No labels at all is not an error.
      expect(fit([], tile), maxTileLabelSize);
    });
  });

  group('the editor grid uses the same one size', () {
    for (final size in const [_portrait, Size(1400, 1000)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        final store = FakeBoardStore.seeded(leaveEmpty: const {(5, 5)});
        await _pump(
          tester,
          EditorScreen(store: store, sync: FakeSyncStatus()),
          size,
        );
        final sizes = _labelSizes(tester);
        expect(sizes, hasLength(1));
        expect(sizes.single, greaterThanOrEqualTo(minTileLabelSize));
        expect(sizes.single, lessThanOrEqualTo(maxTileLabelSize));
        expect(find.byType(TileView), findsNWidgets(35));
        // The empty cell is still there to add a word to.
        expect(
          find.bySemanticsLabel('Empty spot, row 6, column 6. Add a word here'),
          findsOneWidget,
        );
        expect(placedKey(store.homeBoardId, 5, 5), isNotEmpty);
      });
    }
  });
}
